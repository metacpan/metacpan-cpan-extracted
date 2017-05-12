package Java::Build::GenericBuild;
use strict; use warnings;

use Java::Build::Tasks qw(read_prop_file update_prop_file);
use Carp;

our $VERSION = "0.02";

=head1 NAME

Java::Build::GenericBuild - a high level driver to control Java builds

=head1 SYNOPSIS

There are two (or more) code files needed to effectively use this module.
First, create a subclass of this class:

    package Java::Build::MyBuild;
    use Carp;

    # Do the following in a BEGIN block before the use base statement:
    BEGIN { $ENV{CLASSPATH} .= ":/path/to/sun's/lib/tools.jar"; }
    use base 'Java::Build::GenericBuild';
    # use any other Java::Build modules you need

    my @args = (
        { BUILD_SUCCESS => sub { croak "You must supply a BUILD_SUCCESS"  } },
        { CONFIG_LOC    => sub { croak "You must supply a CONFIG_LOC"     } },
        { MAIN_DIR      => \&_form_main_dir                                 },
        # ...
    ); # Include all the attributes that matter to your build here, and
       # what to do if the caller omits them.
       # If they are required, die in the subroutine, otherwise provide a
       # subroutine reference which will fill in the default

    sub new {
        my $class = shift;
        my $self  = shift;
        $self->{ATTRIBUTES} = \@attrs;
        process_attrs($self);

        return bless $self, $class;
    }

    # Include common targets callers can share here.  Put unique targets
    # in the calling scripts (see below).
    sub init           { my $self = shift; ... }
    sub cvs_refresh    { my $self = shift; ... }
    sub compile        { ... }
    # ...
    sub _form_main_dir { my $self = shift; $self->{MAIN_DIR} = '/usr/src'; }

In some script:

    #!/usr/bin/perl
    use strict; use warnings;

    use Java::Build::MyBuild;

    my $project = Java::Build::MyBuild->new(
        BUILD_SUCCESS => '/where/this/module/can/store/build/state.info',
        CONFIG_LOC    => '/some/path/to/my.conf',
        NAME          => 'MyApplication',
        SRC_DIR       => '/where/my/java/files/live',
        SUBPROJECTS   => [
            { NAME => "util"                        },
            { NAME => "app", USING => \&compile_app },
        ],
    );
    $project->targets(qw( init cvs_refresh unique compile ));
    $project->GO(@ARGV);

    package Java::Build::MyBuild; # re-enter the build package to add targets
    sub unique {...} # a routine that MyBuild doesn't provide

=head1 DESCRIPTION

This module is designed to be the top level controller of a build.  You
do not need to use this to enjoy most of the benefits of Java::Build.  Yet,
we have found this scheme very useful.  Here's how we do it.

First, we make a hash which has all the data about our project.  In that
we describe the paths, files, names, and subprojects in our project.

Second, we pass that hash to the constructor of a subclass of this class
which calls this module's process_attrs routine to fill in missing
default values according to the rules in @args.  See below for details.

Third, we call targets to set the order of the build.  We could put these
directly into the hash passed to the constructor, but we actually separate
the constructor call from the other steps in two files.  This allows us
to describe the project in one place, then perform a variety of builds
in another place.

Finally, we call GO which begins running the targets in order.  The
user can request which targets they want to run, see GO below for
details of how dependencies are enforced.

=cut

=head1 targets

This is get/set accessor for the TARGETS field.  It is often convenient
to call this after construction, especially when construction and use
are in different files for the purpose of separting the build description
from the target list.

=cut

sub targets {
    my $self        = shift;
    my $new_targets = shift;

    if (defined $new_targets) {
        $self->{TARGETS} = $new_targets;
    }

    return $self->{TARGETS};
}

=head1 GO

This is the operative method of this module.  It uses the TARGETS attribute
to run the build.  To use this approach, you list the subroutines to call
in order, by name, under the TARGETS key of your build hash (you can put
them there in your constructor call, or call targets to do it later).  Then,
pass a list of user requested targets to this routine.  The rest happens
automagically.

If you don't pass any parameters, GO will perform a complete build from
scratch, calling each TARGETS member in order from first to last.

If you pass one parameter, the build will run from the last successful
task up to and including the requested task.

If you pass in more than one parameter, GO will order these, compare them
to the last successful build step, and produce a final list of required
targets which must be executed in order to satisfy the user request.

This assumes that the TARGETS must be done in order in a successful build.
Each TARGETS member requires all previous TARGETS to be successfully
accomplished, before it will run.  That can happen during this build, or
in a previous build.  The success of previous builds is recorded in
BUILD_SUCCESS, which must be in your project hash.  You can even lie by
manually editing the BUILD_SUCCESS file (if that makes your build explode
in flames, don't come running to me).  That file must have one line of the
form:

    last_successful_target=name

In all cases, the first item in TARGETS runs.  This is usually an init step.
You might use it to obtains a build lock, open a log, etc.  If it should
always be done at the outset, put it in your first target.  This include
setting up signal handlers to clean-up if the program dies.

=cut

sub GO {
    my $self             = shift;
    my $last_success;
    my $first;
    my $last_req;

    unless ($self->{BUILD_SUCCESS}) {
        croak "You must supply a BUILD_SUCCESS filename.";
    }

    my %target_hash;
    my $i    = 0;
    foreach my $target (@{$self->{TARGETS}}) {
        $target_hash{$target} = $i++;
    }
    $target_hash{"NONE"} = -1;
    my %targets_by_number= reverse %target_hash;

    if    (@_ == 0) {  # caller supplied no args, do a full build
        update_prop_file(
            NAME      => $self->{BUILD_SUCCESS},
            NEW_PROPS => { last_successful_target => "NONE" }
        );
        $last_success    = "NONE";
        $first           = $self->{TARGETS}[0];  # from the top...
        $last_req        = $self->{TARGETS}[-1]; # ...to the end
    }
    else {  # caller requested targets, try to accomdate
        $self->_validate_targets(\%target_hash, @_);
        my $success_hash;
        eval {
            $success_hash = read_prop_file($self->{BUILD_SUCCESS});
        };  # We don't care if the file exists.  If it's missing just assume
            # no prior successes.
        $last_success    = $success_hash->{last_successful_target}
                        || "NONE";

        # $earliest is the name of the first step we could safely start on.
        my $earliest;
        # if the last successful step is the last step, earliest is last
        if ($target_hash{$last_success} + 1 == @{$self->{TARGETS}}) {
            $earliest = $targets_by_number{$target_hash{$last_success}};
        }
        # otherwise, earliest is one later than last success
        else {
            $earliest = $targets_by_number{$target_hash{$last_success} + 1};
        }
        if (@_ == 1) {  # caller requested one target
            $last_req    = shift;
            $first       = $earliest;
            # If $earliest is later than the one requested step, start with
            # the requested step.
            if ($target_hash{$first} > $target_hash{$last_req}) {
                $first   = $last_req;
            }
        }
        else {  # caller requested multiple targets
                # Sort the user requests with $earliest.
            my $reqs     = $self->_sort_requests(\%target_hash, @_, $earliest);
            $first       = $reqs->[0];
            # If $earliest continuing starting point is last in the list
            # and the caller did not request it, don't do it.
            if ($reqs->[-1] eq $earliest and $reqs->[-1] ne $reqs->[-2]) {
                $last_req = $reqs->[-2];
            }
            else { # $earliest was either requested, or it is not last,
                   # so use whatever is last
                $last_req    = $reqs->[-1];
            }
        }
    }

    # Step zero always runs, but it can't run twice in a row, so bump
    # along if the above code says we need to start on step zero.
    if ($target_hash{$first} == 0) { $target_hash{$first} =  1; }

    my $first_step = $targets_by_number{0}; # Get the name of step zero.
    $self->$first_step();
    # Don't update the success property file now, everyone can init.

    foreach my $step_number ($target_hash{$first} .. $target_hash{$last_req}) {
        my $this_step = $targets_by_number{$step_number};
        $self->$this_step();
        update_prop_file(
            NAME      => $self->{BUILD_SUCCESS},
            NEW_PROPS => { last_successful_target => $this_step }
        );
    }
}

sub _sort_requests {
    my $self        = shift;
    my $target_hash = shift;

    my @sorted = sort { $target_hash->{$a} <=> $target_hash->{$b} } @_;
    return \@sorted;
}

sub _validate_targets {
    my $self       = shift;
    my $valid_hash = shift;
    my @bad_targets;

    foreach my $requested (@_) {
        if (not defined $valid_hash->{$requested}
            or
            $valid_hash->{$requested} < 0)
        {
            push @bad_targets, $requested;
        }
    }
    local $" = "',\n'";
    die "Bad target(s):\n'@bad_targets'\n"
      . "'Please choose from\n'@{$self->{TARGETS}}'\n"
        if (@bad_targets);
}

=head1 process_attrs

For each element in its ATTRIBUTES array reference, process_attrs looks in
the caller's hash.  If the element is already there, nothing happens.
If the element is missing, it calls the corresponding code reference
with the caller's hash.  The elements are processed in order, so later
routines can rely on the earlier ones to fill in values they need.
Any required attributes should be first in the ATTRIBUTES list and have
an appropriate fatal subroutine.

=cut

sub process_attrs {
    my $self = shift;

    foreach my $attr (@{$self->{ATTRIBUTES}}) {
        my ($key) = keys %$attr;
        my $sub   = $attr->{$key};

        # If the item is missing, call the method.
        unless (defined $self->{$key}) {
            $sub->($self);
        }
    }
}

1;
