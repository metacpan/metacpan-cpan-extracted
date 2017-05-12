# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::Pipe::Read;
use vars '$VERSION';
$VERSION = '1.00';

use base 'IOMux::Handler::Read';

use Log::Report    'iomux';
use Fcntl;
use POSIX          qw/:errno_h :sys_wait_h/;
use File::Basename 'basename';


sub init($)
{   my ($self, $args) = @_;
    my $command = $args->{command}
        or error __x"no command to run specified in {pkg}", pkg => __PACKAGE__;

    my ($cmd, @cmdopts) = ref $command eq 'ARRAY' ? @$command : $command;
    my $name = $args->{name} = (basename $cmd)."|";

    my ($rh, $wh);
    pipe $rh, $wh
        or fault __x"cannot create pipe for {cmd}", cmd => $name;

    my $pid = fork;
    defined $pid
        or fault __x"failed to fork for pipe {cmd}", cmd => $name;

    if($pid==0)
    {   # client
        close $rh;
        open STDIN,  '<', File::Spec->devnull;
        open STDOUT, '>&', $wh
            or fault __x"failed to redirect STDOUT for pipe {cmd}", cmd=>$name;
        open STDERR, '>', File::Spec->devnull;

        exec $cmd, @cmdopts
            or fault __x"failed to exec for pipe {cmd}", cmd => $name;
    }

    # parent

    $self->{IMPR_pid}    = $pid;
    $args->{read_size} ||= 4096;  # Unix typical BUFSIZ

    close $wh;
    fcntl $rh, F_SETFL, O_NONBLOCK;
    $args->{fh} = $rh;

    $self->SUPER::init($args);
    $self;
}


sub bare($%)
{   my ($class, %args) = @_;
    my $self = bless {}, $class;

    my ($rh, $wh);
    pipe $rh, $wh
        or fault __x"cannot create bare pipe reader";

    $args{read_size} ||= 4096;  # Unix typical BUFSIZ

    fcntl $rh, F_SETFL, O_NONBLOCK;
    $args{fh} = $rh;

    $self->SUPER::init(\%args);
    ($self, $wh);
}


sub open($$@)
{   my ($class, $mode, $cmd) = (shift, shift, shift);
      ref $cmd eq 'ARRAY'
    ? $class->new(command => $cmd, mode => $mode, @_)
    : $class->new(command => [$cmd, @_] , mode => $mode);
}

#-------------------

sub mode()     {shift->{IMPR_mode}}
sub childPid() {shift->{IMPR_pid}}

#-------------------

sub close($)
{   my ($self, $cb) = @_;
    my $pid = $self->{IMPR_pid}
        or return $self->SUPER::close($cb);

    waitpid $pid, WNOHANG;
    local $?;
    $self->SUPER::close($cb);
}

1;
