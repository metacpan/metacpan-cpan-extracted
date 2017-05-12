package File::CleanupTask;

use strict;
use warnings;

use Cwd            qw/realpath getcwd chdir/;
use File::Path     qw/mkpath rmtree/;
use File::Basename qw/fileparse/;
use File::Spec     qw/catpath splitpath/;
use Config::Simple;
use File::Which    qw/which/;
use Getopt::Long;
use File::Find;
use File::Copy;
use IPC::Run3      qw/run3/;
use Sort::Key      qw/nkeysort/;
use Config;

=head1 NAME

File::CleanupTask - Delete or back up files using a task-based configuration

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

    use File::CleanupTask;

    my $cleanup = File::Cleanup->new({
        conf => "/path/to/tasks_file.tasks",
        taskname => "TASK_LABEL_IN_TASKFILE",
    });

    $cleanup->run();

Once run() is called, the cleanup operation 'TASK_LABEL_IN_TASKFILE' specified
in tasks_file.tasks is performed.


=head2 CONFIGURATION FORMAT

A .tasks file is a text file in which one or more cleanup tasks are specified.
Each task has a label and a list of options specified as shown in the following
example:

    [TASK_LABEL_IN_TASKFILE]
    path                = '/home/savio/results/'
    backup_path         = '/home/savio/old_results/'
    backup_gzip             = 1
    max_days                = 3
    recursive               = 1
    prune_empty_directories = 1
    keep_if_linked_in       = '/home/savio/results/'

    [ANOTHER_LABEL]
    path = 'C:\\this\\is\\a\\windows\\path'
	...


In this case, [TASK_LABEL_IN_TASKFILE] is the name of the cleanup task to be
executed.

The following options can be specified under a task label:

=head3 path

The path to the directory containing the files to be deleted or removed.

Note that for MS Windows the backslashes in a path should be escaped and single
quotes are strictly needed when specifying a path name (see the example above).

=head3 backup_path

If specified, will cause files to be moved in the specified directory instead
of being deleted. If backup_path doesn't exist, it will be created.  Symlinks
are not backed up. The files are backed up at the toplevel of backup_path in a
.gz (or .tgz, depending on backup_gzip) archive, which preserves pathnames of
the archived files.

=head3 backup_gzip

If set to "1", will gzip the files saved in backup_path. The resulting archive
will preserve the pathname of the original file, and will be relative to
'path'.

For example, given the following configuration:

   [LABEL]
   path = /path/to/cleanup/
   backup_path = /path/to/backup/
   backup_gzip = 1

If /path/to/cleanup/my/target/file.txt is encountered, and it's old, it will be
backed up in /path/to/backup/file.txt.gz. Uncompressing file.txt.gz using
/path/to/backup as current working directory will result in:

   /path/to/backup/path/to/cleanup/my/target/file.txt


=head3 max_days

The number of maximum days within which the files in the cleanup directories
are kept.  If a file is older than the specified number of days, it is queued
for deletion.

For example, max_days = 3 will delete files older than 3 days from the cleanup
directory.

max_days defaults to 0 if it isn't specified, meaning that all the files are to
be deleted.

=head3 recursive

If set to 0, only files within "path" can be deleted/backed up.
If set to 1, files located at any level within "path" can be deleted.

If C<prune_empty_directories> is enabled and C<recursive> is disabled, then
only empty directories that are direct children of "path" will be cleaned up.

By default, this takes the 0 value.

=head3 prune_empty_directories

If set to 1, empty directories will be deleted, respecting the C<max_days>
option. (In versions 0.09 and older, this would not respect the max_days option.)

By default, this takes the 0 value.

=head3 keep_if_linked_in

A pathname to a directory that may contain symlinks. If specified, it will
prevent deletion of files and directories within path that are symlinked in
this directory, regardless of their age.

This option will be ignored in MS Windows or in other operating systems that
don't support symlinks.

=head3 do_not_delete

A regular expression that defines a pattern to look for. Any pathnames matching
this pattern will not be erased, regardless of their age. The regular
expression applies to the full pathname of the file or directory.

In the configuration file, it should be surrounded by forward slashes. Because
the configuration file is parsed by L<Config::Simple>, you will need to escape
any backslashes in the regex with a backslash.

=cut

=head3 delete_all_or_nothing_in

If set to 1, immediate subfolders in path will be deleted only if all the files
in it are deleted.

=head3 pattern

If specified, will apply any potential delete or backup action to the files
that match the pattern. Any other file will be left untouched.

=cut

=head3 enable_symlinks_integrity_in_path

If set to 1, the symlinks inside 'path' will be deleted only if their target
will be deleted. This option is disabled by default, which means that the
target of symlinks within the path will not be questioned during
deletion/backup, they will be just treated as regular files.

This option will be ignored in MS Windows or in other operating systems that
don't support symlinks.

=cut


=head1 METHODS



=head2 new

Create and configure a new File::CleanupTask object.

The object must be initialised as follows:

    my $cleanup = File::Cleanup->new({
        conf => "/path/to/tasks_file.tasks",
        taskname => 'TASK_LABEL_IN_TASKFILE',
    });

=cut

sub new {
    my $class  = shift;
    my $params = shift;
    my $self   = { params => $params };
    $self->{config_simple} = new Config::Simple;

    $self->{cmd_gzip} = File::Which::which('gzip'); 
    if (!$self->{cmd_gzip}) {
        $self->_warn(
            "No gzip executable found in your path."
             . " Option backup_gzip will be disabled!"
        );
    }
    return bless $self, $class;
}

=head2 command_line_run

Given the arguments specified in the command line, processes them,
creates a new File::CleanupTask object, and then calls C<run>.

Options include I<dryrun>, I<verbose>, I<task> and I<conf>.


=over

=item I<dryrun>: just build and show the plan, nothing will be executed or deleted.

=item I<verbose>: produce more verbose output.

=item I<task>: optional, will result in the execution of the specified task.

=item I<path>: the path to the .tasks configuration file.

=back

=cut

sub command_line_run {
    my $class     = shift;
    my $rh_params = {};

    GetOptions(
        $rh_params,
        'conf=s',             # The path to the task configuration file
        'taskname|task=s',    # The name of the task to be executed (must be
                              # included in the configuration)

        'dryrun',             
        'verbose',
        'help',
      )
      || $class->_usage_and_exit();

    if ( $rh_params->{help} ) {
        $class->_usage_and_exit();
    }

    if ( !$rh_params->{conf} ) {
        $class->_usage_and_exit('Parameter --conf required');
    }

    if ( $rh_params->{dryrun} ) {
        $rh_params->{verbose} = 1; # Implicitly turn on verbose
    }

    $class->new($rh_params)->run();

}


=head2 run

Perform the cleanup

=cut

sub run {

    my $can_symlink = eval { symlink("",""); 1 };

    my $self = shift;
    my @compulsory_values = (qw/path max_days/);
    my %allowed_values = (
        'max_days'                 => '',
        'recursive'                => '',
        'prune_empty_directories'  => '',
        'path'                     => '',
        'keep_if_linked_in'        => '',
        'backup_gzip'              => '',
        'backup_path'              => '',
        'do_not_delete'            => '',
        'delete_all_or_nothing_in' => '',
        'pattern'                  => '',
        'enable_symlinks_integrity_in_path' => '',
    );

    ##
    ## Read tasks file
    ##
    my $config_file = $self->{params}{conf};
    if ( !-e $config_file ) {
        $self->_usage_and_exit("Config file $config_file does not exist");
    }

    $self->{config_simple}->read($config_file);
    
    my %taskfile = $self->{config_simple}->vars();
    foreach my $line ( keys %taskfile ) {
        my ($taskname, $key) = split( /[.]/, $line );
        my $value = $taskfile{$line};

        if (!exists($allowed_values{$key})) {
            $self->_usage_and_exit( 
                "Unrecognised configuration option! '$key' was not recognised!"
                . " Check $self->{params}{conf} and try again.\n"
            );
        }

		if (!$can_symlink 
			&& ($key eq 'enable_symlinks_integrity_in_path'
				|| $key eq 'keep_if_linked_in') ) {

			$self->_warn(
					"The option $key specified for task $taskname will be"
					. " ignored, as your operating system doesn't support"
			        . " symlinks"
			);

		} else {
			$self->{_rhh_task_configs}{$taskname}{$key} = $value;
		}

    }

    ##
    ## Check compulsory values are specified
    ##
    foreach my $ckey (@compulsory_values) {
        foreach my $taskname (keys %{$self->{_rhh_task_configs}}) {
            if (!exists $self->{_rhh_task_configs}{$taskname}{$ckey}) {
                $self->_usage_and_exit( 
					"Compulsory $ckey value hasn't been specified in"
					. " [$taskname] task in $config_file"
                );
            }
        }
    }
    
    ##
    ## Decide which tasks to perform - run all the tasks specified
    ## in the configuration by default. Run a single task if it is specified in
    ## the --task option.
    ##
    my @a_all_tasknames = sort keys %{ $self->{_rhh_task_configs} };
    if ( $self->{params}{taskname} ) {
        if ( grep { $_ eq $self->{params}{taskname} } @a_all_tasknames ) {
            @a_all_tasknames = ( $self->{params}{taskname} );
        }
        else {
            $self->_usage_and_exit("No such task: $self->{params}{taskname}"
                                    . " in $self->{params}{conf}"
            );
        }
    }
        
    ##
    ## This is set once as soonish as the cleanup starts. We want to keep files
    ## that are newer than max_days at script run time. If a file is deleted in
    ## one day, we will keep files newer than 8 days. We expect a cleanup to be
    ## rescheduled in case more recent files need to be deleted.
    ##
    $self->{time} = time;

    ##
    ## Execute each task
    ##
    foreach my $taskname (@a_all_tasknames) {
        $self->run_one_task($self->{_rhh_task_configs}{$taskname}, $taskname);
    }
    $self->_info("-++ Cleanup completed ++-");
}

=head2 run_one_task

Run a single cleanup task given its configuration and name. The name is used as
a label for possible output and is an optional parameter of this method.

This will scan all files and directories in path in a depth first fashion. If a
file is encountered a target action is performed based on the state of that file
(file or directory, symlinked, old, empty directory...).

=cut

sub run_one_task {
    my $self = shift;
    my $rh_task_config = shift;
    my $taskname = shift;
        
    if ($taskname) {
        $self->_info(
              "\n"
              . "\n"
              . " ----------------------------------------------\n"
              . " Task -> [ $taskname ]\n"
              . " ----------------------------------------------\n"
        );
    }

    my $all_or_nothing_path = $rh_task_config->{delete_all_or_nothing_in};
    my $path = $rh_task_config->{path};

    ##
    ## Check that path exists
    ##
    if (!-d $path) {
        $self->_info("Cannot run this task because the path '$path' doesn't");
        $self->_info("exist or is not a directory. Please ignore or provide");
        $self->_info("a valid 'path' in your configuration file"            );
        return;
    }
    
    ##
    ## Check that delete_all_or_nothing_in path exists
    ##
    if ($all_or_nothing_path && !-d $all_or_nothing_path) {
        $self->_info("Cannot run this task because the path ");
        $self->_info("'$all_or_nothing_path' doesn't exist or is not a ");
        $self->_info("directory. Please ignore or provide a valid ");
        $self->_info("'delete_all_or_nothing_in' in your configuration file");
        return;
    }
    
    ##
    ## Check that delete_all_or_nothing is within the cleanup path
    ##
    if ($all_or_nothing_path 
		&& (index($all_or_nothing_path, $path) < 0)) {

        $self->_info("Cannot run this task because the specified");
        $self->_info("delete_all_or_nothing path is not a");
        $self->_info("subdirectory of 'path'");
        return;
    }

    ##
    ## Set the minimum time for deleting files
    ##
    my $max_days = $rh_task_config->{max_days};
    $self->{keep_above_epoch} = $max_days
                              ? $self->{time} - ( $max_days * 60 * 60 * 24 ) 
                              : undef;

    ##
    ## Build never_delete, a list of vital files/dirs that we really don't want
    ## to delete.
    ##
    my $path_symlink = $rh_task_config->{keep_if_linked_in};
    my $path_backup  = $rh_task_config->{backup_path};

    my @paths = ();
    push (@paths, $path_symlink) if ($path_symlink);

    my $rh_never_delete = $self->_build_never_delete(\@paths);

    ##
    ## Build delete_once_empty, a list of directories that should be deleted
    ## only if all their content is deleted
    ##
    my $rh_delete_once_empty;
    if ($all_or_nothing_path) {

        $rh_delete_once_empty = 
            $self->_build_delete_once_empty([$all_or_nothing_path]);

        $self->_print_delete_once_empty($rh_delete_once_empty);
    }

    if ($path_backup) {
        if (!$self->_ensure_path($path_backup)) {
            $self->_info("Cannot create the backup directory!. Terminating.");
            return;
        }
        my $cpath_backup = $self->_path_check($path_backup);
        $rh_task_config->{backup_path} = $cpath_backup;

        $self->_never_delete_add_path(
            $rh_never_delete, 
            $self->_path_check($cpath_backup)
        );

    }
    if ($path) {
        my $cpath = $self->_path_check($path);
        $rh_task_config->{path} = $cpath;
        $self->_never_delete_add_path($rh_never_delete, $cpath);
    }
    
    $self->_print_never_delete($rh_never_delete);

    my $ra_plan = $self->_build_plan({
        never_delete => $rh_never_delete,
        delete_once_empty => $rh_delete_once_empty,
        config    => $rh_task_config,
        path      => $path,
    });
    
    $self->_print_plan($ra_plan);

    $self->_execute_plan({ 
        plan => $ra_plan,
        never_delete => $rh_never_delete,
        config => $rh_task_config,
    });

}

=head2 verbose, dryrun

Accessors that will tell you if running in dryrun or verbose mode.

=cut

sub verbose { return $_[0]->{params}{verbose}; }
sub dryrun  { return $_[0]->{params}{dryrun}; }

=for _build_delete_once_empty
Builds a delete_once_empty of pathnames, each of which should be deleted only if
all its files are also deleted.

=cut

sub _build_delete_once_empty {
    my $self         = shift;
    my $rh_paths     = shift;

    my $rh_delete_once_empty = {};
    my $working_directory = Cwd->getcwd();

    foreach my $p (@$rh_paths) {
        $p = $self->_path_check($p);
        foreach my $f (glob "$p/*") {
            if ( -d $f ) {
                $self->_delete_once_empty_add_path($rh_delete_once_empty, $f) 
            }
        }
    }


    return $rh_delete_once_empty;
}

=for _build_never_delete
Builds a never_delete list of pathnames that shouldn't be deleted at any
condition.

=cut

sub _build_never_delete {
    my $self         = shift;
    my $rh_paths     = shift;

    my $rh_never_delete = {};
    my $working_directory = Cwd->getcwd();

    foreach my $p (@$rh_paths) {
        ##
        ## add the directory itself
        ##
        $p = $self->_path_check($p);
        $self->_never_delete_add_path($rh_never_delete, $p);

        Cwd::chdir($p);
        foreach my $f (glob "$p/*") {

            if ( my $f_target = readlink($f) ) {
                ##
                ## add any symlink within the directory
                ##
                $self->_never_delete_add_path($rh_never_delete, $f);

                ##
                ## add any target of the symlink shouldn't be deleted.
                ##
                $self->_never_delete_add_path($rh_never_delete, $f_target);

                ##
                ## if the target is a directory, add all its children
                ##
                if ( -d $f_target ) {
                    if ( $f_target = $self->_path_check($f_target) ) {
                        # Any children of the target shouldn't be deleted at any
                        # cost.
                        find( 
                            sub { 
                                $self->_never_delete_add_path(
                                    $rh_never_delete, 
                                    $self->_path_check($File::Find::name)
                                );
                            },
                            ($f_target) 
                        );
                    }
                }
            }

        }
        Cwd::chdir($working_directory);
    }


    return $rh_never_delete;
}

=for _never_delete_add_path
Adds a path to the given never_delete list.

=cut

sub _never_delete_add_path {
    my $self         = shift;
    my $rh_never_delete = shift;
    my $path         = shift;

    $path = $self->_path_check($path);

    if (!$path) {
        $self->_warn(
            "Attempt to add empty path to the never_delete list. Ignoring it."
        );
    }
    else {
        $rh_never_delete->{paths}{$path} = 1;
    }

    return;
}

=for _delete_once_empty_contains
Checks if the given path is contained in the delete_once_empty

=cut

sub _delete_once_empty_contains {
    my $self         = shift;
    my $rh_delete_once_empty = shift;
    my $path         = shift;

    return 1 if (exists $rh_delete_once_empty->{paths}{$path});

    return 0;
}

=for _delete_once_empty_add_path
Adds a path to the given delete_once_empty.

=cut

sub _delete_once_empty_add_path {
    my $self = shift;
    my $rh_delete_once_empty = shift;
    my $path = shift;

    $path = $self->_path_check($path);
    if (!$path) {
        $self->_warn(
            "Attempt to add empty path to the delete_once_empty. Ignoring it."
        );
    }
    else {
        # Add the path
        $rh_delete_once_empty->{paths}{$path} = 1;
    }
}

=for _never_delete_contains
Checks if the given path is contained in the never_delete.

=cut

sub _never_delete_contains {
    my $self         = shift;
    my $rh_never_delete = shift;
    my $path         = shift;

    return 1 if (exists $rh_never_delete->{paths}{$path});
    return 0;
}

=for _path_check
Checks up the given path, and returns its absolute representation.

=cut

sub _path_check {
    my $self = shift;
    my $path = shift;

    if (!$path) { $self->_info("No path given to _path_check()"); return; }

    if (-l $path) {
        ##
        ## Get the canonical path of the symlink parent and append the symlink
        ## filename to it.
        ##
        my ($volume,undef,$file) = File::Spec->splitpath($path);
        my $parent = $self->_parent_path($path);
        my $cparent = $self->_path_check($parent);
        return File::Spec->catpath($volume, $cparent, $file);
    }

    return (-e $path) ? Cwd::realpath($path)
                      : File::Spec->canonpath($path);
}

=begin _build_plan

Plans the actions to be executed on the files in the target path according to:

 - options in the configuration
 - the target files
 - the never_delete

All files in the never_delete list can't be deleted.

=end _build_plan

=cut

sub _build_plan {
    my $self      = shift;
    my $rh_params = shift;

    my $path         = $rh_params->{path};
    my $rh_never_delete = $rh_params->{never_delete};
    my $rh_delete_once_empty = $rh_params->{delete_once_empty};
    my $recursive    = $rh_params->{config}{recursive};
    my $prune_empty  = $rh_params->{config}{prune_empty_directories};
    my $dont_del_pattern   = $rh_params->{config}{do_not_delete};

    my $symlinks_integrity = 
        $rh_params->{config}{enable_symlinks_integrity_in_path};

    my @plan = (); # holds a list of lists: (['filename','action']). We need a
                   # list as we need to perform these actions in order.

    my %summary;   # holds the number of files to be deleted vs. the
                   # total number of files for each directory visited.

    my %empties;   # avoid to go into empty dirs again.

    # If "enable_symlinks_integrity_in_path" is true, any symlink will be
    # postprocessed, and the plan will be built as symlinks were not existing.
    # 
    # If this is the case, %sym_integrity will be an hash
    #    key: path to symlink target (canonical)
    #    value: symlink pathname  (non canonical)
    my %sym_integrity;  

    if ($recursive) {
        find( 
          { 'bydepth' => 1,

            'preprocess' => sub {
                my @files = @_;
                ##
                ## Prepare this directory's summary
                ##
                my $dir = $self->_path_check($File::Find::dir);
                if (!exists $summary{$dir}) {
                    $summary{$dir}{'nfiles'}  = 0;
                    $summary{$dir}{'ndelete'} = 0;
                }
                return @files;
            },

            'wanted' => sub {
                ##
                ## Update actions and collect summary
                ##
                my $f = $File::Find::name;


                my $will_check_integrity;
                if ($symlinks_integrity) { 

                    $will_check_integrity = 
                        $self->_postprocess_link(\%sym_integrity, $f);
                }

                if (!$will_check_integrity) { 

                    my $dir = $self->_path_check($File::Find::dir);

                    if (!exists $empties{$f}) {

                        my @actions = 
                            @{ $self->_plan_add_actions (
                                \@plan, 
                                $f, 
                                $rh_params
                            )};

                        foreach my $action (@actions) {
                            ## 
                            ## count deleted items
                            ##
                            if ($action eq 'delete' && (-f $f || -l $f)) {
                                $summary{$dir}{'ndelete'} += 1; 
                            }

                            ## count total items
                            $summary{$dir}{'nfiles'}++;
                        }
                    }

                }
            }, 

            'postprocess' => sub {
                ##
                ## Consider deleting a directory given the actions performed on
                ## the files it contains.
                ##
                my $dir  = $self->_path_check($File::Find::dir);
                my $nf   = $summary{$dir}{'nfiles'};
                my $ndel = $summary{$dir}{'ndelete'};

                my $action = 'nothing';
                my $reason = 'default';

                if (!$prune_empty) {
                    ($action, $reason) = ('nothing', 'no prune empty');
                }
                elsif ($self->_never_delete_contains($rh_never_delete, $dir)) {
                    ($action, $reason) = ('nothing', 'never_deleted');
                }
                elsif ($ndel < $nf) {
                    ($action, $reason) = (
                        "nothing", 
                        "will contain files ($ndel/$nf deleted)"
                    );
                }
                else {
                    ##
                    ## May delete if all these conditions are met:
                    ## - prune_empty is on
                    ## - the directory is or will be empty (all files deleted)
                    ## - the directory is not never_deleted
                    ## - the directory is older than max_days old if specified
                    ##


                    # Delete only if the directory doesn't match the pattern
                    my $matches;
                    if ($dont_del_pattern) {

                        $dont_del_pattern = 
                            $self->_fix_pattern($dont_del_pattern);

                        $matches = ($dir =~ m@$dont_del_pattern@gsx)
                    }
                    if ($matches) {
                        ($action, $reason) 
                            = ("nothing", "'do_not_delete' matched");
                    }
                    else {
                        my $d_time = (stat($dir))[9]; # mtime
                        if (! defined($d_time)) {
                            ($action, $reason) = ('nothing', "unable to stat");
                        }
                        elsif ($self->{keep_above_epoch} &&
                            $d_time >= $self->{keep_above_epoch}) {

                            ($action, $reason) = ('nothing', "new directory");

                        }
                        else {
                            ##
                            ## Delete the directory
                            ##
                            my $verb = $self->_is_folder_empty($dir) ? 'is' 
                                                                    : 'will be';

                            ($action, $reason) 
                                = ('delete', sprintf('%s empty', $verb));

                            $empties{$dir} = 1;
                        }
                    }
                }

                ##
                ## Add the action to the plan
                ##
                $self->_plan_add_action( \@plan, 
                    { action => $action, 
                      reason => $reason,
                      f_path => $dir,
                    }
                );

                ##
                ## Sum up what we found to the parent directory
                ##
                if ( my $f_parent = $self->_parent_path($dir)) {
                    $summary{$f_parent}{'nfiles'}  += $nf;
                    $summary{$f_parent}{'ndelete'} += $ndel;
                }
            }
          },

          ($self->_path_check($path))  # The path to visit

        );
    }
    else {
        ##
        ## Non recursive
        ##
        my $cpath = $self->_path_check($path);
        foreach my $f (glob "$path/*") {

             my $will_check_integrity;
             if ($symlinks_integrity) { 
                 $will_check_integrity = 
                    $self->_postprocess_link(\%sym_integrity, $f);
             }

             if (!$will_check_integrity) {

                 $f = $self->_path_check($f);

                 ##
                 ## Update actions
                 ##
                 $self->_plan_add_actions(\@plan, $f, $rh_params);

                 ##
                 ## Now check if the directory is empty
                 ##
                 if ( -d $f && 
                      $prune_empty && 
                      $self->_is_folder_empty($f) &&
                      (!$self->_never_delete_contains($rh_never_delete, $f)) &&
                      (! $self->{keep_above_epoch} || (stat($f))[9] <= $self->{keep_above_epoch})) {


                        $self->_plan_add_action( \@plan, 
                            { action => 'delete', 
                              reason => 'is_empty',
                              f_path => $f,
                            }
                        );
                 }
             }
        }
    }

    ##
    ## Now should fix the plan taking internal symlinks into account
    ##
    return $self->_refine_plan(
        \@plan, 
        { never_delete => $rh_never_delete, 
          delete_once_empty => $rh_delete_once_empty,
          symlinks  => \%sym_integrity
        }
   );
}

=begin _plan_add_actions

Given a path to a file and the task configuration options, augment the plan
with actions to take on that file.

Returns the array containing one or more actions performed.

These actions are meant to be performed in reverse sequence on the given file.
An empty array_ref is returned if no action is to be performed on the given
file.

A returned action can be one of: delete, backup. 

Resulting actions are decided according to one or more of the followings:

 - options in the configuration
 - the target files
 - the never_delete

This method works under the assumption that the specified file or directory
exists and the user has full permissions on it.

=end _plan_add_actions

=cut

sub _plan_add_actions {
    my $self      = shift;
    my $ra_plan   = shift;
    my $f         = shift;
    my $rh_params = shift;

    my $backup_path      = $rh_params->{config}{backup_path};
    my $dont_del_pattern = $rh_params->{config}{do_not_delete};
    my $pattern          = $rh_params->{config}{pattern};

    my @actions = ();

    my $action; # undef = ignore (note, this is different from "nothing")
    my $reason; 


    # deal with directories in the caller
    if (-d $f && !-l $f) { 
        return \@actions 
    }

    ## Only deal with files/symlinks from now on
    ##

    if ($self->_never_delete_contains($rh_params->{never_delete}, $f)) {
        ##
        ## In never_delete
        ##
        ($action, $reason) = ('nothing', 'in never_delete');
    }
    else {
        ##
        ## Decide if the file must be considered
        ##
        my $file_must_be_considered = 1; # default: yes (i.e., may delete it)
        if ($pattern) {
            $pattern = $self->_fix_pattern($pattern);
            $file_must_be_considered = ($f =~ m@$pattern@gsx);
        }

        ##
        ## Decide if the file must be kept
        ##
        my $file_must_be_kept;           # default: no (i.e., may delete it)
        if ($dont_del_pattern) {
            $dont_del_pattern = $self->_fix_pattern($dont_del_pattern);
            $file_must_be_kept = ($f =~ m@$dont_del_pattern@gsx);
        }

        ##
        ## Take decisions
        ##
        if (!$file_must_be_considered) {
            ($action, $reason) = ('nothing', "'pattern' did not match");
        }
        else {
            if ($file_must_be_kept) { 
                ($action, $reason) = ('nothing', "'do_not_delete' matched");
            }
            else {
                ##
                ## Perform an action on the file (delete/backup) according to
                ## the given criteria (max_days for now)
                ##

                ## Make sure we get the time from the symlink rather than the
                ## linked file (if $f is a symlink)
                my $f_time;
                if ($Config{d_lstat} && -l $f) {
                    $f_time = (lstat($f))[9];
                } else {
                    $f_time = (stat($f))[9];
                }
                if ( !defined($f_time) ) {
                    ($action, $reason) = ('nothing', "unable to stat");
                }
                elsif ( $self->{keep_above_epoch} 
                        && $f_time >= $self->{keep_above_epoch} ) {

                    ($action, $reason) = ('nothing', "new file");

                }
                else {
                    ##
                    ## This is an old file
                    ##
                    if ($backup_path) { 
                        ($action, $reason) = ('backup', 'old file');
                    }
                    else { 
                        ($action, $reason) = ('delete', 'old file');
                    }
                }
            }
        }
    }

    if ($action) {
        push (@actions, $action);
        $self->_plan_add_action( $ra_plan ,
            { action => $action,
              reason => $reason,
              f_path => $f
            }
        );
    }

    return \@actions;
}

=for _plan_add_action
Adds the given action to the plan.

=cut

sub _plan_add_action {
    my $self      = shift;
    my $ra_plan   = shift;
    my $rh_action = shift;
    my $add_to_top= shift;

    # perl 5.8.9 compatibility
    $add_to_top = defined $add_to_top ? $add_to_top
                                      : 0;

    if ($add_to_top) {
        unshift (@$ra_plan, 
            [ $rh_action->{reason},
              $rh_action->{f_path},
              $rh_action->{action}
            ]
        );
    }
    else {
        push (@$ra_plan, 
            [ $rh_action->{reason},
              $rh_action->{f_path},
              $rh_action->{action}
            ]
        );
    }
}

=for _is_folder_empty
Returns 1 if the given folder is empty.

=cut

sub _is_folder_empty { 
    my $self    = shift;
    my $dirname = shift; 
    opendir(my $dh, $dirname) or die "Not a directory"; 
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0; 
}

=for _execute_plan
Execute a plan based on the given task options. Blacklist is passed to make
sure once again that no unwanted files or directories are deleted.

=cut

sub _execute_plan {
    my $self      = shift;
    my $rh_params = shift;

    my $rh_never_delete = $rh_params->{never_delete};
    my $rh_config   = $rh_params->{config};
    my $ra_plan     = $rh_params->{plan};

    my $backup_path = $rh_config->{backup_path};
    my $backup_gzip = $rh_config->{backup_gzip};
    my $path        = $rh_config->{path};

    my $working_directory = Cwd->getcwd();

    Cwd::chdir($path);                     # Needed for backup

    while ( my $ra_plan_item = pop @$ra_plan ) {
        my ($desc, $f, $action) = @$ra_plan_item;

        if ($action eq 'delete') {
            ##
            ## Delete here
            ## 
            if ($self->dryrun) {
                $self->_info("-- dryrun [rmtree] --> $f");
            }
            else {
                $self->_info("Deleting $f");
                File::Path::rmtree($f);
            }
        }
        elsif ($action eq 'backup') {
            ##
            ## Do backup as requested. Ensure:
            ##
            ## - from is the path to a file
            ## -  to is the path to a directory of the form
            ##    "<backup_dir>/<relative-from-path>/"
            ##
            my $from = File::Spec->abs2rel( $f, $path );
            my $from_filename = File::Basename::fileparse($f);
            my $to   = sprintf("%s/%s", $backup_path, $from);

            $to =~ s/$from_filename//; 

            $from =~ s#/+#/#g;         # clean multi-slashes
            $to   =~ s#/+#/#g;         #  

            if ( $self->_ensure_path($to) ) {
                ##
                ## Target path now exists - now the target is expected to be a
                ## filename with .gz extension.
                ##
                if ( $backup_gzip && $self->{cmd_gzip} ) {
                    ## 
                    ## Gzip in case
                    ##
                    if ( $from
                         && ($from !~ /[.](gz|tgz)$/i) # do not re-gzip
                         && (!readlink($from))         # do not gzip symlinks
                    ){
                        $self->_info("Gzipping $from");
                        my $ra_cmd = [$self->{cmd_gzip}, '--force', $from ];

                        my $cmd_txt = join(" ", @$ra_cmd);
                        if ($self->dryrun) { 
                            $self->_info("-- dryrun [gzip cmd] --> $cmd_txt");
                        }
                        else {
                            $self->_info("Running $cmd_txt");
                            run3($ra_cmd);
                        }
                        $from .= '.gz';
                    }
                    else {
                        $self->_info("$from appears to be already gzipped");
                    }
                }

                #
                # Move from -> to
                #
                my $to_file = sprintf("%s/%s", $backup_path, $from);
                if ($self->dryrun) { 
                    $self->_info("-- dryrun [mv] $from --> $to_file");
                }
                else {
                    $self->_info("mv $from to $to_file");
                    if (!move( $from, $to_file ) ){
                        $self->_warn("Unable to move. Dying...");
                        die sprintf("Unable to move $from to $to_file: %s", $!);
                    }
                }
            }
        }
    }
    
    Cwd::chdir($working_directory);
}

sub _ensure_path {
    my $self = shift;
    my $path = shift;

    if ( !-e $path || !-d $path ) {
        $self->_info("[making path] $path");
        eval { File::Path::mkpath($path) };
        $self->_warn("Unable to create $path: $@") if ($@);
    }

    if ( !-e $path || !-d $path ) {
        $self->_warn("Path wasn't found after trying to create it."); 
        return 0;
    }
    return 1;
} 

=begin _refine_plan

Takes into account symlinks in the current plan.

The refinement is done in the following way:

1) Go through the plan, and look for symlink targets.

2) Mark any symlink with as the action of it's target if it's in the cleanup
   directory: keep the symlink if its target is kept, delete otherwise (broken
   symlinks, or pointing outside the cleanup, target is being backupped...).
   While deciding this, build an hashref of 
   { symlink_parent (canonical) => symlink_path (non_canonical) }.

3) Add the symlink to the plan in the correct position.
   To do this, build another 'refined' plan.
   - go hrough the pathnames (visits parents first) in the plan, pop each item.
   - if the parent of a marked symlink is found, do the following:
     * mark it as 'delete' if the symlink is going to be deleted.
       or mark it as 'nothing' if the symlink is not going to be deleted.
     * push the parent in the refined plan.
     * push the symlink in the refined plan.

4) Fix the plan to have consistent state (bubble up states between pairs of
   directories)

Return the refined plan.

=end _refine_plan

=cut

sub _refine_plan {
    my $self        = shift;
    my $ra_plan     = shift;
    my $rh_params   = shift;

    my $rh_never_delete = $rh_params->{never_delete};
    my $rh_delete_once_empty = $rh_params->{delete_once_empty};

    # this is:
    #  { symlink_target   (canonical) =>
    #    [ symlink_path (non canonical) ]
    #  }
    my $rh_symlinks  = $rh_params->{symlinks};

    ##
    ## Symlinks to delete and keep
    ##
    my %symlinks_marked; # this is:
                         # { symlink_parent (canonical) => [
                         #    { symlink_path => symlink_path (non canonical),
                         #      action       => 'delete'
                         #    }
                         #   ],...
                         # }

    foreach my $ra_item (@{$ra_plan}) {                 # 1
        my ($reason, $f, $action) = @$ra_item;

        if (exists $rh_symlinks->{$f}) {
            # 2 - Keep the symlink if its target is kept, delete otherwise
            foreach my $sym_path (@{$rh_symlinks->{$f}}) {

                my $sym_cparent = $self->_path_check(
                    $self->_parent_path($sym_path)
                );

                my $sym_action  = ($action eq 'nothing') ? 'nothing' : 'delete';
                  
                # two symlinks may be in the same directory, 
                if (!exists $symlinks_marked{$sym_cparent}) {
                    $symlinks_marked{$sym_cparent} = [];
                }
                
                push( @{$symlinks_marked{$sym_cparent}},
                      { symlink_path => $sym_path,
                        action       => $sym_action
                      }
                );
            }
        }
    }
    
    # 3
    my $rh_undelete_dirs = {};
    my $ra_refined_plan = [];
    while ( my $ra_item = pop @{$ra_plan} ) {             
        my ($reason, $f, $action) = @$ra_item;
        if (!exists $symlinks_marked{$f} ) {
            # just re-add it
            $self->_plan_add_action( $ra_refined_plan, 
                { action => $action,
                  reason => $reason,
                  f_path => $f,
                }
            );
        }
        else {
            # fix the action of a symlink parent - keep the parent if at least
            # one symlink in it is kept.
            my @sym_nothing = 
                grep { $_->{action} eq 'nothing' } @{$symlinks_marked{$f}};

            my $f_action;
            my $f_reason;
            if (scalar @sym_nothing) { # at least one symlink to be kept
                $f_action = 'nothing';
                $f_reason = 'refined (1+ symlink kept in it)';

                # Propagate to the parent
                my $f_parent = $self->_parent_path($f);
                $rh_undelete_dirs->{ $f_parent } = 1 if $f_parent;
            }
            else {
                $f_action = $action;
                $f_reason = 'refined (all symlinks will be deleted)';
            }
            # Add the symlink parent with the updated action
            $self->_plan_add_action( $ra_refined_plan, 
                { action => $f_action, 
                  reason => $f_reason,
                  f_path => $f,
                }
            );

            # Add the action on each symlink's path
            foreach my $rh_item (@{$symlinks_marked{$f}}) {
                $self->_plan_add_action( $ra_refined_plan, 
                    { action => $rh_item->{action},
                      reason => 'refined',
                      f_path => $rh_item->{symlink_path},
                    }
                );
            }
        }
    }

    # 4 - fix inconsistent directory state (and reverse the plan again)
    #
    my @refined_plan_fixed;
    my $add_to_head = ($rh_delete_once_empty) ? 0 : 1;
    while ( my $ra_item = pop @$ra_refined_plan ) {
        my ($reason, $f, $action) = @$ra_item;
        if (-d $f && !-l $f) {
            ##
            ## Directory
            ##
            if ($rh_undelete_dirs->{$f}) {
                $action = 'nothing';
                $reason = "bubbled (was: $reason)";

                # also propagate to the parent
                my $f_parent = $self->_parent_path($f);
                $rh_undelete_dirs->{$f_parent} = 1 if $f_parent;
            }
        }
        ## 
        ## Add current item to the list
        ##
        $self->_plan_add_action( \@refined_plan_fixed, 
            { action => $action,
              reason => $reason,
              f_path => $f
            }
            , $add_to_head
        );
    }

    return \@refined_plan_fixed if (!$rh_delete_once_empty);

    my @final_plan;
    my $propagate_action;
    while ( my $ra_item = pop @refined_plan_fixed ) {
        my ($reason, $f, $action) = @$ra_item;
        ##
        ## Check if we have to stop any previous propagation at this round.
        ##
        if ($propagate_action) { 

            $propagate_action = (index($f, $propagate_action) == 0)
                                ? $propagate_action
                                : 0 ;

        }

        ##
        ## See if we should propagate the 'nothing' action to any children
        ##
        if (!$propagate_action              # we are not propagating...
            && $self->_delete_once_empty_contains(   # toplevel directory found
                $rh_delete_once_empty, 
                $f
            ) 
            && $action eq 'nothing'  ) {    # ... which we don't want to delete
            
            $propagate_action = $f;         # propagate until /^<parent>/
                                            # matches $f from this round
        }

        if ($propagate_action  
            && $f ne $propagate_action ) {  # aesthetics only

            $reason = 'all or none';
            $action = 'nothing';
        }

        $self->_plan_add_action( \@final_plan, 
            { action => $action,
              reason => $reason,
              f_path => $f
            }
        );
    }

    return \@final_plan;
}

=for _parent_path
Get the parent path of a given path. This method only accesses the disk if the
f_path is found to have no parent directory (i.e., just the relative file name
has been specified).  In this case, we check that the current working directory
contains the given file. If yes, we return the current working directory as the
parent of the specified file. If not, we return undef.

=cut

sub _parent_path {
    my $self   = shift;
    my $f_path = shift;

    if (!$f_path) {
        $self->_warn("No path was given to _parent_path()");
        return undef;
    }

    my ($volume, $directories, $file) = File::Spec->splitpath($f_path);

    ##
    ## Try to reconstruct the full pathname of the parent of a relative $f_path
    ##
    if (!$directories) {
        my $cwd = Cwd->getcwd();
        if (-e File::Spec->catpath($volume, $cwd, $file)) {
            $self->_info("Returning $cwd as the parent path for $file");
            return $cwd;
        }
        else {
            $self->_warn("The relative pathname $f_path was given to"
                . "_parent_path(), but such target doesn't exist in the current"
                . "working directory ($cwd)."
            );
            return undef;
        }
    }

    my $f_parent = File::Spec->catpath($volume, $directories, '');
    $f_parent =~ s#/$##g;

    return $f_parent;
}


=begin _postprocess_link

Given a path to a symlink and a hash reference, keep the symlink target as a
key of the hash reference (canonical path), and the path to the symlink (non
canonical) as the corresponding value. Because multiple symlinks can point to
the same target, the value of this hashref is an arrayref of symlinks paths.

Returns true on success, or false if a path to something else than a symlink is
passed to this method.

=end _postprocess_link

=cut

sub _postprocess_link {
    my $self        = shift;
    my $rh_symlinks = shift;
    my $sym_path    = shift;

    if (my $sym_target = readlink($sym_path)) { # check if this is a symlink
        my $sym_target_cpath = $self->_path_check($sym_target);
        if (!exists $rh_symlinks->{$sym_target_cpath}) {
            $rh_symlinks->{$sym_target_cpath} = [];
        }
        push (@{$rh_symlinks->{$sym_target_cpath}}, $sym_path);

        return 1;
    }

    # $sym_path is not a path to a symlink
    return 0;
}

=begin _fix_pattern

Refine a pattern passed from the configuration.

Currently applyes the following transformation:
    - Remove any "/" in case the user has specified a pattern in the form of
      /pattern/.

=end _fix_pattern

=cut

sub _fix_pattern {
    my $self    = shift;
    my $pattern = shift;

    if ($pattern =~ m{^/(.*)/$}) {
        $pattern = $1;
    }
    return $pattern;
}


sub _print_never_delete {
    my $self = shift;
    my $rh_never_delete = shift;
    if ( !scalar keys %$rh_never_delete ) {
        $self->_info ("- - - [ NO NEVER DELETE FILES] - - -");
    }
    else {
        $self->_info ("- - - [ NEVER DELETE ] - - -");
        foreach my $path (keys %{$rh_never_delete->{paths}}) {
            $self->_info (sprintf("* %s", $path));
        }
        $self->_info ("");
    }
}

sub _print_delete_once_empty {
    my $self = shift;
    my $rh_delete_once_empty = shift;
    if ( !scalar keys %$rh_delete_once_empty ) {
        $self->_info ("- - - [ NO DELETE ONCE EMPTY ] - - -");
    }
    else {
        $self->_info ("- - - [ DELETE ONCE EMPTY ] - - -");
        foreach my $path (keys %{$rh_delete_once_empty->{paths}}) {
            $self->_info (sprintf("* %s", $path));
        }
        $self->_info ("");
    }
}
sub _print_plan {
    my $self    = shift;
    my $ra_plan = shift;

    my $i = 1 + scalar @$ra_plan;
 
    if ( !$ra_plan || !scalar @$ra_plan ) {
        $self->_info ("- - - [ EMPTY PLAN ] - - -");
    }
    else {
        $self->_info ("- - - [ PLAN ] - - -");
        foreach my $ra_plan_item (@$ra_plan) {
            $i--;

            my ($reason, $f, $action) = @$ra_plan_item;
            $self->_info(
                sprintf("%2d) [%7s] %14s - %s", $i, $action, $reason, $f)
            );
        }
    }
    $self->_info ("");
}

sub _info {
    my $self    = shift;
    my $message = shift;
    print " [INFO] $message\n" if $self->verbose;
}

sub _warn {
    my $self    = shift;
    my $message = shift;
    warn " [WARN] $message";
}

sub _usage_and_exit {
    my $self    = shift;
    my $message = shift;

    print <<"END";
$0
    required:
        --conf      a tasks configuration file
        --taskname  a task from within the tasks file
        
    optional:
        --dryrun    output plan and then exit
        --verbose   make some noise!
        --help      show this message

For more information and documentation for how to write task config files see
'perldoc File::CleanupTask'.

END
    if ($message) {
        die( $message . "\n" );
    }
    else {
        exit;
    }
}

=head1 AUTHOR

Savio Dimatteo, C<< <savio at lokku.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-cleanuptask at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-CleanupTask>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::CleanupTask


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-CleanupTask>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-CleanupTask>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-CleanupTask>

=item * Search CPAN

L<http://search.cpan.org/dist/File-CleanupTask/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks Alex for devising the original format of a .tasks file and offering me
the opportunity to publish this work on CPAN.

Thanks Mike for your feedback about canonical paths detection.

Thanks David for reviewing the code.

Thanks #london.pm for helping me choosing the name of this module.


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Savio Dimatteo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::CleanupTask
