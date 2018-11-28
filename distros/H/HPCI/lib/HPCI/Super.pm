package HPCI::Super;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use File::ShareDir;
use File::Path qw(make_path);
use File::Spec;
use Time::HiRes qw(usleep gettimeofday);
use Try::Tiny;
use DateTime;
use Module::Load;

use Moose::Role;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use HPCI::File;
use HPCI::Subgroup;

## no critic BoutrosLab::HangingComma
## no critic BoutrosLab::IndentationCheck

sub name;         # tell other roles we provide a name attribute

=head1 NAME

    HPCI::Super

=head1 SYNOPSIS

Role for attributes and methods that are common to group and subgroup
classes (i.e. those superior to a stage-like class).

=head1 ATTRIBUTES

=cut

has '_driver'  => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    init_arg => undef,
    default => sub { 'HPCD::'.$_[0]->cluster },
);

has '_stageClass' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    init_arg => undef,
    default => sub { $_[0]->_driver . '::Stage' },
);

has '_namemap' => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    init_arg => undef,
    default => sub { {} },
);

# method _register_descendent => sub {
sub _register_descendent {
    my $self     = shift;
    my $child    = shift;
    my $name     = $child->name;
    my $fullname = $child->_full_name;
    my $namemap  = $self->_namemap;
    $self->_croak("Duplicate subobject (stage or subgroup) name ($fullname)")
        if exists $namemap->{$name};
    $namemap->{$name} = $fullname;
    $child->does('HPCI::Super')
        ? $self->_register_subgroup($child)
        : $self->_register_stage($child);
};

=head2 stage_defaults

This attribute can be given a hash reference containing values that
will be passed to every stage created.  Subgroups that are not
provided with their own specific hash use their parent groups' hash.
The top level group defaults to an empty hash.

=cut

has 'stage_defaults' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->does('HPCI::Sub')
            ? $self->group->stage_defaults
            : {};
    },
);

=head1 METHODS

=head2 $group->stage( name=>'stagename', ... )

Creates a stage and adds it to the group.  See HPCI::Stage
for the generic parameters you may provide for a stage; and see
HPCD::$cluster::Stage for the cluster-specific parameters for the
actual type of cluster you are using.

Note: this is the only way to add a stage object to the group.
In particular, you cannot create a stage object separately and add
it to the group - this is done to ensure that the created stage
object is consistant with the actual group object and that you don't
have to change code in multiple places if you switch to using a
different cluster type for the group.  (If you want to mix stages
for multiple cluster types within your program, you should either
create two groups that execute independently, or else create a
stage that itself creates a group and manages the stages for the second
type of cluster.)

The name parameter is required and must be unique - two stages
within the same group may not have the same name.

The method returns the stage object that was created, although
most code will not need it directly.  (Whenever you need to refer
to a stage to add dependencies, you can use its name instead of a
reference to the object.)

=cut

# method stage => sub {
sub stage {
    my $self = shift;
    my $stage = $self->_stage( @_ );
    if ($self->does('HPCI::Sub')) {
        $self->add_deps( pre_req => '__START__', dep => $stage );
        $self->add_deps( pre_req => $stage, dep => '__END__' );
    }
    return $stage;
};

# method _stage => sub {
sub _stage {
    my $self = shift;
    $self->_croak("Cannot define new stages after execution has started!")
        if $self->_execution_started;
    my $use_args = { };
    # $self->debug( "Creating stage.  Provided args: " . Dumper( \@_ ));
    HPCI::_merge_hash( $use_args, $self->stage_defaults );
    my $args     = { @_ };
    my $cluster  = $self->cluster;
    for my $arg_set ($use_args, $args) {
        if (my $spec_args = delete $arg_set->{cluster_specific}) {
            HPCI::_merge_hash( $use_args, $spec_args->{$cluster} // {} );
        }
    }
    HPCI::_merge_hash( $use_args, $args );

    my $deps = $self->_extract_deps( $use_args );

    $self->debug( "Creating stage.  Composed args: " . Dumper( \@_ ));
    # my $stage = $StageClass->new(
    my $stage = ($self->_stageClass)->new(
        %$use_args,
        cluster => $self->cluster,
        group   => $self,
    );
    $self->_deps_args( $stage, $deps );
    # $self->_namemap->{$stage->name} = $stage;
    return $stage;
};

# method subgroup => sub {
sub subgroup {
    my $self = shift;
    $self->_croak("Cannot define new subgroups after execution has started!")
        if $self->_execution_started;
    my $use_args = { @_ };
    # $self->debug( "Creating stage.  Provided args: " . Dumper( \@_ ));
    my $cluster  = $self->cluster;
    if (my $spec_args = delete $use_args->{cluster_specific}) {
        HPCI::_merge_hash( $use_args, $spec_args->{$cluster} // {} );
    }

    my $deps = $self->_extract_deps( $use_args );

    $self->debug( "Creating subgroup.  Composed args: " . Dumper( \@_ ));
    my $subgroup = HPCI::Subgroup->new(
        %$use_args,
        cluster => $self->cluster,
        group   => $self,
    );
    
    $subgroup->_stage(
        name => '__START__',
        code => sub { return 1 },
    );
    
    $subgroup->_stage(
        name => '__END__',
        code => sub { return 1 },
        pre_req => '__START__',
    );

    $self->_deps_args( $subgroup, $deps );

    return $subgroup;
};

# method _extract_deps => sub {
sub _extract_deps {
    my $self = shift;
    my $args = shift;
    my $reqs = {};
    for my $key (qw(pre_req pre_reqs)) {
        if (my $list = delete $args->{$key}) {
            $reqs->{pre_req}{$key} = $list;
        }
    }
    for my $key (qw(dep deps)) {
        if (my $list = delete $args->{$key}) {
            $reqs->{dep}{$key} = $list;
        }
    }
    return $reqs;
};

# method _deps_args => sub {
sub _deps_args {
    my $self = shift;
    my $child = shift;
    my $deps  = shift;
    return unless %$deps;
    if (my $pre = $deps->{pre_req}) {
        $self->add_deps( %{$pre}, dep => $child );
    }
    if (my $dep = $deps->{dep}) {
        $self->add_deps( %{$dep}, pre_req => $child );
    }
};

# method _add_dep => sub {
sub _add_dep {
    # little cost/no damage if called again with same dep and pre_req
    my ( $self, $pre_req, $dep ) = @_;
    return if $self->_deps->{$pre_req}{$dep};
    $self->_deps->{$pre_req}{$dep}     = 1;
    $self->_pre_reqs->{$dep}{$pre_req} = 1;
    $self->_blocked->{$dep}            = 1;
    delete $self->_ready->{$dep};
};


=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros http://www.omgubuntu.co.uk/2016/03/vineyard-wine-configuration-tool-linuxLab

The Ontario Institute for Cancer Research

=cut

1;

