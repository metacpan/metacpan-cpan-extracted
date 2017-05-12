#---------------------------------------------------------------------
package MARC::Utils::MARC2Ini;

use 5.008002;
use strict;
use warnings;

our $VERSION = '0.02';

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( marc2ini ini2marc );
}

use constant equals       => ' = ' ;
use constant blank_line   => ''    ;
use constant null_section => '_'   ;

use MARC::Record;

sub quote {
    my( $data ) = @_;
    for( $data ) { return "'$_'" if /^ / or / $/ }  # dumb quotes
    $data;  # returned
}

#---------------------------------------------------------------------
sub marc2ini {
    my( $marc_record ) = @_;

    my @ini;

    for my $leader ( $marc_record->leader() ) {
        push @ini, join equals, leader => quote $leader;
    }

    for my $field ( $marc_record->fields() ) {

        my $ftag = $field->tag();

        if( $field->is_control_field() ) {
            push @ini, join equals, $ftag => quote $field->data();
        }

        else {
            push @ini, blank_line, "[$ftag]";

            for my $i ( 1, 2 ) {
                push @ini, join equals, "ind$i" => quote $field->indicator( $i );
            }

            for my $subfield ( $field->subfields ) {
                push @ini, join equals, $subfield->[0] => quote $subfield->[1];
            }
        }
    }

    join( "\n" => @ini ) . "\n";  # returned
}

#---------------------------------------------------------------------
sub ini2marc {
    my( $ini_string ) = @_;

    my $marc_record = MARC::Record->new();

    open my $fh, '<', \$ini_string;

    my $section = null_section;
    my( $tag, $data, @field );

    local *_;
    while( <$fh> ) {

        # comment or blank line
        if( /^\s*[#;]/ or /^\s*$/ ) { next }

        # [section]
        if( /^\[([^\]]*)\]/ ) {
            $section = $1;
            $marc_record->append_fields( MARC::Field->new( @field ) ) if @field;
            @field = $section;
            next;
        }

        # tag = data (tag="data" tag='data')
        if( /^\s*([^=:]+?)\s*[=:]\s*(.*)$/ ) {
            $tag  = $1;
            $data = $2;
            $data = $2 if $data =~ /^(['"])(.*)\1$/;  # dumb quotes
        }

        # control fields
        if( $section eq null_section ) {
            if( $tag eq 'leader' ) { $marc_record->leader( $data ) }
            else { $marc_record->append_fields( MARC::Field->new( $tag, $data ) ) }
        }

        else {
            if( $tag =~ /^ind[12]$/ ) { push @field, $data }
            else                { push @field, $tag, $data }
        }
    }
    $marc_record->append_fields( MARC::Field->new( @field ) ) if @field;

    $marc_record;  #returned
}

1;
__END__

=head1 NAME

MARC::Utils::MARC2Ini - Perl module that provides routines to
convert from a MARC::Record object to an ini file string.

=head1 SYNOPSIS

    use MARC::Utils::MARC2Ini qw( marc2ini ini2marc );

    $ini_string  = marc2ini( $marc_record );
    $marc_record = ini2marc( $ini_string );

=head1 DESCRIPTION

MARC::Utils::MARC2Ini - Perl module that provides routines to
convert from a MARC::Record object to an ini file string and
back.

=head1 SEE ALSO

MARC::Record

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

