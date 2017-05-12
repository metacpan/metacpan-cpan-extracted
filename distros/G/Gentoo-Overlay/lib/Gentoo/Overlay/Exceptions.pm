use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Exceptions;

our $VERSION = '2.001002';

# ABSTRACT: A custom Exception class for Gentoo which also has warning-style semantics instead of failure

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has with );
use Try::Tiny qw( try catch );
use Types::Standard qw( HashRef Str ArrayRef );
use Type::Utils qw( declare where as );
use Sub::Exporter::Progressive -setup => { exports => [ 'exception', 'warning', ] };
use String::Errf qw( errf );
use Const::Fast qw( const );
use namespace::clean -except => [ 'meta', 'import' ];

const our $W_SILENT  => 'silent';
const our $W_WARNING => 'warning';
const our $W_FATAL   => 'fatal';

our $WARNINGS_ARE = $W_WARNING;

has ident => (
  is       => 'ro',
  isa      => ( declare as Str, where { length && /\A\S/msx && /\S\z/msx } ),
  required => 1,
);

sub has_tag {
  my ( $self, $tag ) = @_;

  $_ eq $tag && return 1 for $self->tags;

  return;
}

sub tags {
  my ($self) = @_;

  # Poor man's uniq:
  my %tags = map { ; $_ => 1 } ( @{ $self->_instance_tags } );

  return wantarray ? keys %tags : ( keys %tags )[0];
}

my $tag = declare Str, where { length };

has instance_tags => (
  is       => 'ro',
  isa      => ArrayRef [$tag],
  reader   => '_instance_tags',
  init_arg => 'tags',
  default  => sub { [] },
);

has 'payload' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1,
  default  => sub { {} },
);

sub as_string {
  my ($self) = @_;
  ## no critic (RegularExpressions)
  return join q{}, $self->message, qq{\n\n  }, ( join qq{\n*  }, ( split /\n/, $self->stack_trace ) ), qq{\n};
}

use overload ( q{""} => 'as_string' );

## no critic (Subroutines::RequireArgUnpacking)
sub exception {
  return __PACKAGE__->throw(@_);
}

sub warning {

  # This code is because warnings::register sucks.
  # You can't do long-distance warning-changes that behave
  # similar to exceptions.
  #
  # warnings::register can only be toggled in the direcltly
  # preceeding scope.

  return if ( $WARNINGS_ARE eq $W_SILENT );
  if ( $WARNINGS_ARE eq $W_WARNING ) {
    ## no critic ( ErrorHandling::RequireCarping )
    return warn __PACKAGE__->new(@_);
  }
  return __PACKAGE__->throw(@_);
}





sub BUILDARGS {
  my ( undef, @args ) = @_;
  if ( 1 == scalar @args ) {
    if ( not ref $args[0] ) {
      return { ident => $args[0] };
    }
    return $args[0];
  }
  return {@args};
}
has 'message_fmt' => (
  is       => 'ro',
  isa      => Str,
  lazy     => 1,
  required => 1,
  init_arg => 'message',
  default  => sub { shift->ident },
);
with( 'Throwable', 'StackTrace::Auto', );

sub message {
  my ($self) = @_;
  return try {
    errf( $self->message_fmt, $self->payload );
  }
  catch {
    sprintf '%s (error during formatting)', $self->message_fmt;
  },;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Overlay::Exceptions - A custom Exception class for Gentoo which also has warning-style semantics instead of failure

=head1 VERSION

version 2.001002

=for Pod::Coverage BUILDARGS

=for Pod::Coverage ident message payload as_string exception warning has_tag tags

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
