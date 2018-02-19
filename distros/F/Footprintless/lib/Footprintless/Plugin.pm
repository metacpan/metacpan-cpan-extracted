use strict;
use warnings;

package Footprintless::Plugin;
$Footprintless::Plugin::VERSION = '1.27';
# ABSTRACT: The base class for footprintless plugins
# PODNAME: Footprintless::Plugin

sub new {
    my ( $class, $config, @rest ) = @_;
    return bless( { config => $config }, $class )->_init(@rest);
}

sub command_packages {
    my ($self) = @_;
    return ( ref($self) . "::Command" );
}

sub _init {
    return $_[0];
}

sub factory_methods {

    # return a map of factory methods by name
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin - The base class for footprintless plugins

=head1 VERSION

version 1.27

=head1 DESCRIPTION

This class serves as a base class for plugins.  It defines the mandatory
interface that a plugin must implement.  Plugins add methods to the factory 
itself at runtime.  For example:

    package Foo::Plugin;

    use parent qw(Footprintless::Plugin);

    sub foo {
        require Foo;
        return Foo->new();
    }

    sub factory_methods {
        my ($self) = @_;
        return {
            foo => sub {
                return $self->foo(@_);
            }
        }
    }

    package Foo;

    sub new() {
        return bless({}, shift);
    }

    sub bar {
        print("BAR");
    }

Then they can be registered with a factory instance:

    $factory->register_plugin(Foo::Plugin->new());

Or, they can be registered via configuration in the
C<footprintless.plugins> entity:

    # $FPL_HOME/config/footprintless.pm
    return {
        plugins => [
            'Foo::Plugin',
            'Bar::Plugin'
        ],
        'Foo::Plugin' => {
            # optional config
        }
        'Bar::Plugin' => {
            # optional config
        }
    };

Then you can use the methods directly on the footprintless instance:

    my $footprintless = Footprintless->new();
    my $foo = $footprintless->foo();

If a key with the same name as the plugin is present in the C<footprintless>
entity, then the entire hashref will be set as C<$self->{config}> on the
plugin instance during construction.  You can then override the C<_init()>
method to do configuration based initialization.

If you want to add commands, just add a module under the package returned
by L<command_packages|/command_packages()> (defaults to 
C<ref($self) . '::Command'>):

    package Foo::Plugin::Command::foo
    use Footprintless::App -command;
    
    sub execute {
        my ($self, $opts, $args) = @_;

        my $foo = $self->app()->footprintless()->foo();

        $foo->bar();
    }

Then your command will be availble from the fpl command:

    $> fpl foo
    BAR

=head1 CONSTRUCTORS

=head2 new()

Creates a new plugin.

=head1 METHODS

=head2 command_packages()

Returns a list of packages to scan for commands.

=head2 factory_methods()

Returns a hash full of factory methods.  The key will be used as the method
name that gets registered with the factory.  Its value must be a reference
to a sub.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=back

=cut
