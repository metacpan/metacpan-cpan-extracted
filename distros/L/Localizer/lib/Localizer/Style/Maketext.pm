package Localizer::Style::Maketext;
use strict;
use warnings;
use utf8;
use 5.010_001;

sub DEBUG () { 0 }

sub new { bless {}, shift }

sub compile {
    my ($self, $msgid, $fmt, $functions) = @_;
    my $code = $self->_compile($msgid, $fmt, $functions);
    return $code;
}

# Based on Locale::Maketext::_compile
sub _compile {
    # This big scary routine compiles an entry.
    # It returns either a coderef if there's brackety bits in this, or
    #  otherwise a ref to a scalar.

    my $msgid = $_[1];
    my $string_to_compile = $_[2]; # There are taint issues using regex on @_ - perlbug 60378,27344
    my $functions = $_[3];

    # The while() regex is more expensive than this check on strings that don't need a compile.
    # this op causes a ~2% speed hit for strings that need compile and a 250% speed improvement
    # on strings that don't need compiling.
    return \"$string_to_compile" if($string_to_compile !~ m/[\[~\]]/ms); # return a string ref if chars [~] are not in the string

    my $target = ref($_[0]) || $_[0];

    my(@code);
    my(@c) = (''); # "chunks" -- scratch.
    my $call_count = 0;
    my $big_pile = '';
    {
        my $in_group = 0; # start out outside a group
        my($m, @params); # scratch

        while($string_to_compile =~  # Iterate over chunks.
            m/(
                [^\~\[\]]+  # non-~[] stuff (Capture everything else here)
                |
                ~.       # ~[, ~], ~~, ~other
                |
                \[          # [ presumably opening a group
                |
                \]          # ] presumably closing a group
                |
                ~           # terminal ~ ?
                |
                $
            )/xgs
        ) {
            DEBUG>2 and warn qq{  "$1"\n};

            if($1 eq '[' or $1 eq '') {       # "[" or end
                # Whether this is "[" or end, force processing of any
                #  preceding literal.
                if($in_group) {
                    if($1 eq '') {
                        $target->_die_pointing($string_to_compile, 'Unterminated bracket group');
                    }
                    else {
                        $target->_die_pointing($string_to_compile, 'You can\'t nest bracket groups');
                    }
                }
                else {
                    if ($1 eq '') {
                        DEBUG>2 and warn "   [end-string]\n";
                    }
                    else {
                        $in_group = 1;
                    }
                    die "How come \@c is empty?? in <$string_to_compile>" unless @c; # sanity
                    if(length $c[-1]) {
                        # Now actually processing the preceding literal
                        $big_pile .= $c[-1];
                        if ($c[-1] !~ m/[^\x20-\x7E]/s) { # ASCII very safe chars
                            # normal case -- all very safe chars
                            $c[-1] =~ s/'/\\'/g;
                            push @code, q{ '} . $c[-1] . "',\n";
                            $c[-1] = ''; # reuse this slot
                        }
                        else {
                            $c[-1] =~ s/\\\\/\\/g;
                            push @code, ' $c[' . $#c . "],\n";
                            push @c, ''; # new chunk
                        }
                    }
                    # else just ignore the empty string.
                }

            }
            elsif($1 eq ']') {  # "]"
                # close group -- go back in-band
                if($in_group) {
                    $in_group = 0;

                    DEBUG>2 and warn "   --Closing group [$c[-1]]\n";

                    # And now process the group...

                    if(!length($c[-1]) or $c[-1] =~ m/^\s+$/s) {
                        DEBUG>2 and warn "   -- (Ignoring)\n";
                        $c[-1] = ''; # reset out chink
                        next;
                    }

                    #$c[-1] =~ s/^\s+//s;
                    #$c[-1] =~ s/\s+$//s;
                    ($m,@params) = split(/,/, $c[-1], -1);  # was /\s*,\s*/

                    # A bit of a hack -- we've turned "~,"'s into DELs, so turn
                    #  'em into real commas here.
                    foreach($m, @params) { tr/\x7F/,/ }

                    # Special-case handling of some method names:
                    if($m eq '_*' or $m =~ m/^_(-?\d+)$/s) {
                        # Treat [_1,...] as [,_1,...], etc.
                        unshift @params, $m;
                        $m = '';
                    }
                    elsif($m eq '*') {
                        $m = 'quant'; # "*" for "times": "4 cars" is 4 times "cars"
                    }
                    elsif($m eq '#') {
                        $m = 'numf';  # "#" for "number": [#,_1] for "the number _1"
                    }

                    # Most common case: a simple, legal-looking method name
                    if($m eq '') {
                        # 0-length method name means to just interpolate:
                        push @code, ' (';
                    }
                    elsif($m =~ /^\w+$/s
                        # exclude anything fancy, especially fully-qualified module names
                    ) {
                        unless (exists $functions->{$m}) {
                            Carp::confess("Language resource compilation error. Unknown function: '${m}'");
                        }
                        push @code, ' $functions->{"' . $m . '"}->(';
                    }
                    else {
                        # TODO: implement something?  or just too icky to consider?
                        $target->_die_pointing(
                            $string_to_compile,
                            "Can't use \"$m\" as a method name in bracket group",
                            2 + length($c[-1])
                        );
                    }

                    pop @c; # we don't need that chunk anymore
                    ++$call_count;

                    foreach my $p (@params) {
                        if($p eq '_*') {
                            # Meaning: all parameters except $_[0]
                            $code[-1] .= ' @_[1 .. $#_], ';
                            # and yes, that does the right thing for all @_ < 3
                        }
                        elsif($p =~ m/^_(-?\d+)$/s) {
                            # _3 meaning $_[3]
                            $code[-1] .= '$_[' . (0 + $1) . '], ';
                        }
                        elsif($p !~ m/[^\x20-\x7E]/s) { # ASCII very safe chars
                            # Normal case: a literal containing only safe characters
                            $p =~ s/'/\\'/g;
                            $code[-1] .= q{'} . $p . q{', };
                        }
                        else {
                            # Stow it on the chunk-stack, and just refer to that.
                            push @c, $p;
                            push @code, ' $c[' . $#c . '], ';
                        }
                    }
                    $code[-1] .= "),\n";

                    push @c, '';
                }
                else {
                    $target->_die_pointing($string_to_compile, q{Unbalanced ']'});
                }

            }
            elsif(substr($1,0,1) ne '~') {
                # it's stuff not containing "~" or "[" or "]"
                # i.e., a literal blob
                my $text = $1;
                $text =~ s/\\/\\\\/g;
                $c[-1] .= $text;

            }
            elsif($1 eq '~~') { # "~~"
                $c[-1] .= '~';

            }
            elsif($1 eq '~[') { # "~["
                $c[-1] .= '[';

            }
            elsif($1 eq '~]') { # "~]"
                $c[-1] .= ']';

            }
            elsif($1 eq '~,') { # "~,"
                if($in_group) {
                    # This is a hack, based on the assumption that no-one will actually
                    # want a DEL inside a bracket group.  Let's hope that's it's true.
                    $c[-1] .= "\x7F";
                }
                else {
                    $c[-1] .= '~,';
                }

            }
            elsif($1 eq '~') { # possible only at string-end, it seems.
                $c[-1] .= '~';

            }
            else {
                # It's a "~X" where X is not a special character.
                # Consider it a literal ~ and X.
                my $text = $1;
                $text =~ s/\\/\\\\/g;
                $c[-1] .= $text;
            }
        }
    }

    if($call_count) {
        undef $big_pile; # Well, nevermind that.
    }
    else {
        # It's all literals!  Ahwell, that can happen.
        # So don't bother with the eval.  Return a SCALAR reference.
        return \$big_pile;
    }

    die q{Last chunk isn't null??} if @c and length $c[-1]; # sanity
    DEBUG and warn scalar(@c), " chunks under closure\n";
    if(@code == 0) { # not possible?
        DEBUG and warn "Empty code\n";
        return \'';
    }
    elsif(@code > 1) { # most cases, presumably!
        unshift @code, "join '',\n";
    }
    unshift @code, qq!#line 1 "${msgid}"\n!;
    unshift @code, "use strict; sub {\n";
    push @code, "}\n";

    DEBUG and warn @code;
    my $sub = eval(join '', @code); ## no critic.
    die "Language resource compilation error: $@ while evalling" . join('', @code) if $@; # Should be impossible.
    return $sub;
}

#--------------------------------------------------------------------------

sub _die_pointing {
    # This is used by _compile to throw a fatal error
    my $target = shift; # class name
    # ...leaving $_[0] the error-causing text, and $_[1] the error message

    my $i = index($_[0], "\n");

    my $pointy;
    my $pos = pos($_[0]) - (defined($_[2]) ? $_[2] : 0) - 1;
    if($pos < 1) {
        $pointy = "^=== near there\n";
    }
    else { # we need to space over
        my $first_tab = index($_[0], "\t");
        if($pos > 2 and ( -1 == $first_tab  or  $first_tab > pos($_[0]))) {
            # No tabs, or the first tab is harmlessly after where we will point to,
            # AND we're far enough from the margin that we can draw a proper arrow.
            $pointy = ('=' x $pos) . "^ near there\n";
        }
        else {
            # tabs screw everything up!
            $pointy = substr($_[0],0,$pos);
            $pointy =~ tr/\t //cd;
            # make everything into whitespace, but preserving tabs
            $pointy .= "^=== near there\n";
        }
    }

    my $errmsg = "$_[1], in\:\n$_[0]";

    if($i == -1) {
        # No newline.
        $errmsg .= "\n" . $pointy;
    }
    elsif($i == (length($_[0]) - 1)  ) {
        # Already has a newline at end.
        $errmsg .= $pointy;
    }
    else {
        # don't bother with the pointy bit, I guess.
    }
    Carp::croak( "$errmsg via $target, as used" );
}

1;
__END__

=for stopwords n-th numf

=encoding utf-8

=head1 NAME

Localizer::Style::Maketext - Maketext style

=head1 DESCRIPTION

This module provide feature to use maketext style 'Hi, [_1]'.

=head1 SYNTAX

=over 4

=item [_1], [_2], [_3], ...

Replace with n-th argument (e.g. C<$_[1], $_[2], ...>). C<[_*]> is the special character, it is replaced to variable to get all of argument (equals C<@_[1 .. $#_]>).

=item [quant,_1,piece]

It's for quantifying a noun (i.e., saying how much of it there is, while giving the correct form of it). Please refer to L<Locale::Maketext/language-quant-number-singular> and L<Locale::Maketext::Lexicon>.

=item [numf,1000]

Returns the given number formatted nicely according to this language's conventions. Please refer to L<Locale::Maketext/language-numf-number> and L<Locale::Maketext::Lexicon>.

=item [*,_1,piece]

Shorthand for quant.

=item [#,1000]

Shorthand for numf.

=item [my_own_lang,_1,piece]

Normal function call. You can register your own function in C<Localizer::Resource-E<gt>new>.

=back

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

