# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::IPC;
use vars '$VERSION';
$VERSION = '1.01';

use base 'IOMux::Bundle';

use warnings;
use strict;

use Log::Report    'iomux';

use IOMux::Pipe::Read  ();
use IOMux::Pipe::Write ();

use POSIX              qw/:errno_h :sys_wait_h/;
use File::Basename     'basename';


sub init($)
{   my ($self, $args) = @_;
    my $command = $args->{command}
        or error __x"no command to run specified in {pkg}", pkg => __PACKAGE__;

    my ($cmd, @cmdopts) = ref $command eq 'ARRAY' ? @$command : $command;
    my $name   = $args->{name} = '|'.(basename $cmd).'|';

    my $mode   = $args->{mode} || '|-|';
    my $errors = $args->{errors};
       if($mode eq '|=|') { $errors //= 1 }
    elsif($mode eq '|-|') { $mode = '|=|' if $errors }
    else
    {   error __x"unknown mode {mode} for {pkg}"
          , mode => $mode, pkg => __PACKAGE__;
    }

    ($args->{stdin},  my $in_rh)
       = IOMux::Pipe::Write->bare(name => 'stdin');
    ($args->{stdout}, my $out_wh)
       = IOMux::Pipe::Read->bare(name => 'stdout');
    ($args->{stderr}, my $err_wh)
      = $errors ? IOMux::Pipe::Read->bare(name => 'stderr') : ();

    my $pid = fork;
    defined $pid
        or fault __x"failed to fork for ipc {cmd}", cmd => $name;

    if($pid==0)
    {   # client
        open STDIN,  '<&', $in_rh
            or fault __x"failed to redirect STDIN for ipc {cmd}", cmd=>$name;
        open STDOUT, '>&', $out_wh
            or fault __x"failed to redirect STDOUT for ipc {cmd}", cmd=>$name;
        if($err_wh)
        {   open STDERR, '>&', $err_wh
                or fault __x"failed to redirect STDERR for ipc {cmd}"
                   , cmd => $name;
        }
        else
        {   open STDERR, '>', File::Spec->devnull;
        }

        exec $cmd, @cmdopts
            or fault __x"failed to exec for pipe {cmd}", cmd => $name;
    }

    # parent

    close $in_rh;
    close $out_wh;
    close $err_wh if $err_wh;

    $self->{IMI_pid} = $pid;
    $self->SUPER::init($args);
    $self;
}


sub open($$@)
{   my ($class, $mode, $cmd) = (shift, shift, shift);
      ref $cmd eq 'ARRAY'
    ? $class->new(command => $cmd, mode => $mode, @_)
    : $class->new(command => [$cmd, @_] , mode => $mode);
}

#-------------------

sub mode()     {shift->{IMI_mode}}
sub childPid() {shift->{IMI_pid}}

#-------------------

sub close($)
{   my ($self, $cb) = @_;
    waitpid $self->{IMI_pid}, WNOHANG;
    local $?;
    $self->SUPER::close($cb);
}

1;
