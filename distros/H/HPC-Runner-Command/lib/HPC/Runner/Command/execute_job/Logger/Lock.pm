package HPC::Runner::Command::execute_job::Logger::Lock;

use Moose::Role;
use namespace::autoclean;


=head3 check_lock

Check to see if the lock exists

Have a max retry count to avoid infinite loops

=cut

sub check_lock {
    my $self = shift;
    my $data_dir = shift;

    my $max_retries = 1000;
    my $x           = 0;
    while ( $self->lock_exists($data_dir) ) {
        Time::HiRes::sleep(0.5);
        $x++;
        last if $x >= $max_retries;
    }
}

sub lock_exists {
    my $self     = shift;
    my $data_dir = shift;

    return unless $data_dir;
    my $file = File::Spec->catfile( $data_dir, '.lock' );

    if ( $self->archive->contains_file($file) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub write_lock {
    my $self     = shift;
    my $data_dir = shift;

    my $file = File::Spec->catfile( $data_dir, '.lock' );
    my $json_text = '';

    if ( $self->archive->contains_file($file) ) {
        $self->archive->replace_content( $file, $json_text );
    }
    else {
        $self->archive->add_data( $file, $json_text )
          || $self->command_log->warn(
            'We were not able to add ' . $file . ' to the archive' );
    }

    $self->archive->write( $self->data_tar )
      || $self->command_log->warn(
        'We were not able to write ' . $file . ' to the archive' );
}

sub remove_lock {
    my $self     = shift;
    my $data_dir = shift;

    my $file = File::Spec->catfile( $data_dir, '.lock' );
    $self->archive->remove($file);

    $self->archive->write( $self->data_tar )
      || $self->command_log->warn(
        'We were not able to write ' . $file . ' to the archive' );
}

1;
