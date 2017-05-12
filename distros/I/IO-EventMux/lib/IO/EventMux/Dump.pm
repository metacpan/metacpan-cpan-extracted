package IO::EventMux::Dump;
use strict;
use warnings;

use IO::EventMux;
use base 'IO::EventMux';

=head1 NAME

IO::EventMux::Dump - A transparent subclass of IO::EventMux that dumps input/output activity to STDOUT

=head1 SYNOPSIS
  
  use IO::EventMux::Dump;

  my $mux = IO::EventMux::Dump->new();

  $mux->add($my_fh);

  while (1) {
    my $event = $mux->mux();

    # ... do something with $event->{type} and $event->{fh}
  }


=cut

=head2 B<send()>

Wrapper for send call that will write filehandle fileno and data being send

=cut

sub send {
    my ($self, $fh, @data) = @_;

    my $fh_id = ($fh) ? $fh->fileno : '-';
    my $data = join('', @data);
    $data =~ s/\n(.)/\n      $1/sg;

    printf("%3s > %s", $fh_id, $data);

    $self->SUPER::send($fh, @data);
}


=head2 B<mux()>

Wrapper for mux call that will write filehandle fileno and data from "read" events.

=cut

sub mux {
    my $self = shift;
    my $event = $self->SUPER::mux(@_);
    
    my $fh_id = ($event->{fh} && $event->{fh}->fileno) ? $event->{fh}->fileno : '-';

    if ($event->{type} eq 'read') {
        printf("%3s < %s\n", $fh_id, $event->{data});
    }
    elsif ($event->{type} ne 'sent') { # 'sent' events are distracting to me
        printf("%3s : %s\n", $fh_id, $event->{type});
    }

    return $event;
}

=head1 AUTHOR

José Micó <jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENCE

Copyright 2009: José Micó 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
