use 5.006;    # our
use strict;
use warnings;

package App::Isa::Splain;

our $VERSION = '0.002001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

# ABSTRACT: Visualize Module Hierarchies on the command line

use Module::Load qw( load );
use Carp qw( croak );
use Devel::Isa::Explainer qw( explain_isa );

# Perl critic is broken. This is not a void context.
## no critic (BuiltinFunctions::ProhibitVoidMap)
use constant 1.03 ( { map { ( ( sprintf '_E%x', $_ ), ( sprintf ' E<%s#%d>', __PACKAGE__, $_ ) ) } 1 .. 3 } );

use namespace::clean;











sub new {
  my ( $class, @args ) = @_;
  my (%args) = ref $args[0] ? %{ $args[0] } : @args;
  return bless \%args, $class;
}












sub new_from_ARGV {
  my (@args) = defined $_[1] ? @{ $_[1] } : @ARGV;
  my $module;
  my @load_modules;
  while ( @args ) {
    my $argument = shift @args;
    if ( not defined $module and $argument !~ /\A-/sx ) {
      $module = $argument;
      next;
    }
    if( $argument =~ /\A-M(.*)\z/sx ) {
      push @load_modules, $1;
      next;
    }
    croak 'Unexpected argument ' . $argument . _E3;
  }
  defined $module or croak 'Expected a module name, got none' . _E1;
  return $_[0]->new( module => $module, load_modules => [ @load_modules ? @load_modules : $module ] );
}

sub _load_modules { return @{ $_[0]->{load_modules} } }
sub _module { return $_[0]->{module} }
sub _output { return ( $_[0]->{output} || *STDOUT ) }







sub run {
  my ($self) = @_;
  load $_ for $self->_load_modules;
  croak "Could not print to output handle: $! $^E" . _E2
    unless print { $self->_output } explain_isa( $self->_module );

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Isa::Splain - Visualize Module Hierarchies on the command line

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

  my $instance = App::Isa::Splain->new_from_ARGV;
  $instance->run;

=for html <center><img alt="Colorised output from a Moose::Meta::Class" src="http://kentnl.github.io/screenshots/Devel-Isa-Explainer/1/c1.png" width="820" height="559" /></center>

=head1 METHODS

=head2 C<new>

Creates an Explainer script for the given module

  my $instance = App::Isa::Splain->new(
    module => "module::name"
  );

=head2 C<new_from_ARGV>

Creates an Explainer script by passing command line arguments

  my $instance = App::Isa::Splain->new_from_ARGV;
  my $instance = App::Isa::Splain->new_from_ARGV(\@ARGV); # Alternative syntax

See L<COMMAND LINE ARGUMENTS|/COMMAND LINE ARGUMENTS>

=head2 C<run>

Executes the explainer and prints its output.

=head1 COMMAND LINE ARGUMENTS

  isa-splain [-MModule::Name] Module::Name

=over 4

=item * C<Module::Name>

A module to C<require> and analyze the C<ISA> of.

=item * C<-MI<Module::Name>>

A module to load instead of the module being analyzed, for example:

  isa-splain -MB B::CV
  isa-splain -Moose Class::MOP::Class

Helpful for cases where simple C<isa-splain Module::Name> causes problems.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
