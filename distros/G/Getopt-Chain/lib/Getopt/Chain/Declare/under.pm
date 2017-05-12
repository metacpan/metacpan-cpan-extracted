package Getopt::Chain::Declare::under;

use strict;
use warnings;

use base qw/Getopt::Chain::Declare::Branch/;

1;

__END__

use Moose();
use Moose::Exporter;

our @IMPORT;

{
    my ($import, $unimport) = Moose::Exporter->build_import_methods(
        with_caller => [qw/ start on rewrite under /],
        also => [qw/ Moose /],
    );

    sub import {
        warn "@_";
        shift;

        local @IMPORT = @_; # Urgh

        goto &$import;
    }

    no warnings 'once';
    *unimport = $unimport;
}

sub init_meta {
    shift;
    warn @IMPORT;
    return Moose->init_meta( @_, base_class => 'Getopt::Chain', metaclass => 'Getopt::Chain::Meta::Class::Branch' );
}

sub start {
    my $caller = shift;
    $caller->meta->start( @_ );
}

sub on {
    my $caller = shift;
    $caller->meta->on( @_ );
}

sub under {
    my $caller = shift;
    $caller->meta->under( @_ );
}

sub rewrite {
    my $caller = shift;
    $caller->meta->rewrite( @_ );
}

1;

package Getopt::Chain::Meta::Class::Branch;

use Moose;
use MooseX::AttributeHelpers;

extends qw/Moose::Meta::Class/;

has getopt_chain_parent_class => qw/is ro lazy_build 1/;
sub _build_getopt_chain_parent_class {
    my $self = shift;
    my ($class) = $self->linearized_isa;
    my @class = split m/::/, $class;
    pop @class;
    join '::', @class;
}

sub getopt_chain_parent_meta {
    return shift->getopt_chain_parent_class->meta;
}

has recorder => qw/is ro lazy_build 1/, handles => [qw/ do_or_record /];
sub _build_recorder {
    require Getopt::Chain::Declare;
    return Getopt::Chain::Declare::Recorder->new;
}

sub replay {
    my $self = shift;
    my $parent_builder = shift;

    # We *could* redispatch here, but ...
    $parent_builder->under( 'help' => sub {
        $self->recorder->replay( $parent_builder );
    } );
}

has registered => qw/is rw default 0/;
before do_or_record => sub {
    my $self = shift;
    return if $self->registered;
    $self->getopt_chain_parent_meta->recorder->record( $self ); # "Register" ourself
    $self->registered( 1 );
};

sub start { shift->do_or_record( start => @_ ) }
sub on { shift->do_or_record( on => @_ ) }
sub under { shift->do_or_record( under => @_ ) }
sub rewrite { shift->do_or_record( rewrite => @_ ) }

1;
