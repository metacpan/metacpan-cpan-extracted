#!/usr/bin/env perl
package Git::Nuggit::Status;
our $VERSION = 0.03;

use v5.10;
use strict;
use warnings;
use Cwd qw(getcwd abs_path);
use Term::ANSIColor;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_status pretty_print_status do_pretty_print_status show_status file_status status_check STATE);

=head1 Git::Nuggit::Status

This package will retrieve the status of a repository, including nested submodules.  Functions are provided to display status, or the returned object can be used directly for processing.

This package is self-contained and does not depend on other Nuggit components.  It utilizes Git porcelain=v2 syntax which requires Git 2.13.2+.

Typical usage:

	chdir($top_level_proj_repo);
	my $status = get_status({uno => 1}); # Get status, ignore tracked files
	pretty_print_status($status);

See L</get_status>() below for details on output format.

=head2 STATE

The status value of each object is an enum-like value.  The STATE() function can be used to translate between the integer and textual forms, for example STATE($status->{status}) may return 'modified', while STATE('modified') may return 4.  The STATE() function is case-insensitive.

States are ordered in level of priority.  The summary state of an object represents the greatest state of it, or any objects (submodules/files) beneath it.  

Integer values of STATE enums may change in future revisions.

Supported states are:
- clean
- ignored
- untracked
- renamed
- modified
- conflict

=cut

# Status values.  This is an (improvised) enum in order of increasing priority.
# WARNING: These variables should NOT be modified under any condition (but making it a const in Perl is messy)
my @STATE = qw(CLEAN IGNORED UNTRACKED UNINITIALIZED RENAMED MODIFIED CONFLICT);
my %STATE;
for my $i (0 .. (@STATE-1)) { $STATE{$STATE[$i]} = $i; }
# This provides conversion between numeric and text versions.  show_status() in comparison adds colorization
# TODO: This function does not currently provide error checking
sub STATE {
    my $val = uc(shift);
    if (defined($STATE{$val}) ) {
        return $STATE{$val};
    } else {
        return $STATE[$val];
    }
}

=head2 get_status($opts)

Retrieve the status of a Git repository, and submodules.

The following options (in hash form) are currently supported:

get_status({
	uno => 0,     # If 1, pass '-uno' flag to ignore untracked files
	ignored => 0, # If 1, git may show any files that have been ignored (ie: due to a .gitignore)
    all => 1,     # If 1, show all submodules, including those nominally un-modified.
});

=head3 Output Format

Output is a nested object with the following keys for each:

- path - Path (or name) of this object
- children - An array of known submodule names (those not in a 'clean' state)
- objects - A hash of object definitions cataloged by their path (ie: file/submodule name).
- status - Summary Status.  This is the greatest state value (described above) of this object and its children
- staged_status - Same as status, but in relation to changes staged for commit
- staged_files_cnt - A count of modified files at this level and below, excluding submodule references.
- unstaged_files_cnt - Same as staged_files_cnt, but for changes that have not been staged.
- old_path - If an object was renamed, this will reflect t's old name
- status_flag - Status (character) flag from Git for unstaged status.
- staged_status_flag - Status (character) flag from Git for staged status.
- is_submodule - Set to 1 if this object represents a submodule
- sub_commit_delta - set to 1 if Git reports the commit tree has changed
- sub_modified - set to 1 if there are tracked changes in this submodule
- sub_untracked - Set to 1 if there are untracked files in this submodule
- branch.ahead, branch.behind - If commit for a repository differs from upstream, how many commits ahead/behind
- branch.oid - The current commit of this repository/submodule.
- branch.head - The currently checked out branch
- branch.* - Any additional 'header' information output by 'git --porcelain=v2 --branch' will be parsed.
- branch_status_flag - True if any submodule is not on the same branch as it's parent.
- detached_heads_flag - True if any submodule (or root) is in a detached HEAD state.
=head3 Limitations

Branch information, including ahead-behind, detached state, or invalid
branch is only calculated for submodules that are otherwise shown in
the output.  If a submodule does not have any outstanding changes, it
will NOT be checked at this time.  This is a limitation of git's
porcelain status and will require an explicit query for additional
submodules to resolve.

=cut

sub get_status
{
    my $opts = shift;
    my $flags = "";
    $flags .= "-uno " if ($opts->{uno}); # Hide untracked files
    $flags .= "--ignored" if ($opts->{ignored}); # Show ignored flags

    my $rtv = {
               'path' => '.',
               'children' => [], # Submodules
               'objects' => {}, # Hash of all Objects (not recursive)
               'status' => $STATE{'CLEAN'}, # Clean, unless it isn't
               'staged_status' => $STATE{'CLEAN'},
               # scalar(children) = # of (modified) submodules
               # scalar(objects) =  # of objects
               # number of >MODIFIED objects that are not submodules
               'staged_files_cnt' => 0, # Number of modified (not submodule) files staged (recursive)
               'unstaged_files_cnt' => 0, # Number of modified (not submodule) files unstaged (recursive)
               'branch_status_flag' => 0, # True if any scanned submodules are not on the same branch as parent
               'detached_heads_flag' => 0, # True if any scanned submodules or root are detached
              };
    _get_status($rtv, $flags, $opts);

    # Root level flag cleanup
    $rtv->{'detached_heads_flag'} = 1 if ($rtv->{'branch.head'} eq "(detached)");
    $rtv->{'branch_status_flag'} = 1 if $rtv->{'detached_heads_flag'};
    return $rtv;
}

# Private function for recursively implementing get_status
# TODO: Can we optimize with fork/join & mutex? 
sub _get_status
{
    my $rtv = shift;
    my $flags = shift;
    my $opts = shift;

    # Get detailed porcelain status, including branch information
    my $status_cmd = "git status --porcelain=v2 --branch $flags";
    my $raw = `$status_cmd`;
    my @lines = split("\n", $raw);

    # Parse Output
    foreach my $line (@lines) {
        my @parts = split(' ', $line);
        my $type = shift(@parts);

        # Parse 'Header' lines
        if ($type eq "#") {
            # Parse headers
            my $key = shift(@parts);
            if ($key eq "branch.ab") {
                # Store split values, and original
                $rtv->{'branch.ahead'} = shift(@parts);
                $rtv->{'branch.behind'} = shift(@parts);
            } else {
                $rtv->{$key} = shift(@parts);
                if ($key eq "branch.oid" && $opts->{details}) {
                    $rtv->{commit} = get_commit_info($rtv->{'branch.oid'});
                }
            }
            next;
        }

        # Prepare object
        my $obj = {
                   'children' => [],
                   'objects' => {},
                   'status' => $STATE{'CLEAN'},
                   'staged_status' => $STATE{'CLEAN'},
                   'staged_files_cnt' => 0, # Number of modified (not submodule) files staged (recursive)
                   'unstaged_files_cnt' => 0, # Number of modified (not submodule) files unstaged (recursive)
                   'branch_status_flag' => 0, # True if any scanned submodules are not on the same branch as parent
        };
        my ($xy, $sub, $mh, $mi, $mw, $hh, $h1, $h2, $h3, $path, $xscore, $oldPath, $m1, $m2, $m3);
        # $mh = octal file mode in HEAD
        # mi - octal file mode in index
        # mw - octal file mode in worktree
        # hh - Object name in HEAD
        # hi - object name in the index
        # path - the path/filename

        if ($type eq "1") {
            # Ordinary changed entries:
            #  1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
            ($xy, $sub, $mh, $mi, $mw, $hh, $h1, $path) = @parts;
            # TODO: Set status based on $xy
        } elsif ($type eq "2") {
            # Renamed or copied entries:
            #  2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>
            ($xy, $sub, $mh, $mi, $mw, $hh, $h1, $xscore, $path, $oldPath) = @parts;
            $obj->{'staged_status'} = $STATE{'RENAMED'};
            $obj->{'status'} = $STATE{'RENAMED'};
            $obj->{'old_path'} = $oldPath;
        } elsif ($type eq "u") {
            # Unmerged:
            #  u <xy> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
            ($xy, $sub, $m1, $m2, $m3, $mw, $h1, $h2, $h3, $path) = @parts;
            $type = 'unmerged';

            # VERIFY: Is there a difference between stated/unstaged here?
            $obj->{'staged_status'} = $STATE{'CONFLICT'};
            $obj->{'status'} = $STATE{'CONFLICT'};
            $obj->{'conflict_status'} = $xy;
        } elsif ($type eq '?') {
            # Untracked
            $path = $parts[0];
            $type = 'untracked';
            $obj->{'status_flag'} = '?';
            $obj->{'staged_status_flag'} = '?';
            $obj->{'status'} = $STATE{'UNTRACKED'};
        } elsif ($type eq '!') {
            # Ignored
            $path = $parts[0];
            $type = 'ignored';
            $obj->{'status_flag'} = '!';
            $obj->{'staged_status_flag'} = '!';
            $obj->{'status'} = $STATE{'IGNORED'};
        }
        else { die("ERROR: Illegal type in porcelain status for line: $line"); } # Debug

        $obj->{'obj_name'} = $hh if $hh;
        $obj->{'obj_name_staged'} = $h1 if $h1;
        
        if ($xy) {
            $obj->{'status_flag'} = substr($xy, 1, 2);
            $obj->{'status_flag'} = ' ' if $obj->{'status_flag'} eq ".";
            $obj->{'staged_status_flag'} = substr($xy, 0, 1);
            $obj->{'staged_status_flag'} = ' ' if $obj->{'staged_status_flag'} eq ".";

            if ($obj->{'status_flag'} ne " " && $obj->{status} < $STATE{'MODIFIED'}) {
                $obj->{'status'} = $STATE{'MODIFIED'};
            }
            if ($obj->{'staged_status_flag'} ne " " && $obj->{staged_status} < $STATE{'MODIFIED'}) {
                $obj->{'staged_status'} = $STATE{'MODIFIED'};
            }
        }

        $obj->{path} = $path;
        
        if ($sub && substr($sub, 0, 1) eq "S") {
            # This is a submodule
            $obj->{is_submodule} = 1;
            my @substate = split("",$sub);

            # Flags, first char 'S' indicates submodule
            
            # [1]; C if commit has changed
            # Set if new commits exist in tree.  It is NOT set if submodule is at an earlier commit.
            $obj->{sub_commit_delta} = 1 if $substate[1] eq 'C';
            
            # [2]; M if tracked changes
            $obj->{sub_modified} = 1 if $substate[2] eq 'M';
            
            # [3]: U if untracked changes
            $obj->{sub_untracked} = 1 if $substate[3] eq 'U';

            my $tmppath = getcwd();
            chdir($path);
            
            _get_status( $obj, $flags, $opts ) unless $opts->{no_recurse};

            # Reference Details, if details requested and does not match checked out commit
            if ($obj->{sub_commit_delta} && $opts->{details}) {
                $obj->{'ref'} = get_commit_info($obj->{'obj_name'});
            }

            push(@{ $rtv->{children} }, $obj); # Add path to children array
            chdir($tmppath);

            # Increment modification counts
            $rtv->{unstaged_files_cnt} += $obj->{unstaged_files_cnt};
            $rtv->{staged_files_cnt} += $obj->{staged_files_cnt};

            # Branch Check (only valid if we've recursed)
            if (!$opts->{no_recurse}) {
                if ($obj->{'branch_status_flag'} || $rtv->{'branch.head'} ne $obj->{'branch.head'}) {
                    $rtv->{branch_status_flag} = 1 ;
                }
                
                $rtv->{detached_heads_flag} = 1 if $obj->{'branch.head'} eq "(detached)";
            }
            
        } else {
            # Not a submodule, increment count if state is > UNTRACKED
            $rtv->{unstaged_files_cnt}++ if $obj->{status} > STATE('UNTRACKED');
            $rtv->{staged_files_cnt}++ if $obj->{staged_status} > STATE('UNTRACKED');
        }
        
        # Update summary state
        $rtv->{status} = $obj->{status} if $obj->{status} > $rtv->{status};
        $rtv->{staged_status} = $obj->{staged_status} if $obj->{staged_status} > $rtv->{staged_status};
        
        # Add $obj to objects
        $rtv->{objects}{$path} = $obj;


    }

    # Query any missing submodules, if all-submodules mode.
    if ($opts->{all}) {
        my $subs = get_submodule_status();

        if ($subs) {
            foreach my $sub (@$subs) {
                my $subname = $sub->{"name"};
                
                if (defined($rtv->{objects}) && defined($rtv->{objects}{$subname})) {
                    my $obj = $rtv->{objects}{$subname};
                    $obj->{"commit_described"} = $sub->{"commit_described"};
                } else {
                    my $obj = {
                        'children' => [],
                            'objects' => {},
                            'status' => $STATE{'CLEAN'},
                            'staged_status' => $STATE{'CLEAN'},
                            'staged_files_cnt' => 0,
                            'unstaged_files_cnt' => 0,
                            'branch_status_flag' => 0,
                            'path' => $subname,
                            'is_submodule' => 1,
                            'status_flag' => " ",
                            'staged_status_flag' => " ",
                            'branch.oid' => $sub->{"commit"},
                            "commit_described" => $sub->{"commit_described"},
                    };

                    # Check if submodule was initialized
                    if (!defined($sub->{"commit_described"}) && $sub->{"state"} eq "-") {
                        $obj->{'status'} = $STATE{'UNINITIALIZED'};
                        $rtv->{'status'} = $obj->{'status'} if $obj->{status} > $rtv->{status};
                    } else {
                        # Otherwise Load Submodule Status as usual
                        my $tmppath = getcwd();
                        chdir($subname) || die "Can't cd to $subname";
                        _get_status( $obj, $flags, $opts );
                        chdir($tmppath);

                        # Branch Check
                        if ($obj->{'branch_status_flag'} || $rtv->{'branch.head'} ne $obj->{'branch.head'}) {
                            $rtv->{branch_status_flag} = 1 ;
                        }

                        $rtv->{detached_heads_flag} = 1 if $obj->{'branch.head'} eq "(detached)";                   
                    }
                    push(@{ $rtv->{children} }, $obj); # Add path to children array
                    $rtv->{objects}{$subname} = $obj;

                }
            }
        }
    }
    


    return $rtv;
} # end get_status

=head2 pretty_print_status($status_obj, $relative_path, $verbose)

Print repository status object to user, including additional summary details for the root level.  It internally invokes do_pretty_print_status() to complete it's output.

See do_pretty_print_status() to output object information only for an object and it's children.

=cut

sub pretty_print_status
{
    my $status = shift;
    my $relative_path = shift;
    my $flags = shift;
    my $verbose = $flags->{verbose};
    $flags->{usr_rel_path} = $relative_path; # Cache rel path to usr folder
    $flags->{usr_abs_path} = abs_path($flags->{user_dir});  # And abs path to same

    my $root_branch = $status->{'branch.head'};

    if ($root_branch) {
        if ($root_branch eq "(detached)") {
            print colored('HEAD detached ','error');
        } else {
            print "On branch $root_branch ";
        }
        say "(".$status->{'branch.oid'}.")" if $status->{'branch.oid'};
    } else {
        say "WARNING: Unable to identify root branch";
        say "\t Root Branch Object: ".$status->{'branch.oid'} if $status->{'branch.oid'};
    }
    print "Summary Status Working: ".show_status($status->{status});
    if ($status->{unstaged_files_cnt} > 0) {
        print "(".$status->{unstaged_files_cnt}.")";
    } else {
        print "(refs only)";
    }
    if ($status->{staged_status} != $STATE{'CLEAN'}) {
        print ", ".colored("Staged: ",'info').show_status($status->{staged_status});
        if ($status->{staged_files_cnt} > 0) {
            print "(".$status->{staged_files_cnt}.")";
        } else {
            print "(refs only)";
        }
    }
    say "";
    if ($status->{'branch_status_flag'}) {
        say colored("\tOne or more submodules are not on the above branch.",'warn');
    }
    if (defined($status->{'branch.ahead'}) && ($status->{'branch.ahead'} != 0 || $status->{'branch.behind'} != 0)) {
        print "Your branch is out of sync with upstream";
        print " (".$status->{'branch.upstream'}.")" if defined($status->{'branch.upstream'});

        my $ahead = $status->{'branch.ahead'};
        my $behind = $status->{'branch.behind'};
        print ". It is ";
        if ($ahead != 0 && $behind != 0) {
            say "$behind commits behind and $ahead ahead";
        } elsif ($ahead != 0) {
            say "ahead by $ahead commits.";
        } else {
            say "behind by ".abs($behind)." commits.";
        }
    }

    if ($flags->{details}) {
        say "\nCommit Details:";
        say "\tInferred Branch: ".$status->{'commit_described'} if $status->{'commit_described'}; # Only if -a
        show_commit_info($status->{'commit'});        
    }
    
    say "";
    do_pretty_print_status($status, $relative_path, $root_branch, $flags);
}

=head2 do_pretty_print_status($status, $relative_path, $root_path, $flags)

Output details on all objects in this $status object and it's children (submodules).

Parameters:
- status - Status object from get_status(), or a nested object state
- relative_path - Relative path to repository root level. This will be concatenated with an object's path for display.  If omitted, path will be relative to the top directory of the repository that the provided status object represents.
- root_branch - If defined for applicable objects, output a warning if current branch does not match.
- verbose - If set, always output additional information when known, for example commit hash.

=cut

sub do_pretty_print_status {
    my $status = shift;
    my $relative_path = shift;
    my $root_branch = shift;
    my $flags = shift;
    my $verbose = $flags->{verbose};

    # TODO: Attempt to cleanup rel paths in output ... need better way to compare dirs
    # ie: File::Spec->catdir($abs_rel_path, $obj->path) vs $usr_abs_path
    # Paths may not be equal when recursing
    my $abs_rel_path = abs_path(File::Spec->catdir($flags->{user_dir},$relative_path));

    foreach my $key (sort keys(%{$status->{'objects'}})) {
        my $obj = $status->{objects}->{$key};
        # Note: We deliberately do not use File::Spec here because we want to colorize submodule path
        #  This is for display-only, so OS compatibility is not an issue

        print " ".$obj->{'status_flag'};
        print colored($obj->{'staged_status_flag'},'info').' ';
        if ($relative_path && $relative_path !~ /^\.\/?$/ && $abs_rel_path ne $flags->{usr_abs_path}) {
            if ($obj->{is_submodule} && File::Spec->catdir($abs_rel_path, $obj->{path}) eq $flags->{usr_abs_path}) {
                # Print only indicator that we are referring to self
                print '../';
            } else {
                print colored($relative_path,'warn');
                print '/' unless(substr($relative_path,-1) eq "/");
            }
        }
        print $obj->{'path'};
        print " <= ".$obj->{'old_path'} if $obj->{'old_path'};

        if ($obj->{'is_submodule'}) {
            print colored(" Delta-Commits",'warn') if $obj->{sub_commit_delta};
            print colored(" Modified",'warn') if $obj->{sub_modified};
            print " Untracked-Content" if $obj->{sub_untracked};

            if ($obj->{'status'} == STATE('UNINITIALIZED')) {
                print colored(' Uninitialized', 'error');
            } elsif ($obj->{'branch.head'} eq "(detached)") {
                print colored(' DETACHED ('.$obj->{'branch.oid'}.') ', 'error');
            } elsif (!defined($obj->{'branch.head'})) {
                print colored(' Detached? OID:'.$obj->{'branch.oid'}, 'warn');
            } elsif (defined($root_branch) && $obj->{'branch.head'} ne $root_branch) {
                print colored(' Branch: '.$obj->{'branch.head'}, 'error');
                print ' ('.$obj->{'branch.oid'}.')' if $verbose;
            } else {
                print " (".$obj->{'branch.oid'}.")" if $verbose;
            }
            if (defined($obj->{'branch.ahead'}) && ($obj->{'branch.ahead'}!=0 || $obj->{'branch.behind'}!=0)) {
                my $ahead = $obj->{'branch.ahead'};
                my $behind = $obj->{'branch.behind'};
                print " Upstream-Delta( ";
                print $ahead." " if $ahead != 0;
                print $behind if $behind != 0;
                print " )";
            }
            print "\n";

            if ($flags->{details}) { # Details View
                if ($obj->{sub_commit_delta}) {
                    say colored("\tCurrent Commit", 'success');
                    
                }
                show_commit_info($obj->{commit});
                
                if ($obj->{sub_commit_delta} && $obj->{'ref'}) {
                    say colored("\tReferenced Commit", 'success');
                    show_commit_info($obj->{'ref'});
                }
                
            }

            # Recurse into any nested submodules
            do_pretty_print_status($obj,
                                   ($abs_rel_path eq $flags->{usr_abs_path}) ? $obj->{path} : File::Spec->catdir($relative_path,$obj->{'path'}),
                                   $root_branch,
                                   $flags);
        } else {
            if ($obj->{status} == $STATE{'CONFLICT'}) {
                print colored(' Conflict', 'error');
                my $conflictFlag = $obj->{'conflict_status'};
                my $conflictMsg;
                if ($conflictFlag eq 'DD') { $conflictMsg = 'Both deleted'; }
                elsif ($conflictFlag eq 'AU') { $conflictMsg = 'Added by us'; }
                elsif ($conflictFlag eq 'UD') { $conflictMsg = 'Deleted by them'; }
                elsif ($conflictFlag eq 'UA') { $conflictMsg = 'Added by them'; }
                elsif ($conflictFlag eq 'DU') { $conflictMsg = 'Deleted by us'; }
                elsif ($conflictFlag eq 'AA') { $conflictMsg = 'Both added'; }
                elsif ($conflictFlag eq 'UU') { $conflictMsg = 'Both modified'; }
                print colored("($conflictMsg)", 'warn') if $conflictMsg;

            }
            print "\n";
        }
    }

}

=head2 show_status($status)

Similar to the STATE() function, converts a state (decimal value) to a user-friendly name, automatically colorizing selected states.

=cut

sub show_status
{
    my $status = shift;
    if ($status == $STATE{'CLEAN'}) {
        return "clean";
    } elsif ($status == $STATE{'IGNORED'}) {
        return "ignored";
    } elsif ($status == $STATE{'UNTRACKED'}) {
        return "untracked";
    } elsif ($status == $STATE{'RENAMED'}) {
        return colored("renamed", 'warn');
    } elsif ($status == $STATE{'MODIFIED'}) {
        return colored("modified", 'warn');        
    } elsif ($status == $STATE{'CONFLICT'}) {
        return colored("conflicted", 'error');
    } elsif ($status == $STATE{'UNINITIALIZED'}) {
        return colored("uninitialized", 'error');
    } else {
        return colored("unknown=$status",'error');
    }

}

=head2 file_status($status_obj, $filename)
Retrieve the status information for a given file or submodule from the overall status tree.

NOTICE: At present, $filename must be the full path to the file (or submodule) relative
  to the root repository.
FUTURE ENHANCEMENTS:
- Handle relative paths if given $relative_path_to_root
- Handle regex/wildcard search for matching files.  Option for negation pattern
    Ideally, detect if an input term is string or regex, and treat accordingly
- Handle multiple input patterns

=cut

sub file_status
{
    my $status = shift;
    my $fn = shift;
    my $dirdelim = File::Spec->catfile('','');
    my ($fn_val, $fn_dir, $fn_file) = File::Spec->splitpath($fn);

    die("Illegal arguments to file_status") unless defined($status) && defined($fn) && defined($status->{objects});
    
    foreach my $key (keys %{$status->{objects}}) {
        my $obj = $status->{objects}->{$key};

        # Check for exact match
        return $obj if $key eq $fn;

        # Recurse if this is a submodule with partial match
        if ($obj->{is_submodule} && substr($fn, 0, length($key)+1) eq $key.$dirdelim) {
            return file_status($obj, substr($fn, length($key)+1));
        }

    }
    return undef;
}

=head2 status_check($status)

Given a status object, return true only if there are no outstanding changes in working tree or stage, excluding untracked files but inclusive of submodule references.

=cut

sub status_check
{
    my $status = shift;
    if ($status->{status} <= STATE('UNTRACKED') && $status->{staged_status} <= STATE('UNTRACKED')) {
        return 1;
    } else {
        return 0;
    }
}


sub get_submodule_status {
    my $path = shift;
    my $recursive = shift;
    my $opts = ($recursive) ? "--recursive" : "";

    # Quick check (this should be faster than shell invocation)
    my $file = ".gitmodules";
    $file = File::Spec->catfile($path, $file) if $path;
    return undef unless -e $file; # Save a bash command if no submodules here

    # Get submodule status
    my $old_dir = getcwd();   
    chdir($path) if $path;
    my $status = `git submodule status $opts`;
    chdir($old_dir) if $path;

    # And parse
    chomp($status);
    my @lines = split('\n', $status);
    
    my @rtv;
    foreach my $sub (@lines) {
        my ($state,$hash,$name,$branch) = $sub =~ /([\s\+\-])([0-9a-fA-F]+)\s+([\w\\\/\-\.]+)\s*(.+)?/;
        # Note: branch is the result of "git describe", which finds the nearest match to hash

        push(@rtv, {
                "name" => $name,
                "commit" => $hash,
                "state" => $state,
                "commit_described" => $branch,
             });
    }

    return \@rtv;
}

sub get_commit_info {
    my $sha = shift;
    if (!$sha) {
        warn colored("WARNING: get_commit_info() on undefined commit. Possible internal error", "warn");
        return undef;
    }

    my $rtv = {'sha' => $sha};

    # If requested, query commit details
    my $msg = `git show $sha --pretty=format:"%aN\n%ar\n%s" -s`;
    if ($?) {
        # Failed to query
    } else {
        my ($author, $date, $cm) = split('\n', $msg);
        $rtv->{'author'} = $author;
        $rtv->{'date'} = $date;
        $rtv->{'msg'} = $cm;
    }
    
    # And matching tags/branches (exact matches only)
    my $tags = `git tag --points-at $sha`; 
    chomp($tags);
    $rtv->{'tags'} = [split('\n',$tags)] if $tags;
    
    my $branches = `git branch --points-at $sha`;
    chomp($branches);
    $rtv->{'branches'} = [split('\n', $branches)] if $branches;

    return $rtv;
}
sub show_commit_info {
    my $obj = shift;
    say "\tSHA: ".$obj->{'sha'};
    #say "\tDescription: ".$obj->{'commit_described'} if $obj->{'commit_described'}; # Only if -a
    
    if (defined($obj->{'author'})) {
        say "\tAuthor: $obj->{'author'}";
        say "\tDate: $obj->{'date'}";
        
        my $msg = $obj->{'msg'};
        $msg = substr($msg,0,67)."..." if length($msg) > 70; # Truncate long messages
        say "\tMessage: $msg";

        say "\tTags: ".join(', ',@{$obj->{'tags'}}) if $obj->{'tags'};
        if ($obj->{'branches'}) {
            # Print Branches as a comma-delimited list
            say "\tBranches: ".join(', ',
                                    # Making active branch name bold
                                    map { $_ =~ /^\*\s+([\w\/]+)/ ? colored($1,'bold') : $_ } @{$obj->{'branches'}}
                                   );
        }
        
    } else {
        say colored("\t Warning: Commit details unavailable. A 'ngt fetch' may be needed.", 'error');
    }
}

1;
