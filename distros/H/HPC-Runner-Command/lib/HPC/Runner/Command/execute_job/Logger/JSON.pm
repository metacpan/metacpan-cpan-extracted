package HPC::Runner::Command::execute_job::Logger::JSON;

use Moose::Role;
use namespace::autoclean;

with 'HPC::Runner::Command::execute_job::Logger::Lock';

use JSON;
use File::Spec;
use DateTime;
use Try::Tiny;
use File::Path qw(make_path remove_tree);
use File::Slurp;
use Cwd;
use Time::HiRes;

has 'task_json' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    required => 0,
);

has 'task_jobname' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

sub parse_meta_str {
    my $self = shift;

    my $job_meta = {};
    if ( $self->metastr ) {
        $job_meta = decode_json( $self->metastr );
    }

    if ( !$job_meta || !exists $job_meta->{jobname} ) {
        ##TO account for single_node mode
        $job_meta->{jobname} = $self->jobname;
    }

    $self->task_jobname( $job_meta->{jobname} );
    return $job_meta;
}

sub create_json_task {
    my $self   = shift;
    my $cmdpid = shift;

    my $job_meta = $self->parse_meta_str;

    my $task_obj = {
        pid        => $cmdpid,
        start_time => $self->table_data->{start_time},
        jobname    => $job_meta->{jobname},
        task_id    => $self->counter,
    };

    $task_obj->{scheduler_id} = $self->job_scheduler_id
      if $self->can('scheduler_id');

    my $data_dir = File::Spec->catdir( $self->data_dir, $self->task_jobname );
    make_path($data_dir);

    if ( !$self->no_log_json ) {
        $self->check_lock;
        $self->write_lock;
        $self->add_to_running( $data_dir, $task_obj );
        try {
          $self->lock_file->remove;
        };
    }

    return $task_obj;
}

##TODO Once we add to the complete
## Get all the for the tasks
## Compute mean, min, max of all tasks
sub update_json_task {
    my $self = shift;

    # my @stats    = ( 'vmpeak', 'vmrss', 'vmsize', 'vmhwm' );
    # my $job_meta = $self->parse_meta_str;
    # my $basename = $self->data_tar->basename('.tar.gz');
    # my $data_dir = File::Spec->catdir( $basename, $job_meta->{jobname} );

    my $data_dir = File::Spec->catdir( $self->data_dir, $self->task_jobname );
    make_path($data_dir);

    my $tags = "";
    if ( exists $self->table_data->{task_tags} ) {
        my $task_tags = $self->table_data->{task_tags};
        if ($task_tags) {
            $tags = $task_tags;
        }
    }

    # my $task_obj = $self->get_from_running($data_dir);
    my $task_obj = {};

    $task_obj->{exit_time}  = $self->table_data->{exit_time};
    $task_obj->{duration}   = $self->table_data->{duration};
    $task_obj->{exit_code}  = $self->table_data->{exitcode};
    $task_obj->{task_tags}  = $tags;
    $task_obj->{cmdpid}     = $self->table_data->{cmdpid};
    $task_obj->{start_time} = $self->table_data->{start_time};
    $task_obj->{task_id}    = $self->table_data->{task_id};

    # $task_obj->{memory_profile} = {};
    #
    # foreach my $stat (@stats) {
    #     $task_obj->{memory_profile}->{$stat}->{low} =
    #       $self->task_mem_data->{low}->{$stat};
    #     $task_obj->{memory_profile}->{$stat}->{high} =
    #       $self->task_mem_data->{high}->{$stat};
    #     $task_obj->{memory_profile}->{$stat}->{mean} =
    #       $self->task_mem_data->{mean}->{$stat};
    #     $task_obj->{memory_profile}->{$stat}->{count} =
    #       $self->task_mem_data->{count}->{$stat};
    # }

    if ( !$self->no_log_json ) {
        $self->check_lock;
        $self->write_lock;

        $self->remove_from_running($data_dir);
        ##TODO Add in mem for job
        $self->add_to_complete( $data_dir, $task_obj );
        try {
          $self->lock_file->remove;
        };
    }

    $task_obj->{pid}           = $self->table_data->{cmdpid};
    $task_obj->{start_time_dt} = $self->table_data->{start_time_dt};
    return $task_obj;
}

sub add_to_complete {
    my $self      = shift;
    my $data_dir  = shift;
    my $task_data = shift;

    my $c_file = File::Spec->catfile( $data_dir, 'complete.json' );

    my $json_obj = $self->read_json($c_file);

    $json_obj->{ $self->counter } = $task_data;
    $self->write_json( $c_file, $json_obj );

    return $json_obj;
}

## keep this or no?
##TODO Create Mem profile file
sub create_task_file {
    my $self     = shift;
    my $data_dir = shift;
    my $json_obj = shift;

    my $t_file = File::Spec->catfile( $data_dir, $self->counter . '.json' );
    $self->write_json( $t_file, $json_obj,  );
}

sub add_to_running {
    my $self      = shift;
    my $data_dir  = shift;
    my $task_data = shift;

    my $r_file = File::Spec->catfile( $data_dir, 'running.json' );

    my $json_obj = $self->read_json( $r_file,  );
    $json_obj->{ $self->counter } = $task_data;

    $self->write_json( $r_file, $json_obj, );
}

sub remove_from_running {
    my $self     = shift;
    my $data_dir = shift;

    my $r_file = File::Spec->catfile( $data_dir, 'running.json' );

    my $json_obj = $self->read_json( $r_file,  );

    delete $json_obj->{ $self->table_data->{task_id} };
    $self->write_json( $r_file, $json_obj, );
}

sub get_from_running {
    my $self     = shift;
    my $data_dir = shift;

    my $r_file   = File::Spec->catfile( $data_dir, 'running.json' );
    my $json_obj = $self->read_json( $r_file,  );

    return $json_obj->{ $self->table_data->{task_id} };
}

sub read_json {
    my $self = shift;
    my $file = shift;

    my $json_obj = {};
    my $text;

    if ( -e $file ) {
        $text = read_file($file);
        try {
            $json_obj = decode_json($text) if $text;
        };
    }

    return $json_obj;
}

sub write_json {
    my $self     = shift;
    my $file     = shift;
    my $json_obj = shift;

    return unless $json_obj;
    my $json_text = '';

    try {
        $json_text = encode_json($json_obj);
    }
    catch {
        $json_text = '';
    };

    write_file($file, $json_text);
}

1;
