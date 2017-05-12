
=head1 NAME

Linux::ProcessInfo::Process - Interface to information about a single process

=head1 SYNOPSIS

    use Linux::ProcessInfo;
    my $process = Linux::ProcessInfo->process($pid);
    print $process->cmdline, "\n";

=head1 DESCRIPTION

This class provides information about a single process. Instances of this class
must be obtained via L<Linux::ProcessInfo>.

=cut

package Linux::ProcessInfo::Process;

use strict;
use warnings;
use Linux::ProcessInfo::Process::Status;

# Internal interface; See Linux::ProcessInfo for the public interface
sub _for_dir {
    my ($class, $pid, $dir) = @_;

    return bless {
        pid => $pid,
        dir => $dir,
    };
}

sub pid {
    return $_[0]->{pid};
}

sub status {
    my ($self) = @_;

    my %status = ();
    open(F, "<", $self->{dir} . "/status") or return undef;
    while (my $l = <F>) {
        chomp $l;
        if ($l =~ m!^\s*(\w+)\s*:\s*(.*?)$!) {
            $status{$1} = $2;
        }
    }
    close(F);

    return Linux::ProcessInfo::Process::Status->_new(\%status);
}

sub _readfile {
    my ($self, $fn) = @_;

    my $full_fn = $self->{dir} . "/" . $fn;
    open(F, "<", $full_fn) or return undef;
    my $ret = join('', <F>);
    chomp $ret;
    close(F);
    return $ret;
}

sub _readlink {
    my ($self, $fn) = @_;

    my $full_fn = $self->{dir} . "/" . $fn;

    return readlink($full_fn);
}

sub cmdline {
    return $_[0]->_readfile("cmdline");
}

sub cwd {
    return $_[0]->_readlink("cwd");
}

sub exe {
    return $_[0]->_readlink("exe");
}

sub root {
    return $_[0]->_readlink("root");
}

sub visit_environ {
    my ($self, $cb) = @_;

    local $/ = "\0"; # environ variables are separated by nuls
    open(ENV, "<", $self->{dir} . "/environ") or return undef;
    while (my $var = <ENV>) {
        my ($k, $v) = split(/=/, $var, 2);
        $cb->($k, $v);
    }
    close(ENV);
    return 1;
}

sub environ {
    my ($self) = @_;

    my %ret = ();
    my $success = $self->visit_environ(sub {
        $ret{$_[0]} = $_[1];
    });

    return $success ? \%ret : undef;
}

sub environ_list {
    my ($self) = @_;

    my @ret = ();
    my $success = $self->visit_environ(sub {
        push @ret, [ $_[0], $_[1] ];
    });

    return $success ? \@ret : undef;
}

1;
