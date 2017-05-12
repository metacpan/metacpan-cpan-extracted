# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::Pipe::Write;
use vars '$VERSION';
$VERSION = '1.00';

use base 'IOMux::Handler::Write';

use Log::Report    'iomux';
use Fcntl;
use POSIX          qw/:errno_h :sys_wait_h/;
use File::Spec     ();
use File::Basename 'basename';

use constant PIPE_BUF_SIZE => 4096;


sub init($)
{   my ($self, $args) = @_;

    my $command = $args->{command}
        or error __x"no command to run specified in {pkg}", pkg => __PACKAGE__;

    my ($cmd, @cmdopts) = ref $command eq 'ARRAY' ? @$command : $command;
    my $name = $args->{name} = '|'.(basename $cmd);

    my ($rh, $wh);
    pipe $rh, $wh
        or fault __x"cannot create pipe for {cmd}", cmd => $name;

    my $pid = fork;
    defined $pid
        or fault __x"failed to fork for pipe {cmd}", cmd => $name;

    if($pid==0)
    {   # client
        close $wh;
        open STDIN, '<&', $rh
            or fault __x"failed to redirect STDIN for pipe {cmd}", cmd => $name;
        open STDOUT, '>', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;

        exec $cmd, @cmdopts
            or fault __x"failed to exec for pipe {cmd}", cmd => $name;
    }
    $self->{IMPW_pid} = $pid;

    # parent

    close $rh;
    fcntl $wh, F_SETFL, O_NONBLOCK;
    $args->{fh} = $wh;

    $self->SUPER::init($args);
    $self;
}


sub bare($%)
{   my ($class, %args) = @_;
    my $self = bless {}, $class;

    my ($rh, $wh);
    pipe $rh, $wh
        or fault __x"cannot create bare pipe writer";

    $args{read_size} ||= 4096;

    fcntl $wh, F_SETFL, O_NONBLOCK;
    $args{fh} = $wh;

    $self->SUPER::init(\%args);
    ($self, $rh);
}


sub open($$@)
{   my ($class, $mode, $cmd) = (shift, shift, shift);
      ref $cmd eq 'ARRAY'
    ? $class->new(command => $cmd, mode => $mode, @_)
    : $class->new(command => [$cmd, @_] , mode => $mode);
}

#-------------------

sub mode()     {shift->{IMPW_mode}}
sub childPid() {shift->{IMPW_pid}}

#-------------------

sub close($)
{   my ($self, $cb) = @_;
    my $pid = $self->{IMPW_pid}
        or return $self->SUPER::close($cb);

    waitpid $pid, WNOHANG;
    local $?;
    $self->SUPER::close($cb);
}



1;
