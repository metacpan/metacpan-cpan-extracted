package Lingua::IT::Ita2heb::Role::Constants::Hebrew;

use 5.010;
use strict;
use warnings;
use utf8;
use charnames ':full';

use Readonly;

our $VERSION = '0.01';

use Moose::Role;

my %HEBREW_LETTERS =
(
    (
    map { 
        my $l = $_; my $heb = $l; $heb =~ tr/_/ /;
        $l => (eval qq{"\\N{HEBREW LETTER $heb}"}) 
    }
    qw(ALEF BET GIMEL DALET HE VAV ZAYIN HET TET YOD KAF FINAL_KAF LAMED
       MEM FINAL_MEM NUN FINAL_NUN SAMEKH AYIN PE FINAL_PE TSADI FINAL_TSADI
       QOF RESH TAV
    ),
    ),
    SHIN => "\N{HEBREW LETTER SHIN}\N{HEBREW POINT SHIN DOT}",
    (
    map { 
        my $l = $_; my $heb = $l; $heb =~ tr/_/ /;
        $l => (eval qq{"\\N{HEBREW POINT $heb}"}) 
    }
    qw(QAMATS HATAF_QAMATS PATAH HATAF_PATAH TSERE SEGOL HATAF_SEGOL HIRIQ
    HOLAM QUBUTS SHEVA RAFE),
    ),
    ( map { $_ => "\N{HEBREW POINT DAGESH OR MAPIQ}" } qw(DAGESH MAPIQ) ),
    (
    map { 
        my $l = $_; my $heb = $l; $heb =~ tr/_/ /;
        "TRUE_$l" => (eval qq{"\\N{HEBREW PUNCTUATION $heb}"}) 
    } qw(GERESH MAQAF)
    ),
);

{
    my %composites =
    (
        HOLAM_MALE   => __PACKAGE__->heb('VAV,HOLAM'),
        SHURUK       => __PACKAGE__->heb('VAV,DAGESH'),
        HIRIQ_MALE   => __PACKAGE__->heb('HIRIQ,YOD'),
    );

    %HEBREW_LETTERS = (%HEBREW_LETTERS, %composites);
}

sub heb {
    my ($self, $spec) = @_;

    return join('', @HEBREW_LETTERS{split/,/, uc($spec)});
}

sub list_heb {
    my $self = shift;

    return (map { $self->heb($_) } @_);    
}




no Moose::Role;

1;    # End of Lingua::IT::Ita2heb::Role::Constants

__END__

=head1 NAME

Lingua::IT::Ita2heb::Role::Constants::Hebrew - a role for the Hebrew constants
we are using.

=head1 DESCRIPTION

A role for the Hebrew constants we are using.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package MyClass;

    use Moose;

    with ('Lingua::IT::Ita2heb::Role::Constants:Hebrew');

    no Moose;

    package main;

    my $obj = MyClass->new();

=head1 METHODS

=head2 $self->heb($spec)

Returns $spec translated into Hebrew letters. One can separate Hebrew letters
using commas (C<,>).

=head2 $self->list_heb(@specs)

Returns a list of @specs converted to Hebrew using heb (see above).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::IT::Ita2heb::Role::Constants

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-IT-Ita2heb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-IT-Ita2heb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-IT-Ita2heb>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-IT-Ita2heb/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Amir E. Aharoni.

This program is free software; you can redistribute it and
modify it under the terms of either:

=over

=item * the GNU General Public License version 3 as published
by the Free Software Foundation.

=item * or the Artistic License version 2.0.

=back

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Amir E. Aharoni, C<< <amir.aharoni at mail.huji.ac.il> >>
and Shlomi Fish ( L<http://www.shlomifish.org/> ).

=cut
