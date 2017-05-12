package Keyword::Declare;
our $VERSION = '0.000005';

# Perl 5.14 required for pluggable keywords and /.../r
use 5.014; use warnings;

use Keyword::Simple; # ...This module provides the keyword pluggability
use PPI;             # ...This module handles the parsing
use Carp;
use List::Util 'max';

# When to warn about possible endless re-substitution loops...
my $REPLACEMENT_WARN_THRESHOLD  = 100;
my $REPLACEMENT_ABORT_THRESHOLD = 1000;

# Useful patterns...

my $IDENT = qr{
    (?<ident>
        [^\W\d] \w*+
    )
}xms;

my $QUAL_IDENT = qr{
    (?<qual_ident>
        (?&ident) (?: :: (?&ident) )*+
    )

    (?(DEFINE) $IDENT )
}xms;

my $UNEXPECTED = qr{
    \s*+ (?<unexpected> \S{0,10} )
}xms;

my $EMPTY_BLOCK = qr{
    \A \{ \s* \} \Z
}xms;

# Take a keyword specification and make a pretty text representation of it...
sub _build_syntax {
    my ($name, @params) = @_;

    # Compose the syntax description...
    my $syntax = $name;
    for my $param (@params) {
        # Literal parameters are shown verbatim, everything else in angles...
        $syntax .= q{ }
                .  ( $param->{type} =~ /\A'/ && !$param->{upto}
                                     ? substr($param->{type},1,-1)
                   : $param->{desc}  ? ($param->{desc} =~ /\A</ ? $param->{desc} : "<$param->{desc}>")
                   :                   '<' . lc($param->{type} =~ tr/A-Z_/a-z /r) . '>'
                   );
    }
    return $syntax;
}

# Tidy up a list of re-subsitutions, so it shows the cyclic order...
sub _sort_cycle {
    my @list = @_;

    # Start with the first re-substitution...
    my $next  = shift @list;
    my @cycle = $next;
    my $tail  = $next =~ s{\w+\s{2,}(\w+)\b.*}{$1}r;

    # For the rest...
    while (@list) {
        # Work out potential next-in-cycle candidates...
        my @followers    = grep {   m{\A \s* $tail\b }x } @list;
        my @nonfollowers = grep { ! m{\A \s* $tail\b }x } @list;

        # Choose one at random...
        $next = shift(@followers) // shift(@nonfollowers) // last;

        # Continue with that follower as the new end-of-chain...
        push @cycle, $next;
        $tail  = $next =~ s{\w+\s*-->\s*(\w+)\b.*}{$1}r;
        @list = (@nonfollowers, @followers);
    }

    return @cycle;
}

# Prretty print reports about ambiguous keywords...
sub _align_reports {
    my @reports = @_;

    # The reports break down into four whitespace-separated components...
    @reports = map { [ split /\s{2,}/ ] } @reports;

    # Find the longest of each component across all reports...
    my ($max_from, $max_to, $max_spec, $max_loc) = (0,0,0,0);
    for my $report (@reports) {
        $max_from = max($max_from, length($report->[0]));
        $max_to   = max($max_to  , length($report->[1]));
        $max_spec = max($max_spec, length($report->[2]));
        $max_loc  = max($max_loc , length($report->[3]));
    }

    # Reformat every report, with each component aligned to the longest...
    return map {
        sprintf("             %*s --> %-*s  by keyword %-*s  defined at %-*s\n",
                $max_from, $_->[0],
                $max_to  , $_->[1],
                $max_spec, $_->[2],
                $max_loc , $_->[3],
        );
    } @reports;
}

# Install a newly declared keyword...
sub _install_keyword {
    my ($NAME, $SYNTAX, $DESC, $INDEX) = @_;

    # This tracks possible re-substitutions...
    state %replacement_tracker;

    # Tell the current lexical scope that this particular keyword syntax is active...
    ${^H}{"Keyword::Declare active=$SYNTAX"} = $INDEX;

    # Where are we going to install this keyword???
    my $package_where_keyword_used = caller;

    # Install the keyword...
    Keyword::Simple::define "$NAME", sub {
        my ($ref) = @_;

        # Pretend this anonymous sub's name is the keyword's name (for error messages)...
        local *__ANON__ = " $DESC ";

        # Work out where the keyword is being invoked...
        my (undef, $filename, $linenum) = caller();
        my $linecount = $$ref =~ tr/\n//;

        # Track source modifications...
        my $pre_source = $$ref;

        # Are there any versions of this keyword in scope???
        use Carp;
        my @candidate_indices = @{^H}{grep {/^Keyword::Declare active=$NAME\b/} keys %{^H}}
            or croak "Keyword '$NAME' not in scope";

        # Parse the code following the keyword with each available keyword variant...
        my @matches;
        my $max_match_score = 0;
        my %errors;
        my @impls = @{$Keyword::Declare::keyword_impls{$NAME}}[@candidate_indices];
        my $parse_src = PPI::Document->new($ref);
        $parse_src->index_locations;
        IMPL:
        foreach my $impl (@impls) {
            # Can this keyword variant parse the code components actually found after the keyword???
            my ($components_ref, $trailing_source, $error)
                = Keyword::Declare::_match_syntax(
                    $parse_src->clone,
                    $NAME,
                    $impl->{desc} // qq{'$NAME' declaration},
                    @{$impl->{params}},
                );

            # Handle or remember any parsing failure...
            if (defined $error) {
                die "$error->{msg} at $filename line $linenum\n" if exists $error->{msg};
                push @{ $errors{"after $error->{after} but found: $error->{found}"} }, $error->{expected};
            };
            next IMPL if !$components_ref;

            # Remember any successful parse (and how good it was)...
            my $match_score = @{$components_ref};
            push @matches, {
                impl  => $impl,
                args  => $components_ref,
                score => $match_score,
                src   => $trailing_source,
            };

            # Longer variant matches are better than shorter ones...
            $max_match_score = max($match_score, $max_match_score);
        }

        # Discard less-than-maximal matches...
        @matches = grep { $_->{score} == $max_match_score } @matches;

        # Resolve ambiguous matches, if possible...
        if (@matches > 1) {
            @matches = _resolve_matches(@matches);
        }
        if (@matches > 1) {
            my @preferred_matches = grep { $_->{impl}{prefer} } @matches;
            if (@preferred_matches) {
                @matches = @preferred_matches;
            }
        }

        # A single match means we can unambiguously handle the keyword...
        if (@matches == 1) {
            # Generate code to unpack the keyword parameters into variants...
            my $param_list
                = join q{}, map {
                    my $default = $_->{default} // 'undef';
                      !defined($_->{var}) ? 'shift;'
                    : $_->{var} =~ /^\@/  ? qq{my $_->{var}=\@{shift()//[]};}
                    : $_->{upto}          ? qq{my $_->{var}=defined(\$_[0])? join(q{},\@{shift()}) : $default;}
                    :                       qq{my $_->{var} = shift // $default;}
                  } @{$matches[0]{impl}{params}};

            # Generate a subroutine that implements the keyword's code substitution behaviour...
            my $generator = eval qq{
                package $package_where_keyword_used;
                sub {
                    $param_list              # Unpack the parameters
                    $matches[0]{impl}{code}; # Perform the substitution
                }
            };
            die "Internal error: $@" if $@; # This shouldn't ever happen, but we definitely need to know if it does! ;-)

            # Apply the code substitution to generate the replacement source code...
            my $new_source = do {
                no warnings 'redefine';
                local *PPI::Structure::Block::reline
                    = sub { my $self = shift;
                            my $line = $self->logical_line_number + $linenum - 1;
                            return "{\n#line $line $filename\n".substr($self,1);
                        };

                $generator->(@{$matches[0]{args}}) // q{};
            };

            # Prepare a pretty version of the keyword syntax for any subsequent error messages...
            $matches[0]{impl}{syntax}
                //= Keyword::Declare::_build_syntax("$NAME", @{$matches[0]{impl}{params}});

            # Check for possible keyword substitution loops...
            my $new_keyword = $new_source =~ m{ \A \s* ([^\W\d]\w*) \b }x ? $1 : q{};
            $replacement_tracker{$filename,$linenum,'count'}++;
            $replacement_tracker{$filename,$linenum,'involves'}{
                qq{$NAME  $new_keyword  $matches[0]{impl}{syntax}  $matches[0]{impl}{loc}}
            } = 1;

            # If it seems possible that a re-substitution cycle is occurring, warn about that...
            if ($replacement_tracker{$filename,$linenum,'count'} == $REPLACEMENT_WARN_THRESHOLD) {
                carp "\n",
                     "Warning: Possible unresolvable keyword substitution cycle involving:\n",
                     _align_reports(_sort_cycle(keys %{$replacement_tracker{$filename,$linenum,'involves'}})),
                     "         More than $replacement_tracker{$filename,$linenum,'count'} keyword subsitutions";
            }

            # If it seems highly likely that a re-substitution cycle is occurring, give up...
            elsif ($replacement_tracker{$filename,$linenum,'count'} == $REPLACEMENT_ABORT_THRESHOLD) {
                croak "\n",
                      "Error: Probable unresolvable keyword substitution cycle involving:\n",
                      _align_reports(_sort_cycle(keys %{$replacement_tracker{$filename,$linenum,'involves'}})),
                      "       Keywords on line $linenum were not resolved ",
                      "after $replacement_tracker{$filename,$linenum,'count'} keyword substitutions\n",
                      "       Compilation aborted";
            }

            # If debugging requested, provide a summary of the substitution...
            if (${^H}{"Keyword::Declare debug"}) {
                my $keyword = $matches[0]{impl}{syntax};
                my $from    = $NAME . substr($$ref,0,1-length($matches[0]{src}));
                my $to      = $new_source;
                s{^}{    }gm for $keyword, $from, $to;

                my $debug_msg = ( ("#" x 50) . "\n"
                                . " Keyword macro defined at $matches[0]{impl}{loc}:\n\n$keyword\n\n"
                                . " Converted code at $filename line $linenum:\n\n$from\n\n"
                                . " Into:\n\n$to\n\n"
                                . ("#" x 50) . "\n"
                                ) =~ s{^}{###}gmr;

                warn $debug_msg;
            }

            # Preserve line numbers in the original source file...
            $linenum += $linecount - ($matches[0]{src} =~ tr/\n//);
            $$ref = $new_source . "\n#line $linenum $filename\n" . $matches[0]{src};

        }

        # If no valid keyword variants are in scope, report a fatal syntax error...
        elsif (@matches == 0) {
            my %descs = map { $_->{desc} ? ($_->{desc} => 1) : () } @impls;
            my $desc = join ' or ', (%descs ? keys(%descs) : "$NAME declaration");
            croak "Syntax error in $desc...\n",
                  map({ ' Expected ' . join(' or ', @{$errors{$_}}) . " $_\n" } keys %errors);
        }

        # If too many valid keyword variants are in scope, report a fatal ambiguity...
        else {
            croak "Ambiguous use of '$NAME'...\n",
                       ' Could be:  ',
                  join('       or:  ',
                       map { Keyword::Declare::_build_syntax("$NAME", @{$_->{impl}{params}}) . "\n" } @matches
                   );
        }
    };
}

# Compare two types...
sub _is_narrower {
    my ($type_a, $type_b) = @_;

    # Short-circuit on identity...
    return 0  if $type_a eq $type_b;

    # Otherwise, work out the metatypes of the types...
    my $kind_a = $type_a =~ /\A'/ ? 'literal'  :  $type_a =~ m{\A/}xms ? 'pattern'  :  'typename';
    my $kind_b = $type_b =~ /\A'/ ? 'literal'  :  $type_b =~ m{\A/}xms ? 'pattern'  :  'typename';

    # If both are named types, try the standard inheritance hierarchy rules...
    if ($kind_a eq 'typename' && $kind_b eq 'typename') {
        return +1 if $type_b->isa($type_a);
        return -1 if $type_a->isa($type_b);
    }

    # Otherwise, the metatype names "just happen" to be in narrowness order ;-)...
    return $kind_a cmp $kind_b;
}

# Compare two type signatures (of equal length)...
sub _cmp_signatures {
    my ($sig_a, $sig_b) = @_;

    # Track relative ordering parameter-by-parameter...
    my $partial_ordering = 0;
    for my $n (0 .. $#$sig_a) {
        # Find the ordering of the next pair from the two lists...
        my $is_narrower = _is_narrower($sig_a->[$n], $sig_b->[$n]);

        # If this pair's ordering contradicts the ordering so far, there is no ordering...
        return 0 if $is_narrower && $is_narrower == -$partial_ordering;

        # Otherwise if there's an ordering, it becomes the "ordering so far"...
        $partial_ordering ||= $is_narrower;
    }

    # If we make it through the entire list, return the resulting ordering...
    return $partial_ordering;
}

# Resolve ambiguous argument lists using Perl6-ish multiple dispatch rules...
sub _resolve_matches {
    my @sigs = @_;

    # Track narrownesses...
    my %narrower = map { $_ => [] } 0..$#sigs;

    # Compare all signatures, recording definitive differences in narrowness...
    for my $index_1 (0 .. $#sigs) {
        for my $index_2 ($index_1+1 .. $#sigs) {
            my $narrowness = _cmp_signatures($sigs[$index_1]{impl}{sig}, $sigs[$index_2]{impl}{sig});

            if    ($narrowness < 0) { push @{$narrower{$index_1}}, $index_2; }
            elsif ($narrowness > 0) { push @{$narrower{$index_2}}, $index_1; }
        }
    }

    # Was there a signature narrower than all the others???
    my $max_narrower = max map { scalar @{$_} } values %narrower;
    my $unique_narrowest = $max_narrower == $#sigs;

    # If not, return the entire set...
    return @sigs if !$unique_narrowest;

    # Otherwise, return the narrowest...
    return @sigs[ grep { @{$narrower{$_}} >= $max_narrower } keys %narrower ];
}

# Generate the code to be substituted in place of the keyword declaration...
sub _build_keyword_code {
    # These parameters are all going tobe string-interpolated, so quotemeta them...
    my ($NAME, $SYNTAX, $DESC, $INDEX) = map {defined($_) ? quotemeta($_) : $_} @_;
    $DESC //= "$NAME declaration";

    # The keyword declaration is simply replaced by a compile-time call to _install_keyword()...
    return qq{ Keyword::Declare::_install_keyword(qq{$NAME}, qq{$SYNTAX}, qq{$DESC}, qq{$INDEX}); };

}

# Generate a subroutine that implements /.../-style parameter matching...
sub _matcher_for {
    my $regex = shift;

    return sub {
            my $candidate = shift;
            my $source    = q{}.shift;

            # If the following source code matches the regex...
            use re 'eval';
            if ($source =~ s{\A$regex}{}p) {
                my $match = ${^MATCH};

                # If it matched a single PPI token, return that token...
                return (1, $candidate)  if $match eq $candidate;

                # Otherwise, return the first capture or the raw match
                # and the remaining source code (for reparsing)...
                return (1, $1 // $match, $source);
            }

            # If no match, return failure for the original candidate...
            else {
                return (0, $candidate);
            }
    };
}

# Generate a subroutine that matches a single declared class type...
sub _is_a {
    my ($classname) = @_;
    return sub {
        return ($_[0]->isa($classname), $_[0]);
    }
}

# Generate a subroutine that matches any one of several declared class types...
sub _is_any {
    my @classnames = @_;
    return sub {
        for my $classname (@classnames) {
            return (1, $_[0]) if $_[0]->isa($classname);
        }
        return (0, $_[0]);
    }
}

# The following PPI types are all matched using _is_a(), so generate them from a table...
my @single_matches = qw{
    PPI::Statement

    PPI::Token::Regexp
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute
    PPI::Token::Regexp::Transliterate

    PPI::Token::HereDoc
    PPI::Token::Label

    PPI::Token::Whitespace
    PPI::Token::Comment
    PPI::Token::Pod

    PPI::Token::Number
    PPI::Token::Number::Binary
    PPI::Token::Number::Octal
    PPI::Token::Number::Hex
    PPI::Token::Number::Float
    PPI::Token::Number::Exp
    PPI::Token::Number::Version

    PPI::Token::ArrayIndex

    PPI::Token::Operator

    PPI::Token::Quote
    PPI::Token::Quote::Single
    PPI::Token::Quote::Double
    PPI::Token::Quote::Literal
    PPI::Token::Quote::Interpolate

    PPI::Token::QuoteLike
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Words
    PPI::Token::QuoteLike::Readline

    PPI::Structure::Subscript

    PPI::Structure::Constructor
};

my %multi_matches = (
    List       => [qw<  PPI::Structure::List           PPI::Structure::Condition >],
    Expression => [qw<  PPI::Statement::Expression     PPI::Statement            >],
    AnonHash   => [qw<  PPI::Structure::Constructor    PPI::Structure::Block     >],
    String     => [qw<  PPI::Token::HereDoc            PPI::Token::Quote         >],
    Pattern    => [qw<  PPI::Token::QuoteLike::Regexp  PPI::Token::Regexp::Match >],
);

# Build look-up table of standard recognizers...
my %recognizer_for = (
    # Everything from the preceding type tables...
    map( { m{.*::(.*)}; $1 => _is_a($_) } @single_matches ),

    map( { $_ => _is_any( @{$multi_matches{$_}} ) } keys %multi_matches ),

    # But override these...
    Block      => sub { return ($_[0] =~ $EMPTY_BLOCK || $_[0]->isa('PPI::Structure::Block'), $_[0]) },
    Identifier => sub { return (scalar $_[0] =~ m{\A [^\W\d]\w* \Z }x,                      $_[0]) },
    QualIdent  => sub { return (scalar $_[0] =~ m{\A [^\W\d]\w* (?: :: [^\W\d]\w* )* \Z }x, $_[0]) },
    Comma      => sub { return (scalar $_[0] =~ m{\A (?:,|=>) \Z }x,                        $_[0]) },
    Var        => sub { return (scalar $_[0] =~ m{\A [\$\@%] [^\W\d]\w* \Z}x,               $_[0]) },
    ScalarVar  => sub { return (scalar $_[0] =~ m{\A      \$ [^\W\d]\w* \Z}x,               $_[0]) },
    ArrayVar   => sub { return (scalar $_[0] =~ m{\A      \@ [^\W\d]\w* \Z}x,               $_[0]) },
    HashVar    => sub { return (scalar $_[0] =~ m{\A       % [^\W\d]\w* \Z}x,               $_[0]) },
    Integer    => sub { return (scalar $_[0] =~ m{\A     [+-]? \d+      \Z}x,               $_[0]) },
);

# Add in some convenient aliases...
my %type_aliases = (
    Identifier => 'Ident',
    Operator   => 'Op',
    String     => 'Str',
    Regexp     => 'Regex',
    Expression => 'Expr',
    Pattern    => 'Pat',
    Integer    => 'Int',
);
for my $typename (keys %type_aliases) {
    $recognizer_for{ $type_aliases{$typename} } = $recognizer_for{$typename};
}

# Conversion of Keyword::Declare types back to longer PPI equivalents...
my %actual_type_for = (
    # Everything from the preceding type tables...
    map( { m{.*::(.*)};   $1 => $_                                 } @single_matches     ),
    map( {                $_ => "Keyword::Declare::Pseudotype::$_" } keys %multi_matches ),

    # Plus these Keyword::Declare additions...
    Block      => 'PPI::Structure::Block',
    Identifier => '/\A[^\W\d]\w*\Z/',
    Comma      => '/\A(?:,|=>)\Z/',
    Var        => 'Keyword::Declare::Pseudotype::Var',
    ScalarVar  => 'Keyword::Declare::Pseudotype::ScalarVar',
    ArrayVar   => 'Keyword::Declare::Pseudotype::ArrayVar',
    HashVar    => 'Keyword::Declare::Pseudotype::HashVar',
);

  @actual_type_for{ values %type_aliases }
= @actual_type_for{   keys %type_aliases };


# Set up pseudotype hierarchy to facilitate multiple dispatch resolution on built-in types...
BEGIN {
    no strict 'refs';
    for my $typename (keys %multi_matches) {
        @{"Keyword::Declare::Pseudotype::${typename}::ISA"}
            = @{ $multi_matches{$typename} };
    }

    @Keyword::Declare::Pseudotype::Var::ISA = qw< PPI::Statement::Expression PPI::Statement >;
    for my $typename (qw< ScalarVar ArrayVar HashVar >) {
        @{"Keyword::Declare::Pseudotype::${typename}::ISA"}
            = 'Keyword::Declare::Pseudotype::Var';
    }
}

# Convert a type specification into a sub that recognizes instances of that type...
sub _get_recognizer_for {
    my ($type) = @_;

    # Is it an explicit literal???
    return _matcher_for('\s*+\K'. quotemeta(substr($type,1,-1))) if $type =~ m{\A'};

    # Is it an explicit pattern (with possible suffix flags than need to be inlined)???
    if ($type =~ m{\A/}) {
        my ($pat, $flags) = $type =~ m{\A / (.*) / (\w*) \Z}xms;
        if (length $flags) {
            $pat = "(?$flags:$pat)";
        }
        return _matcher_for($pat)
    }

    # Is it a user-defined type???
    if (defined ${^H}{"Keyword::Declare type=$type"}) {
        return eval(${^H}{"Keyword::Declare type=$type"}) // croak $@;
    }

    # Otherwise, it's a standard named type (or an unknown)...
    return $recognizer_for{$type};
}

sub _parse_params {
    my ($desc, $param_list) = @_;

    my @params;
    my $expected = 'type';
    my $has_upto;

    COMPONENT:
    for my $component (eval{ $param_list->schild(0)->schildren() }) {

        # Comma marks the end of a component --> start looking for the next...
        if ($component eq ',') {
            $expected = 'type';
            next COMPONENT;
        }

        # At the start of a component there must be a type...
        if ($expected eq 'type') {
            # The type may have a single optional 'up to' (...) prefix...
            if (!$has_upto && $component eq '...') {
                $has_upto = 1;
                next COMPONENT;
            }

            my $type = "$component";

            # The type must be an typename (an identifier) or a regex or string...
            my $is_named_type = $type =~ /\A$QUAL_IDENT\Z/;
            croak "Expected parameter type specification, but found $type instead\n"
                . "in parameter list of $desc"
                if not (   $is_named_type
                       ||  $component->isa('PPI::Token::Regexp::Match')
                       ||  $component->isa('PPI::Token::Quote::Single')
                       ||  $component->isa('PPI::Token::Quote::Double')
                );

            # The type must be recognizable by the module...
            my $recognizer = _get_recognizer_for($type);

            # Is it a known type?
            if ($is_named_type && !$recognizer) {
                croak "Unknown type ($type) in parameter list of $desc";
            }

            # Set up a new parameter...
            push @params, { type => $type, recognizer => $recognizer, var => undef, upto => $has_upto };
            $has_upto = 0;

            # Then go look for a variable...
            $expected = 'var';
            next COMPONENT;
        }

        # After the type there is optionally a parameter...
        if ($expected eq 'var') {
            # After the variable, there may be an 'optional' marker...
            $expected = 'optional';

            # Parameter variables are scalar or array variables...
            if ($component =~ /[\$\@]$IDENT/) {
                # If found, remember them and infer a description and a repeatability...
                $params[-1]{var}        = "$component";
                $params[-1]{desc}       = substr("$component",1);
                $params[-1]{optional}   = 0;
                $params[-1]{repeatable} = !$params[-1]{upto} && substr("$component",0,1) eq '@';

                # Then continue parsing...
                next COMPONENT;
            }
            # If it's not there, we're already looking at the next token, so reparse it...
            else {
                redo COMPONENT;
            }
        }

        # Having just seen a type or variable, we need to check whether it's marked 'optional'...
        if ($expected eq 'optional') {

            # The 'optional marker has to be at the end of the parameter...
            $expected = 'default';

            # If it's there, remember it and move on to the next parameter...
            if ($component eq '?') {
                $params[-1]{optional} = 1;
                next COMPONENT;
            }
            # If it's not there, we're already looking at the next token, so reparse it...
            else {
                redo COMPONENT;
            }
        }

        # Having just seen a type or variable, we need to check whether it has a default value...
        if ($expected eq 'default') {

            # If it's there, remember it and move on to the next parameter...
            if ($component eq '=') {
                $expected = 'default_val';
                $params[-1]{optional} = 1;
                next COMPONENT;
            }
            # If it's not there, we're already looking at the next token, so reparse it...
            else {
                $expected = 'comma';
                redo COMPONENT;
            }
        }

        # Having found a default value introducer, we expect a default value...
        if ($expected eq 'default_val') {

            if ($component eq ',' || $component eq ')') {
                $expected = 'comma';
                redo COMPONENT;
            }

            $params[-1]{default} .= "$component";
            next COMPONENT;
        }

        # If we find anything unexpected at the end of a parameter defn, report it...
        if ($expected eq 'comma') {
            croak "Expected comma or closing paren, but found $component instead\n"
                . "in parameter list of $desc";
        }

        # If we find anything unexpected anywhere else, report it too...
        croak "Unexpected $component in parameter list of $desc";
    }

    return @params;
}


sub _match_syntax {
    my ($src, $name, $desc, @expected) = @_;

    my $parse = ref($src) ? $src : PPI::Document->new(\$src);
    $parse->index_locations;

    my @candidates = $parse->children;
    my @matches;
    my $reparsed = 1;
    my $repeated;

    for my $expected (@expected) {
        my $type = $expected->{type};

        # Normalize parameter description...
        if (!defined $expected->{desc}) {
            $expected->{desc} = $type =~ m{\A/} ? "something matching $type"
                              : $type =~ m{\A'} ? substr($type,1,-1)
                              :                   "<$type>";
        }
        $expected->{desc} =~ tr{A-Z_}{a-z };
    }

    my $prev_candidate = $name;
    EXPECTED:
    for my $expected (@expected) {
        # Next candidate...
        my $candidate = shift @candidates;
        return (undef, $src, {expected => $expected->{desc}, after => "$prev_candidate", found => 'end of file'})
            if !defined $candidate;

        if ($expected->{recognizer}) {

            my ($matched, $new_source);
            ($matched, $candidate, $new_source)
                = $expected->{recognizer}->( $candidate, $parse, @candidates );

            if (defined $new_source) {
                $parse = PPI::Document->new(\$new_source);
                $parse->index_locations;
                @candidates = $parse->children();
            }

            if ($matched) {
                # Remember this matched...
                $prev_candidate = eval{ $candidate->isa('PPI::Structure::Block')} ? 'code block' : $candidate;

                if (ref $candidate) {
                    # Extract the match from the parse, and remember it...
                    if ($expected->{repeatable} || $expected->{upto}) {
                        if ($repeated) { push @{ $matches[-1] }, $candidate->remove();  }
                        else           { push @matches,         [$candidate->remove()]; }
                    }
                    else {
                        push @matches, $candidate->remove();
                    }

                    # Expressions need to give back their terminators...
                    if ($expected->{type} ne 'Statement' &&$candidate->isa('PPI::Statement')) {
                        my $terminator = $candidate->schild(-1);
                        if ($terminator eq ';') {
                            unshift @candidates, $terminator->remove();
                        }
                    }
                }
                else {
                    # Remember the match from the parse...
                    if ($expected->{repeatable} || $expected->{upto}) {
                        if ($repeated) { push @{ $matches[-1] }, $candidate;  }
                        else           { push @matches,         [$candidate]; }
                    }
                    else {
                        push @matches, $candidate;
                    }
                }

                # Having matched something, this becomes the One True Parse...
                $reparsed = 0;

                # Having matched something repeatable, remember it's been repeated...
                if ($expected->{repeatable}) {
                    $repeated = 1;
                }

                # If this item is repeatable, try it again...
                if ($expected->{repeatable}) {
                    unshift @expected, $expected;
                }

                # Then move on to the next expectation...
                next EXPECTED;
            }
        }

        if (ref($candidate)) {
            # If candidate is decomposable, decompose it...
            if ($candidate->isa('PPI::Statement')) {
                unshift @candidates, $candidate->children();
                redo EXPECTED;
            }

            # Not matching whitespace is not fatal: just skip over it...
            if (!$candidate->significant()) {
                $candidate->remove();
                redo EXPECTED;
            }
        }

        # If this is an "upto" then failures just mean we're not their yet..
        if ($expected->{upto}) {
            if (ref $candidate) {
                # Extract the match from the parse, and remember it...
                if ($repeated) { push @{ $matches[-1] }, $candidate->remove();  }
                else           { push @matches,         [$candidate->remove()]; }

                # Expressions need to give back their terminators...
                if ($expected->{type} ne 'Statement' &&$candidate->isa('PPI::Statement')) {
                    my $terminator = $candidate->schild(-1);
                    if ($terminator eq ';') {
                        unshift @candidates, $terminator->remove();
                    }
                }
            }
            else {
                # Remember the match from the parse...
                if ($repeated) { push @{ $matches[-1] }, $candidate;  }
                else           { push @matches,         [$candidate]; }
            }

            # An "upto" is inherently a repeatable parameter...
            $repeated = 1;

            redo EXPECTED;
        }

        # Move on if expected component is repeatable...
        if ($expected->{repeatable} && $repeated && eval{ $candidate->significant }) {
            $repeated = 0;
            unshift @candidates, $candidate;
            next EXPECTED;
        }

        # Give up if expected component is optional...
        if ($expected->{optional} && eval{ $candidate->significant }) {
            $repeated = 0;
            push @matches, undef;
            unshift @candidates, $candidate;
            next EXPECTED;
        }

        # If we failed "inside" a parse, try reparsing from that point (once only!)...
        if (!$reparsed) {
            # Rebuild the parse...
            my $source = "$parse";
            $parse  = PPI::Document->new(\$source);
            $parse->index_locations;
            @candidates = $parse->children();

            # Remember we did so...
            $reparsed = 1;

            # And then retry...
            redo EXPECTED;
        }

        # Otherwise, we've failed...
        $candidate = 'code block' if $candidate->isa('PPI::Structure::Block');
        return (undef, $src, {expected => $expected->{desc}, after => "$prev_candidate", found => "$candidate"});
    }

    return (\@matches, join q{}, @candidates);
}


# Track lexical keyword implementations...
our %keyword_impls;

sub import {
    my (undef, $opt_ref) = @_;
    $opt_ref //= {};

    my $arg_type = ref($opt_ref);
    if (@_ > 2 || $arg_type ne 'HASH') {
        $arg_type ||= $opt_ref;
        croak "Invalid option for: use Keyword::Declare.\n",
              "Expected single hash reference, but found $arg_type instead.\n",
              "Error detected";
    }

    if ($opt_ref->{debug}) {
        ${^H}{'Keyword::Declare debug'} = !!$opt_ref->{debug};
    }

    Keyword::Simple::define 'keytype', sub {
        my ($ref) = @_;

        # Track line numbers in trailing source...
        my (undef, $filename, $linenum) = caller(0);
        my $linecount = $$ref =~ tr/\n//;
        my $loc = "$filename line $linenum";

        # Parse the keytype declaration...
        my ($components_ref, $trailing_source, $error)
            = _match_syntax(
                $$ref,
                'keytype',
                'keyword type declaration',
                { desc       => 'type name',
                  type       => 'Ident',
                  recognizer => $recognizer_for{'Ident'},
                },
                { desc       => 'type parameter',
                  type       => 'List',
                  recognizer => $recognizer_for{'List'},
                  optional   => 1,
                  default    => '(undef)',
                },
                { desc       => 'type specification',
                  type       => 'Block',
                  recognizer => $recognizer_for{'Block'},
                },
            );

        # Report any parsing failure...
        croak $error->{msg} // "Expected $error->{expected} after $error->{after} but found: $error->{found}"
            if defined $error;

        # Put everything following the parsed components back into the source code...
        $$ref = $trailing_source;

        # Adjust line numbers in source code...
        $linenum += $linecount - ($$ref =~ tr/\n//);
        $$ref = "\n#line $linenum $filename\n" . $$ref;

        # Unpack and normalize the components of the declaration...
        my ($name, $param, $block) = @{$components_ref};
        $name = "$name";
        $param = substr($param//'(undef)', 1, -1);

        # Convert block specification to a recognizer generator...
        my $typedef = qq{ sub { my ($param) = \@_; return( scalar do $block, $param ) } };
        if ($block->schildren() == 1) {
            my $content = $block->schild(0)->schild(0);
            if ($content->isa('PPI::Token::Word')) {
                if ($content =~ m{\A PPI:: }xms) {
                    $typedef = qq{Keyword::Declare::_is_a(q{$content})};
                }
                else {
                    $typedef = qq{Keyword::Declare::_get_recognizer_for(q{$content})};
                }
            }
            elsif ($content->isa('PPI::Token::Quote')) {
                $typedef = qq{Keyword::Declare::_get_recognizer_for(q{$content})};
            }
            elsif ($content->isa('PPI::Token::Regexp::Match')) {
                croak "Not a valid regex: $content\nin keytype specification"
                    if !eval qq{#line 0 keytype:$name\n1;\nsub{$content} };
                $content =~ s{\\}{\\\\}g;
                $typedef = qq{Keyword::Declare::_get_recognizer_for(q{$content})};
            }
            else {
                eval "#line 1 keytype:$name\n$typedef" or croak $@;
            }
        }
        else {
            eval "#line 1 keytype:$name\n$typedef" or croak $@;
        }

        # Install new type...
        $$ref = qq{ BEGIN{ \${^H}{'Keyword::Declare type=$name'} = qq{\Q$typedef\E} } } . $$ref;
    };

    Keyword::Simple::define 'keyword', sub {
        my ($ref) = @_;

        # Track line numbers in trailing source...
        my (undef, $filename, $linenum) = caller(0);
        my $linecount = $$ref =~ tr/\n//;
        my $loc = "$filename line $linenum";

        # Parse the standard keyword declaration...
        my ($components_ref, $trailing_source, $error)
            = _match_syntax(
                $$ref,
                'keyword',
                'keyword declaration',
                { desc       => 'keyword name',
                  type       => 'Ident',
                  recognizer => $recognizer_for{'Ident'},
                },
                { desc       => 'parameter list',
                  type       => 'List',
                  recognizer => $recognizer_for{'List'},
                  optional   => 1,
                  default    => '()',
                },
                { desc       => 'keyword attribute',
                  type       => 'Attribute',
                  recognizer => _matcher_for(':\s*[^\W\d]\w*(?:\([^)]*\))?'),
                  optional   => 1,
                  repeatable => 1,
                },
                { desc       => 'keyword block',
                  type       => 'Block',
                  recognizer => $recognizer_for{'Block'},
                },
            );

        # Parse the special keyword declaration...
        if (defined $error) {
            my ($components_ref_special, $trailing_source_special, $error_special)
                = _match_syntax(
                    $$ref,
                    'keyword',
                    'keyword declaration',
                    { desc       => 'keyword name',
                      type       => 'Ident',
                      recognizer => $recognizer_for{'Ident'},
                    },
                    { desc       => 'from',
                      type       => 'Ident',
                      recognizer => _matcher_for('from'),
                    },
                    { desc       => 'keyword source',
                      type       => 'QualIdent',
                      recognizer => $recognizer_for{'QualIdent'},
                    },
                );
            if (!defined $error_special) {
                $components_ref = [
                    $components_ref_special->[0],
                    undef,
                    undef,
                    qq({{{ use $components_ref_special->[2]; $components_ref_special->[0] }}}),
                ];
                ($trailing_source, $error) = ($trailing_source_special, $error_special);
            }
            else {
                carp $error_special->{msg} // "Expected $error_special->{expected} after $error_special->{after} but found: $error_special->{found}"
            }
        }

        # Report any parsing failure...
        croak $error->{msg} // "Expected $error->{expected} after $error->{after} but found: $error->{found}"
            if defined $error;

        # Put everything following the parsed components back into the source code...
        $$ref = $trailing_source;

        # Adjust line numbers in source code...
        $linenum += $linecount - ($$ref =~ tr/\n//);
        $$ref = "\n#line $linenum $filename\n" . $$ref;

        # Unpack and normalize the components of the declaration...
        my ($name, $param_list, $attrs, $block) = @{$components_ref};
        $attrs //= [];
        my %attr;
        for my $attr (@{$attrs}) {
            $attr =~ m{\A : \s* (?: (?<name> desc ) \( (?<value> [^)]*) \) | (?<name> prefer ) ) \Z}xms
                or croak "Unknown attribute:  $attr\nin keyword declaration";
            $attr{$+{name}} = $+{value} // 1;
        }
        $name  = "$name";
        $block = $block =~ $EMPTY_BLOCK ? '{;}' : "$block";

        # Is it a template block???
        if ($block =~ s[ \A \{\{\{ ][]xms) {
            croak qq(Missing }}} on string-style block of keyword $name\ndefined)
                if $block !~ m[ \}\}\}\Z ]xms;

            if ($block =~ m{ <\{ (?<interpolation> (?<leader> \s* \S*) .*? ) (?: <\{ | \Z ) }xms) {
                my %match = %+;
                croak qq[Missing }> on interpolation <{$match{leader}...\n]
                    . qq[in string-style block of keyword $name\ndefined]
                        if $match{interpolation} !~ m{ \}> }xms;
            }

            $block =~ s{
                  (?<end_of_block> \}\}\} \Z )
                |
                  <\{ (?<interpolation> .*? ) \}>
                |
                  (?<literal_code> .*? ) (?= <\{ | \}\}\} )
            }{
                if (exists $+{literal_code}) {
                    'qq{' . quotemeta($+{literal_code}) . '}.';
                }
                elsif (exists $+{interpolation}) {
                    qq{ do{$+{interpolation}}. };
                }
                elsif (exists $+{end_of_block}) {
                    q{''};
                }
                else {
                    say {*STDERR} 'Inconceivable!'; exit;
                }
            }gexms;

            $block = "{ return $block; }";
        }

        # Extract the parameter specifications...
        my @params = _parse_params("keyword $name", $param_list);

        # Record the definition and track its lexical scope...
        push @{$keyword_impls{$name}}, {
            desc   => $attr{desc},
            prefer => $attr{prefer},
            params => \@params,
            sig    => [ map {my $typename = $_->{type}; $actual_type_for{$typename} // $typename } @params ],
            code   => $block,
            loc    => $loc,
        };

        my $next_index = $#{$keyword_impls{$name}};

        my $keyword_defn
            = _build_keyword_code($name, _build_syntax($name, @params), $attr{desc}, $next_index);

        # Install the keyword, exporting as well if it's in an import() or unimport() sub...
        $$ref = qq{ BEGIN{ $keyword_defn } if (((caller 0)[3]//q{}) =~ /\\b(?:un)?import\\Z/) { $keyword_defn } $$ref };
    };
}

sub _normalize_desc {
    my ($component) = @_;
    return eval{ $component->isa('PPI::Structure::Block') } ? 'code block' : "$component";
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Keyword::Declare - Declare new Perl keywords...via a keyword


=head1 VERSION

This document describes Keyword::Declare version 0.000005


=head1 STATUS

This module is an alpha release.
Aspects of its behaviour will probably change in future releases.

In particular, do not rely on keyword parameters having been parsed into
PPI objects. This is an interim solution that is likely to go away in
future releases.


=head1 SYNOPSIS

    use Keyword::Declare;

    # Declare something matchable within a keyword's syntax...
    keytype UntilOrWhile { /until|while/ }

    # Declare a keyword and its syntax...
    keyword repeat (UntilOrWhile $type, List $condition, Block $code) {
        # Return new source code as a string (which replaces any parsed syntax)
        return qq{
            while (1) {
                $code;
                redo $type $condition;
                last;
            }
        };
    }

    # Implement method declarator...
    keyword method (Ident $name, List $params?, /:\w+/ @attrs?, Block $body) {
        return build_method_source_code($name, $params//'()', \@attrs, $body);
    }

    # Keywords can have two or more definitions (distinguished by syntax)...
    keyword test (String $desc, Comma, Expr $test) {
        return "use Test::More; ok $test => $desc"
    }

    keyword test (Expr $test) {
        my $desc = "q{$test at line }.__LINE__";
        return "use Test::More; ok $test => $desc"
    }

    keyword test (String $desc, Block $subtests) {
        return "use Test::More; subtest $desc => sub $subtests;"
    }

    # Keywords declared in an import() are automatically exported...
    sub import {

        keyword debug (Expr $expr) {
            return "" if !$ENV{DEBUG};
            return "use Data::Dump 'ddx'; ddx $expr";
        }

    }



=head1 DESCRIPTION

This module implements a new Perl keyword: C<keyword>, which you can
use to specify other new keywords.

Normally, to define new keywords in Perl, you either have to write them
in XS (shiver!) or use a module like L<Keyword::Simple> or
L<Keyword::API>. Using any of these approaches requires you to grab all
the source code after the keyword, manually parse out the components of
the keyword's syntax, construct the replacement source code, and then
substitute it for the original source code you just parsed.

Using Keyword::Declare, you define a new keyword by specifying its name
and a parameter list corresponding to the syntactic components that must
follow the keyword. You then use those parameters to construct and
return the replacement source code. The module takes care of setting up
the keyword, and of the associated syntax parsing, and of inserting the
replacement source code in the correct place.

For example, to create a new keyword (say: C<loop>) that takes an optional
count and a block, you could write:

    use Keyword::Declare;

    keyword loop (Int $count?, Block $block) {
        if (defined $count) {
            return "for (1..$count) $block";
        }
        else {
            return "while (1) $block";
        }
    }

At compile time, when the parser subsequently encounters source
code such as:

    loop 10 {
        $cmd = readline;
        last if valid_cmd($cmd);
    }

then the keyword's $count parameter would be assigned the value C<"10">
and its $code parameter would be assigned the value
S<C<"{\n$cmd = readline;\nlast if valid_cmd($cmd);\n}">>. Then the "body" of
the keyword definition would be executed and its return value used as the
replacement source code:

    for (1..10) {
        $cmd = readline;
        last if valid_cmd($cmd);
    }



=head1 INTERFACE

=head2 Declaring a new lexical keyword

The general syntax for declaring new keywords is:

    keyword NAME (PARAM, PARAM, PARAM...) [:desc] { REPLACEMENT }

The name of the new keyword can be any identifier, including the name of
an existing Perl keyword. However, using the name of an existing keyword
usually creates an infinite loop of keyword expansion, so it rarely does
what you actually wanted.


=head3 Specifying keyword parameters

The parameters of the keyword tell it how to parse the source code that
follows it. The general syntax for each parameter is:

                           [...] TYPE [$@] VARNAME [?] [= DEFAULT]

                            \_/  \__/  VV  \_____/ \_/ \_________/
    Everything up to [opt]...:     :   ::     :     :       :
    Component type.................:   ::     :     :       :
    Appears once.......................::     :     :       :
    Appears once or more................:     :     :       :
    Capture variable..........................:     :       :
    Component is optional [opt].....................:       :
    Default source (if missing) [opt].......................:


=head4 Named keyword parameter types

The type of each keyword parameter specifies how to parse the
corresponding item in the source code after the keyword. Most
of the available types are drawn from the PPI class hierarchy,
and are named with the final component of the PPI class name.

The standard named types that are available are:

    Typename             Matches                    PPI equivalent
    ========             =======                    ==============
    Statement            a full Perl statement      PPI::Statement

    Block                a block of Perl code       PPI::Structure::Block

    List                 a parenthesized list       PPI::Structure::List
                                                       or PPI::Structure::Condition

    Expression or Expr   a Perl expression          PPI::Statement::Expression
                                                       or PPI::Statement

    Number               any Perl number            PPI::Token::Number
    Integer or Int       any Perl integer                  <none>
    Binary               0b111                      PPI::Token::Number::Binary
    Octal                07777                      PPI::Token::Number::Octal
    Hex                  0xFFF                      PPI::Token::Number::Hex
    Float                -1.234                     PPI::Token::Number::Float
    Exp                  -1.234e-56                 PPI::Token::Number::Exp
    Version              v1.2.3                     PPI::Token::Number::Version

    Quote                a string literal           PPI::Token::Quote
    Single               'single quoted'            PPI::Token::Quote::Single
    Double               "double quoted"            PPI::Token::Quote::Double
    Literal              q{uninterpolated}          PPI::Token::Quote::Literal
    Interpolate          qq{interpolated}           PPI::Token::Quote::Interpolate
    HereDoc              <<HERE_DOC                 PPI::Token::HereDoc
    String or Str        a string literal           PPI::Token::HereDoc
                                                       or PPI::Token::Quote

    Regex or Regexp      /.../                      PPI::Token::Regexp
    Match                m/.../                     PPI::Token::Regexp::Match
    Substitute           s/.../.../                 PPI::Token::Regexp::Substitute
    Transliterate        tr/.../.../                PPI::Token::Regexp::Transliterate
    Pattern or Pat       qr/.../ or m/.../          PPI::Token::QuoteLike::Regexp
                                                       or PPI::Token::Regexp::Match

    QuoteLike            any Perl quotelike         PPI::Token::QuoteLike
    Backtick             `cmd in backticks`         PPI::Token::QuoteLike::Backtick
    Command              qx{cmd in quotelike}       PPI::Token::QuoteLike::Command
    Words                qw{ words here }           PPI::Token::QuoteLike::Words
    Readline             <FILE>                     PPI::Token::QuoteLike::Readline

    Operator or Op       any Perl operator          PPI::Token::Operator
    Comma                , or =>

    Label                LABEL:                     PPI::Token::Label
    Whitespace           Empty space                PPI::Token::Whitespace
    Comment              # A comment                PPI::Token::Comment
    Pod                  =pod ... =cut              PPI::Token::Pod

    Identifier or Ident  simple identifier                 <none>
    QualIdent            identifier containing ::          <none>

    Var                  a scalar, array, or hash          <none>
    ScalarVar            a scalar                          <none>
    ArrayVar             an array                          <none>
    HashVar              a hash                            <none>
    ArrayIndex           $#arrayname                PPI::Token::ArrayIndex
    Constructor          [arrayref] or {hashref}    PPI::Structure::Constructor
    AnonHash             {...}                      PPI::Structure::Constructor
                                                       or  PPI::Structure::Block
    Subscript            ...[$index] or ...{$key}   PPI::Structure::Subscript


=head3 Regex and literal parameter types

In addition to the standard named types listed in the previous section,
a keyword parameter can have its type specified as either a regex or a
string, in which case the corresponding component in the trailing source
code is expected to match the pattern or literal.

For example:

    keyword fail ('all' $all?, /hard|soft/ $fail_mode, Block $code) {...}

would accept:

    fail hard {...}
    fail all soft {...}
    # etc.

If a literal or pattern is only parsing a static part of the syntax, there
may not be a need to give it an actual parameter variable. For example:

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {

        my $EXTRACTOR = $what eq 'values' ? 'values' : 'keys';
        my $REPORTER  = $what eq 'pairs' ? $hash.'{$data}' : '$data';

        return qq{for my \$data ($EXTRACTOR $hash) { say join ': ',$REPORTER }
    }

Here the C<'in'> parameter just parses a fixed syntactic component of the
keyword, so there's no need to capture it in a parameter.


=head4 Naming literal and regex types

Literal and regex parameter types are useful for matching syntax that PPI
cannot recognize. However, they tend to muddy a keyword definition with
large amounts of line noise (especially the regexes).

So the module allows you to declare a named type that matches whatever
a given literal or regex would have matched in the same place...via the
C<keytype> keyword.

For example, instead of explicit regexes and string literals:

    keyword fail ('all' $all?, /hard|soft/ $fail_mode, Block $code) {...}

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {

...you could predeclare named types that work the same:

    keytype All       { 'all' }
    keytype FailMode  { /hard|soft/ }

    keytype ListMode  { /keys|values|pairs/ }
    keytype In        { 'In' }

and then declare the keywords like so:

    keyword fail (All $all?, FailMode $fail_mode, Block $code) {...}

    keyword list (ListMode $what, In, HashVar $hash) {

A C<keytype> can also be used to rename an existing named type more 
meaningfully. For example:

    keytype Name      { Ident  }
    keytype ParamList { List   }
    keytype Attr      { /:\w+/ }
    keytype Body      { Block  }

    keyword method (Name $name, ParamList $params?, Attr @attrs?, Body $body)
    {...}

Finally, if the block of the C<keytype> is not a simple regex, string
literal, or standard type name, it is treated as the code of a
subroutine that is passed the value of the parameter and should return
true if the type matches. In that case, the keytype may be given a
parameter, so you don't need to unpack C<@_> manually.

For example, if a keyword could take either a block or an
expression after it:

    keytype BlockOrExpr ($block_expr) {
        return $block_expr->isa('PPI::Structure::Block')
            or $block_expr->isa('PPI::Statement::Expression');
    }

    # and later...

    keyword demo (BlockOrExpr $demo_what) {...}

B<Note:> Do not rely on source code components having been parsed via PPI
in the long-term. The module implementation is likely to change to
a lighter-weight parsing solution once one can be created.


=head4 "Up-to" types

Normally, a parameter's type tells the module how to parse it out of the
source code. But you can also use any type to specify when to stop parsing
the source code...that is: what to parse B<up to> in the source code when
matching the parameter.

If you place an ellipsis (C<...>) before the type specifier, the module
matches everything in the source code until it has also matched the type.
The parameter variable will contain all of the source up to and including
whatever the type specifier matched.

For example:

    keyword omniloop (Ident $type, ...Block $config_plus_block) {...}
    # After the type, grab everything up to the block

    keyword test (Expr $condition, ...';' $description) {...}
    # After the condition expression, grab everything to the next semicolon



=head4 Scalar vs array keyword parameters

Declaring a keyword's parameter as a scalar (the usual approach) causes
the source code parser to match the corresponding type of component
exactly once in the trailing source. For example:

    # try takes exactly one trailing block
    keyword try (Block $block) {...}

Declaring a keyword's parameter as an array causes the source code
parser to match the corresponding type of component as many times as it
appears (but at least once) in the trailing source.

    # tryall takes one or more trailing blocks
    keyword tryall (Block @blocks) {...}


=head4 Optional keyword parameters (with or without defaults)

Any parameter can be marked as optional, in which case failing to
find a corresponding component in the trailing source is no longer
a fatal error. For example:

    # The forpair keyword takes an optional iterator variable
    keyword forpair ( Var $itervar?, '(', HashVar $hash, ')', Block $block) {...}

    # The checkpoint keyword can be followed by zero or more trailing strings
    keyword checkpoint (Str @identifier?) {...}

Instead of a C<?>, you can specify an optional parameter with an C<=> followed
by a compile-time expression. The parameter is still optional, but if th e
corresponding syntactic component is mising, the parameter variable will be assigned
the result of the compile-time expression, rather than C<undef>.

For example:

    # The forpair keyword takes an optional iterator variable (or defaults to $_)
    keyword forpair ( Var $itervar = '$_', '(', HashVar $hash, ')', Block $block) {...}


=head3 Specifying a keyword description

Normally the error messages the module generates refer to the
keyword by name. For example, an error detected in parsing a
C<repeat> keyword with:

    keyword repeat (/while/ $while, List $condition, Block $code)
    {...}

might produce the error message:

    Syntax error in repeat...
    Expected while after repeat but found: with

which is a good message, but would be slightly better if it was:

    Syntax error in repeat-while loop...
    Expected while after repeat but found: with

You can request that a particular keyword be referred to in error
messages using a specific description, by adding the C<:desc>
modifier to the keyword definition. For example:

    keyword repeat (/while/ $while, List $condition, Block $code)
    :desc(repeat-while loop)
    {...}


=head2 Simplifying keyword generation with an interpolator

Frequently, the code block that generates the replacement syntax for the
keyword will consist of something like:

    {
        my $code_interpolation = some_expr_involving_a($param);
        return qq{ REPLACEMENT $code_interpolation HERE };
    }

in which the block does some maniulation of one or more parameters, then
interpolates the results into a single string, which it returns.

So the module provides a shortcut for that structure: the "triple
curly" block. If a keyword's block is delimited by three adjacent curly
brackets, the entire block is taken to be a single uninterpolated string
that specifies the replacement source code. Within that single string
anything in C<< <{...}> >> delimiters is a piece of code to be executed
and its result is interpolated at that point in the replacement code.

In other words, a triple-curly block is a literal code template, with
special C<< <{...}> >> interpolators.

For example, instead of:

    keyword forall (List $list, '->', Params @params, Block $code_block)
    {
        $list =~ s{\)\Z}{,\\\$__acc__)};
        substr $code_block, 1, -1, q{};
        return qq[
            {
                state \$__acc__ = [];
                foreach my \$__nary__ $list {
                    if (!ref(\$__nary__) || \$__nary__ != \\\$__acc__) {
                        push \@{\$__acc__}, \$__nary__;
                        next if \@{\$__acc__} <= $#parameters;
                    }
                    next if !\@{\$__acc__};
                    my ( @parameters ) = \@{\$__acc__};
                    \@{\$__acc__} = ();

                    $code_block
                }
            }
        ]
    }

...you could write:

    keyword forall (List $list, '->', Params @params, Block $code_block)
    {{{
        {
            state $__acc__ = [];
            foreach my $__nary__  <{ $list =~ s{\)\Z}{,\\\$__acc__)}r }>
            {
                if (!ref($__nary__) || $__nary__ != \$__acc__) {
                    push @{$__acc__}, $__nary__;
                    next if @{$__acc__} <= <{ $#parameters }>;
                }
                next if !@{$__acc__};
                my ( <{"@parameters"}> ) = @{$__acc__};
                @{$__acc__} = ();

                <{substr $code_block, 1, -1}>
            }
        }
    }}}

...with a significant reduction in the number of sigils that have to be
escaped (and hence a significant decrease in the likelihood of errors
creeping in).


=head2 Declaring multiple variants of a single keyword

You can declare two (or more) keywords with the same name, provided they
all have distinct parameter lists. In other words, keyword definitions
are treated as multimethods, with each variant parsing the following
source code and then the variant which matches best being selected to
provide the replacement code.

For example, you might specify three syntaxes for a C<repeat> loop:

    keyword repeat ('while', List $condition, Block $block) {{{
        while (1) { do <{$block}>; last if !(<{$condition}>); }
    }}}

    keyword repeat ('until', List $condition, Block $block) {{{
        while (1) { do <{$block}>; last if <{$condition}>; }
    }}}

    keyword repeat (Num $count, Block $block) {{{
        for (1..<{$count}>) <{$block}>
    }}}

When it encounters a keyword, the module now attempts to (re)parse the
trailing code with each of the definitions of that keyword in the
current lexical scope, collecting those definitions that successfuly
parse the source.

If more than one definition was successful, the module selects the
definition(s) with the most parameters. If more than one definition had
the maximal number of parameters, the module selects the one whose
parameters matched most specifically. If two or more definitions matched
equally specifically, the module looks for one that is marked with a
C<:prefer> attribute. If there is no C<:prefer> indicated (or more than
one), the module gives up and reports a syntax ambiguity.

The C<:prefer> attribute works like this:

    

The order of specificity for a paremeter match is determined by the relationships
between the various components of a Perl program, as follows (where the further
left a type is, the more specific it is):

    ArrayIndex
    Comment
    Label
    Pod
    Subscript
    Whitespace
    Operator
        Comma
    Statement
        Block
        Expr
            Identifier
            QualIdent
            Var
                ScalarVar
                ArrayVar
                HashVar
            Number
                Integer
                Binary
                Octal
                Hex
                Float
                Exp
                Version
            Quote/String
                Single
                Double
                Literal
                Interpolate
                HereDoc
            QuoteLike
                Backtick
                Command
                Words
                Readline
            Regexp/Pattern
                Match
                Substitute
                Transliterate
            AnonHash
            Constructor
            Condition
            List

=head2 Exporting keywords

Normally a keyword definition takes effect from the statement after
the C<keyword> declaration, to the end of the enclosing lexical block.

However, if you declare a keyword inside a subroutine named C<import>
(i.e. inside the import method of a class or module), then the keyword
is also exported to the caller of that import method.

In other words, simply placing a keyword definition in a module's
C<import> exports that keyword to the lexical scope in which the
module is used.


=head2 Debugging keywords

If you load the module with the C<'debug'> option:

    use Keyword::Declare {debug=>1};

then keywords declared in that lexical scope will report how they 
transform the source following them. For example:

    use Keyword::Declare {debug=>1};

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {
        my $EXTRACTOR = $what eq 'values' ? 'values' : 'keys';
        my $REPORTER  = $what eq 'pairs' ? $hash.'{$data}' : '$data';

        return qq{for my \$data ($EXTRACTOR $hash) { say join ': ', $REPORTER }};
    }

    # And later...

    list pairs in %foo;

...would print to STDERR:

    #####################################################
    ### Keyword macro defined at demo.pl line 3:
    ###
    ###    list <what> in <hash>
    ###
    ### Converted code at demo.pl line 12:
    ###
    ###    list pairs in %foo;
    ###
    ### Into:
    ###
    ###    for my $data (keys %foo) { say join ': ', %foo{$data} }
    ###
    #####################################################


=head1 DIAGNOSTICS

=over

=item C<< Keyword %s not in scope >>

The module detected that you used a user-defined keyword, but not
in a lexical scope in which that keyword was declared or imported.

You need to move the keyword declaration (or the import) into scope, or
else move the use of the keyword to a scope where the keyword is valid.


=item C<< Syntax error in %s... Expected %s >>

You used a keyword, but with the wrong syntax after it.
The error message lists what the valid possibilities were.


=item C<< Ambiguous use of %s >>

You used a keyword, but the syntax after it was ambiguous
(i.e. it matched two or more variants of the keyword).

You either need to change the syntax you used (so that it matches only
one variant of the keyword syntax) or else change the definition of one
or more of the keywords (to ensure their syntaxes are no longer ambiguous).


=item C<< Expected parameter type specification, but found %s instead >>

=item C<< Unexpected %s in parameter list of %s >>

You put something in the parameter list of a keyword definition that the
mechanism didn't recognize. Perhaps you misspelled something?

=item C<< Unknown type (%s) in parameter list of keyword >>

You used a type for a keyword parameter that the module did not
recognize. See earlier in this document for a list of the types that the
module knows. Alternatively, did you declare a C<keytype> but then use
it in the wrong lexical scope?

=item C<< Expected comma or closing paren, but found %s instead >>

There was something unexpected after the end of a keyword parameter.
Possibly a misspelling, or a missing closing parenthesis.

=item C<< Invalid option for: use Keyword::Declare >>

Currently the module takes only a simple argument when loaded: a hash
of configuration options. You passed something else to C<use Keyword::Declare;>

A common mistake is to load the module with:

    use Keyword::Declare  debug=>1;

instead of:

    use Keyword::Declare {debug=>1};


=item C<< Expected %s after %s but found: %s >>

You used a user-defined keyword, but with the wrong syntax.
The error message indicates the point at which an unexpected
component was encountered during compilation, and what should
have been there instead.

=item C<< Not a valid regex: %s in keytype specification" >>

A C<keytype> expects a valid regex to specify the new keyword-parameter
type. The regex you supplied wasn't valid (for the reason listed).

=item C<< Missing }}} on string-style block of keyword %s >>

You created a C<keyword> definition with a C<{{{...}}}> interpolator
for its body, but the module couldn't find the closing C<}}}>. Did
you use C<}}> or C<}> instead?


=item C<< Missing }> on interpolation <{%s... >>

You created a C<keyword> definition with a C<{{{...}}}> interpolator,
within which there was an interpolation that extended to the end of the
interpolator without supplying a closing C<< }> >>. Did you accidentally
use just a C<< > >> or a C<< } >> instead?


=back

=head1 CONFIGURATION AND ENVIRONMENT

Keyword::Declare requires no configuration files or environment variables.


=head1 DEPENDENCIES

The module is an interface to Perl's pluggable keyword mechanism, which
was introduced in Perl 5.12. Hence it will never work under earlier
versions of Perl. The implementation also uses contructs introduced in
Perl 5.14, so that is the minimal practical version.

Currently requires both the Keyword::Simple module and the PPI module.


=head1 INCOMPATIBILITIES

None reported.

But Keyword::Declare probably won't get along well with source filters
or Devel::Declare.


=head1 BUGS AND LIMITATIONS

The module currently relies on Keyword::Simple, so it is subject to all
the limitations of that module. Most significantly, it can only create
keywords that appear at the beginning of a statement.

Even with the remarkable PPI module, parsing Perl code is tricky, and
parsing Perl code to build Perl code that parses other Perl code is even
more so. Hence, there are likely to be cases where this module gets it
spectacularly wrong. In particular, attempting to mix PPI-based parsing with
regex-based parsing--as this module does--is madness, and almost certain
to lead to tears for someone (apart from the author, obviously).

Moreover, because of the extensive (and sometimes iterated) use of PPI,
the module currently imposes a noticeable compile-time delay, both on the
code that declares keywords, and also on any code that subsequently uses
them.

Plans are in train to address most or all of these limitations....eventually.

Please report any bugs or feature requests to
C<bug-keyword-declare.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
