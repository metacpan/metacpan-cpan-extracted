package Getopt::Chain::Declare;

use strict;
use warnings;

=head1 NAME

Getopt::Chain::Declare - Syntactic sugar for command-line processing like svn and git

=head1 SYNPOSIS 

    package My::Command;

    use Getopt::Chain::Declare;

    start [qw/ verbose|v /]; # These are "global"
                             # my-command --verbose ...

    # my-command ? initialize ... --> my-command help initialize ...
    rewrite qr/^\?(.*)/ => sub { "help ".($1||'') };

    # NOTE: Rewriting applies to the command sequence, NOT options

    # my-command about ... --> my-command help about
    rewrite [ ['about', 'copying'] ] => sub { "help $1" };

    # my-command initialize --dir=...
    on initialize => [qw/ dir|d=s /], sub {
        my $context = shift;

        my $dir = $context->option( 'dir' )

        # Do initialize stuff with $dir
    };

    # my-command help
    on help => undef, sub {
        my $context = shift;

        # Do help stuff ...
        # First argument is undef because help
        # doesn't take any options
        
    };

    under help => sub {

        # my-command help create
        # my-command help initialize
        on [ [ qw/create initialize/ ] ] => undef, sub {
            my $context = shift;

            # Do help for create/initialize
            # Both: "help create" and "help initialize" go here
        };

        # my-command help about
        on 'about' => undef, sub {
            my $context = shift;

            # Help for about...
        };

        # my-command help copying
        on 'copying' => undef, sub {
            my $context = shift;

            # Help for copying...
        };

        # my-command help ...
        on qr/^(\S+)$/ => undef, sub {
           my $context = shift;
           my $topic = $1;

            # Catch-all for anything not fitting into the above...
            
            warn "I don't know about \"$topic\"\n"
        };
    };

    # ... elsewhere ...

    My::Command->new->run( [ @arguments ] )
    My::Command->new->run # Just run with @ARGV

=head1 DESCRIPTION

For more information, see L<Getopt::Chain>

=cut

use Moose();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_caller => [qw/ context start on rewrite under /],
    also => [qw/ Moose /],
);

sub init_meta {
    shift;
    return Moose->init_meta( @_, base_class => 'Getopt::Chain', metaclass => 'Getopt::Chain::Declare::Meta::Class' );
}

sub context {
    my $caller = shift;
    $caller->meta->context_from( @_ );
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

package Getopt::Chain::Declare::Recorder;

use Moose;
use MooseX::AttributeHelpers;

has _replay_list => qw/metaclass Collection::Array is ro isa ArrayRef/, default => sub { [] }, provides => {qw/
    push        record
    elements    replay_list
/};

our $BUILDER;

sub replay {
    my $self = shift;
    my $builder = shift;

    {
        local $BUILDER = $builder;

        for my $replay ($self->replay_list) {
            if ( ref $replay eq 'ARRAY' ) {
                my @replay = @$replay;
                my $method = shift @replay;
                $builder->$method( @replay );
            }
            else {
                # It's a "child" package
                $replay->replay( $builder );
            }
        }
    }
}

sub do_or_record {
    my $self = shift;
    my $method = shift;

    if ($BUILDER) {
        $BUILDER->$method( @_ );
    }
    else {
        $self->record( [ $method => @_ ] );
    }
}

package Getopt::Chain::Declare::Meta::Class;

use Moose;
use MooseX::AttributeHelpers;

extends qw/Moose::Meta::Class/;

has recorder => qw/is ro lazy_build 1/, handles => [qw/ replay do_or_record /];
sub _build_recorder {
    return Getopt::Chain::Declare::Recorder->new;
}

around new_object => sub {
    my $around = shift;
    my $meta = shift;

    my @arguments = map { $_ => $meta->$_ } grep { defined $meta->$_ } qw/ context_from /;

    my $self = $around->( $meta, @arguments, 1 == @_ && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_ );
    my $builder = $self->builder;

    $meta->recorder->replay( $builder );

    return $self;
};

has context_from => qw/is rw/;
sub start { shift->do_or_record( start => @_ ) }
sub on { shift->do_or_record( on => @_ ) }
sub under { shift->do_or_record( under => @_ ) }
sub rewrite { shift->do_or_record( rewrite => @_ ) }

package Getopt::Chain::Declare::Branch;

use Moose();
use Moose::Exporter;

my %IMPORT_ARGUMENTS; # Yes, an ugly hack

{
    my ($import, $unimport) = Moose::Exporter->build_import_methods(
        with_caller => [qw/ start on rewrite under /],
        also => [qw/ Moose /],
    );

    sub import {
        my $class = shift; # 'under' or 'redispatch' or ...
        my $caller = caller();

        $IMPORT_ARGUMENTS{$caller} = [ @_ ];

        goto &$import;
    }

    no warnings 'once';
    *unimport = $unimport;
}

sub init_meta {
    shift;
    return Moose->init_meta( @_, base_class => 'Getopt::Chain', metaclass => 'Getopt::Chain::Declare::Branch::Meta::Class' );
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

package Getopt::Chain::Declare::Branch::Meta::Class;

use Moose;
use Getopt::Chain::Carp;

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

sub import_arguments {
    my $self = shift;

    my ($class) = $self->linearized_isa;
    
    croak "No import arguments for \"$class\"" unless my $arguments = $IMPORT_ARGUMENTS{$class};

    return @$arguments;
}

has recorder => qw/is ro lazy_build 1/, handles => [qw/ do_or_record /];
sub _build_recorder {
    require Getopt::Chain::Declare;
    return Getopt::Chain::Declare::Recorder->new;
}

sub replay {
    my $self = shift;
    my $parent_builder = shift;

    my @arguments = $self->import_arguments;
    my $match = $arguments[0];

    # We *could* redispatch here, but ...
    $parent_builder->under( $match => sub {
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
