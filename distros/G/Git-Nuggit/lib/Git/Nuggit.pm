#!/usr/bin/env perl
package Git::Nuggit;
our
$VERSION = 1.01;
# TIP: To format documentation in the command line, run "perldoc nuggit.pm"

use v5.10;
use strict;
use warnings;
use Cwd qw(getcwd);
use Term::ANSIColor 4.00 qw(coloralias);
use Git::Nuggit::Log;
use Cwd qw(getcwd);
use IPC::Run3;
use File::Spec;
use JSON;
use File::Slurp qw(read_file write_file);

our @ISA = qw(Exporter);
our @EXPORT = qw(get_submodules list_submodules_here submodule_foreach find_root_dir nuggit_init get_remote_tracking_branch get_selected_branch_here get_selected_branch do_upcurse check_merge_conflict_state get_branches);

# Nuggit Color Scheme
#  TODO: $ngt constructor may override these if alternate scheme is specified in .nuggit/config
#  TODO: Consider built-in theme alternatives including: no colors, or 'color-blind' mode that primarily utilizes bold/underline/italics instead
# NOTE: This will override any values in ANSI_COLORS_ALIASES env variable
coloralias('error', 'red');
coloralias('warn', 'yellow');
coloralias('info', 'cyan');
coloralias('success', 'green');

=head1 Nuggit Library

This library provides common utility functions for interacting with repositories using Nuggit.

=head1 Procedural Methods

=cut

=head2 get_submodules()

Return an array of all submodules from current (or specified) directory and below listed depth-first, queried via git submodule foreach.

NOTE: Direct usage of submodule_foreach() is preferred when possible.

=cut

sub get_submodules {
    my $dir = shift;
    my $old_dir = getcwd();
    chdir($dir) if defined($dir);
    my @modules;
    submodule_foreach(sub {
                          push(@modules, getcwd() );
                      });
    chdir($old_dir) if defined($dir);

    return \@modules;
}

=head2 list_submodules_here([path])

Return an array listing all submodules of the current (or specified) directory.  This function uses 'git config' to parse the .gitmodules file and is NOT recursive.

=cut

sub list_submodules_here {
    my $path = shift;
    my $file = ".gitmodules";
    $file = File::Spec->catfile($path, $file) if $path;

    return undef unless -e $file;

    my $rtv = `git config --file $file --get-regexp path | awk '{ print \$2 }'`;
    chomp($rtv);

    my @rtv = split('\n', $rtv);

    return \@rtv;
}


=head2 submodule_foreach(fn)

WARNING: This function is now deprecated in favor of $ngt->foreach and will be phased out in a future release.

Recurse into each submodule and execute the given command. This is roughly equivalent to "git submodule foreach"

Parameters:

=over

=item fn

Callback function to be called foreach submodule found.  CWD will be at root of current submodule.

Callback will always be called starting from the deepest submodule.

Function will be called with

-parent Relative path from root to parent
-name   Name of submodule.  $name/$parent is full path from root
-status If modified, '+' or '-' as reported by Git
-hash   Commit SHA1
-label  Matching Branch/Tag as reported by Git (?)


=over 20

=item parent Relative path from root to parent

=item name   Name of submodule.  $name/$parent is full path from root

=item status If modified, '+' or '-' as reported by Git

=item hash   Commit SHA1

=item label  Matching Branch/Tag as reported by Git (?)

=back


=item opts

Hash containing list of user options.  Currently supported options are:

=over

=item recursive If false, do not recurse into nested submodules

=item breadth_first_fn
If defined, execute this callback function prior to recursing into nested submodules.

The main callback function is executed after visiting all nested submodules.

=item recursive

If set, or undefined, recurse into any nested submodules. If set to 0, only visit submodules of the current repository.

=item TODO/FUTURE: parallel

If defined, parse each submodule in parallel using fork/wait

=item FUTURE: Option may include a check if .gitmodules matches list reported by git submodule

=back

=item parent

Path of Parent Directory. In each recursion, the submodule name will be appended.

=back

=cut

sub submodule_foreach {
    my ($fn, $opts);
    if (ref $_[0] eq "CODE") {
        $fn = shift;
        $opts = shift;
    } else {
        $opts = shift;
        $fn = $opts->{'depth_first_fn'};
    }
  my $parent = shift || ".";
  my $cwd = getcwd();

  if (!-e '.gitmodules')
  {
      return; # early if there are no submodules (for faster execution)
  }
  my $list = `git submodule`;

  # TODO: Consider switching to IPC::Run3 to check for stderr for better error handling
  if (!$list || $list eq "") {
    return;
  }

  my @modules = split(/\n/, $list);
  while(my $submodule = shift(@modules))
  {
      my $status = substr($submodule, 0,1);
      $status = 0 if ($status eq ' ');
      
      my @words = split(/\s+/, substr($submodule, 1));
      
      my $hash   = $words[0];
      my $name = $words[1];
      my $label;
      $label = substr($words[2], 1, -1) if defined($words[2]); # Label may not always exist

      # Enter submodule
      chdir($name) || die "submodule_foreach can't enter $name";

      # Pre-traversal callback (breadth-first)
      if (defined($opts) && defined($opts->{breadth_first_fn}) ) {
          $opts->{breadth_first_fn}->($parent, $name, $status, $hash, $label, $opts);
          chdir(File::Spec->catdir($cwd,$name)) || die "Error returning to directory"; # In case caller changes folder
      }


      # Recurse
      if (!$opts || !defined($opts->{recursive}) || (defined($opts->{recursive}) && $opts->{recursive})) {
          submodule_foreach($fn, $opts, File::Spec->catdir($parent,$name));
      }

      # Callback (depth-first)
      $fn->($parent, $name, $status, $hash, $label, $opts) if $fn;

      # Reset Dir
      chdir($cwd);
    
  }
  
}

=head2 find_root_dir

Returns the root directory of the nuggit, or undef if not found
Also navigate to the nuggit root directory

=cut

# note a side effect is that this will change to the nuggit root directory
# consider returning to the cwd and making the caller chdir to the root
# dir if desired.
sub find_root_dir
{
    my $cwd = getcwd();
    my $nuggit_root;
    my $path = "";

    my $max_depth = 10;
    my $i = 0;

    for($i = 0; $i < $max_depth; $i = $i+1)
    {
        # .nuggit must exist inside a git repo
        if(-e ".nuggit" && -e ".git") 
        {
            $nuggit_root = getcwd();
            #     print "starting path was $cwd\n";
            #     print ".nuggit exists at $nuggit_root\n";
            $path = "./" unless $path;
            chdir($cwd);
            return ($nuggit_root, $path, $cwd);
        }
        chdir "../";
        $path = "../".$path;
  
        #  $cwd = getcwd();
        #  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
    }
    chdir($cwd);
    return undef;
}

=head1 nuggit_init

Initialize Nuggit Repository by creating a .nuggit file at current location.

=cut

sub nuggit_init
{
    if (-e ".not_a_nuggit") {
        say read_file(".not_a_nuggit") if -f ".not_a_nuggit";
        die("'.not_a_nuggit' detected, Nuggit will not be initialized for this folder. If you wish to use nuggit at this level anyway, remove this file and run 'ngt init'.\n");
    }
    die("nuggit_init() must be run from the top level of a git repository.\n") unless -e ".git";
    mkdir(".nuggit"); # This should fail silently if folder already exists

    # Git .git dir (this handles non-standard directories, including bare repos and submodules)
    my $git_dir = `git rev-parse --git-dir`;
    chomp($git_dir);

    system("echo \".nuggit\" >> $git_dir/info/exclude");

}

=head2 get_remote_tracking_branch

Get the name of the default branch used for pushes/pulls for this repository.

NOTE: This function may serve as the basis for an improved get_selected_branch() function that retrieves additional information.

=cut

sub get_remote_tracking_branch
{
    my $data = `git branch -vv`;
    my @lines = split(/\n/,$data);
    foreach my $line (@lines) {
        if ($line =~ /^\*\s/) {
            # This line is the current branch
            if ($line =~ /\'([\w\-\_\/]+)\'$/) {
                return $1;
            } else {
                say "No branch matched from $line";
                return undef; # No remote tracking branch defined
            }
        }
    }
    die "Internal ERROR: get_remote_tracking_branch() couldn't identify current branch"; # shouldn't happen
}

=head2 get_selected_branch_here

?

=cut

sub get_selected_branch_here()
{
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);
}




=head2 get_selected_branch

 get the checked out branch from the list of branches
 The input is the output of git branch (list of branches)

=cut

sub get_selected_branch
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* // if $selected_branch;

  if ($selected_branch =~ /^\(HEAD detached/) {
      # If in a detached HEAD state, return undef
      return undef;
  } else {  
      return $selected_branch;
  }
}

=head2 get_branches

Get a listing of all branches in the current repository/directory.

Supported options (passed directly to git) include:
- get_branches() - Return a list of all local branches
- get_branches("-a") - Return a list of all local+remote branches (ie: $branch or remotes/origin/$branch)
- get_branches("-r") - Return a list of all remote branches (ie: origin/$branch)
- get_branches("--merged")
- get_branches("--no-merged")

Returns a hash where key is branch name and value will be a hash with any known details.

=cut
sub get_branches
{
    my $opts = shift;
    my $cmd = "git branch -vv ";

    if (ref($opts)) {
        $cmd .= "-a " if $opts->{all};
        if (defined($opts->{merged})) {
            $cmd .= ($opts->{merged}) ? "--merged" : "--no-merged";
        }
    } elsif ($opts) {
        $cmd .= $opts; # String opts given
    }
        
    # execute git branch
    my $raw = `$cmd`;
    my %rtv;
    my @lines = split("\n", $raw);

    foreach my $line (@lines) {
        if ($line =~ /HEAD detached at ([0-9a-fA-F]+)/) {
            # Special handling
            $rtv{'HEAD'} = {commit => $1};
        } elsif ($line =~ /HEAD\s+->\s/) {
            my ($name, $link) = $line =~ m{([\d\w\-\_/]+)\s+->\s+(.+)};
            $rtv{$name} = {name => $name, link => $link};
        } else {
            $line =~ m/^(?<selected>\*)?\s+(?<name>\S+)\s+(?<commit>[0-9a-fA-F]+)\s+(?<upstream>\[\S+\])?\s*(?<msg>.*)/;
            my %obj = %+;

            # Aide parsing when -a is used
            if ($obj{name} =~ m{remotes/([\w+])/(.+)}) {
                $obj{remote} = $1;
                $obj{remote_branch} = $2;
            } elsif ($opts && $opts eq "-r") { # or -r
                my ($remote,$branch) = $obj{name} =~ m{(\w+)/(.+)};
                $obj{remote} = $1;
                $obj{remote_branch} = $2;
                $obj{remote_full_name} = $obj{name};
                $obj{name} = $obj{remote_branch};
            }
            $rtv{$obj{name}} = \%obj;
        }
    }
    return \%rtv;
}

=head2 do_upcurse

Find the top-level of this project and chdir into it.  If not a nuggit project, 'die'

Returns root_dir since this is often needed by callers. (FUTURE: This should be an OOP method, in which case this return value would be deprecated in favor of class variable)

=cut

sub do_upcurse
{
    my $verbose = shift;
    
    my ($root_dir, $relative_path_to_root) = find_root_dir();
    die("Not a nuggit!\n") unless $root_dir;

    print "nuggit root dir is: $root_dir\n" if $verbose;
    print "nuggit cwd is ".getcwd()."\n" if $verbose;
    print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;
    
    #print "changing directory to root: $root_dir\n";
    chdir $root_dir;
    return $root_dir;
}

=head2 check_merge_conflict_state()

Checks if a merge operation is in progress, and dies if it is.

This function should be called with the path to the nuggit root repository or with that as the current working directory.

DEPRECATED - Use $ngt->merge_conflict_state(1) instead

=cut

sub check_merge_conflict_state
{
    my $root_dir = shift || '.';
    if( -e "$root_dir/.nuggit/merge_conflict") {
        die "A merge is in progress.  Please complete with 'ngt merge --continue' or abort with 'ngt merge --abort' before proceeding.";
    }
}

=head1 Object Oriented Interface

The following is an initial cut at an OOP interface.  The OOP interface is incomplete at this stage
 and serves primarily as a convenience wrapper for other commands, and Nuggit::Log

=cut

sub new
{
    my ($class, %args) = @_;
    # This is a Singleton library, handled transparently for the user
    # Note: At present, singleton logic is for optimization only. The bypass_singleton flag can be used to instantiate a new instance, intended only for usage by test drivers.
    state $instance;
    if (defined($instance) && (!defined($args{'bypass_singleton'}) || !$args{'bypass_singleton'})) {
        # If previously initialized, do not re-initialize
        return $instance;
    }

    my ($root_dir, $relative_path_to_root, $user_dir) = find_root_dir(); # TODO: Move all functions into namespace & export
    $args{root} = $root_dir; # For Logger initialiation

    return undef unless $root_dir; # Caller is responsible for aborting if Nuggit is required
   
    # Create our object
    $instance = bless {
        logger => Git::Nuggit::Log->new(%args),
        root => $root_dir,
        relative_path_to_root => $relative_path_to_root,
        user_dir => $user_dir, # Original path user executed script from
        verbose => $args{verbose},
        # Command execution defaults (TODO: setters)
        run_die_on_error => defined($args{run_die_on_error}) ? $args{run_die_on_error} : 1,
        run_error_fn => undef, # Consolidate error handling logic with a callback
        run_echo_always => defined($args{echo_always}) ? $args{echo_always} : 1,
        # level =>  (defined($args{level}) ? $args{level} : 0),
    }, $class;

    # Wrapper to conveniently allow root/file to be specified in constructor or start method
    #  Return self if successful, fail if parsing fails.
    return $instance;
}
sub run_echo_always
{
    my $self = shift;
    my $val = shift;
    if (defined($val)) {
        $self->{run_echo_always} = shift;
    } else {
        return $self->{run_echo_always};
    }
}

sub run_die_on_error
{
    my $self = shift;
    $self->{run_die_on_error} = shift;
}

sub root_dir
{
    my $self = shift;
    return $self->{root};
}
sub cfg_dir
{
    my $self = shift;
    return File::Spec->catdir($self->{root}, ".nuggit");
}

sub start
{
    my $self = shift;
    return $self->{logger}->start(@_);
}

sub logger {
    my $self = shift;
    return $self->{logger};
}

=head2 run_foreach

Run given command (str) in the current repository, and all nested submodules.

Note: Current repository corresponds to current working directory. To run from nuggit root, user should change directories first. This permits greater flexibility in usage.

=cut
sub run_foreach {
    my $self = shift;
    my $cmd = shift;

    $self->foreach({
        'depth_first' => sub {
                          $self->run($cmd);
                      },
        'run_root' => 1
       });

}

=head2 run

Execute the given git command from the current directory.  The command will be wrapped in IPC::Run3 in order to capture stdout, stderr, and exit status.  Output and 'die' functionality are controlled by object settings.

Usage: my ($status, $stdout, $stderr) = run($cmd [,@args]);  

TODO: @args to be added later, for now a single string expected
TODO: Optional parameters to overrride object default for die_on_error and run_echo_always.

=cut

sub run {
    my $self = shift;
    # TODO: Support optional log level and args.  If set, the first argument will be hashref.
    my $opts = (ref($_[0]) eq 'HASH') ? shift : undef;
    my $cmd = shift;

    my ($stdout, $stderr);
    
    $self->{logger}->cmd($cmd);

    # Run it (wrap in an eval, since we don't want script to die automatically)
    # We use IPC::Run3 so we can reliably capture stdout + stderr (backticks only captures stdout)
    run3($cmd, undef, \$stdout, \$stderr);

    if (($self->{run_die_on_error} || $opts->{die_on_error}) && $?) {
        say $stderr if $stderr;
        my ($package, $filename, $line) = caller;
        $self->{logger}->cmd_full($cmd, $stdout, $stderr, $?);

        if ($self->{run_error_fn}) {
            $self->{run_error_fn}($?, $stdout, $stderr);
        } elsif ($self->{run_die_on_error}) {
            my $cwd = getcwd(); # TODO: Convert to relative path
            die("$cmd failed with $? at $package $filename:$line in $cwd");
        }
    }

    if ($self->{run_echo_always} || $opts->{echo_always}) {
        say $stdout if $stdout;
        say $stderr if $stderr;
    }

    $self->{logger}->cmd_full($cmd, $stdout, $stderr);
    
    return ($?, $stdout, $stderr);
}

=head2 merge_conflict_state()

If no argument is specified, it returns true if a merge operation is in progress, false otherwise.

If any parameter is defined, then we will die with an appropriate error if a merge is in progress.

=cut

sub merge_conflict_state {
    my $self = shift;
    my $die_if_conflict = shift;
    if (-e $self->{root}."/.nuggit/merge_conflict_state") {
        die "A merge is in progress.  Please complete with 'ngt merge --continue' or abort with 'ngt merge --abort' before proceeding.";
    } else {
        return undef;
    }
}

=head2 foreach(opts)

Recurse into each submodule and execute the given command. This is roughly equivalent to "git submodule foreach" with added functionality.

It accepts a hashref as it's sole parameter which may contain the following fields.
Parameters:

=over

=item breadth_first

Callback function to be called foreach submodule with breadth-first recursion (starting from the top level).  CWD will be at root of current submodule.  See below for arguments provided.

=item depth_first

Callback function to be called foreach submodule with depth-first recursion (starting from most nested).  CWDW will be at roto of current submodule.  See below for arguments provided.

=item recursive If false, do not recurse into nested submodules

=item run_root If true, execute defined callbacks on the root repository as well.

=item modified_only  If true, execute and recurse into submodules that Git reports as modified, uninitialized, o rin a conflicted state only.

=item parallel.  Reserved for future parallel processing enhancements.

=back

Callback functions will be called with a single hashref argument containing the following fields

opts - A copy of the input options
parent - The name of the parent repository
name   - The name of this submodule

The above fields will be defined for the root repository (if run_root) and all submodules, while the following fields only apply to submodules:

status - The status for this repository.  0 for unmodified, '+' for modified, '-' for uninitialized, 'U' for pending merge conflicts.

=cut
# TODO: Add recursion level flag to parameters passed to callbacks
# TODO: 'run_parallel' option using fork&join. This can be used for select operations, if git doesn't provide a '-j' flag.  Libraries may hlp in such an implmentation, ie: https://perlmaven.com/speed-up-calculation-by-running-in-parallel
# TODO: Support for array of return values, primarily for compatibility with parallel mode
sub foreach {
    my $self = shift;
    my $user_opts = shift;
    my $opts = shift;
    my $is_root = 0;

    if (ref($user_opts) eq "CODE") {
        # Base Case: Only a simpple fn reference given
        $user_opts = { 'breadth_first' => $user_opts };
    }

    if (!$opts) {
        $opts = {
            # Note:  // is Perl's "defined-or" operator
            'breadth_first' => $user_opts->{'breadth_first'},
            'depth_first'   => $user_opts->{'depth_first'},
            'recursive '    => $user_opts->{'recursive'} // 1,
            'run_root'      => $user_opts->{'run_root'} // 0,
            'modified_only' => $user_opts->{'modified_only'} // 0,
            'load_tracking' => $user_opts->{'load_tracking'} // 0, # If set, query submodule tracking branches
            #'parallel'     => # Reserved for future enhancement
        };
        $is_root = 1;
    }

    my $parent = shift || "."; # Not part of opts as this will vary per recursion.
    my $cwd = getcwd();

    if ($is_root && $opts->{'run_root'} && $opts->{'breadth_first'}) {
        $opts->{'breadth_first'}->({
            'opts' => $user_opts,
            'parent' => $parent,
            'name' => '',
            'cwd' => $cwd,
            # Note: OTher fields will not be provided for root
           });
        chdir($cwd); # Ensure we haven't changed dir
    }

    if (!-e '.gitmodules' && !$is_root )
    {
        return; # early if there are no submodules (for faster execution) and we are sure cwd is root of a submodule
    }
    my $list = `git submodule`;

    # TODO: Consider switching to IPC::Run3 to check for stderr for better error handling
    if (!$list || $list eq "") {
        return;
    }

    # Preload submodule tracking branch info if requested
    my $gitmodules;
    $gitmodules = `git config --file .gitmodules --get-regexp branch` if $opts->{load_tracking};

  my @modules = split(/\n/, $list);
  while(my $submodule = shift(@modules))
  {
      # Get Status. Git will report:
      #  ' ' for unmodified, '+' for modified commit, '-' for uninitialized, or 'U' for merge conflicts
      my $status = substr($submodule, 0,1);
      $status = 0 if ($status eq ' ');
      
      my @words = split(/\s+/, substr($submodule, 1));
      
      my $hash   = $words[0];
      my $name = $words[1];
      my $label;
      $label = substr($words[2], 1, -1) if defined($words[2]); # Label may not always exist

      if ($opts->{'modified_only'} && !$status) {
          next; # Don't parse a submodule if it's un-modified.
      }
      
      # Enter submodule
      chdir($name) || die "submodule_foreach can't enter $name";

      # Create argument object for callbacks
      my $cb_args = {
              'parent' => $parent,
              'name' => $name,
              'status' => $status,
              'hash' => $hash,
              'label' => $label,
              'opts' => $user_opts,
              'subname' => File::Spec->catdir($parent,$name),
          };
      if ($gitmodules && $gitmodules =~  m/submodule\.$name\.branch (.*)$/m) {
          $cb_args->{'tracking_branch'} = $1;
      }
      
      # Pre-traversal callback (breadth-first)
      if (defined($opts->{breadth_first}) ) {
          $opts->{breadth_first}->($cb_args);
          chdir(File::Spec->catdir($cwd,$name)) || die "Error returning to directory"; # In case caller changes folder
      }


      # Recurse
      if (!$opts || !defined($opts->{recursive}) || (defined($opts->{recursive}) && $opts->{recursive})) {
          $self->foreach($user_opts, $opts, $cb_args->{'subname'});
      }

      # Callback (depth-first)
      if (defined($opts->{depth_first})) {
          $opts->{depth_first}->($cb_args);
      }

      # Reset Dir
      chdir($cwd);
    
  }
    if ($is_root && $opts->{'run_root'} && $opts->{'depth_first'}) {
        $opts->{'depth_first'}->({
            'opts' => $user_opts,
            'parent' => $parent,
            'name' => '',
            'cwd' => $cwd,
            # Note: OTher fields will not be provided for root
        });
        chdir($cwd); # Ensure we haven't changed dir
    }
  
}

# This is the getter/setter for all global Nuggit user cfg settings.
#  It will return undef if no matching field is known.
#  If the main Nuggit config file has not been loaded yet, and it exists, it will be parsed on first call
sub cfg {
    my $self = shift;
    my $key = shift;
    my $val = shift;

    $self->{cfg} = $self->load_config("config.json",{}) unless defined($self->{cfg});

    return undef unless $self->{cfg};

    if (defined($val)) {
        $self->{cfg}{$key} = $val;
    } else {
        return $self->{cfg}{$key};
    }
}

# TODO: Option to merge with default instead of replacing and/or option to automatically check for a default file.  Perhaps if $default is a string and refers to a valid file, then always merge contents.  Or 3-way checek with params: global_file, local_file, app_default.  NOTE: home dir is $ENV{"HOME"} for unix, or File::HomeDir for a generic solution
sub load_config {
    my $self = shift;
    my $name = shift;
    my $default = shift;
    my $fn = File::Spec->catfile($self->cfg_dir(), $name);
    if (-f $fn) {
        my $raw = read_file($fn);
        return $default unless $raw;
        return decode_json($raw);
    } else {
        return $default;
    }
}
sub save_config {
    my $self = shift;
    my $cfg = shift;
    my $name = shift;
    my $fn = File::Spec->catfile($self->cfg_dir(), $name);
    write_file($fn, encode_json($cfg));
}
sub clear_config {
    my $self = shift;
    my $name = shift;
    my $fn = File::Spec->catfile($self->cfg_dir(), $name);
    if (-e $fn) {
        rename($fn, "$fn.old");
    }
}



1;
