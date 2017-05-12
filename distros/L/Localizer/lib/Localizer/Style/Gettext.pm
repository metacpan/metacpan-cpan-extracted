package Localizer::Style::Gettext;
use strict;
use warnings;
use utf8;
use 5.010_001;

use B;
use Carp ();

sub new { bless {}, shift }

sub compile {
    my ($self, $msgid, $fmt, $functions) = @_;
    my $code = $self->_compile($msgid, $fmt, $functions);
    return $code;
}

sub _compile {
    my ($self, $msgid, $str, $functions) = @_;

    return \$str unless $str =~ /%/;

    my @code;
    my @bind;
    while ($str =~ m/
            (.*?)
            (?:
                ([\\%]%)
                |
                %(?:
                    ([A-Za-z#*]\w*)\(([^\)]*)\)
                    |
                    ([1-9]\d*|\*)
                )
                |
                $
            )
        /gsx
    ) {
        if ($1) { # Raw string
            my $text = $1;
            if ($text !~ m/[^\x20-\x7E]/s) { # ASCII very safe chars
                $text =~ s/\\/\\\\/g;
                push @code, B::perlstring($text) . ',';
            } else {
                # For example, `(eval "sub { qq{% usar\x{e1}n}}")->()` drops UTF-8 flag.
                # This code is the workaround for this issue.
                push @code, sprintf(q{$bind[%d],}, 0+@bind);
                push @bind, $text;
            }
        }
        if ($2) { # \% %%
            my $text = $2;
            $text =~ s/\\/\\\\\\\\/g;
            push @code, "'" . $text . "',";
        }
        elsif ($3) {
            my $function_name = $3;
            if ($function_name eq '*') {
                $function_name = 'quant';
            }
            elsif ($function_name eq '#') {
                $function_name = 'numf';
            }

            unless (exists $functions->{$function_name}) {
                Carp::confess("Language resource compilation error. Unknown function: '${function_name}'");
            }

            my $code = q!$functions->{'! . $function_name . q!'}->(!;
            for my $arg (split(/,/, $4)) {
                if (my $num = $arg =~ /%(.+)/) {
                    $code .= '$_[' . $num . '], ';
                }
                else {
                    $code .= "'" . $arg . "', ";
                }
            }
            $code .= '), ';
            push @code, $code;
        }
        elsif ($5) {
            my $arg = $5;

            my $var = '';
            if ($arg eq '*') {
                $var = '@_[1 .. $#_],';
            }
            else {
                $var = '$_[' . $arg . '],';
            }
            push @code, $var;
        }
    }

    if (@code > 1) { # most cases, presumably!
        unshift @code, "join '',\n";
    }
    unshift @code, qq!#line 1 "${msgid}"\n!;
    unshift @code, "use strict; sub {\n";
    push @code, "}\n";

    my $sub = eval(join '', @code); ## no critic.
    die "Language resource compilation error: $@ while evalling" . join('', @code) if $@; # Should be impossible.
    return $sub;
}

1;
__END__

=for stopwords gettext n-th numf

=encoding utf-8

=head1 NAME

Localizer::Style::Gettext - Gettext style

=head1 DESCRIPTION

This module provide feature to use gettext style 'Hi, %1'.

=head1 SYNTAX

=over 4

=item %1, %2, %3, ...

Replace with n-th argument (e.g. C<$_[1], $_[2], ...>). C<%*> is the special character, it is replaced to variable to get all of argument (equals C<@_[1 .. $#_]>).

=item %quant(%1,piece)

It's for quantifying a noun (i.e., saying how much of it there is, while giving the correct form of it). Please refer to L<Locale::Maketext/language-quant-number-singular> and L<Locale::Maketext::Lexicon>.

=item %numf(1000)

Returns the given number formatted nicely according to this language's conventions. Please refer to L<Locale::Maketext/language-numf-number> and L<Locale::Maketext::Lexicon>.

=item %*(%1,piece)

Shorthand for quant.

=item %#(1000)

Shorthand for numf.

=item %my_own_lang(%1,piece)

Normal function call. You can register your own function in C<Localizer::Resource-E<gt>new>.

=back

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

