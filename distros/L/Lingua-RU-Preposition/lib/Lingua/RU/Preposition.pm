package Lingua::RU::Preposition;

use warnings;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Lingua::RU::Preposition - linguistic function for prepositions in Russian.

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

Lingua::RU::Preposition is a perl module
that provides choosing proper form of varying Russian prepositions.

=cut


BEGIN {
    use Exporter   ();
    our ($VERSION, $DATE, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 0.02;
    # date written by hands because git does not process keywords
    $DATE        = '2014-09-16';

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
        choose_preposition_by_next_word
    );

    # exported package globals
    @EXPORT_OK   = qw(
        bezo izo izpodo ko nado ob obo oto predo peredo podo so vo
    );

    %EXPORT_TAGS = (
        'subs'    => [ @EXPORT ],
        'short'   => [ @EXPORT_OK ],
        'all'     => [ @EXPORT, @EXPORT_OK ],
    )

}

=head1 SYNOPSIS

    use Lingua::RU::Preposition qw/:all/;

    # Following string contains cyrillic letters
    print ob, 'мне'; # prints 'обо' (obo)
    print choose_preposition_by_next_word 'из', 'огня'; # prints 'из' (iz)

=head1 TO DO

Check rules by dictionaries and correct if needed.

=head1 EXPORT

Function C<choose_preposition_by_next_word> exported by default.

Also you can export only short aliases for subs

    use Lingua::RU::Preposition qw/:short/;

Or everything: subs and aliases:

    use Lingua::RU::Preposition qw/:all/; # or
    use Lingua::RU::Preposition qw/:subs :short/;

=head1 FUNCTIONS

=head2 choose_preposition_by_next_word

Chooses preposition by next word and returns chosen preposition.

Expects 2 arguments: I<preposition> and I<next_word>.
I<Preposition> should be string with shortest of possible values.
Available values of I<preposition> are:
C<'без'>, C<'в'>, C<'из'>, C<'из-под'>, C<'к'>, C<'над'>, C<'о'>, C<'от'>,
C<'пред'>, C<'перед'>, C<'под'> and  C<'с'>.

There is an aliases for calling this subroutine with common preposition:

=head3 bezo

C<bezo> is an alias for C<choose_preposition_by_next_word 'без',>

This preposition can be used with some words in both forms, they are correct.
Example: “без всего” (bez vsego) and “безо всего” (bezo vsego) both are correct.
If possible function return long form.

=head3 izo

C<izo> is an alias for C<choose_preposition_by_next_word 'из',>

=head3 izpodo

C<izo> is an alias for C<choose_preposition_by_next_word 'из-под',>

=head3 ko

C<ko> is an alias for C<choose_preposition_by_next_word 'к',>

=head3 nado

C<nado> is an alias for C<choose_preposition_by_next_word 'над',>

=head3 ob and obo

C<ob> and C<obo> are aliases for C<choose_preposition_by_next_word 'о',>

=head3 oto

C<oto> is an alias for C<choose_preposition_by_next_word 'от',>

=head3 podo

C<podo> is an alias for C<choose_preposition_by_next_word 'под',>

=head3 predo

C<predo> is an alias for C<choose_preposition_by_next_word 'пред',>

=head3 peredo

C<peredo> is an alias for C<choose_preposition_by_next_word 'перед',>

=head3 so

C<so> is an alias for C<choose_preposition_by_next_word 'с',>

=head3 vo

C<vo> is an alias for C<choose_preposition_by_next_word 'в',>

These aliases are not exported by default. They can be expored with tags C<:short> or C<:all>.

Example of code with these aliases:

    use Lingua::RU::Preposition qw/:short/;

    map {
        print ob, $_;
    } qw(
        арбузе баране всём Елене ёлке игле йоде
        мне многом огне паре ухе юге яблоке
    );

    map {
        print so, $_;
    } qw(
        огнём водой
        зарёй зноем зрением зябликом
        садом светом слоном спичками ссылкой
        Стёпой стаканом сухарём сэром топором
        жарой жбаном жратвой жуком
        шаром шкафом шлангом шубой
    );

=cut

sub choose_preposition_by_next_word ($$) {
    my $preposition = lc shift or return undef;
    local $_        = lc shift or return undef;

    # Nested subroutine
    local *_check_instrumental = sub {
        for my $word (qw( льдом льном мной мною )) {
            return $_[0] . 'о' if $word eq $_[1]
        }
        return $_[0]
    }; # _check_instrumental

    # preposition => function
    # TODO Check by dictionary
    my %GRAMMAR = (
        'без' => sub {
            for my $word (qw( всего всей всех всякого всякой всяких )) {
                # WARNING
                # difficult case, both words are OK
                return 'безо' if $word eq $_
            }
            'без'
        },
        'в' => sub {
            for my $word (qw( все всём мне мно )) {
                return 'во' if /^$word/
            }
            /^[вф][^аеёиоуыэюя]/
            ? 'во'
            : 'в'
        },
        'из' => sub {
            for my $word (qw( всех льда )) {
                return 'изо' if $word eq $_
            }
            'из'
        },
        'из-под' => sub {
            for my $word (qw( всех льда )) {
                return 'из-подо' if $word eq $_
            }
            'из-под'
        },
        'к' => sub {
            for my $word (qw( всем мне мно )) {
                return 'ко' if /^$word/
            }
            'к'
        },
        'о' => sub {
            for my $word (qw( всех всем всём мне что )) {
                return 'обо' if $word eq $_
            }
            return
                /^[аиоуыэ]/
                ? 'об'
                : 'о'
        },
        'от' => sub {
            for my $word (qw( всех )) {
                return 'ото' if $word eq $_
            }
            'от'
        },
        'с' => sub {
            return 'со' if /^мно/;
            return
                /^[жзсш][^аеёиоуыэюя]/i
                ? 'со'
                : 'с'
        },
        # Same rules:
        'над'   => sub { _check_instrumental('над',   $_) },
        'под'   => sub { _check_instrumental('под',   $_) },
        'перед' => sub { _check_instrumental('перед', $_) },
        'пред'  => sub { _check_instrumental('пред',  $_) },
    );

    return undef unless exists $GRAMMAR{$preposition};

    $GRAMMAR{$preposition}->($_);

} # sub choose_preposition_by_next_word

# Aliases
*bezo   = sub { choose_preposition_by_next_word 'без',   shift };
*izo    = sub { choose_preposition_by_next_word 'из',    shift };
*izpodo = sub { choose_preposition_by_next_word 'из-под',shift };
*ko     = sub { choose_preposition_by_next_word 'к',     shift };
*nado   = sub { choose_preposition_by_next_word 'над',   shift };
*ob     = sub { choose_preposition_by_next_word 'о',     shift };
*obo    = sub { choose_preposition_by_next_word 'о',     shift };
*oto    = sub { choose_preposition_by_next_word 'от',    shift };
*predo  = sub { choose_preposition_by_next_word 'пред',  shift };
*peredo = sub { choose_preposition_by_next_word 'перед', shift };
*podo   = sub { choose_preposition_by_next_word 'под',   shift };
*so     = sub { choose_preposition_by_next_word 'с',     shift };
*vo     = sub { choose_preposition_by_next_word 'в',     shift };

=head1 AUTHOR

Alexander Sapozhnikov, C<< <shoorick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-lingua-ru-preposition at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-RU-Preposition>.
I will be notified, and then
you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::RU::Preposition

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-RU-Preposition>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-RU-Preposition>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-RU-Preposition>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-RU-Preposition/>

=back

=head1 SEE ALSO

Russian translation of this documentation available
at F<RU/Lingua/RU/Preposition.pod>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2014 Alexander Sapozhnikov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
