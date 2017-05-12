package Gapp::App::Role::HasHooks;
{
  $Gapp::App::Role::HasHooks::VERSION = '0.222';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Gapp::App::Hook;

use MooseX::Types::Moose qw( Str Object );

has '_hooks' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { { } },
    lazy => 1,
);

# call a hook
sub call_hook {
    my ( $self, $hook_name, @params ) = @_;
    return if ! $self->_hooks->{$hook_name};
    
    my $hook = $self->_hooks->{$hook_name};
    return if ! $hook;
    
    $hook->call( $self, @params );
}


# register a callback to a hook
sub hook {
    my ( $self, $hook_name, $plugin, $function, $data ) = @_;
    
    # create a hook if it does not exist already
    $self->_hooks->{$hook_name} = $self->register_hook( $hook_name ) if ! $self->_hooks->{$hook_name};
    
    my $hook = $self->_hooks->{$hook_name};
    $hook->push( $plugin, $function, $data );
}

# define behavior of a hook
sub register_hook {
    my ( $self, $hook, %opts ) = @_;
    
    # if is a string, create a new hook
    if ( is_Str( $hook ) ) {
        $hook = $self->_hooks->{$hook} = Gapp::App::Hook->new( name => $hook, %opts );
    }
    # if is a hook object, just add it to the registry
    elsif ( is_Object( $hook ) ) {
        $self->_hooks->{$hook->name} = $hook;
    }
    # if not a string or hook, die
    else {
        $self->meta->throw_error( qq[could not register hook $hook, not a string or Gapp::App::Plugin::Hook] );
    }
   
    return $hook;
}



1;


__END__

=pod

=head1 NAME

Gapp::App::Role::HasHooks - Role for app with hooks

=head1 SYNOPSIS

  package Foo::App;
  
  use Moose;

  extends 'Gapp::App';

  with 'Gapp::App::Role::HasHooks';

  sub BUILD {

    ( $self ) = @_;

    $self->register_hook('init');

  }

  sub init {

    $self->call_hook('init');

  }

  ...

  package main;

  $app = Foo::App->new;
  
  $app->hook( 'init', sub { print 'Hello world!' } );

  $app->init;
  
=head1 DESCRIPTION

Hooks are named callbacks points in your application. Hooks can be used to
add plugin functionality.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<hooks>

HashRef of L<Gapp::App::Hook> objects.

=over 4

=item is rw

=item isa HashRef

=item default { }

=item lazy

=back

=back

=head1 PROVIDED METHODS

=over 4

=item B<call_hook $hook_name, @params>

Will call callbacks for C<$hook_name>, passing in the supplied C<params>. Callbacks
are associated with hooks using the C<hook> method.

=item B<hook $hook_name, $func, $data>

Bind a callback to the given C<$hook_name>.

=item B<register_hook $hook_name, %opts?>

Register a hook with the application. See <Gapp::App::Hook> for available options.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut

