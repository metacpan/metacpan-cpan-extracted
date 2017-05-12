package Maypole::FormBuilder::Model::Plain;

use warnings;
use strict;

use base 'Maypole::FormBuilder::Model';

use Maypole::FormBuilder;
our $VERSION = $Maypole::FormBuilder::VERSION;

Maypole::Config->mk_accessors( qw( table_to_class ) );

sub setup_database 
{
    my ( $self, $config, $namespace, $classes ) = @_;
    
    $config->{classes}        = $classes;
    $config->{table_to_class} = { map { $_->table => $_ } @$classes };
    $config->{tables}         = [ keys %{ $config->{table_to_class} } ];
}

sub class_of 
{
    my ( $self, $r, $table ) = @_;
    
    return $r->config->{table_to_class}->{ $table };
}

1;

=head1 NAME

Maypole::FormBuilder::Model::Plain - Class::DBI model without ::Loader

=head1 SYNOPSIS

    package Foo;
    use 'Maypole::Application';
    use Foo::SomeTable;
    use Foo::Other::Table;

    Foo->config->model( 'Maypole::FormBuilder::Model::Plain' );
    
    Foo->setup( [ qw/ Foo::SomeTable Foo::Other::Table / ] );
    
    # Foo now inherits from Class::DBI::FormBuilder via the model
    Foo->form_builder_defaults( { method => 'post' } );

=head1 DESCRIPTION

This module allows you to use Maypole with previously set-up
L<Class::DBI> classes; simply call C<setup> with a list reference
of the classes you're going to use, and Maypole will work out the
tables and set up the inheritance relationships as normal.

=head1 METHODS

=over 4

=item setup_database

=item  class_of

=back

See L<Maypole::FormBuilder::Model>

=cut