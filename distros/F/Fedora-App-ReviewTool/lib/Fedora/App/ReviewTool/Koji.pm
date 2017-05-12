package Fedora::App::ReviewTool::Koji;

=begin

This is kinda wimpy right now -- we just call the external koji "binary" 
rather than do the actual xmlrpc calls.

=cut

use Moose::Role;

use MooseX::Types::Path::Class qw{ File };
use MooseX::Types::URI qw{ Uri };

use English qw{ -no_match_vars };  # Avoids regex performance penalty
use List::Util qw{ first };

use namespace::clean -except => 'meta';

# debugging
#use Smart::Comments;

our $VERSION = '0.10';

has koji => (
    is            => 'rw',
    isa           => File,
    coerce        => 1,
    lazy_build    => 1,
    documentation => 'Full path to the koji script',
);
sub _build_koji { '/usr/bin/koji' }

has koji_target => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Str',
    lazy_build    => 1,
    cmd_flag      => 'koji-target',
    documentation => 'Target for scratch build (default: dist-f12)',
);
sub _build_koji_target { 'dist-f12' }

has no_koji => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_flag      => 'no-koji',
    documentation => q{Don't run a scratch build},
);

has _koji_success => (
    is  => 'rw',
    isa => 'Bool',

    clearer   => '_clear_koji_success',
    predicate => '_has_koji_success',
);

# e.g. http://koji.fedoraproject.org/koji/taskinfo?taskID=914599
has _koji_uri => (is => 'rw', isa => Uri, coerce => 1);

has _koji_output => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    auto_deref => 1,
    predicate => '_has_koji_output',
);

sub koji_run_scratch {
    my ($self, $srpm) = @_;

    # first, make sure things work...
    die "Cannot read $srpm!\n"
        unless -r $srpm && -f _;

    my $cmd = $self->koji . ' build --scratch ' . $self->koji_target
        . q{ } . "$srpm";

    print "Running koji build -- this may take some time\n";
    
    my @output = `$cmd`;

    # $CHILD_ERROR aka $?, which I can never remember...
    #die "koji failed with: $CHILD_ERROR\n" if $CHILD_ERROR;

    $self->_koji_output(\@output);

    # find our task uri; e.g.
    # Task info: http://koji.fedoraproject.org/koji/taskinfo?taskID=914599
    my $uri = first { /^Task info/ } @output;
    $uri = (split / /, $uri)[2];
    $self->_koji_uri($uri);

    $self->_koji_success($output[-1] =~ /success/); 
    if ($output[-1] =~ /success/) {

        # victory is mine!
        $self->_koji_success(1);
        return 1;
    }

    # if we're here, the build failed
    $self->_koji_success(0);
    $self->log->warn("Koji failed! ($uri): \n" . join q{}, @output);
}

# this is horribly hackish, and I certainly hope it won't be around any longer
# than it has to (read: until Fedora::Koji is available)

# we don't actually use this yet
with 'MooseX::Role::XMLRPC::Client' => {
    name       => '_kojirpc',
    uri        => 'http://koji.fedoraproject.org/kojihub',
    login_info => 0,
};

sub get_koji_task_children {
    my ($self, $task_id) = @_;
 
    return $self->_kojirpc_rpc->simple_request('getTaskChildren', $task_id);
}

1;

__END__
