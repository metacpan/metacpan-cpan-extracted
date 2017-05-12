package Deeme::Backend::Mango;

our $VERSION = '0.02';
use Deeme::Obj 'Deeme::Backend';
use Mango;
use Deeme::Utils qw(_serialize _deserialize);
use Carp 'croak';

#use Carp::Always;
has [qw(host database)];

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    croak "No connection string defined, host option missing"
        if ( !$self->host );
    croak "No database string defined, database option missing"
        if ( !$self->database );
    return $self;
}

sub mango {
    my $self = shift;
    return Mango->new( $self->host )->db( $self->database );
}

sub events_get {
    my $self        = shift;
    my $name        = shift;
    my $deserialize = shift // 1;
    my $event
        = $self->mango->collection("Event")->find_one( { name => $name } );

    #deserializing subs and returning a reference
    return undef if ( !$event );
    return [ map { _deserialize($_) } @{ $event->{functions} } ]
        if ( $deserialize == 1 );
    return $event->{functions};
}    #get events

sub events_reset {
    my $self = shift;
    $self->mango->collection("Event")->remove( {} );
}

sub events_onces {
    my $self = shift;
    my $name = shift;
    my $event
        = $self->mango->collection("Event")->find_one( { name => $name } );

    #deserializing subs and returning a reference
    return @{ $event->{onces} };
}    #get events

sub once_update {
    my $self  = shift;
    my $name  = shift;
    my $onces = shift;
    $self->mango->collection("Event")
        ->update( { name => $name }, { '$set' => { onces => $onces } } );
}    #get events

sub event_add {
    my $self = shift;
    my $name = shift;
    my $cb   = shift;
    my $once = shift // 0;
    $cb = _serialize($cb);
    return $cb
        if ( $self->mango->collection("Event")
        ->find_one( { name => $name, functions => $cb } ) )
        ;    #return if already existing
             #  serializing sub and adding to db
    if ( my $event
        = $self->mango->collection("Event")->find_one( { name => $name } ) )
    {
        $self->mango->collection("Event")->update( { name => $name },
            { '$push' => { onces => $once, functions => $cb } } );
    }
    else {
        my $event = $self->mango->collection("Event")->insert(
            {   name      => $name,
                functions => [$cb],
                onces     => [$once]
            }
        );
    }
    return $cb;
}

sub event_delete {
    my $self = shift;
    my $name = shift;
    $self->mango->collection("Event")->remove( { name => $name } );
}    #delete event

sub event_update {
    my $self      = shift;
    my $name      = shift;
    my $functions = shift;
    my $serialize = shift // 1;
    return $self->event_delete($name) if ( scalar( @{$functions} ) == 0 );
    return $self->mango->collection("Event")->update(
        { name => $name },
        {   '$set' =>
                { functions => [ map { _serialize($_) } @{$functions} ] }
        }
    ) if ( $serialize == 1 );
    $self->mango->collection("Event")->update( { name => $name },
        { '$set' => { functions => $functions } } );
}    #update event

1;
__END__

=encoding utf-8

=head1 NAME

Deeme::Backend::Mango - MongoDB Backend using Mango for Deeme

=head1 SYNOPSIS

  use Deeme::Backend::Mango;
  my $e = Deeme->new( backend => Deeme::Backend::Mango->new(
        database => "deeme",
        host     => "mongodb://user:pass@localhost:27017",
    ) );

=head1 DESCRIPTION

Deeme::Backend::Mango is a MongoDB Deeme database backend using Mango.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Deeme>

=cut
