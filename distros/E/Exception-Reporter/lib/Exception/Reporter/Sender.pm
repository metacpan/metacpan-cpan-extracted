use strict;
use warnings;
package Exception::Reporter::Sender;
# ABSTRACT: a thing that sends exception reports
$Exception::Reporter::Sender::VERSION = '0.014';
#pod =head1 OVERVIEW
#pod
#pod This class exists almost entirely to allow C<isa>-checking.  It provides a
#pod C<new> method that returns a blessed, empty object.  Passing it any parameters
#pod will cause an exception to be thrown.
#pod
#pod =cut

sub new {
  my $class = shift;

  Carp::confess("$class constructor does not take any parameters") if @_;

  return bless {}, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Sender - a thing that sends exception reports

=head1 VERSION

version 0.014

=head1 OVERVIEW

This class exists almost entirely to allow C<isa>-checking.  It provides a
C<new> method that returns a blessed, empty object.  Passing it any parameters
will cause an exception to be thrown.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
