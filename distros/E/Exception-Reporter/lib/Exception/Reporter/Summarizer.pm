use strict;
use warnings;
package Exception::Reporter::Summarizer 0.015;
# ABSTRACT: a thing that summarizes dumpables for reporting

use Carp ();
use Scalar::Util ();

#pod =head1 OVERVIEW
#pod
#pod This class exists almost entirely to allow C<isa>-checking.  It provides a
#pod C<new> method that returns a blessed, empty object.  Passing it any parameters
#pod will cause an exception to be thrown.
#pod
#pod A C<sanitize_filename> method is also provided, which turns a vaguely
#pod filename-like string into a safer filename string.
#pod
#pod =cut

sub new {
  my $class = shift;

  Carp::confess("$class constructor does not take any parameters") if @_;

  return bless {}, $class;
}

sub sanitize_filename {
  my ($self, $filename) = @_;

  # These don't need to be actually secure, since we won't use this for
  # opening any filehandles. -- rjbs, 2012-07-03
  $filename =~ s/\.+/./g;
  $filename =~ s/[^-a-zA-Z0-9]/-/g;
  return $filename;
}

sub register_reporter {
  my ($self, $reporter) = @_;

  Carp::confess("register_reporter called, but a reporter was already registered")
    if $self->{reporter};

  $self->{reporter} = $reporter;
  Scalar::Util::weaken($self->{reporter});
  return;
}

sub reporter { $_[0]->{reporter} }

sub dump {
  my ($self, $value, $arg) = @_;
  $self->reporter->dumper->dump($value, $arg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer - a thing that summarizes dumpables for reporting

=head1 VERSION

version 0.015

=head1 OVERVIEW

This class exists almost entirely to allow C<isa>-checking.  It provides a
C<new> method that returns a blessed, empty object.  Passing it any parameters
will cause an exception to be thrown.

A C<sanitize_filename> method is also provided, which turns a vaguely
filename-like string into a safer filename string.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
