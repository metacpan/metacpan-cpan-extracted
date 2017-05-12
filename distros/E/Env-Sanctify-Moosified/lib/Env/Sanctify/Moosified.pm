package Env::Sanctify::Moosified;
{
  $Env::Sanctify::Moosified::VERSION = '1.06';
}

#ABSTRACT: Lexically scoped sanctification of %ENV

use strict;
use warnings;

use Moo;
use MooX::late;

has env => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { { } },
);

has sanctify => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [ ] },
);

has _backup => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { { } },
);

has _restored => (
  is      => 'rw',
  isa	  => 'Bool',
  default => 0,
);

sub consecrate {
  my $self = shift->new( @_ );
  $self->_sanctify;
  return $self;
}

sub _sanctify {
  my $self = shift;
  foreach my $regex ( @{ $self->sanctify } ) {
    $self->_backup->{$_} = delete $ENV{$_} for grep { eval { /$regex/ } } keys %ENV;
  }
  $self->_backup->{$_} = delete $ENV{$_} for grep { defined $ENV{$_} } keys %{ $self->env };
  $ENV{$_} = $self->env->{$_} for keys %{ $self->env };
  return 1;
}

sub restore {
  my $self = shift;
  delete $ENV{$_} for keys %{ $self->env };
  $ENV{$_} = $self->_backup->{$_} for keys %{ $self->_backup };
  return $self->_restored(1);
}

sub DEMOLISH {
  my $self = shift;
  $self->restore unless $self->_restored;
}

no Moo;
__PACKAGE__->meta->make_immutable;

'Sanctify yourself, set yourself free';

__END__

=pod

=head1 NAME

Env::Sanctify::Moosified - Lexically scoped sanctification of %ENV

=head1 VERSION

version 1.06

=head1 SYNOPSIS

  my $sanctify = Env::Sanctify::Moosified->consecrate( sanctify => [ '^POE' ] );

  # do some stuff, fork some processes etc.

  $sanctify->restore

  {

    my $sanctify = Env::Sanctify::Moosified->consecrate( env => { POE_TRACE_DEFAULT => 1 } );

    # do some stuff, fork some processes etc.
  }

  # out of scope, %ENV is back to normal

=head1 DESCRIPTION

Env::Sanctify::Moosified is a module that provides lexically scoped manipulation and sanctification of
C<%ENV>.

You can specify that it alter or add additional environment variables or remove existing ones
according to a list of matching regexen.

You can then either C<restore> the environment back manually or let the object fall out of
scope, which automagically restores.

Useful for manipulating the environment that forked processes and sub-processes will inherit.

=for Pod::Coverage   DEMOLISH

=head1 CONSTRUCTOR

=over

=item C<consecrate>

Creates an Env::Sanctify::Moosified object. Takes two optional arguments:

=over

=item C<env>

A hashref of env vars to add to C<%ENV>.

=item C<sanctify>

An arrayref of regex pattern strings to match against current C<%ENV> vars;

=back

Any C<%ENV> var that matches a C<sanctify> regex is removed from the resultant C<%ENV>.

=back

=head1 METHODs

=over

=item C<restore>

Explicitly restore the previous C<%ENV>. This is called automagically when the object is C<DESTROY>ed,
for instance, when it goes out of scope.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
