use strict;
use warnings;

package KSx::Index::ByteBufDocReader;
use base qw( KinoSearch::Index::DocReader );
use KinoSearch::Document::HitDoc;
use Carp;

# Inside-out member vars.
our %width;
our %field;
our %instream;

sub new {
    my ( $either, %args ) = @_;
    my $width = delete $args{width};
    my $field = delete $args{field};
    my $self  = $either->SUPER::new(%args);
    confess("Missing required param 'width'") unless defined $width;
    confess("Missing required param 'field'") unless $field;
    if ( $width < 1 ) { confess("'width' must be at least 1") }
    $width{$$self} = $width;
    $field{$$self} = $field;

    my $segment  = $self->get_segment;
    my $metadata = $self->get_segment->fetch_metadata("bytebufdocs");
    if ($metadata) {
        if ( $metadata->{format} != 1 ) {
            confess("Unrecognized format: '$metadata->{format}'");
        }
        my $filename = $segment->get_name . "/bytebufdocs.dat";
        $instream{$$self} = $self->get_folder->open_in($filename)
            or confess KinoSearch->error;
    }

    return $self;
}

sub fetch_doc {
    my ( $self, $doc_id ) = @_;
    my $field = $field{$$self};
    my %fields = ( $field => '' );
    $self->read_record( $doc_id, \$fields{$field} );
    return KinoSearch::Document::HitDoc->new(
        doc_id => $doc_id,
        fields => \%fields,
    );
}

sub read_record {
    my ( $self, $doc_id, $buf ) = @_;
    my $instream = $instream{$$self};
    if ($instream) {
        my $width = $width{$$self};
        $instream->seek( $width * $doc_id );
        $instream->read( $$buf, $width );
    }
}

sub close {
    my $self = shift;
    delete $width{$$self};
    delete $instream{$$self};
}

sub DESTROY {
    my $self = shift;
    delete $width{$$self};
    delete $field{$$self};
    delete $instream{$$self};
    $self->SUPER::DESTROY;
}

1;

__END__

__POD__

=head1 NAME

KSx::Index::ByteBufDocReader - Read a Doc as a fixed-width byte array.

=head1 SYNOPSIS

    # See KSx::Index::ByteBufDocWriter

=head1 DESCRIPTION

This is a proof-of-concept class to demonstrate alternate implementations for
fetching documents.  It is unsupported.

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 Marvin Humphrey

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

