package Log::Any::Plugin;
# ABSTRACT: Adapter-modifying plugins for Log::Any
$Log::Any::Plugin::VERSION = '0.008';
use strict;
use warnings;

use Log::Any 1.00;
use Log::Any::Plugin::Util  qw( get_class_name  );

use Class::Load qw( try_load_class );
use Carp qw( croak );

sub add {
    my ($class, $plugin_class, %plugin_args) = @_;

    my $adapter_class = ref Log::Any->get_logger(category => caller());

    $plugin_class = get_class_name($plugin_class);

    my ($loaded, $error) = try_load_class($plugin_class);
    die $error unless $loaded;

    $plugin_class->install($adapter_class, %plugin_args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Plugin - Adapter-modifying plugins for Log::Any

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Log::Any::Adapter;
    use Log::Any::Plugin;

    # Create your adapter as normal
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Add plugin to modify its behaviour
    Log::Any::Plugin->add( 'Stringify' );

    # Multiple plugins may be used together
    Log::Any::Plugin->add( 'Levels', level => 'debug' );

=head1 DESCRIPTION

Log::Any::Plugin is a method for augmenting arbitrary instances of
Log::Any::Adapters.

Log::Any::Plugins work much in the same manner as Moose 'around' modifiers to
augment logging behaviour of pre-existing adapters.

=head1 MOTIVATION

Many of the Log::Any::Adapters have extended functionality, such as being
able to selectively disable various log levels, or to handle multiple arguments.

In order for Log::Any to be truly 'any', only the common subset of adapter
functionality can be used. Any specific adapter functionality must be avoided
if there is a possibility of using a different adapter at a later date.

Log::Any::Plugins provide a method to augment adapters with missing
functionality so that a superset of adapter functionality can be used.

=head1 METHODS

=head2 add ( $plugin, [ %plugin_args ] )

This is the single method for adding plugins to adapters. It works in a
similar function to Log::Any::Adapter->set()

=over

=item * $plugin

The plugin class to add to the currently active adapter. If the class is in
the Log::Any::Plugin:: namespace, you can simply specify the name, otherwise
prefix a '+'.

    eg. '+My::Plugin::Class'

=item * %plugin_args

These are plugin specific arguments. See the individual plugin documentation for
what options are supported.

=back

=head1 SEE ALSO

L<Log::Any>, L<Log::Any::Plugin::Levels>, L<Log::Any::Plugin::Stringify>

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2011 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords José Joaquín Atria Kamal Advani

=over 4

=item *

José Joaquín Atria <jjatria@gmail.com>

=item *

Kamal Advani <kamal@namingcrisis.net>

=back

=cut
