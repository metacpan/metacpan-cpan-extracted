package Deeme::Backend::Memory;

use strict;
use 5.008_005;
our $VERSION = '0.05';
use Deeme::Obj 'Deeme::Backend';
use Carp 'croak';

sub events_get {
    my $self        = shift;
    my $name        = shift;
    my $deserialize = shift || 1;
    #deserializing subs and returning a reference
    #return undef if ( !$event );
    return $self->{'events'}{$name}{'functions'};
}    #get events

sub events_reset{
    my $self=shift;
    delete $self->{'events'};
}

sub events_onces {
    my $self = shift;
    my $name = shift;
    #deserializing subs and returning a reference
    return @{ $self->{'events'}{$name}{'onces'} };
}    #get events

sub once_update {
    my $self  = shift;
    my $name  = shift;
    my $onces = shift;
    $self->{'events'}{$name}{'onces'} = $onces;
}    #get events

sub event_add {
    my $self = shift;
    my $name = shift;
    my $cb   = shift;
    my $once = shift || 0;
      push @{$self->{'events'}{$name}{'functions'} ||= []}, $cb;
      push @{$self->{'events'}{$name}{'onces'} ||= []}, $once;

    return $cb;
}

sub event_delete {
    my $self = shift;
    my $name = shift;

    delete $self->{'events'}{$name};

}    #delete event

sub event_update {
    my $self      = shift;
    my $name      = shift;
    my $functions = shift;
    my $serialize = shift;

    $self->{'events'}{$name}{'functions'} = $functions;
}    #update event


1;

__END__

=encoding utf-8

=head1 NAME

Deeme::Backend::Memory - Local memory backend for Deeme

=head1 SYNOPSIS

  use Deeme;
  use Deeme::Backend::Memory;
  my $e = Deeme->new( backend => Deeme::Backend::Memory->new() );


=head1 DESCRIPTION

Deeme::Backend::Memory is a local memory backend for Deeme

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
