use v5.20.0;
package JMAP::Tester::Abort 0.108;

use Moo;
extends 'Throwable::Error';

use experimental 'signatures';

use namespace::clean;

use Sub::Exporter -setup => {
  exports => {
    abort => sub {
      my $pkg = shift;
      return sub (@args) { die $pkg->new(@args) }
    }
  }
};

around BUILDARGS => sub ($orig, $self, @args) {
  return { message => $args[0] } if @args == 1 && ! ref $args[0];
  return $self->$orig(@args);
};

has message => (
  is => 'ro',
  required => 1,
);

has diagnostics => (
  is => 'ro',
);

sub as_test_abort_events ($self) {
  return [
    [ Ok => (pass => 0, name => $self->message) ],
    ($self->diagnostics
      ? (map {; [ Diag => (message => $_) ] } @{ $self->diagnostics })
      : ()),
  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Abort

=head1 VERSION

version 0.108

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
