package Developer::Dashboard::UpdateManager;

use strict;
use warnings;

our $VERSION = '2.26';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Spec;

use Developer::Dashboard::Platform qw(command_argv_for_path is_runnable_file);

# new(%args)
# Constructs the updater coordinator.
# Input: config, files, paths, and runner objects.
# Output: Developer::Dashboard::UpdateManager object.
sub new {
    my ( $class, %args ) = @_;
    my $config = $args{config} || die 'Missing config';
    my $files  = $args{files}  || die 'Missing file registry';
    my $paths  = $args{paths}  || die 'Missing path registry';
    my $runner = $args{runner} || die 'Missing collector runner';

    return bless {
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    }, $class;
}

# updates_dir()
# Returns the directory containing updater scripts.
# Input: none.
# Output: directory path string.
sub updates_dir {
    my ($self) = @_;
    return File::Spec->catdir( cwd(), 'updates' );
}

# run()
# Executes update scripts in order while stopping and restarting managed collectors.
# Input: none.
# Output: array reference of update step result hashes.
sub run {
    my ($self) = @_;

    my @running = $self->_running_collectors;
    $self->_stop_collectors(@running);

    my @results;
    my $dir = $self->updates_dir;

    return \@results if !-d $dir;

    opendir my $dh, $dir or die "Unable to open updates directory $dir: $!";
    for my $file ( sort readdir $dh ) {
        next if $file eq '.' || $file eq '..';
        next if !-f File::Spec->catfile( $dir, $file );

        my $path = File::Spec->catfile( $dir, $file );
        next if !$self->_is_supported_update_script($path);
        my @cmd = command_argv_for_path($path);

        print "-" x 40, "\n";
        print ">> Run Update: $file...\n";
        print "-" x 40, "\n";
        print ">> @cmd\n";
        print "-" x 40, "\n";

        my ( $stdout, $stderr, $exit_code ) = capture {
            system @cmd;
            return $? >> 8;
        };
        my $output = $stdout . $stderr;

        print $output if defined $output && $output ne '';
        print "\n>> Finished.\n\n";

        push @results, {
            file      => $file,
            exit_code => $exit_code,
            output    => $output,
        };
    }
    closedir $dh;

    $self->_restart_collectors(@running);

    return \@results;
}

# _is_supported_update_script($path)
# Determines whether one update file is a supported runnable update script on this platform.
# Input: update file path string.
# Output: boolean true when the file should be executed by run().
sub _is_supported_update_script {
    my ( $self, $path ) = @_;
    return 0 if !defined $path || $path eq '';
    return 1 if $path =~ /\.pl\z/i;
    return 1 if $path =~ /\.(?:sh|bash|ps1|cmd|bat)\z/i;
    return is_runnable_file($path) ? 1 : 0;
}

# _running_collectors()
# Returns the list of currently running managed collectors.
# Input: none.
# Output: list of collector name strings.
sub _running_collectors {
    my ($self) = @_;
    return map { $_->{name} } $self->{runner}->running_loops;
}

# _stop_collectors(@names)
# Stops the named managed collectors.
# Input: list of collector name strings.
# Output: none.
sub _stop_collectors {
    my ( $self, @names ) = @_;
    for my $name (@names) {
        eval { $self->{runner}->stop_loop($name) };
    }
}

# _restart_collectors(@wanted)
# Restarts configured collectors that were previously running and are still desired.
# Input: list of collector name strings.
# Output: none.
sub _restart_collectors {
    my ( $self, @names ) = @_;
    return if !@names;

    my %wanted = map { $_ => 1 } @names;
    my @jobs = @{ $self->{config}->collectors };

    for my $job (@jobs) {
        next if ref($job) ne 'HASH';
        next if !$wanted{ $job->{name} };
        eval { $self->{runner}->start_loop($job) };
    }
}

1;

__END__

=head1 NAME

Developer::Dashboard::UpdateManager - managed update runner

=head1 SYNOPSIS

  my $updater = Developer::Dashboard::UpdateManager->new(...);
  my $steps = $updater->run;

=head1 DESCRIPTION

This module executes repository update scripts while coordinating managed
collector shutdown and restart around the update process.

=head1 METHODS

=head2 new, updates_dir, run

Construct and execute dashboard updates.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module runs the ordered update hook chain for C<dashboard update>. It discovers executable update scripts, runs them in sorted order, streams their stdout and stderr, updates the structured C<RESULT> state between hooks, and coordinates collector stop/start around the update window.

=head1 WHY IT EXISTS

It exists because update hooks are a first-class runtime workflow, not a one-off shell loop. The dashboard needs one module that owns ordering, streaming, structured hook results, and collector lifecycle around updates.

=head1 WHEN TO USE

Use this file when changing update hook discovery, update streaming behavior, RESULT propagation between update hooks, or the way updates stop and restart collectors.

=head1 HOW TO USE

Construct it with the file registry, path registry, and collector runner, then call its run method from the update command. Keep update hook execution policy in this module rather than in the command wrapper.

=head1 WHAT USES IT

It is used by the C<dashboard update> flow, by runtime bootstrap/update smoke tests, and by coverage that verifies update hook ordering and collector restart semantics.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::UpdateManager -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/04-update-manager.t t/26-sql-dashboard.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
