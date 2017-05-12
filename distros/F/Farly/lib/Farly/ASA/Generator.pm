package Farly::ASA::Generator;

use 5.008008;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Log::Any qw($log);

our $VERSION = '0.26';

sub new {
    my ($class) = @_;

    my $self = {
        CONTAINER => Farly::Object::List->new(), # result
    };
    bless $self, $class;
    
    $log->info("$self new");
    $log->info( "$self CONTAINER is " . $self->container() );

    return $self;
}

sub container {
    return $_[0]->{CONTAINER};
}

sub visit {
    my ( $self, $node ) = @_;
    # $node isa reference to the root of the AST

    # the Farly translator parses one firewall object at a time
    my $object = Farly::Object->new();

    # the AST root node is the 'ENTRY'
    $object->set( 'ENTRY', Farly::Value::String->new( ref($node) ) );

    $log->debug( "ENTRY = " . ref($node) );

    # set s of explored vertices
    my %seen;

    #stack is all neighbors of s
    my @stack;
    push @stack, $node;

    my $key;

    while (@stack) {

        my $node = pop @stack;

        next if ( $seen{$node}++ );

        $log->debug( "ast node class = " . ref($node) );

        # continue exploring the AST
        foreach my $key ( keys %$node ) {

            my $next = $node->{$key};

            if ( $key eq '__VALUE__' ) {

                #then $next isa token
                $object->set( ref($node), $next );
                $log->debug( "set " . ref($node) . " = " . ref($next). " " . $next->as_string );
            }
            else {
                push @stack, $next;
            }
        }
    }

    $self->container->add($object);
}

1;
__END__

=head1 NAME

Farly::ASA::Generator - Create Farly::Objects from the AST

=head1 DESCRIPTION

Farly::ASA::Generator walks a Farly abstract syntax tree searching for Token
value objects. Token objects are recognized by the presence
of the '__VALUE__' key.

When a Token value object is found the AST node class is used as the 
Farly::Object key. The key and value object, from $node->{__VALUE__},
are then set in the new Farly::Object.

The new Farly::Object is stored in the container after the AST
has been explored.

Farly::ASA::Generator dies on error.

Farly::ASA::Generator is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Generator
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
