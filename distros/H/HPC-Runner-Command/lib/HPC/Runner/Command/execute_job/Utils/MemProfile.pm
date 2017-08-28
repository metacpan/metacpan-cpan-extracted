package HPC::Runner::Command::execute_job::Utils::MemProfile;

use Moose::Role;
use IPC::Cmd qw[can_run];
use Number::Bytes::Human qw(format_bytes parse_bytes);
use Memoize;
use Path::Tiny;
use DateTime;
use Try::Tiny;
use Capture::Tiny ':all';

has 'task_start_time' => (
    is       => 'rw',
    required => 0,
);

has 'task_mem_data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { return {} },
);

has 'can_pstree' => (
    is      => 'rw',
    isa     => 'Num',
    default => sub {
        return 1 if can_run('pstree');
        return 0;
    }
);

sub get_cmd_stats {
    my $self   = shift;
    my $cmdpid = shift;

    return unless $self->can_pstree;
    my $cmd = "pstree -p $cmdpid";

    my $child_pids = `$cmd`;

    my (@cmdpids) = $child_pids =~ m/\((\d+)\)/g;
    push( @cmdpids, $cmdpid );

    my $found_stats      = 0;
    my $total_stats_data = {
        vmpeak => 0,
        vmsize => 0,
        vmhwm  => 0,
        vmrss  => 0,
    };

    foreach my $cmdpid (@cmdpids) {
        my $stats_file = path("/proc/$cmdpid/status");

        next unless $stats_file->exists;

        my $data;
        try {
            $data = $stats_file->slurp_utf8;
        };

        next unless $data;
        if ( $data =~ m/State:  R/ || $data =~ m/State.*run/ ) {

            my $stats = parse_proc_file_data($data);
            ##Add up the procs of all the children
            $total_stats_data = add_proc_stats( $total_stats_data, $stats );
            $found_stats = 1;
        }
    }

    $self->compare_proc_stats($total_stats_data) if $found_stats;
}

=head3 compare_proc_stats

Compare the proc stats to the most recent
Only record those that are self->memory_diff different

=cut

sub compare_proc_stats {
    my $self       = shift;
    my $stats_data = shift;
    my @stats      = ( 'vmpeak', 'vmrss', 'vmsize', 'vmhwm' );

    foreach my $stat (@stats) {
        if ( !exists $self->task_mem_data->{recent}->{$stat} ) {
            $self->task_mem_data->{recent}->{$stat} = $stats_data->{$stat};
            $self->task_mem_data->{count}->{$stat}  = 1;
            $self->task_mem_data->{high}->{$stat}   = $stats_data->{$stat};
            $self->task_mem_data->{low}->{$stat}    = $stats_data->{$stat};
            $self->task_mem_data->{mean}->{$stat}   = $stats_data->{$stat};

            $self->add_stats_to_archive( $stat, $stats_data->{$stat} );
        }
        elsif (
            $self->task_mem_data->{recent}->{$stat} == $stats_data->{$stat} )
        {
            next;
        }
        else {
            my $old       = $self->task_mem_data->{recent}->{$stat};
            my $new       = $stats_data->{$stat};
            my $diff      = $new * $self->memory_diff;
            my $perc_diff = ( $old - $new ) / $old;
            $perc_diff = abs($perc_diff);
            if ( $perc_diff > $self->memory_diff ) {
                $self->task_mem_data->{recent}->{$stat} = $new;

                $self->task_mem_data->{count}->{$stat} += 1;
                $self->task_mem_data->{high}->{$stat} = $new

                  if $new > $self->task_mem_data->{high}->{$stat};
                $self->task_mem_data->{low}->{$stat} = $new
                  if $new < $self->task_mem_data->{low}->{$stat};

                my $mean = ( $self->task_mem_data->{mean}->{$stat} + $new ) /
                  $self->task_mem_data->{count}->{$stat};
                $self->task_mem_data->{mean}->{$stat} = $mean;
                $self->add_stats_to_archive( $stat, $stats_data->{$stat} );
            }
        }
    }

}

sub add_stats_to_archive {
    my $self       = shift;
    my $stat_key   = shift;
    my $stat_value = shift;

    my $dt1 = $self->task_start_time;
    my $dt2 = DateTime->now( time_zone => 'local' );
    my $dur = $dt2->subtract_datetime_absolute($dt1);

    my $new_content = $dur->seconds . "\t" . $stat_value . "\n";

    my $basename = $self->data_tar->basename('.tar.gz');
    my $file     = File::Spec->catdir( $basename, $self->task_jobname,
        $self->counter . '.' . $stat_key );

    if ( $self->archive->contains_file($file) ) {
        my $content = $self->archive->get_content($file);
        $content .= $new_content;
        $self->archive->replace_content( $file, $content );
    }
    else {
        $self->archive->add_data( $file, $new_content );
    }

    capture {
        $self->archive->write( $self->data_tar, 1 );
    };
}

=head3 add_proc_stats

Sum up all the pids and child pids from the proc

=cut

memoize('add_proc_stats');

sub add_proc_stats {
    my $total_stats_data = shift;
    my $proc_data        = shift;

    $total_stats_data->{vmpeak} =
      $total_stats_data->{vmpeak} + $proc_data->{vmpeak};
    $total_stats_data->{vmrss} =
      $total_stats_data->{vmrss} + $proc_data->{vmrss};
    $total_stats_data->{vmsize} =
      $total_stats_data->{vmsize} + $proc_data->{vmsize};
    $total_stats_data->{vmhwm} =
      $total_stats_data->{vmhwm} + $proc_data->{vmhwm};

    return $total_stats_data;
}

=head3 parse_proc_file_data
Get the data from the proc file
If it is in a running state it might look like This
# VmPeak:  4491304 kB
# VmSize:  4491304 kB
..
# VmHWM:    919748 kB
# VmRSS:    919748 kB
=cut

sub parse_proc_file_data {
    my $data = shift;

    my $human = Number::Bytes::Human->new(
        bs          => 1000,
        round_style => 'round',
        precision   => 2
    );

    my ( $vmpeak, $vmsize, $vmhwm, $vmrss ) = ( 0,  0,  0,  0 );
    my ( $punit,  $sunit,  $hunit, $runit ) = ( '', '', '', '' );

    ##I think these are always in kb, but I am not sure
    ( $vmpeak, $punit ) = $data =~ m/VmPeak:\s+(\d+)\s+(\w+)/;
    ( $vmsize, $sunit ) = $data =~ m/VmSize:\s+(\d+)\s+(\w+)/;
    ( $vmhwm,  $hunit ) = $data =~ m/VmHWM:\s+(\d+)\s+(\w+)/;
    ( $vmrss,  $runit ) = $data =~ m/VmRSS:\s+(\d+)\s+(\w+)/;

    $vmpeak = parse_bytes( $vmpeak . $punit ) if $vmpeak;
    $vmsize = parse_bytes( $vmsize . $sunit ) if $vmsize;
    $vmhwm  = parse_bytes( $vmhwm . $hunit )  if $vmhwm;
    $vmrss  = parse_bytes( $vmrss . $runit )  if $vmrss;

    return {
        vmpeak => $vmpeak,
        vmsize => $vmsize,
        vmhwm  => $vmhwm,
        vmrss  => $vmrss
    };
}

1;
