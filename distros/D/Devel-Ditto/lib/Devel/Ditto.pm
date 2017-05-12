package Devel::Ditto;

use 5.008;

=head1 NAME

Devel::Ditto - Identify where print output comes from

=head1 VERSION

This document describes Devel::Ditto version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

  $ perl -MDevel::Ditto myprog.pl
  [main, t/myprog.pl, 9] This is regular text
  [main, t/myprog.pl, 10] This is a warning
  [MyPrinter, t/lib/MyPrinter.pm, 7] Hello, World
  [MyPrinter, t/lib/MyPrinter.pm, 8] Whappen?

=head1 DESCRIPTION

Sometimes it's hard to work out where some printed output is coming
from. This module ties STDOUT and STDERR such that each call to C<print>
or C<warn> will have its output prefixed with the package, file and line
of the C<print> or C<warn> statement.

Load it in your program:

  use Devel::Ditto;

or from the command line:

  perl -MDevel::Ditto myprog.pl
  
=cut

no warnings;

open( REALSTDOUT, ">&STDOUT" );
open( REALSTDERR, ">&STDERR" );

use warnings;
use strict;

use File::Spec;

sub import {
  my $class  = shift;
  my %params = @_;

  tie *STDOUT, $class, %params,
   is_err  => 0,
   realout => sub {
    open( local *STDOUT, ">&REALSTDOUT" );
    $_[0]->( @_[ 1 .. $#_ ] );
   };

  tie *STDERR, $class, %params,
   is_err  => 1,
   realout => sub {
    open( local *STDOUT, ">&REALSTDERR" );
    $_[0]->( @_[ 1 .. $#_ ] );
   };
}

sub TIEHANDLE {
  my ( $class, %params ) = @_;
  bless \%params, $class;
}

sub _caller {
  my $self  = shift;
  my $depth = 0;
  while () {
    my ( $pkg, $file, $line ) = caller $depth;
    return unless defined $pkg;
    return ( $pkg, $file, $line )
     unless $pkg->isa( __PACKAGE__ );
    $depth++;
  }
}

sub _logbit {
  my $self = shift;
  my ( $pkg, $file, $line ) = $self->_caller();
  $file = File::Spec->canonpath($file);
  return "[$pkg, $file, $line] ";
}

sub PRINT {
  my $self = shift;
  $self->{realout}->( sub { print $self->_logbit, @_ }, @_ );
}

sub PRINTF {
  my $self = shift;
  $self->PRINT( sprintf $_[0], @_[ 1 .. $#_ ] );
}

sub WRITE {
  my $self = shift;
  $self->{realout}->(
    sub {
      my ( $buf, $len, $offset ) = @_;
      syswrite STDOUT, $buf, $len, defined $offset ? $offset : 0;
    },
    @_
  );
}

sub CLOSE {
  my $self = shift;
  if ( $self->{is_err} ) {
    close REALSTDERR;
  }
  else {
    close REALSTDOUT;
  }
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-Ditto@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
