package Deeme::Job;
use Deeme::Obj -base;
has [qw(cb deeme)];

sub process {
    my $self = shift;
    my $cb   = $self->cb;
    $self->deeme->{'queue'}
        = [ grep { $self ne $_ } @{ $self->deeme->{'queue'} } ];
    return eval { $self->$cb(@_); 1; };
}
1;
__END__

=encoding utf-8

=head1 NAME

Deeme::Job - represent a Deeme Job

=head1 SYNOPSIS



  my $worker_tiger = Deeme::Worker->new(backend=> Deeme::Backend::Mango->new(...));
  while(my $Job=$worker_tiger->dequeue("roar")){
    $Job->process(@args);
  }

=head1 DESCRIPTION

Deeme::Job it's  a class representing a job in L<Deeme::Worker>.


=head1 METHODS

=head2 process

  $r = $Job->process(1,2,3,"beer");

Process the job with the given arguments

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Deeme>, L<Deeme::Backend::Mango>, L<Deeme::Backend::Meerkat>,  L<Deeme::Backend::Memory>, L<Mojo::EventEmitter>, L<Mojolicious>

=cut
