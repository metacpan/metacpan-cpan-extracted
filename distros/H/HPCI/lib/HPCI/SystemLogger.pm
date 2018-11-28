package HPCI::SystemLogger;

use namespace::autoclean;

use Moose::Role;
use Moose::Util::TypeConstraints;

use autodie;
use Carp;

use feature qw(say);

use MooseX::Types::Path::Class qw(Dir File);
use Fcntl qw(:flock);
use FindBin;
use DateTime;

=head1 NAME

HPCI::SystemLogger - This role provides an optional system logger

=head1 DESCRIPTION

Defines a systemlogger attribute which logs the return status of
the group exwecution.

Not provided by default, but it can usefully included with a HPCI::LocalConfig
to set a local system logging facility.  The saved logs can be examined for
such purposes as scanning for recurring errors coming from individual hardware
components of the cluster.

=head1 Attributes

=over 4

=item * systemlogger - a code reference

This code reference (if provided) is called at the completion of
group execution.  It is called with two parameters: the group object,
and the return_status hash.

The provider of this attribute (usually the HPCI::LocalConfig module)
is responsible to providing additional code to determine the location
and format of the logged data, although the B<write_system_log> method
provided below can be used to write info in a useable format to a
provided file handle.

=item * write_system_log - method to write a result description to a file handle

Can be used by the systemlogger to do the actual log writing, after systemlogger
has opened a file handle to the proper destination.

=back

=cut

has 'systemlogger' => (
    is       => 'ro',
    isa      => 'CodeRef',
    predicate => '_has_systemlogger'
);

sub write_system_log {
    my $self   = shift;
    my $path   = shift;
    my $fh     = shift;
    my $ret    = shift;
    my $lock   = shift;
    my $unlock = shift;
    _getlock(  $self, $path, $fh ) if $lock;
    _log_ret(  $self, $path, $fh, $ret );
    _freelock( $self, $path, $fh ) if $unlock;
}

sub _getlock {
    my $self     = shift;
    my $path     = shift // 'UNKNOWN PATH';
    my $fh       = shift;
    my $lock_cnt = 0;
    while (1) {
        flock $fh, LOCK_EX and last;
        $self->croak( "$0 [$$]: flock failed on $path: $!" ) if $lock_cnt > 30;
        $self->info( "Waiting for lock on $path" ) unless $lock_cnt++;
        sleep(2);
    }
    $self->info( "Acquired lock on $path" );
    seek $fh, 2, 0; # make sure we're still at the end now that it is locked
}

sub _freelock {
    my $self = shift;
    my $path = shift;
    my $fh   = shift;
    flock $fh, LOCK_UN;
    $self->info( "Released lock on $path" );
}

my $groupcnt = 0;
my $start    = DateTime->from_epoch(epoch => time);

sub _log_ret {
    my $self = shift;
    my $path = shift;
    my $fh   = shift;
    my $ret  = shift;
    say $fh "";
    say $fh "*"x40 for 1..2;
    say $fh "Program\t$FindBin::Bin/$FindBin::Script";
    say $fh "ProcessID\t$$";
    say $fh "StartTime\t", $start;
    say $fh "User\t", scalar(getpwuid $<);
    my $gname = $self->name;
    say $fh "GroupName\t$gname";
    say $fh "GroupCount\t", ++$groupcnt;
    say $fh "GroupEndTime\t", DateTime->from_epoch(epoch => time);
    $self->_log_stages( $fh, $gname, $ret );
}

sub _log_stages {
    my ($self, $fh, $gname, $ret, @parents) = @_;

    my @stages;
    my @subgroups;

    map {
        my $val = $ret->{$_};
        push @{ ref($val) eq 'HASH' ? \@subgroups : \@stages }, [ $_, $val ];
    } sort keys %$ret;

    for my $stage_pair (@stages) {
        my ($stage, $runs) = @$stage_pair;
        $stage = join( '__', @parents, $stage );
        say $fh "StageName\t$gname\t$stage";
        say $fh "StageAttempts\t$gname\t$stage\t", scalar( @$runs );
        for my $i (0..$#$runs) {
            my $pre = "\t$gname\t$stage\tRun$i\t";
            my $run = $runs->[$i];
            for my $k (sort keys %$run) {
                my $v = $run->{$k};
                say $fh "Res$pre$k\t$v";
            }
        }
    }
    for my $subgroup_pair (@subgroups) {
        my ($subgroup, $val) = @$subgroup_pair;
        $self->_log_stages( $fh, $gname, $val, @parents, $self->_subgroups->{$subgroup}->name );
    }
}

1;
