
=head1 NAME

Linux::ProcessInfo::Process::Status - Interface to process status information

=cut

package Linux::ProcessInfo::Process::Status;

use strict;
use warnings;
use Sub::Name ();

# Internal interface; see Linux:ProcessInfo::Process::status
sub _new {
    my ($class, $data) = @_;

    return bless $data, $class;
}

my @simple = qw(
    Name
    Tgid
    Pid
    PPid
    TracerPid
    FDSize
    Threads
    SigPnd
    ShdPnd
    SigBlk
    SigIgn
    SigCgt
    CapInh
    CapPrm
    CapEff
    CapBnd
    Cpus_allowed
    Cpus_allowed_list
    Mems_allowed
    Mems_allowed_list
    voluntary_ctxt_switches
    nonvoluntary_ctxt_switches
);

{
    foreach my $k (@simple) {
        my $meth_name = __PACKAGE__ . "::" . $k;
        my $code = sub {
            return $_[0]->{$k};
        };
        Sub::Name::subname $k => $code;
        no strict 'refs';
        *{$meth_name} = $code;
    }
}

1;
