package Forks::Super::Tie::IPCDupSTDIN;
use strict;
use warnings;
use Carp;

# tied class for *STDIN so that operations on STDIN are forwarded
# to another filehandle, Like dup'ing STDIN but operations also
# get the tied behavior of the underlying FS::Tie::IPCFileHandle .

# assumes that this tied handle class will only be used for *STDIN.
# open and close operations have the effect of untying STDIN

sub TIEHANDLE {
    my ($pkg, %list) = @_;
    return bless { %list }, $pkg;
}

sub READLINE {
    return Forks::Super::Job::Ipc::_readline(
	$_[0]->{GLOB}, $_[0]->{JOB}, wantarray);
}

sub SEEK {
    my $tied = $_[0]->{TIED};
    return $tied && $tied->SEEK($_[1], $_[2]);
}

#############################################################################

sub GETC {
    return getc($_[0]->{GLOB});
}

sub READ {
    my $bufref = \$_[1];
    return sysread $_[0]->{GLOB}, $$bufref, $_->[2], $_->[3];
}

sub EOF {
    return eof($_[0]->{GLOB});
}

sub CLOSE {
    # close breaks tie to STDIN
    my $glob = $_[0]->{GLOB};
    untie *STDIN;
    return close $glob;
}

sub BINMODE {
    my $self = shift;
    return binmode $self->{GLOB}, @_;
}

sub OPEN {
    # open breaks tie to STDIN
    my ($self, $mode, $expr, @list) = @_;
    carp "open on tie'd STDIN breaks tie";
    untie *STDIN;
    close *STDIN;
    if (@list==1 && ref($list[0])) {
	return open *STDIN, $mode, $expr, $list[0];
    } elsif (@list > 0) {
	return open *STDIN, $mode, $expr, @list;
    } elsif (defined $expr) {
	return open *STDIN, $mode, $expr;
    } elsif (defined $mode) {
	return open *STDIN, $mode;
    } else {
	return open *STDIN;
    }
}

sub FILENO {
    return fileno($_[0]->{GLOB});
}

sub TELL {
    return tell($_[0]->{GLOB});
}

sub WRITE {
    carp "bad WRITE call on tied STDIN";
    return;
}

sub PRINT {
    carp "bad PRINT call on tied STDIN";
    return;
}

sub PRINTF {
    carp "bad PRINTF call on tied STDIN";
    return;
}

1;
