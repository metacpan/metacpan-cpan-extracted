use v5.14.0;
package JMAP::Tester::Abort 0.104;

use Moo;
extends 'Throwable::Error';

use namespace::clean;

use Sub::Exporter -setup => {
  exports => {
    abort => sub {
      my $pkg = shift;
      return sub { die $pkg->new(@_) }
    }
  }
};

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
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

sub as_test_abort_events {
  return [
    [ Ok => (pass => 0, name => $_[0]->message) ],
    ($_[0]->diagnostics
      ? (map {; [ Diag => (message => $_) ] } @{ $_[0]->diagnostics })
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

version 0.104

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
