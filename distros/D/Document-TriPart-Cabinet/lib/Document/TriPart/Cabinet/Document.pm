package Document::TriPart::Cabinet::Document;

use strict;
use warnings;

use Moose;

use Document::TriPart;

has cabinet => qw/is ro required 1/;
has uuid => qw/is ro required 1/;

has _tp => qw/is ro isa Document::TriPart lazy_build 1/, handles => [qw/ preamble header body /];
sub _build__tp {
    return Document::TriPart->new;
}

sub creation {
    my $self = shift;
    return $self->header->{creation} unless @_;
    $self->header->{creation} = shift;
}

sub modification {
    my $self = shift;
    return $self->header->{modification} unless @_;
    $self->header->{modification} = shift;
}

sub load {
    my $self = shift;
    $self->cabinet->storage->load( $self );
}

sub save {
    my $self = shift;
    $self->cabinet->storage->save( $self );
}

sub _datetime {
    return DateTime->now->set_time_zone('UTC')->strftime("%F %T %z");
}

sub edit {
    my $self = shift;

    $self->header->{uuid} = $self->uuid;
    my $new;
    unless ($self->creation) {
        $new = 1;
        $self->creation( _datetime );
    }

    $self->_tp->edit( tmp => 1 );

    $self->modification( _datetime ) unless $new;

    my $uuid = $self->header->{uuid};
    $self->{uuid} = Document::TriPart::Cabinet::UUID->normalize( $uuid );

    $self->save;
}

#sub uuid {
#    my $self = shift;
#    return $self->header->{uuid} unless @_;
#    $self->header->{uuid} = shift;
#}

#sub write {
#    my $self = shift;
#    my $file = shift;
#    $self->_stembolt->write( $file => @_ );
#}

#sub read {
#    my $self = shift;
#    my $file = shift;
#    $self->_stembolt->read( $file => @_ );
#}

#has [qw/ _created_datetime _modified_datetime /] => qw/is ro lazy_build 1/;
#sub _build__created_datetime {
#    my $self = shift;
#    $self->_extract_datetime;
#    return $self->{_created_datetime};
#}
#sub _build__modified_datetime {
#    my $self = shift;
#    $self->_extract_datetime;
#    return $self->{_modified_datetime};
#}
#sub _extract_datetime {
#    my $self = shift;
#    return unless my $datetime = $self->header->{datetime};
#    my ($created, $modified) = split m/\s*|\s*/, $datetime, 2;
#    $self->{_created_datetime} = $created;
#    $self->{_modified_datetime} = $modified;
#    
#}
#sub created_datetime {
#    my $self = shift;
#    return $self->_created_datetime unless @_;
#    $self->_set_datetime( shift, $self->modified_datetime );
#}
#sub modified_datetime {
#    my $self = shift;
#    return $self->_modified_datetime unless @_;
#    $self->_set_datetime( $self->created_datetime, shift );
#}
#sub _set_datetime {
#    my $self = shift;
#    my ($created, $modified) = @_;
#    my $datetime;
#    # TODO These are not datetime objects!
#    if ($modified) {
#        $datetime = join '|', map { defined $_ ? $_ : '' } ( $created, $modified );
#    }
#    else {
#        $datetime = $created;
#    }
#    $self->header->{datetime} = $datetime;
#    $self->{_created_datetime} = $created;
#    $self->{_modified_datetime} = $modified;
#}

1;
