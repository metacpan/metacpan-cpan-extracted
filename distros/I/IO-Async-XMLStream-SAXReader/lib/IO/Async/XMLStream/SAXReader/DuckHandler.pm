use 5.006;    # our
use strict;
use warnings;

package IO::Async::XMLStream::SAXReader::DuckHandler;

our $VERSION = '0.001002';

# ABSTRACT: Deferred Handler proxy for IO::Async constructor-driven interface

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Scalar::Util qw(weaken);
use Carp qw(croak);










sub new {
  my ( $self, $opts ) = @_;
  croak('SAXReader option is mandatory') unless exists $opts->{SAXReader};
  weaken $opts->{SAXReader};
  return bless $opts, $self;
}

sub _dyn_method {
  my ( $self, $method ) = @_;
  my $sax      = $self->{SAXReader};
  my $event    = 'on_' . $method;
  my $callback = $sax->can_event($event);
  return unless $callback;
  return sub {
    my ( undef, @args ) = @_;
    return $callback->( $sax, @args );
  };
}

sub can {
  my ( $self, $method ) = @_;
  my $orig = $self->SUPER::can($method);
  return $orig if $orig;
  return $self->_dyn_method($method);
}

## no critic (ClassHierarchies::ProhibitAutoloading)
sub AUTOLOAD {
  my ( $self, @args ) = @_;
  ( my $methname = our $AUTOLOAD ) =~ s/.+:://msx;
  return if 'DESTROY' eq $methname;
  return unless my $meth = $self->_dyn_method($methname);
  return $meth->( $self, @args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Async::XMLStream::SAXReader::DuckHandler - Deferred Handler proxy for IO::Async constructor-driven interface

=head1 VERSION

version 0.001002

=for Pod::Coverage new
can

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
