#---------------------------------------------------------------------
package MARC::Utils::MARC2Pairs;

use 5.008002;
use strict;
use warnings;

our $VERSION = '0.02';

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( marc2pairs pairs2marc );
}

use MARC::Record;
use Data::Pairs qw( pairs_add pairs_get_array );

#---------------------------------------------------------------------
sub marc2pairs {
    my( $marc_record ) = @_;

    my $pairs = [];

    for my $leader ( $marc_record->leader() ) {
        pairs_add( $pairs, leader => $leader );
    }

    for my $field ( $marc_record->fields() ) {

        my $ftag = $field->tag();

        if( $field->is_control_field() ) {
            pairs_add( $pairs, $ftag => $field->data() );
        }

        else {
            my $subpairs = [];

            for my $i ( 1, 2 ) {
                pairs_add( $subpairs, "ind$i" => $field->indicator( $i ) );
            }

            for my $subfield ( $field->subfields ) {
                pairs_add( $subpairs, $subfield->[0] => $subfield->[1] );
            }

            pairs_add( $pairs, $ftag => $subpairs );
        }
    }

    $pairs;  # returned
}

#---------------------------------------------------------------------
sub pairs2marc {
    my( $pairs ) = @_;

    my $marc_record = MARC::Record->new();

    for my $field ( pairs_get_array( $pairs ) ) {

        my( $ftag, $fdata ) = %$field;

        if( $ftag eq 'leader' ) {
            $marc_record->leader( $fdata );
        }

        elsif( ref $fdata ) {
            my( $ind1, $ind2, @subfields );

            for my $subfield ( pairs_get_array( $fdata ) ) {
                my( $sftag, $sfdata ) = %$subfield;
                if(    $sftag eq 'ind1' ) { $ind1 = $sfdata }
                elsif( $sftag eq 'ind2' ) { $ind2 = $sfdata }
                else { push @subfields, $sftag, $sfdata }
            }
            $marc_record->append_fields( MARC::Field->new(
                $ftag, $ind1, $ind2, @subfields ) );
        }

        # control field
        else {
            $marc_record->append_fields( MARC::Field->new( $ftag, $fdata ) );
        }
    }

    $marc_record;  #returned
}

1;
__END__

=head1 NAME

MARC::Utils::MARC2Pairs - Perl module that provides routines to
convert from a MARC::Record object to a Data::Pairs structure.

=head1 SYNOPSIS

    use MARC::Utils::MARC2Pairs qw( marc2pairs pairs2marc );

    $pairs       = marc2pairs( $marc_record );
    $marc_record = pairs2marc( $pairs );

=head1 DESCRIPTION

MARC::Utils::MARC2Pairs - Perl module that provides routines to
convert from a MARC::Record object to a Data::Pairs structure and
back.

The resulting structure may be serialized, e.g., as JSON or YAML.

=head1 SEE ALSO

MARC::Record
Data::Pairs

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

