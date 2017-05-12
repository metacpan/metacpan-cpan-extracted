
=head1 NAME

Linux::ProcessInfo - Interface to process information in Linux

=head1 SYNOPSIS

    my $proc = Linux::ProcessInfo->new();
    
    my $processes = $proc->all_processes();
    foreach my $process (@$processes) {
        print $process->cmdline, "\n";
    }

=head1 TODO

Need to support more things exposed in /proc .

Need to write some tests.

Need to write better documentation.

=head1 AUTHOR

Martin Atkins <mart@degeneration.co.uk>

Copyright 2011 SAY Media Ltd. This library may be redistributed under the same terms as Perl itself.

=cut

package Linux::ProcessInfo;

our $VERSION = 0.01;

use strict;
use warnings;
use Carp qw(croak);

use Linux::ProcessInfo::Process;

sub new {
    my ($class, %opts) = @_;

    my $base_dir = delete $opts{base_dir} || "/proc";
    croak "Unsupported options: ".join(", ", keys %opts) if %opts;

    return bless {
        base_dir => $base_dir,
    }, $class;
}

sub visit_all_processes {
    my ($self, $cb) = @_;

    opendir(PROC, $self->{base_dir}) || croak "Failed to open proc dir: $!";
    while (my $fn = readdir(PROC)) {
        my $process_dir = $self->{base_dir} . "/" . $fn;
        next unless -d $process_dir;
        next unless -e $process_dir . "/environ";
        next unless $fn =~ m!^\d+$!;

        my $process = Linux::ProcessInfo::Process->_for_dir($fn + 0, $process_dir);
        $cb->($process);
    }
}

sub all_processes {
    my ($self) = @_;

    my @ret = ();
    $self->visit_all_processes(sub {
        push @ret, $_[0];
    });
    return \@ret;
}

sub grep_processes {
    my ($self, $cb) = @_;

    my @ret = ();
    $self->visit_all_processes(sub {
        my $process = $_[0];
        push @ret, $process if $cb->($process);
    });
    return \@ret;
}

sub process {
    my ($self, $pid) = @_;

    $pid = $pid + 0;
    my $process_dir = $self->{base_dir} . "/" . $pid;
    return undef unless -d $process_dir;
    my $process = Linux::ProcessInfo::Process->_for_dir($pid, $process_dir);
}

1;
