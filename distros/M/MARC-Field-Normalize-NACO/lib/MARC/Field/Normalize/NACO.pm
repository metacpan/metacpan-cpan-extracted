package MARC::Field::Normalize::NACO;

use strict;
use warnings;
use utf8;
use Unicode::Normalize qw(NFD);
use List::MoreUtils qw(natatime);
use MARC::Field;
use Method::Signatures;

our $VERSION = '0.05';

use vars qw( @EXPORT_OK );
use Exporter 'import';
@EXPORT_OK = qw(
    naco_from_string naco_from_array
    naco_from_field naco_from_authority
);

func naco_from_string( Str $s, Bool :$keep_first_comma ) {
    # decompose and uppercase
    $s = uc( NFD($s) );

    # strip out combining diacritics
    $s =~ s/\p{M}//g;

    # transpose diagraphs and related characters
    $s =~ s/Æ/AE/g;
    $s =~ s/Œ/OE/g;
    $s =~ s/Ø|Ҩ/O/g;
    $s =~ s/Þ/TH/g;
    $s =~ s/Ð/D/g;
    $s =~ s/ß/SS/g;

    # transpose sub- and super-script with numerals
    $s =~ tr/⁰¹²³⁴⁵⁶⁷⁸⁹/0123456789/;
    $s =~ tr/₀₁₂₃₄₅₆₇₈₉/0123456789/;

    # delete or blank out punctuation
    $s =~ s/[!"()\-{}<>;:.?¿¡\/\\*\|%=±⁺⁻™℗©°^_`~]/ /g;
    $s =~ s/['\[\]ЪЬ·]//g;

    # blank out commas
    if ($keep_first_comma) {
        my $i = index $s, ',';
        $s =~ s/,/ /g;
        $s =~ s/^((?:.){$i})\s/$1,/;
        # always strip off a trailing comma, even if it's the only one
        $s =~ s/,$//;
    }
    else {
        $s =~ s/,/ /g;
    }

    # lastly, trim and deduplicate whitespace
    $s =~ s/\s\s+/ /g;
    $s =~ s/^\s+|\s+$//g;

    return $s;
}

func naco_from_array( ArrayRef $subfs ) {
    # Expects $subfs == [ 'a', 'Thurber, James', 'd', '1914-', ... ]
    my $itr = natatime 2, @$subfs;
    my $out = '';
    while (my ($subf, $val) = $itr->()) {
        my $norm = naco_from_string( $val, keep_first_comma => $subf eq 'a' );
        $out .= '$'. $subf . $norm;
    }
    return $out;
}

func naco_from_field( MARC::Field $f, :$subfields = 'a-df-hj-vx-z') {
    my @flat = map {@$_} grep {$_->[0] =~ /[$subfields]/} $f->subfields;
    return naco_from_array( \@flat );
}

func naco_from_authority( MARC::Record $r ) {
    return naco_from_field( scalar $r->field('1..'), subfields => 'a-z' );
}

{
    no warnings qw(once);
    *MARC::Field::as_naco = \&naco_from_field;
}

1;
__END__

=encoding utf-8

=head1 NAME

MARC::Field::Normalize::NACO - Matching normalization for MARC::Field

=head1 SYNOPSIS

  use MARC::Field;
  use MARC::Field::Normalize::NACO;

  my $field = MARC::Field->new(
      '100', ' ', ' ', a => 'Stephenson, Neal,', d => '1953-');
  my $normalized = $field->as_naco;
  my $custom = $field->as_naco(subfields => 'a');

=head1 DESCRIPTION

MARC::Field::Normalize::NACO turns MARC::Field objects into
strings canonicalized into NACO format. This makes them
suitable for matching against an index of similarly normalized
fields.

The principal means of invoking is through the as_naco() method
that the module injects into MARC::Field when loaded. A string
is returned.

This method takes an optional named parameter, subfields. The
value of this parameter should be something that fits nicely
into the regex qr/[$subfields]/, typically a range of letters.
The default value is "a-z68".

=head1 AUTHOR

Clay Fouts E<lt>cfouts@khephera.netE<gt>

=head1 COPYRIGHT

Copyright 2013 PTFS, Inc.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://www.loc.gov/aba/pcc/naco/normrule-2.html

=item *

MARC::Record

=back

=cut
