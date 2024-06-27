package Filter::Syntactic;

use 5.022;
use warnings;

our $VERSION = '0.000002';

use Filter::Simple;
use PPR::X;
use experimental 'signatures';

sub _expected ($what = q{}) {
    state ($expected, $unexpected);
    if ($what) {
        $expected   = $what;
        $unexpected = do { substr($_,pos()) =~ m{ \A \s* (\S \N*) } ? $1 : substr($_,pos(),20) };
    }
    else {
        my $expectation = qq{Expected $expected but found "$unexpected"};
        $expected = $unexpected = q{};
        return $expectation;
    }
}

# Extract context information...
sub _line_comment ($str, $pos, $line_offset) {
    $pos //= 0;
    return "\n#" . _line_loc($str, $pos, $line_offset) . "\n";
}

sub _line_loc ($str, $pos, $line_offset) {
    $pos //= 0;
    my $line_num = $line_offset + (substr($str,0,$pos) =~ tr/\n//);
    return "line $line_num";
}

sub import {
    # Generated filters use subroutine signatures (which were experimental until 5.36)...
    if ($] < 5.36) {
        experimental->import('signatures');
    }
}

FILTER {
    return if m{ \A __(DATA|END)__ \n }xms;

    # Remember where we parked...
    my ($filename, $start_line) = (caller 1)[1,2];

    # What filter blocks look like...
    my @filters;
    my $PERL_WITH_FILTER_BLOCKS = qr{
        \A (?&PerlEntireDocument) \z

        (?(DEFINE)
            (?<PerlControlBlock> (?>
                filter \b
                (?>
                    (?<_>                                                              (?>(?&PerlNWS))
                        (?{ _expected('PPR rule name') })
                        (?<NAME>(?<RULENAME> [A-Za-z_]++                          ))   (?>(?&PerlOWS))
                        (?{ _expected('mode, rule, or code block') })
                        (?<MODE>             :extend |                            )    (?>(?&PerlOWS))
                        (?{ _expected('rule or code block') })
                        (?<REGEX>            \( (?>(?&PPR_X_balanced_parens)) \)  )?+  (?>(?&PerlOWS))
                        (?{ _expected('code block') })
                        (?<BLOCK>            (?>(?&PerlBlock))                    )
                    )
                    (?{ _expected();
                        my $len = length($+{_}) + 6;
                        push @filters, { POS => pos() - $len, LEN => $len, END => pos(),
                                         BLOCKPOS => pos() - length($+{BLOCK}), %+ };
                    })
                |
                    (?{ push @filters, { POS => pos() - 6, EXPECTED => _expected(), INVALID => 1 } })
                )
            |
                (?>(?&PerlStdControlBlock))
            ))
        )

        $PPR::X::GRAMMAR
    }xms;

    # Did we find any???
    if (/$PERL_WITH_FILTER_BLOCKS/) {

        # Delete all the filters, reporting bad filters, but leaving the line numbers unchanged...
        my $invalid;
        for my $filter (reverse @filters) {
            if ($filter->{INVALID}) {
                substr($_, $filter->{POS}, 0)
                    = qq{BEGIN { die "Invalid filter specification. \Q$filter->{EXPECTED}\E" } };
                $invalid = 1;
            }
            else {
                substr($_, $filter->{POS}, $filter->{LEN}) =~ tr/\n/ /c;
            }
        }
        return if $invalid;

        # Normalize filters...
        for my $filter (@filters) {

            $filter->{RULENAME}  =~ s{ \A (?:Perl)?+ (.*) \z }{Perl$1}xms;
            $filter->{STDNAME}    = $filter->{RULENAME} =~ s{ \A Perl }{PerlStd}xmsr;
            $filter->{REGEX}    //= "(?&$filter->{STDNAME})";
            my $active_regex      = $filter->{REGEX}
                                        =~ s{ \(\?\(DEFINE\) (?>(?&PPR_X_balanced_parens)) \)
                                              $PPR::X::GRAMMAR }{}gxmsr;
            my @captures          = _uniq($active_regex =~ m{ \(\?< \K [^>]++ }gxms);
            $filter->{CAPTURES}   = \@captures;
            $filter->{UNPACK}     = @captures >  1 ? '[@+{'. join(',', map { "'$_'" } @captures) .'}]'
                                  : @captures == 1 ? qq{[\$+{'$captures[0]'}]}
                                  :                  q{[]};
            my $PARAMS            = join ',', map { '$'.$_ } @captures;
            $filter->{HANDLER}    = qq{sub ($PARAMS)}
                                  . _line_comment($_,$filter->{BLOCKPOS},$start_line)
                                  . $filter->{BLOCK};
        }

        # Build progressive regexes for each filter...
        my ($PATTERN, $SELFPATTERN);
        for my $f (keys @filters) {
            my $filter = $filters[$f];

            # The pattern for this filter needs to capture match information...
            $SELFPATTERN = $filter->{REGEX};
            $PATTERN = qq{
                (?<_> $filter->{REGEX} )
                (?{ my \$len = length(\$+{_});
                    push \@Filter::Syntactic::captures, { RULENAME => '$filter->{RULENAME}',
                                                          CAPTURES => $filter->{UNPACK},
                                                          MATCH    => \$+{_},
                                                          POS      => pos() - \$len,
                                                          LEN      => \$len,
                                                          END      => pos(),
                                                        }
                })
            };

            # If this filter extends a current rule, it needs to include the standard syntax...
            if ($filter->{MODE} eq ':extend') {
                $PATTERN     .= qq{ | (?>(?&$filter->{STDNAME})) };
            }

            # The reparsing rule ALWAYS includes the standard syntax...
            # (because it's reparsing partially transformed source code, which may be standard Perl)
            $SELFPATTERN .= qq{ | (?>(?&$filter->{STDNAME})) };

            # Then we wrap it in the appropriately named subrule...
            $PATTERN       = qq{ (?<$filter->{RULENAME}> $PATTERN     ) };
            $SELFPATTERN   = qq{ (?<$filter->{RULENAME}> $SELFPATTERN ) };

            # The filter also needs to recognize any new syntax for any later filters...
            my $SELFEXTRAS = q{};
            for my $next_filter (@filters[$f+1..$#filters]) {
                my $NEXT_PAT = $next_filter->{REGEX};
                   $NEXT_PAT = $next_filter->{MODE} eq ':extend'
                    ? qq{ (?<$next_filter->{RULENAME}> $NEXT_PAT | (?>(?&$next_filter->{STDNAME}))) }
                    : qq{ (?<$next_filter->{RULENAME}> $NEXT_PAT                                  ) };

                $PATTERN    .= $NEXT_PAT;
                $SELFEXTRAS .= $NEXT_PAT;
            }

            # And the filter's version of the full document-parsing regex gets saved in the filter...
            $filter->{FULLREGEX}
                = qq{ \\A (?&PerlEntireDocument)  \\z (?(DEFINE) $PATTERN    ) \$PPR::X::GRAMMAR };
            $filter->{SELFREGEX}
                = qq{ \\A     $SELFPATTERN        \\z (?(DEFINE) $SELFEXTRAS ) \$PPR::X::GRAMMAR };
        }

        # Build handlers...
        for my $filter (@filters) {
            my $PARAMS         = join ',', map { '$'.$_ } @{$filter->{CAPTURES}};
            my $__LINE__       = _line_loc($_,$filter->{POS},$start_line);
            $filter->{HANDLER} = qq{sub ($PARAMS)}
                                  . _line_comment($_,$filter->{BLOCKPOS},$start_line)
                                  . qq{ {   # Check for nested replacements...
                                            if (\$_ ne \$_{MATCH}) {
                                                if (m{$filter->{SELFREGEX}}xms) {
                                                    ($PARAMS) = \@{$filter->{UNPACK}};
                                                }
                                                else {
                                                    warn 'filter $filter->{NAME} from ', __PACKAGE__,
                                                         ' (', __FILE__, ' $__LINE__)',
                                                         ' is not recursively self-consistent at ',
                                                         "\$_{LOC}\n";
                                                }
                                            }

                                            # Execute the transformation...
                                            $filter->{BLOCK};
                                        }
                                    }
                                  . _line_comment($_,$filter->{END},$start_line);
        }

        # Build the lookup table of transformation handlers for each filter...
        my $LUT = q{my %_HANDLER = (}
                . join(',', map { qq{ '$_->{RULENAME}' => $_->{HANDLER} } } @filters)
                . q{);};

        # Build replacement processing loops...
        my $FIRST_FILTER = 1;
        my $PROC_LOOPS = q{ my ($filename, $start_line); };
        for my $filter (@filters) {
            $PROC_LOOPS .=  q{ local @Filter::Syntactic::captures;
                                ($filename, $start_line) = (caller 1)[1,2];
                             }
                         . qq{ if (m{$filter->{FULLREGEX}}xms) }
                         . (q{ {
                                # Index captures and generate error message context info...
                                my $index = 1;
                                for my $capture (sort {$a->{POS} <=> $b->{POS}} @Filter::Syntactic::captures) {
                                    $capture->{ORD} = $index++;
                                    $capture->{LOC} = qq{$filename }
                                                    . Filter::Syntactic::_line_loc(
                                                            $_, $capture->{POS}, $start_line
                                                      );
                                }

                                # Identify and record any nested captures...
                                for my $c (reverse keys @Filter::Syntactic::captures) {
                                    my $capture = $Filter::Syntactic::captures[$c];

                                    POSSIBLE_OUTER:
                                    for my $prev (@Filter::Syntactic::captures[reverse 0..$c-1]) {
                                        last POSSIBLE_OUTER if $prev->{END} < $capture->{POS};
                                        if ($capture->{END} > $prev->{END}) {
                                            push @{$prev->{OUTERS}}, $capture;
                                            use Scalar::Util 'weaken';
                                            weaken($prev->{OUTERS}[-1]);
                                        }
                                    }
                                }

                                # Install replacement code and any adjust outer captures...
                                for my $capture
                                    (sort {$b->{POS} <=> $a->{POS}} @Filter::Syntactic::captures) {
                                        # Generate replacement code...
                                        my $replacement = do {
                                            local $_  = substr($_, $capture->{POS}, $capture->{LEN});
                                            local *_  = $capture;
                                            $_HANDLER{ $capture->{RULENAME} }(@{$capture->{CAPTURES}});
                                        };

                                        # Replace capture...
                                        substr($_, $capture->{POS}, $capture->{LEN}) = $replacement;

                                        # Adjust length of surrounding captures...
                                        my $delta = length($replacement) - $capture->{LEN};
                                        for my $outer (@{$capture->{OUTERS}}) {
                                            $outer->{LEN} += $delta;
                                        }
                                    }
                                    if ($_debugging) {
                                        Filter::Syntactic::_debug(
                                            'Before filter <FILTERNAME>' => $_prev_under,
                                            ' After filter <FILTERNAME>' => $_,
                                        );
                                        $_prev_under = $_;
                                    }
                                }
                            } =~ s{<FILTERNAME>}{$filter->{NAME}}gr
                            )
                          . ( $FIRST_FILTER
                                ? q{ else {
                                    # Failure to parse the initial source code is an external issue...
                                    my $error = $PPR::X::ERROR->origin($start_line, $filename);
                                    my $diagnostic = "syntax error at $filename line " . $error->line;
                                    $diagnostic .= qq{\nnear: }
                                                 . ($error->source =~ s{ \A (\s* \S \N* ) .* }{$1}xmsr
                                                                   =~ tr/\n/ /r)
                                        if $diagnostic !~ /, near/;
                                    die "$diagnostic\n";
                                    }
                                  }
                                : q{ else {
                                    # Report the (presumably) filter-induced syntax error...
                                    my $error = $PPR::X::ERROR->origin($start_line, $filename);
                                    my $diagnostic = "syntax error at $filename line " . $error->line;
                                    $diagnostic .= qq{\nnear: }
                                                 . ($error->source =~ s{ \A (\s* \S \N* ) .* }{$1}xmsr
                                                                   =~ tr/\n/ /r)
                                        if $diagnostic !~ /, near/;
                                    die "Possible problem with source filter at ",
                                        (caller 1)[1] . " line ", ($start_line-1) . "\n",
                                        "\n$diagnostic\n",
                                        "(possibly the result of source filtering by ",
                                        __PACKAGE__ . " at line " . ($start_line-1) . ")\n";
                                    }
                                  }
                             );
                        $FIRST_FILTER = 0;
        }

        # Create a final syntax check after all the filters have been applied...
        my $FINAL_CHECK = q{
            if ($_ !~ m{ \A (?>(?&PerlEntireDocument)) \z $PPR::X::GRAMMAR }xms) {
                # Report that the final transformation isn't valid Perl...
                my ($file, $line) = (caller 1)[1,2]; $line--;
                my $error = $PPR::X::ERROR->origin($start_line, $filename);
                my $diagnostic = "syntax error at $filename line " . $error->line;
                $diagnostic .= qq{\nnear: }
                             . ($error->source =~ s{ \A (\s* \S \N* ) .* }{$1}xmsr
                                               =~ tr/\n/ /r)
                    if $diagnostic !~ /, near/;
                die "Possible problem with source filter at $file line $line\n",
                    "\n$diagnostic\n",
                    "(possibly the result of source filtering by " . __PACKAGE__ . " at line $line)\n";
            }
        } =~ s{<FILTERLINE>}{$start_line - 1}gre;

        # If there was more than one filter, debug the final state...
        if (@filters > 1) {
            $FINAL_CHECK .= q{
                Filter::Syntactic::_debug(
                    'Initial source' => $_initial_under, '  Final source' => $_, "final"
                ) if $_debugging;
            }
        }

        # Put the entire source filter together...
        my $FILTER = qq{
            use Filter::Simple;

            FILTER {
                # Handle options...
                my \$_debugging = \@_ && \$_[1] && \$_[1] eq '-debug';
                if (!\$_debugging && \$_[1]) {
                    warn "Unknown option: \$_[1] at " . join(' line ', (caller 1)[1,2]) . "\n";
                }

                # Prep for debugging...
                my \$_prev_under    = \$_;
                my \$_initial_under = \$_;

                # Build filter...
                $LUT;
                $PROC_LOOPS
                $FINAL_CHECK
            } { terminator => "" };
        };

        # Install new filter, adjusting line reporting...
        substr ($_, $filters[0]{POS}//0, 0)
            = $FILTER . _line_comment($_, $filters[0]{POS}, $start_line);
    }
    else {
        # Report syntax error...
        my $error = $PPR::X::ERROR->origin($start_line, $filename);
        my $diagnostic = $error->diagnostic || "syntax error at $filename line " . $error->line;
        $diagnostic .= qq{\nnear: } . ($error->source =~ tr/\n/ /r)  if $diagnostic !~ /, near/;
        die "$diagnostic\n";
    }
} {terminator => ""};

sub _uniq (@list) {
    my %seen;
    return grep {!$seen{$_}++} @list;
}

sub _debug ($pre_label, $pre, $post_label, $post, $is_final = 0) {
    # Set up the (possibly paged) output stream for debugging info...
    state $DBOUT = do {
        my $fh;
        if    ($ENV{DIFFPAGER} && open $fh, "|$ENV{DIFFPAGER}") { $fh      }
        elsif ($ENV{PAGER}     && open $fh, "|$ENV{PAGER}"    ) { $fh      }
        else                                                    { \*STDERR }
    };

    # If we can diff, then diff...
    if (eval { require Text::Diff }) {
        print {$DBOUT} "--- $pre_label\n+++ $post_label\n",
                       Text::Diff::diff(\$pre, \$post) . "\n";
    }

    # Otherwise, just print out each post-transformation source (except the last)...
    elsif (!$is_final) {
        print {$DBOUT} '=====[ '. _trim($post_label) . " ]========================\n\n$post\n";
    }

    # For the last, just rule a line under the previous output (which will be identical)...
    else {
        print {$DBOUT} ('=' x 50), "\n\n";
    }
}

sub _trim ($str) {
    return $str =~ s{^\s+}{}r =~ s{\s*$}{}r;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Filter::Syntactic - Source filters based on syntax, instead of luck


=head1 VERSION

This document describes Filter::Syntactic version 0.000002


=head1 SYNOPSIS

    use Filter::Syntactic;

    # Add a new kind of control block (a DWIM block) that calls the _DWIM subroutine...
    filter ControlBlock :extend
        # The following pattern specifies the new syntax (it can use PPR::X named subrules)...
        (
            DWIM (?&PerlOWS)
            (?<REQUEST> \{ (?&PPR_X_balanced_curlies_interpolated) \} )
        )
        # The following block generates the replacement code, when the new syntax is encountered...
        {
            # The $REQUEST variable is autogenerated from the named capture in the pattern..
            "{ _DWIM(qq $REQUEST) }"
        }

    # You can extend any syntactic element that PPR::X provides
    # (and you can leave of the Perl prefix on the element's name, as this example illustrates)...
    filter PerlCall :extend
        # When the new syntax matches...
        ( (?<ARG> (?&PerlTerm) )  ->&  (?<SUBNAME> (?&PerlIdentifier) )  )
        # Replace the matched source code with this...
        { "$SUBNAME($ARG)" }

    # Replace an existing rule instead of extending it
    # (because no :extend attribute is specified)...
    filter Label  ( \[ (?>(?&PerlIdentifier)) \] )  { substr($_,1,-1) . ":" }

    # Apply a filter to every match of an existing rule without changing its syntax
    # (because no new syntax parens are specified)...
    filter QuotelikeQQ {
        s{ (?: \s | \A ) \K \{ (?&PPR_X_balanced_curlies) \} $PPR::X::GRAMMAR }
        {\${\\scalar do $&}}gxmsr;
    }


=head1 DESCRIPTION

This module gives you a C<filter> declarator, with which you can declare
one or more source code filters that respect Perl syntax (with possible extensions).
As with old-style Filter::Simple filters, this new kind of filter is declared at
the outermost scope of the module's files, I<not> in its C<import> subroutine.

The general syntax is:

    filter  RULE   ATTR  (SYNTAX)  {REPLACEMENT}

...but the C<ATTR> and C<(SYNTAX)> components are optional. For example:

    #       RULE   ATTR      (SYNTAX)                    {REPLACEMENT}

    filter  Block  :extend   (%% (?<CONTENTS> .*? ) %%)  { qq({$CONTENTS}) }

    filter  String           ( `` (?<TEXT> .*? ) ''   )  { qq('$TEXT') }

    filter  PerlLabel                                    { qq(warn 'Jumped to $_'; $_) }

Collectively, these C<filter> declarations define a set of variations
on the standard Perl grammar (as represented by the PPR::X module),
each of which rewrites matching components of the source code
using the final value generated in their I<REPLACEMENT> block.

The name of each filter must be the name of a valid subrule in the
PPR::X grammar (see: L<PPR::X/"Available rules">). The C<Perl...>
prefix may be omitted when specifying the subrule name, though it
need not be. The previous example, therefore filters the C<PerlBlock>,
C<PerlString>, and C<PerlLabel> components defined in C<$PPR::X::GRAMMAR>.

If the C<:extend> attribute (which is the only attribute currently supported)
is specified, then the syntax in the following parens is I<added> to the standard
syntax for the component. Otherwise, the syntax in the following parens I<replaces>
the standard syntax. So, in the above example, the C<Block> filter adds a new kind
of block delimited by surrounding C<%%>, whilst the C<String> filter replaces all
the many standard Perl string formats (I<i.e.> C<'string'>, C<"string">, C<q/string/>,
C<qq(string)>, I<etc.>) with a single syntax: C<``string''>.

If the parenthesized syntax is omitted (as in the C<PerlLabel> filter in the previous example),
the filter simply identifies every instance of that syntactic component via its standard
Perl syntax, and replaces each instance with whatever the block generates. Hence:

    filter  PerlLabel                        { qq(warn 'Jumped to $_'; $_) }

...is just a shorthand for:

    filter  PerlLabel  ( (?&PerlStdLabel) )  { qq(warn 'Jumped to $_'; $_) }
                       ####################

The block is called every time a matching syntactic component is found in
the source file being filtered. The substring of that file that matched
the component is then replaced by whatever final value the block produces.
You can also explicitly return that value, if you prefer. Thus these
two versions of the C<String> filter are identical in effect:

    filter  String  ( `` (?<TEXT> .*? ) ''   )  {        qq('$TEXT') }

    filter  String  ( `` (?<TEXT> .*? ) ''   )  { return qq('$TEXT') }

The block has access to any named captures specified in the preceding
syntax parens, via a scalar variable of the same name. Hence, in the
preceding example, C<$TEXT> will contain whatever the C<< (?<TEXT> .*? ) >>
named capture matched. The block also has access to the entire substring
that the syntax parens matched, via C<$_>. In addition, the block has
access to other information from the parse, via the C<%_> hash.
Specifically:

    $_{RULENAME}   The name of filter (and of the rule that it matched)
    $_{MATCH}      The substring of the source file that the filter matched
    $_{POS}        The character position at which the match started
    $_{END}        The character position at which the match ended
    $_{INDEX}      The ordinal position (starting from 1) of the match within the source code
    $_{LEN}        The length of the match
    $_{OUTERS}     An arrayref containing any encapsulating matches of the same filter

B<NOTE: The C<%_> hash provides direct access to the data structures that
the filters themselves use to coordinate their filtering. Modifying any
aspect of any element of C<%_> will almost certainly break your filters
(and possibly the entire universe. :-)>

The C<$_{POS}> and C<$_{END}> character positions are B<NOT> absolute positions
in the source file being filtered; they are I<relative> to the first
character in the source file B<after> the point where the filter has been activated.
Usually, that would be the first character after the C<use> statement
that loaded the filtering module. Mostly, these values are useful only
to uniquely identify each instance of the component that the filter is
processing.

The C<${MATCH}> value is the substring for the component in the original
source file. It may not be identical to the component substring passed
into the block via C<$_>. See L<"Handling nestable components"> for
more details.


=head2 The filtering process

If you place two or more C<filter> definitions in your filtering
module, those filters are applied independently and sequentially
to the entire source code. That is, given:

    filter  Block  :extend   (%% (?<CONTENTS> .*? ) %%)  { qq({$CONTENTS}) }

    filter  String           ( `` (?<TEXT> .*? ) ''   )  { qq('$TEXT') }

    filter  PerlLabel                                    { qq(warn 'Jumped to $_'; $_) }

...first every block in the source is located and transformed,
then every string in the source is found and replaced,
then every label in the string is identified and substituted.

This means that any subsequent filter will be applied to a version of
the source code that has already been preprocessed by every earlier filter.
It is therefore generally a good idea E<mdash> though not essential E<mdash> to specify
filters that process larger components (such as blocks or statements) before
those that process smaller components (such as expressions or literals).

Each filter parses the entire source code top-to-bottom, but the
replacement source for each matched instance is generated and then
substituted into the source in the opposite order: bottom-to-top. This is necessary
to ensure that any L<nested components|"Handling nestable components">
are transformed before the components that contain them.

However, this bottom-to-top replacement sequence has consequences
for any filter that maintains an internal counter
(or any other state information), especially if that counter is
then substituted into the source code. In particular, interpolating
a stateful counter will I<not> produce ascending count sequences,
as might be expected. For example:

    # Track entry and exit of every block...
    filter Block {
        state $BLOCKNUM = 0;                              # Shared counter
        $BLOCKNUM++;                                      # ...incremented
        qq{ {         warn "Entering block $BLOCKNUM\n";  # ...and interpolated
              defer { warn " Leaving block $BLOCKNUM\n" } #    into source code
              $_
            }
        }
    };

This is likely to produce output something like:

    Entering block 46
    Entering block 45
     Leaving block 45
    Entering block 44
     Leaving block 44
     Leaving block 46

...which may confuse end-users, because the numbers count down, not up,
as control moves through the code. In other words, users may expect
the first few blocks to be C<"block 1">, C<"block 2">, C<"block 3">,
but they might turn out to be C<"block 86">, C<"block 85">, C<"block 84">
instead.

To mitigate this necessary bottom-to-top ordering, each match is given
a unique consecutive ordinal index (starting from 1), corresponding to
its position within the source being filtered. This ordinal index
is available though the C<%_> variable (specifically through C<$_{ORD}>)
within the body of the filter. For example:

    # Track entry and exit of every block...
    filter Block {
        qq{ {         warn "Entering block $_{ORD}\n";   # "Count" using ordinal index
              defer { warn " Leaving block $_{ORD}\n" }  # within source code
              $_
            }
        }
    };

This would then produce output something like:

    Entering block 1
    Entering block 2
     Leaving block 2
    Entering block 3
     Leaving block 3
     Leaving block 1


=head2 Debugging your filters

When you use this module to create filters, the module in which
you are creating those filters can then be loaded with a single
option: C<-debug>. If your filtering module is loaded with that
option, the filtering process becomes verbose and reports the
effects of each successive filter in the module.

At a minumum, the filters each report how the source code they're
collectively filtering changes after each filter has been applied.
You get something like:

    =====[  After filter ControlBlock ]========================

    sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    say 'sourcery'->&demo;
    goto HERE;
    say qq{n = {$n++} : { get_blocks() } };
    [HERE] exit;

    =====[  After filter PerlCall ]========================

    sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    say demo('sourcery');
    goto HERE;
    say qq{n = {$n++} : { get_blocks() } };
    [HERE] exit;

    =====[  After filter Label ]========================

    sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    say demo('sourcery');
    goto HERE;
    say qq{n = {$n++} : { get_blocks() } };
    HERE: exit;

    =====[  After filter QuotelikeQQ ]========================

    sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    say demo('sourcery');
    goto HERE;
    say qq{n = ${\scalar do{ $n++ }} : ${\scalar do{  get_blocks()  }} };
    HERE: exit;

If the module can locate and load the C<Text::Diff> module,
then you get diffs instead (including a final cumulative diff
between the original source and the final filtered version):

    --- Before filter ControlBlock
    +++  After filter ControlBlock
    @@ -1,4 +1,4 @@
    -sub demo ($what) { DWIM { a block } }
    +sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    say 'sourcery'->&demo;
    goto HERE;

    --- Before filter PerlCall
    +++  After filter PerlCall
    @@ -1,5 +1,5 @@
    sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    -say 'sourcery'->&demo;
    +say demo('sourcery');
    goto HERE;
    say qq{n = {$n++} : { get_blocks() } };

    --- Before filter Label
    +++  After filter Label
    @@ -2,4 +2,4 @@
    goto HERE;
    say qq{n = {$n++} : { get_blocks() } };
    -[HERE] exit;
    +HERE: exit;

    --- Before filter QuotelikeQQ
    +++  After filter QuotelikeQQ
    @@ -1,5 +1,5 @@
    say demo('sourcery');
    goto HERE;
    -say qq{n = {$n++} : { get_blocks() } };
    +say qq{n = ${\scalar do{ $n++ }} : ${\scalar do{  get_blocks()  }} };
    HERE: exit;

    --- Initial source
    +++   Final source
    @@ -1,5 +1,5 @@
    -sub demo ($what) { DWIM { a block } }
    +sub demo ($what) { { DWIM::Block::_DWIM(qq { a block }) } }
    -say 'sourcery'->&demo;
    +say demo('sourcery');
    goto HERE;
    -say qq{n = {$n++} : { get_blocks() } };
    +say qq{n = ${\scalar do{ $n++ }} : ${\scalar do{  get_blocks()  }} };
    -[HERE] exit;
    +HERE: exit;

If C<$ENV{DIFFPAGER}> is defined, the debugging output will be piped
through that utility. Otherwise, if C<$ENV{PAGER}> is defined,
that utility will be used. If neither is defined, the debugging
information is simply printed to C<STDERR>.


=head2 Handling nestable components

B<[NOTE: The following section documents a very rare situation that may arise
when filtering using this module, and wades some way down into the module's
implementation in order to explain it. With luck, you will never encounter
the issues described here, so you can almost certainly skip this bit initially,
unless a specific error message has directed you here.]>

Many of the syntactic components that this module can filter are intrinsically
recursive: they can contain nested instances of the same component within them.
Blocks can contain nested blocks, subroutine definitions can contain nested
subroutines, package declarations can contain nested packages, anonymous
arrays can contain smaller anonymous arrays, the keys of a hash look-up
can contain other hash-lookups, I<etc.>, I<etc.>

This presents a challenge when filtering such components. Any "inner" (I<i.e.>
contained or nested) instances of a particular kind of component (say, a C<Block>)
must obviously be transformed before any of the "outer" instances that
contain/surround them, because doing the outer transformations first might
partially replace, or even completely remove, the inner instances...before they
can be processed.

However, performing the inner transformations first means that, by the time
the outer transformations occur, the source code of that outer component
will not be identical to the original source from the file that is being filtered.
Which means that the original named captures that the filter block receives will
not contain the I<updated> source, reflecting the now-transformed inner components.

For example, consider a filter that tracks new-style packages:

    filter PackageDeclaration :extend
        (
            package (?&PerlNWS)      (?<NAME>  (?&PerlQualifiedIdentifier) )
                (?: (?&PerlNWS)      (?<VERS>  (?&PerlVersionNumber)       ) )?+
                    (?&PerlOWSOrEND) (?<BLOCK> (?&PerlBlock)               )
        )
        {
            qq{ package $NAME $VERS { warn "package now $NAME at ", __LINE__;
                    $BLOCK
                }
            }
        }

Suppose the original source code being filtered was:

    package Outside {
        package Inside {
            sub in { say "in" }
        }
        sub out { say "out" }
    }

After the inner component had been filtered, the partially transformed
source code would look like this:

    package Outside {
        package Inside { warn "package now Inside at ", __LINE__;
            sub in { say "in" }
        }
        sub out { say "out" }
    }

But when the outer package declaration comes to be processed,
the C<< (?<BLOCK> ... ) >> capture from the initial parse
of the original source code (and hence the autogenerated
C<$BLOCK> variable passed to the filter's block) will still
contain the B<original> block of the outer package. Namely:

    $BLOCK = '{
                  package Inside {
                      sub in { say "in" }
                  }
                  sub out { say "out" }
              }'

The filter's replacement code is generated from the interpolated string
in the filter's body:

    qq{ package $NAME $VERS { warn "package now $NAME at ", __LINE__;
            $BLOCK
        }
    }

...which, for the outer package, with its B<original> C<$BLOCK> capture,
would then produce:

    qq{ package Outer  { warn "package now Outer at ", __LINE__;
            {
                package Inside {
                    sub in { say "in" }
                }
                sub out { say "out" }
            }
        }
    }

...which (unintentionally) "untransforms" the previously transformed source code
of the inner package.

To mitigate this very common annoyance, filters automatically check each
instance that they are filtering, to detect whether the original source code
that the instance initially matched has subsequently changed, thereby
invalidating the instance's original captured substrings.

If such a change is detected, the transformed source code for the instance is reparsed,
so that the associated capture variables are updated to reflect the now partially
transformed contents.

So, in the above example, when the C<PackageDeclaration> filter is processing
the outer package declaration, it will detect that the inner package declaration
has already been processed (thereby changing the source code of the inner package
and hence changing the source code for the outer package as well).

The filter will therefore reparse the source code of the outer package,
which will cause the captured substring in the C<$BLOCK> variable to update to:

    $BLOCK = '{
                  package Inside { warn "package now Inside at ", __LINE__;
                      {
                          sub in { say "in" }
                      }
                  }
                  sub out { say "out" }
              }'

This means the filter's block will then correctly transform the outer package's
source code to:

    qq{
        package Outside  { warn "package now Outside at ", __LINE__;
            package Inside  { warn "package now Inside at ", __LINE__;
                {
                    sub in { say "in" }
                }
            }
            sub out { say "out" }
        }
    }

This reparsing process is fully automatic, and only carried out when transformations
of nested components cause the source of their containing components to change.
The automatic reparsing process is so reliable that this documentation explaining it
would not even exist, except for the fact that auto-reparsing can E<mdash> very
occasionally E<mdash> B<fail>.

Reparsing can fail if the replacement of an inner component causes its containing
outer component to no longer match the extended syntax that was specified for
the filter.

For example, suppose you wanted to change the syntax for specifying blocks
from C<{ ... }> to C<< >-{ ... }-< >>
(Yes, that's a I<terrible> idea, but it's about the simplest possible example,
so let's just run with it.)

To accomplish that syntactic change, you would probably write
a filter something like this:

    filter Block
        (  >-\{  (?<CONTENTS> (?&PerlStatementSequence) )  \}-<  )
        { "{$CONTENTS}" }

The filter simply maps the new C<< >-{ ... }-< >> syntax back to the standard
Perl block syntax. But, because the filter is B<replacing> the existing syntax
(not B<extending> it), this means that the replacement source code, with its
transformed-to-standard C<{ ... }> blocks, will no longer match the new syntax rule
(which demands that blocks can I<only> be delimited by S<C<< >-{ ... }-< >>>).

The filter will work fine for unnested blocks, but any source code such as:

    use New::Block::Syntax;

    >-{
       say 'in outer block';

       >-{ say 'in nested block' }-<

       say 'in outer block';
    }-<

...will fail to reparse, because the inner block will first be transformed to:

    >-{
       say 'in outer block';

       { say 'in nested block' }

       say 'in outer block';
    }-<

...but that is no longer a valid block syntax in your modified grammar
(because standard C<{ ... }> blocks are not allowed).
Such a situation will cause a compile-time exception to be thrown,
complaining that:

    filter Block from New::Block::Syntax is not recursively self-consistent

To mitigate this problem, the auto-reparsing process on nested components B<doesn't>
actually reparse with a rule that I<only> matches your new modified syntax for the component.
Instead, it reparses with a rule that matches I<either> your modified syntax I<or>
the standard syntax for that component. Hence, in reality, the above example would
B<not> generate errors, because the reparser would effectively reparse against:

        qr{
            # The new syntax the filter explicitly specified...
            >-\{  (?<CONTENTS> (?&PerlStatementSequence) )  \}-<
          |
            # If that new syntax fails, try the old syntax as well...
            (?&PerlStdBlock)
          }x

This only happens during reparsing; the initial parse uses B<only> the new syntax
(because the filter wasn't marked C<:extend>). This means that the original source
code will only be able to use the horrible new-style block delimiters, but the
replacement code that the filter progressively generates will still be able to
translate nested block delimiters back to the standard delimiters without breaking
the essential reparsing process on outer blocks.

Despite the various mitigations described so far, it I<is> still possible
to define a C<filter> that causes nested reparsing to fail. Most commonly,
this happens when a filter injects replacement code that is inherently
syntactically invalid. For example, if we had made an error in
the I<horrible-new-blocks> example:

    filter Block
        (  >-\{  (?<CONTENTS> (?&PerlStatementSequence) )  \}-<  )
        { "{$CONTENTS" }    # Missing closing curly in the replacement string!!!

...then the syntactically invalid replacement code would cause the source code
of any surrounding blocks to be inherently invalid as well, and the module would
catch this and report a "..not recursively self-consistent" error
(as well as one or more more-puzzling error messages, when it tries to parse
the final broken code).

Such errors usually indicate bugs in the filter implementation, though
occasionally they may reflect inherent flaws in the design of the new syntax.
The only solution at that point is to either debug the filter code,
or rethink the entire design.


=head1 DIAGNOSTICS

=over

=item C<< Invalid filter specification. Expected <X> but found <Y> >>

You specified a C<filter> keyword, but got the syntax wrong.
If possible, the error message will point out precisely
where the syntax it found deviated from what is allowed.

To fix this error, get the syntax right. :-)


=item C<< Possible problem with source filter >>

Application of one of the filters in the specified module
produced a syntax error in the post-filtered code.

This suggests that there is something wrong with the filtering module
that's being loaded at the indicated line. This error will almost always be
followed by a more detailed error message indicating precisely where the
post-filtered syntax error was found.

Note that, as it is the result of source filtering, the syntax error
may not be present in the original source code. To track such
problems down within your filtering module, you may need to
temporarily add the C<-debug> option when loading C<Filter::Syntactic>.
See: L<"Debugging your filters">


=item C<< syntax error (possibly the result of source filtering by <MODULE>) >>

During the filtering process, one of the filters detected that
a preceding filter had introduced a syntax error.

This suggests that there is something wrong with the filtering module
that's being used at the indicated line. Once again, unless the problem
is obvious, it may be necessary to add the C<-debug> option when
C<Filter::Syntactic> is loaded in the filtering module.
See: L<"Debugging your filters">


=item C<< filter <NAME> from <SOMEWHERE> is not recursively self-consistent >>

You are filtering a nestable syntactic component (such as a C<PerlBlock> or
C<PerlExpression>), but the replacement code you are generating for the
inner nested components has caused the outer containing components
to no longer match the syntax you specified (or the standard Perl syntax either).

In other words, the inner nested replacements you are making
are breaking the surrounding outer replacements that are attempted afterwards.

For more details on what is going wrong here, and how to fix it,
see L<"Handling nestable components">.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Filter::Syntactic requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the C<Filter::Simple> and C<PPR::X> modules.


=head1 INCOMPATIBILITIES

None reported.

However, this module may not always coexist happily
with other source-filtering modules, because the filters
it creates expect the source code to be standard Perl
(plus whatever extra syntax those filters provide).

Hence, these filters will not be able to successfully
filter any other non-standard Perl syntax destined
to be filtered by other modules.

If possible, try to load modules that source-filter
via this module I<last>, so that the source code they see
has already had any other non-standard Perl syntax prefiltered.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-filter-syntactic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2024, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
