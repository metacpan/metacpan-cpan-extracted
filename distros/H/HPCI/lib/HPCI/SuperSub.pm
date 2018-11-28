package HPCI::SuperSub;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;

use Moose::Role;

## no critic BoutrosLab::HangingComma
## no critic BoutrosLab::IndentationCheck

=head1 NAME

    HPCI::SuperSub

=head1 SYNOPSIS

A role containing attibutes and methods common to all of group,
subgroup, and stage classes.

=head1 ATTRIBUTES

The attributes for this class are pulled in from HPCI::Super
and HPCI::Sub. Super contains all the characteristics common to
container classes (Group and Subgroup), while Sub contains all
the characteristics common to contained classes (Subgroup and Stage).

=head2 _full_name (composed internally)

The name of a group/subgroup/stage is expanded into a directory-like
name that is composed of the parent subgroups' and the final object's names
all joined together with double underscores.  E.g. 'subgroupA__subgroupB__stage1'

=cut

has '_full_name' => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my $name = $self->name;
        if ($self->does('HPCI::Sub') ) {
            return $self->group->_sub_name( $name );
        }
        return $name;
    },
);

sub _sub_name {
    my $self = shift;
    my $name = shift;
    return join '__', $self->_group_names, $name;
}

sub _group_names {
    my $self = shift;
    if ($self->does('HPCI::Sub')) {
        return ( $self->group->_group_names, $self->name );
    }
    return ();
}

sub _build_stage_list {
    my $self     = shift;
    my $sgtarget = shift;
    my $stages   = $self->_stages;
    my $subgrps  = $self->_subgroups;
    return
        map  { $self->_croak( "Unknown stage name ($_) passed to add_deps" )
                   unless exists $stages->{$_};
               $_
             }
        map  { $subgrps->{$_} ? ($_ . '__' . $sgtarget) : $_ }
        map  { $self->_find_named_stage( $_ ) }
        # grep { defined }
        map  { ref($_) ? $_->_full_name : $_ }
        map  { ref($_) eq 'Regexp' ? ($self->_match_stages( $_ )) : ($_) }
        map  { ref($_) eq 'ARRAY' ? @{$_} : ($_) }
        grep { defined }
        @_
};

sub _find_named_stage {
    my $self = shift;
    my $name = shift;
    return $name if $name =~ m{/};  # return if already a full name
    return $self->_namemap->{$name} # or if short name is in this subgroup
        || ( $self->does('HPCI::Sub')
            ? $self->group->_find_named_stage($name) # search parent group
            : $name );              # at top, return short name for failure message
};

sub _match_stages {
    my $self  = shift;
    my $pat   = shift;
    my @matches = grep { m/$pat/ } keys %{ $self->_namemap };
    return @matches if @matches;
    return $self->does('HPCI::Sub')
            ? $self->group->_match_stages($pat)
            : ()
        ;
};

=head2 $group->add_deps

    $group->add_deps(
        dep      => 'a_dep',                  ## one of these two
        deps     => ['dep1', 'dep2', ...],
        pre_req  => 'a_pre_req',              ## and one of these two
        pre_reqs => ['pre_req1', 'pre_req2', ...],
    );

    # A scalar value, either provided alone or in a list, can be
    # any of:
    #    - an existing stage object
    #    - a string - the exact value of some existing stage's name
    #    - a regexp - all of the stages whose name matches the regexp

The add_deps method marks the pre_req (or all of the pre_reqs)
as being pre-requisites to the dep (or all of the deps).  When the
group is executed, stages may be run in parallel, but a dependent
stage will not be permitted to start executing until all of its
prerequisites stages have completed successfully.

It is permitted to list the same dependency multiple times.  This can
be convenient in that you do not need to be careful about providing
non-overlapping groups when you specify sets of prerequisites.

So, you could write:

    $group->add_deps( pre_req=>'stage1', deps=>[qw(stage2 stage3)] );
    $group->add_deps( pre_reqs=>[qw(stage1 stage2)], dep=>'stage3' );

instead of:

    $group->add_deps( pre_req=>'stage1', deps=>qr(^stage[23]$) );
    $group->add_deps( pre_req=>'stage2', dep=>'stage3' );

or:

    $group->add_deps( pre_req=>'stage1', dep=>'stage2' );
    $group->add_deps( pre_req=>'stage2', dep=>'stage3' );


All three forms will provide the same ordering, the last is
clearer for this simple sequence, but when there are many
stages that have it may be easier to specify collections of
dependencies at once.

However, you B<must> be careful to avoid dependency loops.
That would be a chain of dependencies stages that include the
same stage multiple times (stage1 -> stage2 -> stage1).  Since a
dependency indicates that the prerequisite stage must be finished
executing before the dependent stage can start executing, this loop
would mean that the stage1 cannot start until stage2 has completed,
but also that stage2 cannot start until stage1 has completed.  So,
neither one can ever start and they will both never complete.

Such a loop will eventually be detected, when the group has reached
a point where there are no stages running, and no stages can be
started - but there could have been a lot of time wasted executing
stages that were not part of the loop before this is noticed and
the run aborted.

Each stage argument passed can be either a reference to the stage
object or the name of the stage, or a regexp that select all of the
stages whose name matches the regexp.  (If no stage name matches a
regexp, then no stages are selected.  This allows using a regexp to
match against an optional stage without having to check whether that
optional stage was actually used in this run.  The downside is that
a mistyped regexp will give no complaint when it matches nothing,
but it is certainly not possibly to give a complaint if a mistyped
regexp matches more stages than the user intended so checking the
regexp carefully is necessary in any case.)

=cut

sub add_deps {
    my $self = shift;
    my %defargs = (
        dep => undef,
        deps => [],
        pre_req => undef,
        pre_reqs => [],
    );
    my %args     = ( %defargs, scalar(@_) == 1 ? %{ $_[0] } : @_ );
    my $badargs  = join ' ', grep { ! exists $defargs{$_} } keys %args;
    $self->_croak( "Unknown arg($badargs) provided to add_deps" ) if $badargs;
    my @deps     = $self->_build_stage_list( '__START__', $args{dep}, $args{deps});
    my @pre_reqs = $self->_build_stage_list( '__END__', $args{pre_req}, $args{pre_reqs});
    for my $dep (@deps) {
        for my $pre_req (@pre_reqs) {
            $self->_add_dep( $pre_req, $dep );
        }
    }
};

=head2 group_dir (optional)

The directory which will contain all output pertaining to the entire
group.  By default, this is a new directory under the parent group's
B<group_dir> named for this subgroup, or, for the top level group,
under B<base_dir> a name combining the name of the group and the timestamp
when the group was created (e.g. EXAMPLEGROUP-YYMMDD-HHMMSS).

=cut

    has 'group_dir' => (
        is => 'ro',
        isa     => 'Path::Class::Dir',
        lazy    => 1,
        coerce  => 1,
        default => sub {
            my $self = shift;
            my $target =
                $self->does('HPCI::Sub')
                    ? $self->group->group_dir->subdir($self->name)
                    : $self->base_dir->subdir($self->_unique_name);
            HPCI::_trigger_mkdir( $self, $target );
            return $target;
        },
        trigger => \&HPCI::_trigger_mkdir,
    );

=head2 file_params

A hash containing the param list for files that need params is
kept in the internal attribute C<_file_info>.  That attribute
is initialized to the value of the patent (sub)group (or to
an empty hash for the top level group).

The internal method C<_add_file_params> is used to add any values
passed in this C<file_params> attribute into the C<_file_info>
hash.

Providing file info this way means that it does not have to be written
out in full every time the file is used through the program.

Defaults to an empty hash.

=cut

has 'file_params' => (
    is      => 'bare',
    isa     => 'HashRef',
    trigger => sub {
        my $self = shift;
        $self->add_file_params( @_ );
    },
);

has '_file_info' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_default_file_info',
);

=head2 $group->add_file_params

Augment the file_params list with additioal files.
Provide either a hashref or a list of value pairs,
in either case, the pairs are filename as the key,
and params as the value.

=cut

sub add_file_params {
    my $self = shift;
    my $fi   = $self->_file_info;
    my $args = $_[0];
    $args    = { @_ } unless ref $args eq 'HASH';
    while ( my ($k,$v) = each %$args ) {
        $self->_croak( "file params value for $k must be a hash ref" )
            unless (ref($v) eq 'HASH');
        $k = File::Spec->rel2abs($k);
        $fi->{$k}{params} = $v;
    }
}


=head1 AUTHOR

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros http://www.omgubuntu.co.uk/2016/03/vineyard-wine-configuration-tool-linuxLab

The Ontario Institute for Cancer Research

=cut

1;

