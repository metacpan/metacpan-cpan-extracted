#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Term::ANSIColor;
use JSON;

use Data::Dumper; # DEBUG

my $opts = {
    "verbose" => 0,
    "ngtstrategy" => 'ref', # Original Nuggit behavior was branch-first, we now default to a ref-first strategy.
};

# Initialize Nuggit.
# TODO: Consider adding ability to run in non-nuggit repos, or on relative path (ie: merge current repo and below)
my $ngt = Git::Nuggit->new("run_die_on_error" => 0, "echo_always" => 0) || die ("Not a nuggit"); 
ParseArgs();

# Set root dir
# TODO: Option to skip this and run preview from current folder
my $root_dir = $ngt->root_dir();
chdir($root_dir) || die("Can't enter root_dir\n");


# Global Count Variables (TODO: Refactor these)
$_ = 0 for my ($cnt_files, $cnt_conflicts, $cnt_submodules, $cnt_submodule_conflicts);
my @all_conflicts;

root_merge_tree();

sub ParseArgs {
    Getopt::Long::GetOptions( $opts,
                              "verbose!",
                              "help!",
                              "man!",
                              "ngtstrategy|s=s",
                              "branch-first!",
                              "ref-first!",
                              "branch=s", # Optional explicit alternative to namesless spec
                              "remote=s", # Optional explicit alternative to namesless spec
                              "base=s",   # Optional explicit alternative to nameless spec
                              "json!",    # If set, output obj in JSON format (intended for usage with future UI wrapper)
                              "full!",    # Show all results, instead of only conflicts & summary
                              "patch!",   # Display output as a standard patch file (no coloring)
                              # TODO: remote flag.  For pull operation, this will cause a pull in the root, and a submodule update --remote in all submodules.  This is a more git-like version of the previous '--default' concept.
                              # TODO: Default flag.  For branch-first operations only.
        );
    
    if ($opts->{help} || $opts->{man}) {
        my $pv = ($opts->{help} ? 1 : 2);
        my $input = $FindBin::Bin.'/../docs/merge-tree.pod';
        my $msg = undef;
        
        if (!-e $input) {
            $input = $0;
            $msg = colored("Error: Unable to locate documentation. Try running \"man ngt-$opts->{mode}\" for addiitonal information",'warn');
            # TODO: Better way of resolving this, or move pod docs back in here
        }

        pod2usage(-exitval => 0,
                  -verbose => $pv,
                  -input => $input,
                  -msg => $msg
                  );
            
    }    
    # First unparsed argument indicates operation (ie: pull, merge, or checkout)
    if (@ARGV > 0) {
        $opts->{base} = shift @ARGV if @ARGV > 2;
        $opts->{branch} = (@ARGV > 1) ? shift @ARGV : "HEAD";
        $opts->{branch2} = shift @ARGV if @ARGV > 0;
    } elsif (!$opts->{branch}) {
        pod2usage(-exitval => 1,
                  -verbose => 1,
                  -msg => colored("Target branch, tag, or commit must be specified",'error'),
            );
    }

    $ngt->start(verbose => $opts->{verbose}, level => 0);

}

sub root_merge_tree {
    # TODO: Consider adding automatic pagination option via IO::Page
    my @objs;
    
    # Verify that a merge target (branch/tag/hash) was specified
    die "Merge preview requires a branch, tag, or commit.\n" unless $opts->{branch};

    if ($opts->{'ngtstrategy'} eq 'branch') {
        $ngt->foreach({
            'breadth_first' => sub {
                push(@objs, do_merge_tree($opts->{branch}, $opts->{branch2}) );
            },
            'run_root' => 1,
           });
    } else {
        # Execute for root repo, which will in turn follow submodule references           
        @objs = do_merge_tree($opts->{branch}, $opts->{branch2});
    }

    # Display results
    if ($opts->{json}) {
        say encode_json(\@objs);
    } elsif ($opts->{patch}) {
        foreach my $obj (@objs) {
            say "diff $opts->{branch} $opts->{branch2}";
            # TODO: Normalize relative path
            say "--- $opts->{branch}/$obj->{parent}/$obj->{name}";
            say "+++ $opts->{branch2}/$obj->{parent}/$obj->{name}";
            say $obj->{diff};
        }                    
    } else {
        # TODO: Enable pagination (see ngt diff)
        
        say colored("NOTICE: This is an experimental feature", 'warn');
        
        say Dumper(@objs) if $opts->{verbose};

        if ($opts->{full}) {
            say colored("Displaying all incoming changes",'warn');
            foreach my $obj (@objs) {
                say colored($obj->{name},'info');
                say $obj->{diff};
            }            
        } elsif (@all_conflicts) {
            say colored("Displaying ".scalar(@all_conflicts)." potential conflicts",'warn');
            foreach my $obj (@all_conflicts) {
                say colored($obj->{name},'info');
                say $obj->{diff};
            }
        }
    
        say colored("Diffs found for ".scalar(@objs)." objects, $cnt_files files, across $cnt_submodules submodules with $cnt_conflicts potential conflicts in $cnt_submodule_conflicts submodules",'info');
    }
}

# TODO: Refactor to return an obj, with nested results
sub do_merge_tree { # TODO: Rename merge-tree
    my $base = (@_ > 2) ? shift : $opts->{base};
    my $b1 = shift; # Destination branch, typically HEAD
    my $b2 = shift; # Source branch
    my $pwd = getcwd();
    $cnt_submodules++;

    my $local_conflicts = 0;
    
    # Calculate base if not provided
    if (!$base) {
        my ($err, $stdout, $stderr) = $ngt->run("git merge-base $b1 $b2");
        
        if ($err) {
            say $stdout if $stdout;
            say $stderr if $stderr;
            die colored("Failed to find common ancestor of $b1 and $b2",'error').'\n';
        }
        $base = $stdout;
        chomp($base);
    }
    
    # Run Merge-tree
    my $cmd = "git merge-tree $base $b1 $b2";

    my ($err, $stdout, $stderr) = $ngt->run($cmd);
    if ($err) {
        say $stdout if $stdout;
        say $stderr if $stderr;
        die colored("ERROR Previewing Merge", 'red')."\n"; # TODO/VERIFY: For strategy=branch, we likely want to fail silently
    }

    # NOTES On merge-tree output format
    #       First line will be "merged" or "added in both" or ?
    #       result|our|their     mode    obj   name
    #            mode is file mode
    #            for submodules, obj is the committed ref
    #            name is the name of the file. If name is a directory, then it is a submodule
    #
    # status line: 'merged', 'changed in both', 'added in remote', or other state string
    #
    # Info line repeats 2-4 times (result, base, our, their)
    # info line:  /^\s{2}(?<src>\w+) (?<mode>\d+) (?<obj>[a-f0-9]+) (?<name>.+)$/
    #
    # May be followed by diff (next line starts with @@, no clear delimiter for end of section)

    my @lines = split('\n', $stdout);
    my @objs;
    while(@lines) {
        my %obj = (parent => $pwd);
        # TODO: Normalized name
        
        # First line in set is a state indication (ie: 'merged','changed in both','added in remote')
        my $state = shift @lines;
        die "Regex error (DEBUG)" unless $state =~ /^\w+/;
        chomp($state);
        $obj{state} = $state;

        # Next line(s) are status lines
        while( @lines && $lines[0] =~ /^\s+(?<src>\w+)\s+(?<mode>\d+)\s+(?<obj>[a-f0-9]+)\s+(?<name>.+)$/ ) {
            $obj{details}{$+{src}} = { src => $+{src}, mode => $+{mode}, obj => $+{obj}, name => $+{name} };
            shift @lines;

            if ($obj{name}) {
                $obj{moved} = 1 if $obj{name} ne $+{name}; # VERIFY
            } else {
                $obj{name} = $+{name};
                # TODO: Normalize name/path to root repo
            }
        }
        die "DBG: Regex error (no matches) for >>>>$lines[0]<<<<" if scalar(keys %{$obj{details}}) == 0;
        

        # Check if this is a submodule. NOTE: This may not work if a submodule is new, uninitialized, or renamed
        # TODO: Option to calculate delta commits for submodule
        if (-d $obj{name}) {
            $cnt_submodules++;
            $obj{is_submodule} = 1;

            if ($opts->{ngtstrategy} eq 'ref' && scalar(keys %{$obj{details}})>1 ) {
                my ($subbase, $subb1, $subb2);

                #say "Submodule $obj{name} found at ".getcwd(); say Dumper(\%obj);
                chdir($obj{name}) || die "Can't cd to $obj{name}";
                if ($state eq "merged") {
                    $subb1 = $obj{details}{our}{obj};
                    $subb2 = $obj{details}{result}{obj};
                    die "ERROR HANDLING TOOD: $state did not define our and/or result fields" unless $subb1 && $subb2;
                    push(@objs, do_merge_tree($subb1, $subb2));
                } elsif ($state eq "changed in both") {
                    $subb1   = $obj{details}{our}{obj};
                    $subb2   = $obj{details}{their}{obj};
                    $subbase = $obj{details}{base}{obj};
                    die "ERROR HANDLING TOOD: $state did not define one of 'our'=$subb1,'their'=$subb2,'details'=$subbase fields" unless $subb1 && $subb2 && $subbase;
                    push(@objs, do_merge_tree($subbase,$subb1, $subb2));
                } else {
                    die "TODO: state $state not yet handled";
                }
                chdir($pwd);
            }
        } else {
            $cnt_files++;
        }

        # Parse any diffs
        my @diff_lines;
        if ( @lines && $lines[0] =~ /^@@/) {
            # Loop until we hit a status line (should be the next line to start with a character, not a symbol or space)
            # And count conflicts (and regex parsing consistency
            my $cnt_conflict_markers = 0;
            while(@lines && $lines[0] !~ /^\w+/) {
                my $line = shift @lines;

                # NOTE: We do not match the '=+' markers as, unfortunately, it is susceptible to false positives
                my ($marker1, $marker2) = $line =~ /^([\+-])([<>]+(\s\.(?:our|their))?$)?/;
                
                # TODO: Colorize output based on first char, unless --json, --patch, or --no-color
                # TODO: Check for conflict start/end markers (count all 3, and give warning if counts differ as a sign our parsing has glitched)
                $cnt_conflict_markers++ if $marker2;
                
                push( @diff_lines, $line );
            }
            die "Parsing Error: Uneven number of conflict markers detected ($cnt_conflict_markers) in $pwd for ".Dumper(%obj) if ($cnt_conflict_markers % 2 != 0);
            $obj{conflicts} += $cnt_conflict_markers/2;
        }
        $obj{diff} = join("\n",@diff_lines) if @diff_lines > 0;

        # Collect statistics
        if ($obj{conflicts}) {
            $local_conflicts += $obj{conflicts};
            push(@all_conflicts, \%obj);
        }
        push(@objs, \%obj);
    }

    if ($local_conflicts) {
        $cnt_submodule_conflicts++;
        $cnt_conflicts += $local_conflicts;
    }
    return @objs;
    
}

