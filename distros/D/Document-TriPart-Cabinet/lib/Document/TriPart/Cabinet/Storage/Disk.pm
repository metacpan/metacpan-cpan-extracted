package Document::TriPart::Cabinet::Storage::Disk;

use Moose;

use Document::TriPart::Cabinet::UUID;

use Path::Class;

has dir => qw/is ro required 1/;

sub uuid_path {
    my $self = shift;
    my $uuid = Document::TriPart::Cabinet::UUID->normalize( shift );
    my $first2 = substr $uuid, 0, 2;
    my @path = ( $first2, $uuid );
    return wantarray ? @path : join '/', @path;
}

sub document_dir {
    my $self = shift;
    my $uuid = shift;

    $uuid = $uuid->uuid if blessed $uuid && $uuid->can( 'uuid' ); # Probably ::Document
    return $self->dir->subdir( $self->uuid_path( $uuid ) );
}

sub document_file {
    my $self = shift;
    my $uuid = shift;

    return $self->document_dir( $uuid )->file( 'document' );
}

sub assets_dir {
    my $self = shift;
    my $uuid = shift;

    return $self->document_dir( $uuid )->subdir( 'assets' );
}

sub _read_document {
    my $self = shift;
    my $document = shift;

    my $document_file = $self->document_file( $document->uuid );
    return unless -e $document_file;

    $document->_tp->read( $document_file );
    # TODO Sanity check that $document->uuid == $uuid
}

sub load {
    my $self = shift;
    my $document = shift;
    $self->_read_document( $document );
}

sub _write_document {
    my $self = shift;
    my $document = shift;

    my $document_file = $self->document_file( $document->uuid );
    $document_file->parent->mkpath unless -d $document_file->parent;
    $document->_tp->write( $document_file );
}

sub save {
    my $self = shift;
    my $document = shift;
    $self->_write_document( $document );
}

#sub insert {
#    my $self = shift;
#    my $document = shift;
#    $self->_write_document( $document );
#}

#sub update {
#    my $self = shift;
#    my $document = shift;
#    $self->_write_document( $document );
#}

#sub update_or_insert {
#    my $self = shift;
#    my $document = shift;

#    if ( $self->_load( $document ) ) {
#        $self->update( $document );
#    }
#    else {
#        $self->insert( $document );
#    }
#}
1;
