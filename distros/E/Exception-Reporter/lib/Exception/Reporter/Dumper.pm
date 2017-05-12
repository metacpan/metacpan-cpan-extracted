use strict;
use warnings;
package Exception::Reporter::Dumper;
# ABSTRACT: something that dumps values into records
$Exception::Reporter::Dumper::VERSION = '0.014';
sub new {
  my $class = shift;

  Carp::confess("$class constructor does not take any parameters") if @_;

  return bless {}, $class;
}

sub dump {
  my $class = ref $_[0] || $_[0];
  Carp::confess("$class does not implement required Exception::Reporter::Dumper method 'dump'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Dumper - something that dumps values into records

=head1 VERSION

version 0.014

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
