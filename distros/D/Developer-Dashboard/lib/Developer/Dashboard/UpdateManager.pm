package Developer::Dashboard::UpdateManager;

use strict;
use warnings;

our $VERSION = '2.02';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Spec;
use FindBin qw($Bin);

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

Perl module in the Developer Dashboard codebase. This file runs the staged update scripts that maintain the dashboard runtime.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::UpdateManager> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::UpdateManager -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
