package Grid::Request::JobFormulator;

use strict;
use Grid::Request::HTC;
use Grid::Request::Param;
use Grid::Request::Exceptions;
use Log::Log4perl qw(get_logger);

my $logger = get_logger(__PACKAGE__);

our $VERSION = '0.11';
if ($^W) {
    $VERSION = $VERSION;
}

# The constructor.
sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class || ref($class);
    return $self;
}

sub formulate {
    $logger->debug("In formulate.");

    # The first argument is the blocksize, or how many invocations each worker
    # will be processing. The second argument is the executable to invoke to
    # invoke, and the remaining arguments are the MW parameters.
    my ($self, $blocksize, $executable, @mw_params) = @_; 

    if (! defined $blocksize || $blocksize <= 0) {
        Grid::Request::Exception->throw("Bad blocksize. Must be >= 1.");
    } else {
        $logger->debug("Blocksize: $blocksize");
    }

    $logger->debug("Number of MW parameters: " . scalar(@mw_params));

    # An array of arrays for all the parameters to invoke
    my @arg_groups = ();
    foreach my $param (@mw_params) {
        $logger->debug(qq|Processing parameter "$param"|);
        my $arg_ref = _get_arguments_for_param($param);
        push (@arg_groups, $arg_ref);
    }

    # Determine the largest list of parameters, then backfill the "PARAM"
    # arguments with that number of values.
    my $min;
    if (scalar @arg_groups) {
        for (my $column = 0; $column < scalar @arg_groups; $column++) {
            if ( ref($arg_groups[$column]) eq "ARRAY") {
                my $column_count =  scalar @{ $arg_groups[$column] }; 
                if (defined $min) {
                    if ( $column_count < $min) {
                        $min = $column_count;
                    }
                } else {
                    $min = $column_count;
                }
            }
        }
    }

    # Now replace the PARAM columns with $min copies of the value.
    if (scalar @arg_groups) {
        for (my $column = 0; $column < scalar @arg_groups; $column++) {
            my $arg = $arg_groups[$column];
            if ( ref(\$arg) eq "SCALAR") {
                my $param = Grid::Request::Param->new($arg);
                my $value = $param->value();
                my @args = ($value) x $min;
                $arg_groups[$column] = \@args;
            }
        }
    }
    
    # Chop all the arg_groups according to the group with the smallest size
    @arg_groups = _limit_arguments(\@arg_groups);

    my @invocations =  _assemble_invocations($blocksize, $executable, \@arg_groups);

    return wantarray ? @invocations : \@invocations;
}

sub _limit_arguments {
    my $arg_group_ref = shift;
    my @arg_groups = @$arg_group_ref;
    # Chop all the arg_groups according to the group with the smallest size
    my $min;
    foreach my $group (@arg_groups) {
        # $group is an array ref here
        my $current_size = scalar(@$group);
        if (defined $min) {
            if ($current_size < $min) {
                $min = $current_size;
            }
        } else {
            $min = $current_size;
        }
    }
    $logger->debug("Determined that the number of times we can iterate with these arguments is $min.");

    # Now that we know the minimum size, we can limit each group
    my @limited_groups;
    my $group_number = 0;
    foreach my $group (@arg_groups) {
        $group_number++;
        my $size = scalar(@$group);
        if ($size > $min) {
            # Okay, this group is too big. Cut it down to size
            $logger->debug("Cutting argument group number $group_number down to $min from $size.");
            # Change the array size by assigning to $#ARRAY
            my @lesser = @$group;
            $#lesser = $min - 1;
            $group = \@lesser;
        }
        push (@limited_groups, $group);
    }
    return wantarray ? @limited_groups : \@limited_groups;
}

sub _assemble_invocations {
    $logger->debug("In _assemble_invocations.");
    my ($blocksize, $executable, $arg_group_ref) = @_;
    my ($success, $failed) = (0,0);
    my @invocations = ();

    my $group_size = scalar @$arg_group_ref;
    $logger->debug("The number of arguments each invocation of $executable will have: $group_size");

    if ( $group_size > 0 ) {
        # Which worker invocation the assembled invocations are for.
        # This module produces invocations for all the tasks that will be launched
        # so we have to replace all $Index occurrences with the right number. Block size
        # dictates how many invocations per task...
        my $task_id = 1; 
        my $block_index = 1; # Initialize a counter to iterate over the blocksize with.

        $logger->debug("Assembling iterations for task ID $task_id.");
        
        # Length of the various argument arrays should all be the same, so we'll just use
        # the length of the first one.
        my $arg_length = scalar(@{ $arg_group_ref->[0] });
        
        # This loop is to iterate across the argument arrays
        for (my $arg_index = 0; $arg_index < $arg_length; $arg_index++) {
            my @exec = ($executable);

            for (my $group_index = 0; $group_index < $group_size; $group_index++) {
                my $arg = $arg_group_ref->[$group_index]->[$arg_index];

                # Replace $(Index) with the task id.
                $arg =~ s/\$\(Index\)/$task_id/g;
                
                push(@exec, $arg);
                if ($block_index == $blocksize) {
                    $task_id++;
                    $block_index = 1;
                } else {
                    $block_index++;
                }
            }

            push(@invocations, \@exec);
        }
    } else {
        $logger->warn("No arguments! Just invoking the configured executable with no args.");
        push(@invocations, [ $executable ])
    }

    return wantarray ? @invocations : \@invocations;
}

sub _get_arguments_for_param {
    my $param_string = shift;
    my $arg_ref;
    # Use the Grid::Request::Param class to build a param and extract the type. 
    my $param = Grid::Request::Param->new($param_string);
    my $type = uc($param->type());
    my $value = $param->value();
    my $key = $param->key();
    
    # This should be dynamic. Dynamically load a module that computes the array
    # at runtime.
    if ($type eq "PARAM") {
        # This is a special case. We simply return the param string scalar,
        # so that we can later substitute it with the exact argument as
        # many times as necessary.
        $arg_ref = $param_string;
    } elsif ($type eq "DIR") {
        $arg_ref = _get_dir_args($value, $key);
    } elsif ($type eq "FILE") {
        $arg_ref = _get_file_args($value, $key);
    } else {
        # Possibly, try a dynamic load of a module
        Grid::Request::Exception->throw("Unrecognized parameter type of \"$type\".");
    }

    return $arg_ref;
}

sub _get_dir_args {
    my ($dir, $key) = @_;

    my @args = ();

    # Read all the files in the directory into an array. Then take
    # the appropriate slice of the array according to our block size
    # and our task id. Then cycle through those filenames and replace
    # any tokens in the $key, then push that resultant argument to
    # the @args array.

    opendir(DIR, $dir) || $logger->logdie("Cannot open directory $dir: $!");
    my @files = grep { /^[^\.]/ && -f "$dir/$_" } readdir(DIR);
    closedir DIR;
    $logger->debug("Finished scanning directory $dir");

    @files = sort(@files);
    $logger->debug("Files scanned: ", sub { Dumper(\@files) } );

    foreach my $file (@files) {
        $logger->debug(qq|Using file: "$file"|);
        my $final_arg = $key;
        $final_arg =~ s/\$\(Name\)/$file/g;
        push (@args, $final_arg);
    }
    $logger->info("Total number of files to use: " . scalar(@args));

    return \@args;
}

sub _get_file_args {
    my ($file, $key) = @_;

    my @args = ();

    # Open the file specified by the param. Cycle through these
    # lines that were pulled and replace any tokens in the $key and
    # push that resultant argument to the @args array.
    $logger->info("About to open $file");

    open (FILE, "<", $file) or die "Unable to open $file for reading.";

    # Read the lines from the file, and perform substitutions as necessary.
    while (<FILE>) {
        chomp;
        my $valid_line = $_;
        my $final_arg = $key;
        $final_arg =~ s/\$\(Name\)/$valid_line/g;
        push (@args, $final_arg);
    } 
    eval {
        close (FILE);
    };
    if ($@) {
        Grid::Request::Exception->throw("Unable to close filehandle for $file.");
    }
    return \@args;
}

1;
