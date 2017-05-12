package Gapp::App::Role::HasPlugins;
{
  $Gapp::App::Role::HasPlugins::VERSION = '0.222';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Gapp::App::Hook;

use MooseX::Types::Moose qw( Str Object );

has '_plugins' => (
    is => 'ro',
    isa => 'HashRef',
    traits => [qw( Hash )],
    default => sub { { } },
    handles => {
        plg => 'get',
    },
    lazy => 1,
);


sub register_plugin {
    my ( $self, $name, $plg ) = @_;
    
    $self->meta->throw_error( 'usage $app->register_plugin( $name, $com )' ) if ! $name || ! $plg;
    
    $plg->set_app( $self );
    
    $plg->register;
    
    $self->_plugins->{ $name } = $plg;
    
    return $plg;
}


1;

__END__

=pod

=head1 NAME

Gapp::App::Role::HasComponents - Role for app with components

=head1 SYNOPSIS

  package Foo::App;
  
  use Moose;

  extends 'Gapp::App';

  with 'Gapp::App::Role::HasComponents';

  sub BUILD {

    ( $self ) = @_;
    
    $com = .... ; # your custom component here

    $self->register_component( 'foo', $com );

  }

  package main;

  $app = Foo::App->new;
  
  $app->com('foo')->browser->show_all;

  
=head1 DESCRIPTION

Applications built using components are highly extensible. 

=head1 PROVIDED METHODS

=over 4

=item B<com $name>

Returns the component object registered with the given C<$name>.

=item B<register_component $name, $com>

Register the component with the application.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut

