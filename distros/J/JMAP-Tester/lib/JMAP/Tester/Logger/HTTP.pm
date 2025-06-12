use v5.14.0;
package JMAP::Tester::Logger::HTTP 0.104;

use Moo;

use namespace::clean;

my %counter;

sub _log_generic {
  my ($self, $type, $thing) = @_;

  my $i = $counter{$type}++;
  $self->write("=== BEGIN \U$type\E $$.$i ===\n");
  $self->write( $thing->as_string );
  $self->write("=== END \U$type\E $$.$i ===\n");
  return;
}

for my $which (qw(jmap misc upload download)) {
  for my $what (qw(request response)) {
    my $method = "log_${which}_${what}";
    no strict 'refs';
    *$method = sub {
      my ($self, $arg) = @_;
      $self->_log_generic("$which $what", $arg->{"http_$what"});
    }
  }
}

with 'JMAP::Tester::Logger';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Logger::HTTP

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
