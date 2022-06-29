#!/usr/bin/env perl
package Git::Nuggit::Log;
our $VERSION = 0.01;

use v5.10;
use strict;
use warnings;
use File::Spec;
use Term::ANSIColor;
use Cwd;

# TODO: Automatic rotation of primary logfile based on filesize

=head1 Nuggit Logging Library

Activity is autoamtically logged to root .nuggit/nuggit_log.txt in a parseable format as required.

If logger is iniitalized with a verbose flag, all entires will be echoed to stdout.

File logging will be performed only if started with a critical flag of 1 (ie: $log->start(1)). This allows non-critical commands to utilize the same log and make usage of the verbose flag to output details to stdout.

In the future, additional verbosity levels may be implemented to allow greater control.

=head2 Log Format

Log file is a (mostly) CSV file with the following format:

Script execution is logged as timestamp, command
    NOTE: For nuggit, current working dir is irrelevant if within a nuggit repo.

These columns will be blank for any additional entries for a given script.  Other entries may include:

A general message, prepended with ",,\t" such that the first 2 columns are empty and a tab improves readability when viewed directly.

For all other cases, remaining columns will follow in a title,value form, for example a git add command may show:
   CWD, current/rel/path, CMD, git add myfile

Any git commands that may affect working state should be logged as noted above with "nuggit_log" function.

=head2 Usage

# Create logger object PRIOR to any manipulation of @ARGV
my $logger = Git::Nuggit::Log->new(root => $root_dir, verbose => $verbose);

# After parsing args, call start function to write initial entry
# Pass an argument of 1 for critical commands (always log to file), 0 for others
$logger->start(1); 

# Log an explicit message
$logger->log($msg);

# Log a command (automatically logs specified command and current working directory)
$logger->cmd($cmd);

=head1 Function Reference

=head2 new

This is a singleton constructor.  If called more than once, the original object shall be returned.

It is required to specify either root or file parameter.  

Supported parameters:

=over

=item root

Root directory of Nuggit project.  root or file parameter must be specified here or in start() if file logging is to be used.

=item file

Name, including path, or log file to access.  root or file parameter must be specified here or in start() if file logging is to be used.

=item verbose

If set, all log commands will be output to stdout.

=item file_verbose

Write to log file regardless of specified logging level of script

=back

=head2 start

This function must be called before logging any additional details.  

It accepts as input a log level, which is currently 0 or 1.  If 1, data will be logged to the file.  Additional log levels may be added in the future.  If verbose flag is specified, all log output will be echoed to stdout.

If file logging is enabled, this function will open the log file for appending and record an initial command record.

This function returns a reference to it's self, allowing function chaining during initialization.

The following arguments are supported:

=over

=item level

0 for non-critical commands that will not be logged to file, 1 for commmands that should be logged.

=item log_as_child

If this flag is set, initial log entry will be made as a command logged beneath the prior entry in the log file.  This is intended for usage in cases where one script may invoke another in a separate execution context.

=item verbose

If specified, set the verbose flag in the logger object to enable output to stdout.

=back

=head2 clear

This function will clear the log file.  If no argument is specified, the file will be deleted.  Otherwise, the specified number of lines will be truncated.

=head2 log

Log the specified message

=head2 cmd

Log the speciied commmand.  The current working directory will be included in the log entry.

=cut

sub new
{
    my ($class,%args) = @_;

    # This is a Singleton library, handled transparently for the user
    # Future: If a non-singleton use case arises, we can add a flag to bypass it below
    state $instance;
    if (defined($instance)) {
        # If previously initialized, do not re-initialize
        return $instance;
    }

    # Validate Settings
    my $verbose = $args{verbose};
    my $cmd = $args{cmd};
    my $file;
    
    if (!$cmd) {
        # If caller does not explicitly override it's description, generate it from ARGV
        if ($verbose) {
            $cmd .= $0; # Include full path to script, this may make it difficult to read output
        } else {
            my ($vol, $dir, $file) = File::Spec->splitpath($0);
            $cmd .= $file;
        }

        # Perl Magic to re-assemble arguments
        foreach (@ARGV) {
            $cmd .= /\s/ ?   " \'" . $_ . "\'"
            :           " "   . $_;
        }

    }

    # Create our object
    $instance = bless {
                      cmd => $cmd,
                      # level =>  (defined($args{level}) ? $args{level} : 0),
                     }, $class;

    # Wrapper to conveniently allow root/file to be specified in constructor or start method
    #  Return self if successful, fail if parsing fails.
    return $instance->parse_args(%args) ? $instance : undef;
}

# Intended as a private function for setting root/file path prior to (or by) start()
sub parse_args
{
    my ($self, %args) = @_;

    $self->{verbose} = $args{verbose} if $args{verbose};
    $self->{file_verbose} = $args{file_verbose} if $args{file_verbose};

    
    if (defined($args{file})) {
        $self->{file} = $args{file};
        if (!defined($args{root})) {
            # Set Root for logging purposes (one dir above log file)
            $self->{root} = File::Spec->updir(File::Spec->updir($self->{file})); 
        }
    } elsif (defined($args{root})) {
        return 0 unless (-d $args{root});
        $self->{root} = ($args{root} eq ".") ? getcwd() : File::Spec->rel2abs($args{root});
        $self->{file} = File::Spec->catfile($args{root}, ".nuggit", "nuggit_log.txt");
    } elsif (-d '.nuggit') {
        $self->{file} = File::Spec->catfile(".nuggit","nuggit_log.txt");
        $self->{root} = getcwd();
    } else {
        return 0;
    }

    return 1;
}

sub get_filename
{
    my $self = shift;
    return $self->{file};
}

sub start_as
{
    my $self = shift;
    my $cmd = shift;
    $self->{cmd} = $cmd;
    $self->start(1);
}

sub start
{
    my $self = shift;
    my ($level, $log_as_child);
    my $root_dir = $self->{root};
    
    if (@_ == 1) {
        # If a single argument, assume it is level
        $level = shift;
    } else {
        my %args = @_;
        
        $level = $args{level}; # 0 = non-critical (no file logging), 1 = critical (use file logging)
    
        # Log as child command of prior script. Used when one ngt tool invokes another via shell
        $log_as_child = $args{log_as_child};

        # Let user override verbose flag as part of start call
        if (defined($args{verbose})) {
            $self->{verbose} = $args{verbose};
        }
        $self->parse_args(%args);
    }
    
    my $cmd = $self->{cmd};

    say colored('NGT_LOG: '.$cmd,'yellow') if $self->{verbose};
    
    # No effect if called more than once
    return if (defined($self->{log_fh}));

    die("Error: Can't initialize file logging without a valid file/path") unless (defined($self->{file}));
    
    # Prepare single-command detailed log
    my $last_cmd_file = $self->{file}.".last_cmd";
    rotate_file($last_cmd_file) if -f $last_cmd_file && !$log_as_child;
    open(my $log_detail_fh, '>>', $last_cmd_file) || die "Can't open last_cmd_log.txt for writing";
    $self->{log_detail_fh} = $log_detail_fh;
    $self->cmd_full($cmd);

    # Nothing to do if logging is diabled (by verbosity or log-level)
    return if ($level == 0 && !$self->{file_verbose});
 
    open(my $log_fh, '>>', $self->{file}) || die("Can't open log file $self->{file}: $!");
    $self->{log_fh} = $log_fh;
    
    if ($log_as_child) {
        $self->cmd($cmd);
    } else {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        my $nice_timestamp = sprintf( "%02d/%02d/%04d %02d:%02d:%02d",
                                      $mon+1,$mday,$year+1900,$hour,$min,$sec);
        my $msg = "$nice_timestamp, "; # Command/script eecuted

    
        say $log_fh $msg.$cmd;
    }
    return $self;
}

sub rotate_file
{
    my $fn = shift;
    my $cnt = shift // 7;

    # Base case
    return if (!-f $fn); # File does not exist
    if (!-f "$fn.1") {
        # No old file
        rename($fn, "$fn.1");
        return;
    }

    # Increment cnt for all existing files < $cnt (last file will be overwritten)

    my @files = sort {$b cmp $a} <$fn.*>;
    foreach my $file (@files) {
        if ($file =~ /$fn\.(\d)/) {
            if ($1 < $cnt) {
                   rename("$fn.$1", "$fn.".($1+1) );
            }
        }
    }
    
    # Finally rename our base file
    rename($fn, "$fn.1");
    
}

# NOTE: $keep_lines arg may be deprecated in future in favor of an export capability to overrite existing log
sub clear
{
    my $self = shift;
    
    my $keep_lines = shift; # Number of lines in log to preserve
    # Note: The last line (when used as intended) will be a log of this clear operation from nuggit_log_init
    
    my $file = $self->{file};
    my $fh = $self->{log_fh};

    close($fh) if $fh;

    if ($keep_lines) {
        system("tail -n $keep_lines $file > $file.new");
        rename("$file.new", $file);
    } else {
        unlink($file);
    }
    if ($fh) {
        open($fh, '>>', $file);
        $self->{log_fh} = $fh;
    }
}

# TODO: Consider verbosity flag to nuggit_log, or guarding with said flag in caller
sub log
{
    my $self = shift;
    my $msg = shift;
    #my $level = shift; # FUTURE
    my $fh = $self->{log_fh};

    say colored('NGT_LOG: '.$msg, 'yellow') if ($self->{verbose});
    
    return unless defined($fh); # Fail silently if file is not open

    # Log message. We prepend marker (CSV-friendly and read-friendly) to indicate this continues init entry
    say $fh ",,\t".$msg;
}

# Log a git command in a consistent manner (only commands that affect state of the repository; ie; not for status)
sub cmd
{
    my $self = shift;
    my $cmd = shift;
    my $cwd = File::Spec->abs2rel( getcwd(), $self->{root} );
    my $fh = $self->{log_fh};

    say colored('NGT_LOG: '.$cmd, 'yellow').colored("\t$cwd",'cyan') if $self->{verbose};
    
    return unless defined($fh); # Fail silently if file is not open
    
    say $fh ",,CWD,$cwd,CMD,$cmd";
}

sub cmd_full
{
    my $self = shift;
    my $cmd = shift;
    my $stdout = shift;
    my $stderr = shift;
    my $rtv = shift;
    my $fh = $self->{log_detail_fh};

    return unless defined($fh);
    say $fh colored($cmd, 'bold');
    say $fh colored("\t at ".getcwd(), 'bold');
    say $fh colored("ERROR Return Value: $rtv", 'bold red') if $rtv;
    if ($stdout) {
         say $fh colored("STDOUT:", 'bold');
         say $fh $stdout;
    }
    if ($stderr) {
         say $fh colored("STDERR:", 'bold');
         say $fh $stderr;
     }
}

1;
