package HPC::Runner::Command::execute_job::Logger::Lock;

use Moose::Role;

use namespace::autoclean;
use Try::Tiny;
use Path::Tiny;
use File::Slurp;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;

has 'lock_file' => (
    is       => 'rw',
    isa      => Path,
    lazy     => 1,
    coerce   => 1,
    required => 1,
    default  => sub {
        my $self = shift;
        my $file =
            File::Spec->catdir($self->data_dir,  '.lock' );
        return $file;
    },
);

=head3 check_lock

Check to see if the lock exists

Have a max retry count to avoid infinite loops

=cut

sub check_lock {
    my $self     = shift;

    my $max_retries = 1000;
    my $x           = 0;

    while ( $self->lock_file->exists ) {
        $self->command_log->info('Lock exists!');
        Time::HiRes::sleep(0.5);
        $x++;
        last if $x >= $max_retries;
    }
    if ( $x >= $max_retries ) {
        $self->command_log->warn(
            'Logger::JSON Error: We exited the lock!'  );
    }
}

sub write_lock {
    my $self     = shift;

    try {
        $self->lock_file->touchpath;
    }
    catch {
        $self->command_log->warn(
            'Logger::JSON Error: We were not able to write ' . $self->lock_file->stringify );
    };
}

1;
