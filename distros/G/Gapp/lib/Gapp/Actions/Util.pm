package Gapp::Actions::Util;
{
  $Gapp::Actions::Util::VERSION = '0.60';
}

use Carp qw( carp );
use List::MoreUtils qw( all any );
use Scalar::Util qw( blessed reftype );
use Moose::Exporter;
use Scalar::Util 'blessed';

use Gapp::Action;
use Gapp::Action::Registry;

use Gapp::Types qw( GappAction GappCallback );
use MooseX::Types::Moose qw( ArrayRef CodeRef Undef );

Moose::Exporter->setup_import_methods(
    with_caller => [
        qw( action ),
    ],
    as_is => [
        qw( ACTION_REGISTRY perform parse_action actioncb),
    ]
);

{
    my %REGISTRY;

    sub ACTION_REGISTRY {
        my $class = shift;
        return $REGISTRY{$class} ||= Gapp::Action::Registry->new;
    }
}

sub action {
    
    my ( $caller, $name ) = ( shift, shift );
    $name = $name->name if ref $name;
    
    my %p = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    my $action = Gapp::Action->new( name => $name, %p );   
    ACTION_REGISTRY( $caller )->add_action( $action );

    return 1;
}

sub perform {
    my ( $value, @args ) = @_;
    return if ! defined $value;
    
    if ( ! is_GappCallback( $value ) ) {
        carp "cannot do ($value): not a valid callback";
    }
    else {
        my ( $cb, @args ) = is_ArrayRef( $value ) ? (@$value) : ($value);
        return if ! defined $cb;
        
        if ( is_GappAction( $cb ) ) {
            return $cb->perform( @args );
        }
        elsif ( is_CodeRef( $cb ) ) {
            return $cb->( @args );
        }
        else {
            carp "cannot do ($cb): not a valid callback";
        }
        
    }    
}

sub parse_action {
    my ( $value ) = @_;
    
    my ( $action, @args );
    
    if ( is_ArrayRef( $value ) ) {
        ( $action, @args ) = @$value;
    }
    elsif ( is_GappAction( $value ) || is_CodeRef( $value ) ) {
        $action = $value;
    }
    
    return $action, @args;
}


sub actioncb {
    my ( $action, $w, $args ) = @_;
    return sub {
        my ( $gtkw, @gtkargs ) = @_;
        $action->perform( $w, $args, $gtkw, \@gtkargs );
    };
}

1;
