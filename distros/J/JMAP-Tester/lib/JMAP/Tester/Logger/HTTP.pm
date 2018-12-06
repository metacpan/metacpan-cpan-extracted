use 5.14.0;
package JMAP::Tester::Logger::HTTP;
$JMAP::Tester::Logger::HTTP::VERSION = '0.022';
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

for my $which (qw(jmap upload download)) {
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

version 0.022

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
