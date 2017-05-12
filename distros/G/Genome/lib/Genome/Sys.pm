package Genome::Sys;

use strict;
use warnings;
use Genome;
use Cwd;

class Genome::Sys { 
    # TODO: remove all cases of inheritance 
    #is => 'UR::Singleton', 
};

sub dbpath {
    my ($class, $name, $version) = @_;
    unless ($version) {
        die "Genome::Sys dbpath must be called with a database name and a version.  Use 'latest' for the latest installed version.";
    }
    my $base_dirs = $ENV{"GENOME_DB"} ||= '/var/lib/genome/db';
    return $class->_find_in_path($base_dirs, "$name/$version");
}

sub swpath {
    my ($class, $name, $version) = @_;
    unless ($version) {
        die "Genome::Sys swpath must be called with a database name and a version.  Use 'latest' for the latest installed version.";
    }
    my $base = $ENV{"GENOME_SW"} ||= '/var/lib/genome/sw';
    return join("/",$base,$name,$version);
}

sub _find_in_path {
    my ($class, $base_dirs, $subdir) = @_;
    my @base_dirs = split(':',$base_dirs);
    my @dirs =
        map { -l $_ ? Cwd::abs_path($_) : ($_) }
        map {
            my $path = join("/",$_,$subdir);
            (-e $path ? ($path) : ())
        }
        @base_dirs;
    return $dirs[0];
}

# temp file management

sub _temp_directory_prefix {
    my $self = shift;
    my $base = join("_", map { lc($_) } split('::',$self->class));
    return $base;
}

our $base_temp_directory;
sub base_temp_directory {
    my $self = shift;
    my $class = ref($self) || $self;
    my $template = shift;

    my $id;
    if (ref($self)) {
        return $self->{base_temp_directory} if $self->{base_temp_directory};
        $id = $self->id;
    }
    else {
        # work as a class method
        return $base_temp_directory if $base_temp_directory;
        $id = '';
    }

    unless ($template) {
        my $prefix = $self->_temp_directory_prefix();
        $prefix ||= $class;
        my $time = $self->__context__->now;

        $time =~ s/[\s\: ]/_/g;
        $template = "/gm-$prefix-$time-$id-XXXX";
        $template =~ s/ /-/g;
    }

    # See if we're running under LSF and LSF gave us a directory that will be
    # auto-cleaned up when the job terminates
    my $tmp_location = $ENV{'TMPDIR'} || "/tmp";
    if ($ENV{'LSB_JOBID'}) {
        my $lsf_possible_tempdir = sprintf("%s/%s.tmpdir", $ENV{'TMPDIR'}, $ENV{'LSB_JOBID'});
        $tmp_location = $lsf_possible_tempdir if (-d $lsf_possible_tempdir);
    }
    # tempdir() thows its own exception if there's a problem

    # For debugging purposes, allow cleanup to be disabled
    my $cleanup = 1;
    if($ENV{'GENOME_SYS_NO_CLEANUP'}) {
        $cleanup = 0;
    } 
    my $dir = File::Temp::tempdir($template, DIR=>$tmp_location, CLEANUP => $cleanup);

    $self->create_directory($dir);

    if (ref($self)) {
        return $self->{base_temp_directory} = $dir;
    }
    else {
        # work as a class method
        return $base_temp_directory = $dir;
    }

    unless ($dir) {
        Carp::croak("Unable to determine base_temp_directory");
    }

    return $dir;
}

our $anonymous_temp_file_count = 0;
sub create_temp_file_path {
    my $self = shift;
    my $name = shift;
    unless ($name) {
        $name = 'anonymous' . $anonymous_temp_file_count++;
    }
    my $dir = $self->base_temp_directory;
    my $path = $dir .'/'. $name;
    if (-e $path) {
        Carp::croak "temp path '$path' already exists!";
    }

    if (!$path or $path eq '/') {
        Carp::croak("create_temp_file_path() failed");
    }

    return $path;
}

sub create_temp_file {
    my $self = shift;
    my $path = $self->create_temp_file_path(@_);
    my $fh = IO::File->new($path, '>');
    unless ($fh) {
        Carp::croak "Failed to create temp file $path: $!";
    }
    return ($fh,$path) if wantarray;
    return $fh;
}

sub create_temp_directory {
    my $self = shift;
    my $path = $self->create_temp_file_path(@_);
    $self->create_directory($path);
    return $path;
}

sub create_directory {
    my ($self, $directory) = @_;

    unless ( defined $directory ) {
        Carp::croak("Can't create_directory: No path given");
    }

    # FIXME do we want to throw an exception here?  What if the user expected
    # the directory to be created, not that it already existed
    return $directory if -d $directory;

    my $errors;
    # make_path may throw its own exceptions...
    File::Path::make_path($directory, { mode => 02775, error => \$errors });
    
    if ($errors and @$errors) {
        my $message = "create_directory for path $directory failed:\n";
        foreach my $err ( @$errors ) {
            my($path, $err_str) = %$err;
            $message .= "Pathname " . $path ."\n".'General error' . ": $err_str\n";
        }
        Carp::croak($message);
    }
    
    unless (-d $directory) {
        Carp::croak("No error from 'File::Path::make_path', but failed to create directory ($directory)");
    }

    return $directory;
}

sub create_symlink {
    my ($self, $target, $link) = @_;

    unless ( defined $target ) {
        Carp::croak("Can't create_symlink: no target given");
    }

    unless ( defined $link ) {
        Carp::croak("Can't create_symlink: no 'link' given");
    }

    unless ( -e $target ) {
        Carp::croak("Cannot create link ($link) to target ($target): target does not exist");
    }
    
    if ( -e $link ) { # the link exists and points to spmething
        Carp::croak("Link ($link) for target ($target) already exists.");
    }
    
    if ( -l $link ) { # the link exists, but does not point to something
        Carp::croak("Link ($link) for target ($target) is already a link.");
    }

    unless ( symlink($target, $link) ) {
        Carp::croak("Can't create link ($link) to $target\: $!");
    }
    
    return 1;
}

sub _open_file {
    my ($self, $file, $rw) = @_;
    if ($file eq '-') {
        if ($rw eq 'r') {
            return 'STDIN';
        }
        elsif ($rw eq 'w') {
            return 'STDOUT';
        }
        else {
            die "cannot open '-' with access '$rw': r = STDIN, w = STDOUT!!!";
        }
    }
    my $fh = IO::File->new($file, $rw);
    return $fh if $fh;
    Carp::croak("Can't open file ($file) with access '$rw': $!");
}

sub validate_file_for_reading {
    my ($self, $file) = @_;

    unless ( defined $file ) {
        Carp::croak("Can't validate_file_for_reading: No file given");
    }

    if ($file eq '-') {
        return 1;
    }

    unless (-e $file ) {
        Carp::croak("File ($file) does not exist");
    } 

    unless (-f $file) {
        Carp::croak("File ($file) exists but is not a plain file");
    }

    unless ( -r $file ) { 
        Carp::croak("Do not have READ access to file ($file)");
    }

    return 1;
}

sub open_file_for_reading {
    my ($self, $file) = @_;

    $self->validate_file_for_reading($file)
        or return;

    # _open_file throws its own exception if it doesn't work
    return $self->_open_file($file, 'r');
}

sub shellcmd {
    # execute a shell command in a standard way instead of using system()\
    # verifies inputs and ouputs, and does detailed logging...

    # TODO: add IPC::Run's w/ timeout but w/o the io redirection...

    my ($self,%params) = @_;
    my $cmd                         = delete $params{cmd};
    my $output_files                = delete $params{output_files} ;
    my $input_files                  = delete $params{input_files};
    my $output_directories          = delete $params{output_directories} ;
    my $input_directories           = delete $params{input_directories};
    my $allow_failed_exit_code      = delete $params{allow_failed_exit_code};
    my $allow_zero_size_output_files = delete $params{allow_zero_size_output_files};
    my $skip_if_output_is_present   = delete $params{skip_if_output_is_present};
    $skip_if_output_is_present = 1 if not defined $skip_if_output_is_present;
    if (%params) {
        my @crap = %params;
        Carp::confess("Unknown params passed to shellcmd: @crap");
    }

    if ($output_files and @$output_files) {
        my @found_outputs = grep { -e $_ } grep { not -p $_ } @$output_files;
        if ($skip_if_output_is_present
            and @$output_files == @found_outputs
        ) {
            $self->status_message(
                "SKIP RUN (output is present):     $cmd\n\t"
                . join("\n\t",@found_outputs)
            );
            return 1;
        }
    }

    if ($input_files and @$input_files) {
        my @missing_inputs = grep { not -s $_ } grep { not -p $_ } @$input_files;
        if (@missing_inputs) {
            Carp::croak("CANNOT RUN (missing input files):     $cmd\n\t"
                         . join("\n\t", map { -e $_ ? "(empty) $_" : $_ } @missing_inputs));
        }
    }

    if ($input_directories and @$input_directories) {
        my @missing_inputs = grep { not -d $_ } @$input_directories;
        if (@missing_inputs) {
            Carp::croak("CANNOT RUN (missing input directories):     $cmd\n\t"
                        . join("\n\t", @missing_inputs));
        }
    }

    $self->status_message("RUN: $cmd");
    my $exit_code = system($cmd);
    if ( $exit_code == -1 ) {
        Carp::croak("ERROR RUNNING COMMAND. Failed to execute: $cmd");
    } elsif ( $exit_code & 127 ) {
        my $signal = $exit_code & 127;
        my $withcore = ( $exit_code & 128 ) ? 'with' : 'without';

        Carp::croak("COMMAND KILLED. Signal $signal, $withcore coredump: $cmd");
    } elsif ($exit_code >> 8 != 0) {
        $exit_code = $exit_code >> 8;
        $DB::single = $DB::stopper;
        if ($allow_failed_exit_code) {
            Carp::carp("TOLERATING Exit code $exit_code, msg $! from: $cmd");
        } else {
            Carp::croak("ERROR RUNNING COMMAND.  Exit code $exit_code, msg $! from: $cmd");
        }
    }

    my @missing_output_files;
    if ($output_files and @$output_files) {
        @missing_output_files = grep { not -s $_ }  grep { not -p $_ } @$output_files;
    }
    if (@missing_output_files) {
        if ($allow_zero_size_output_files
            and @$output_files == @missing_output_files
        ) {
            for my $output_file (@$output_files) {
                Carp::carp("ALLOWING zero size output file '$output_file' for command: $cmd");
                my $fh = $self->open_file_for_writing($output_file);
                unless ($fh) {
                    Carp::croak("failed to open $output_file for writing to replace missing output file: $!");
                }
                $fh->close;
            }
            @missing_output_files = ();
        }
    }
    
    my @missing_output_directories;
    if ($output_directories and @$output_directories) {
        @missing_output_directories = grep { not -s $_ }  grep { not -p $_ } @$output_directories;
    }


    if (@missing_output_files or @missing_output_directories) {
        for (@$output_files) { unlink $_ or Carp::croak("Can't unlink $_: $!"); }
        Carp::croak("MISSING OUTPUTS! "
                    . join(', ', @missing_output_files)
                    . " "
                    . join(', ', @missing_output_directories));
    } 

    return 1;    

}
1;

__END__

    methods => [
        dbpath => {
            takes => ['name','version'],
            uses => [],
            returns => 'FilesystemPath',
            doc => 'returns the path to a data set',
        },
        swpath => {
            takes => ['name','version'],
            uses => [],
            returns => 'FilesystemPath',
            doc => 'returns the path to an application installation',
        },
    ]

# until we get the above into ur...

=pod

=head1 NAME

Genome::Sys

=head1 VERSION

This document describes Genome::Sys version 0.05.

=head1 SYNOPSIS

use Genome;

my $dir = Genome::Sys->dbpath('cosmic', 'latest');

=head1 DESCRIPTION

Genome::Sys is a simple layer on top of OS-level concerns,
including those automatically handled by the analysis system, 
like database cache locations.

=head1 METHODS

=head2 swpath($name,$version)

Return the path to a given executable, library, or package.

This is a wrapper for the OS-specific strategy for managing multiple versions of software packages,
(i.e. /etc/alternatives for Debian/Ubuntu)

The GENOME_SW environment variable contains a colon-separated lists of paths which this falls back to.
The default value is /var/lib/genome/sw/.


=head2 dbpath($name,$version)

Return the path to the preprocessed copy of the specified database.
(This is in lieu of a consistent API for the database in question.)

The GENOME_DB environment variable contains a colon-separated lists of paths which this falls back to.
The default value is /var/lib/genome/db/.

=cut
