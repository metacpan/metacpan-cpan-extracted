use strict;
use warnings;

use Test::More;
use Test::File qw/file_not_exists_ok/;
use Config::Simple qw//;
use Cwd qw/abs_path cwd/;
use File::Spec  qw/catpath splitpath splitdir/;
use File::Path  qw/rmtree mkpath/;
use File::Temp  qw/tempdir tempfile/;
use File::Touch qw//;
use File::Find::Rule qw//;
use File::Find qw//;

##
## Test Setup - Create a .task file for this test that points to a temporary
##              test root, then load the task file.
##
my $test_root = tempdir("file_cleanup_test_XXXXX", CLEANUP => 1);
my $task_file = _create_task_file($test_root);
my $cwd       = cwd();

my $Config = Config::Simple->new(syntax=>'ini');
$Config->read($task_file);

use_ok('File::CleanupTask');

##
## TEST A - Releases scenario
##
## This test will try to simulate a situation in which code releases are kept in
## a releases/ directory within the test root. However, the *active* releases
## are symlinked within the test root directory. All the files created will have
## a modification and access time that is way back in the past (i.e., all files
## can be potentially deleted).
##
{
    my $task_name = 'TEST_A';
    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');

    is(
        $dir_to_cleanup, 
        "$test_root/home/test/releases",
        "Got correct path from config"
    );

    is(
        $dir_keep_if_linked_in,
        "$test_root/home/test",
        "Got correct keep_if_linked_in from config"
    );

    my $cleanup = File::CleanupTask->new(
        {
            'conf'     => $task_file,   
            'taskname' => $task_name,
        }
    );
    
    _make_structure($dir_to_cleanup, [qw(
        /52873.activated/ [oldR]
        /52808.activated/ [oldR]
        /52930/           [oldR]
        /52504.activated/ [oldR]
        /52544.activated/ [oldR]
        /52591.activated/ [oldR]
        /52613.activated/ [oldR]
        /52679.activated/ [oldR]
        /52717.activated/ [oldR]
        /52742.activated/ [oldR]
        /52537.activated/ [oldR]
        /52562.activated/ [oldR]
        /52598.activated/ [oldR]
        /52655.activated/ [oldR]
        /52688.activated/ [oldR]
        /52728.activating/ [oldR]
        /52791.activated/ [oldR]
        /code.copy.done/  [oldR]
    )]);


    ## Also touch another old file and directory that we don't want to delete
    ##
    _make_structure($dir_keep_if_linked_in, [qw(
        .bashrc [oldR]
        /working/savio/hack.sh [oldR]
    )]);
     
    SKIP:
    {
        ## Create 'code/' and 'previous/' symlinks.  We use a double slash in
        ## the symlink to make sure that we are normalizing paths correctly
        ## (it is possible to create symlinks with multiple consecutive
        ## slashes that still work as expected).
        ##
        ## Possible situation in which symlinks can't be created: FAT32 FS
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${dir_keep_if_linked_in}/code",
                  target  => "$cwd/${dir_to_cleanup}//52873.activated",
                },
                { symlink => "${dir_keep_if_linked_in}/previous",
                  target  => "releases//52808.activated",
                },
                { symlink => "${dir_keep_if_linked_in}/launch_candidate",
                  target  => "releases/52930",
                },
            ]
        );
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
     
        $cleanup->run();

        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
 
        # We should have the directories the symlinks link to plus other
        # unrelated old content still there...
        #
        my @expected = _make_expected_list($test_root, [ qw(
            /home/test/.bashrc
            /home/test/code
            /home/test/previous
            /home/test/launch_candidate
            /home/test/working/savio/hack.sh
            /home/test/releases/52930/
            /home/test/releases/52873.activated/
            /home/test/releases/52808.activated/
        )]);

        is_deeply(
            \@dirs_after_cleanup,
            \@expected, 
            'TEST A - Releases scenario'
        ) or diag(_dump_arrays(\@dirs_after_cleanup, \@expected));
    }

    _subtest_ended();
}

##
## TEST B - Check if we are able to preserve specified patterns of filenames.
##
{
    my $cleanup_filtering = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_B',
    });

    ## Create files/dirs - and make ___the leaves___ of the dirtree old.
    ##
    _make_structure($test_root, [qw(
      /dat/10/11/12.txt.gz       [old]
      /bar/1/2/3/4/5/6/7/8/9.txt [old]
      /empty/1/2/     [old]
      /foo/1/a.txt    [old]
      /foo/1/b.txt    [old]
      /foo/1/c.txt    [old]
      /foo/2/a.txt    [old]
      /foo/2/b.txt.gz [old]
      /foo/2/c.txt.gz [old]
      /empty_no_subs/ [old]
    )]);
    
    $cleanup_filtering->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );

    ## - - - Moment of truth - - -
    ##
    ## All "*.txt.gz" files should still be there.
    ## We delete files and directory differently:
    ##
    ## Files: must be old
    ## Directory: must be empty (no matter what)
    ## 
    ## Because recursive is specified in the task file, we delete files and
    ## directories down in the tree.
    ##
    ## given 'recursive = 1' in the config:
    ##   * 9.txt is deleted as it is old + down in the tree
    ##   * /bar/.../8 is deleted because is empty after 9.txt is deleted
    ##   * the same as above for /foo/1, /empty_no_subs, /empty
    ##   * foo/2 cannot be deleted as it wasn't touched.
    ##
    ## 'prune_empty_directory' in the config, only works if directories in
    ## test_root are empty (and old), therefore:
    ##   * /old_and_empty is deleted
    ##
    my @expected = _make_expected_list($test_root, [qw(
        /foo
        /foo/2
        /foo/2/b.txt.gz
        /foo/2/c.txt.gz
        /dat
        /dat/10
        /dat/10/11
        /dat/10/11/12.txt.gz
    )]);
    
    is_deeply(\@dirs_after_cleanup, \@expected, 'TEST B - Save *.txt.gz files');

    _subtest_ended();
}
       
##
## TEST C - Check if we are able to preserve specified patterns of filenames
## (i.e., TEST B), but touch all the directory tree (instead of leaves only!)
##
{
    my $cleanup_filtering = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_C'
    });

    _make_structure($test_root, [qw(
      /bar/1/2/3/4/5/6/7/8/9.txt [oldR]
      /dat/10/11/12.txt.gz       [oldR]
      /empty/1/2/  [oldR]
      /foo/1/a.txt [oldR]
      /foo/1/b.txt [oldR]
      /foo/1/c.txt [oldR]
      /foo/2/a.txt [oldR]
      /foo/2/b.txt.gz [oldR]
      /foo/2/c.txt.gz [oldR]
      /empty_no_subs/ [oldR]
    )]);
    
    $cleanup_filtering->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
    
    ## - - - Moment of truth - - -
    ##
    ## All of the directories in TEST2 have been deleted...
    ## ... plus, /empty, and that's because all of it's subdirectories are old.
    ##
    my @expected = _make_expected_list($test_root, [qw(
        /foo/2/b.txt.gz
        /foo/2/c.txt.gz
        /dat/10/11/12.txt.gz
    )]);

    is_deeply(
        \@dirs_after_cleanup, 
        \@expected, 
        'TEST C - Recursively save pattern *.txt.gz'
    );

    _subtest_ended();
}


##
## TEST D - Handle complex situations with internal and external cross-directory
## links.
##
{
    my $task_name = 'TEST_D';
    
    my $cleanup_test = File::CleanupTask->new({
        conf     => $task_file,
        taskname => $task_name,
    });

    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');

    is(
        $dir_to_cleanup,
        "$test_root/foo", 
        "Got correct path from config"
    );

    is(
        $dir_keep_if_linked_in,
        $test_root, 
        "Got correct keep_if_linked_in from config"
    );

    SKIP:
    {
        _make_structure($test_root, [qw(
          /bar/1/2/3/4/5/6/7/8/9.txt.gz [oldR]
          /empty/1/2/ [oldR]
          /foo/txt/a.txt [oldR]
          /foo/txt/b.txt [oldR]
          /foo/txt/c.txt [oldR]
          /foo/gz/a.txt.gz [oldR]
          /foo/gz/b.txt.gz [oldR]
          /foo/gz/c.txt.gz [oldR]
        )]);
        
        ## Create symlinks:
        ##
        ## '/b.lnk -> foo/b.txt' and '/c.lnk' -> 'foo/2/c.txt.gz'
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${dir_keep_if_linked_in}/b.lnk",
                  target  => "$cwd/${dir_to_cleanup}/txt/b.txt",
                },
                { symlink => "${dir_keep_if_linked_in}/c.lnk",
                  target  => "$cwd/${dir_to_cleanup}/gz/c.txt.gz",
                },
                { symlink => "${dir_to_cleanup}/txt/a.lnk",    
                  target  => "$cwd/${dir_to_cleanup}/gz/a.txt.gz",
                },
            ]
        );
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }

        ## - - - Summary of the current situation and expectation - - -
        ##
        ## We have the following structure within $test_root:
        ##
        ## [old] ./bar/1/2/3/4/5/6/7/8/9.txt.gz  ( to keep, outside path )
        ## [old] ./empty/1/2/                    ( to keep, outside path )
        ## [old] ./foo/txt/a.txt                 ( keep, matches *.txt )
        ## [old] ./foo/txt/b.txt                 ( keep, matches *.txt )
        ## [old] ./foo/txt/c.txt                 ( keep, matches *.txt )
        ## [old] ./foo/gz/a.txt.gz               ( to delete, symlinked not at
        ##                                         top level )
        ## [old] ./foo/gz/b.txt.gz               ( to delete, old + no match )
        ## [old] ./foo/gz/c.txt.gz               ( keep, symlinked! )
        ## [new] ./foo/txt/a.lnk -> [old] ./foo/gz/a.txt.gz ( to keep, symlink is new )
        ## [new] ./b.lnk -> [old] ./foo/txt/b.txt  ( keep, a toplevel symlink )
        ## [new] ./c.lnk -> [old] ./foo/gz/c.txt.gz ( keep, a toplevel symlink
        ##                                           that refers to something
        ##                                           in the cleanup directory )

        ## Cleanup
        ##
        $cleanup_test->run();
        
        ## - - - Moment of truth - - -
        ##
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );

        my @expected = _make_expected_list($test_root, [qw(
            /c.lnk
            /b.lnk
            /foo/txt/a.lnk
            /foo/txt/a.txt
            /foo/txt/b.txt
            /foo/txt/c.txt
            /foo/gz/c.txt.gz
            /empty/1/2
            /bar/1/2/3/4/5/6/7/8/9.txt.gz
        )]);

        # Everything worked?
        is_deeply (
            \@dirs_after_cleanup,
            \@expected, 
            'TEST D - Handle complex situation with internal/external'
            . ' cross-directory symlinks, patterns to save.'
        );
    }

    _subtest_ended();
}


##
## TEST E - Directories are pruned correctly (non-recursive mode, max_days=0)
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_E'
    });
    _make_structure($test_root, [qw(
        /empty/a/1/2/ [new]
        /empty/b/1/2/4/5/6/ [new]
        /foo/1/a.txt [new]
        /foo/2/b.txt [new]
        /foo/2/c.txt [new]
        /foo/3/ [new]
        /fie [new]
        /xfoobar/ [newR]
    )]);
    
    $cleanup->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
    
    ## - - - Moment of truth - - -
    my @expected = _make_expected_list($test_root, [qw(
        /empty/a/1/2/
        /empty/b/1/2/4/5/6/
        /foo/1/a.txt
        /foo/2/b.txt
        /foo/2/c.txt
        /foo/3/
    )]);

    is_deeply(
        \@dirs_after_cleanup, 
        \@expected, 
        'TEST E - Test prune_empty_directories works correctly (non-recursive, max_days=0)'
    ) or diag(_dump_arrays(\@dirs_after_cleanup, \@expected));
    
    _subtest_ended();
}

##
## TEST E1 - Directories are pruned correctly (non-recursive mode, max_days=7)
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_E1'
    });
    _make_structure($test_root, [qw(
        /empty/a/1/2/ [new]
        /empty/b/1/2/4/5/6/ [new]
        /foo/1/a.txt [new]
        /foo/2/b.txt [new]
        /foo/2/c.txt [new]
        /foo/3/ [new]
        /fie [new]
        /bla [old]
    )]);
    
    $cleanup->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
    
    ## - - - Moment of truth - - -
    my @expected = _make_expected_list($test_root, [qw(
        /empty/a/1/2/
        /empty/b/1/2/4/5/6/
        /foo/1/a.txt
        /foo/2/b.txt
        /foo/2/c.txt
        /foo/3/
        /fie
    )]);

    is_deeply(
        \@dirs_after_cleanup, 
        \@expected, 
        'TEST E1 - Test prune_empty_directories works correctly (non-recursive, max_days=7)'
    ) or diag(_dump_arrays(\@dirs_after_cleanup, \@expected));
    
    _subtest_ended();
}

##
## TEST F - Directories are pruned correctly (recursive mode, max_days=0)
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_F',
    });
    _make_structure($test_root, [qw(
        /empty/a/1/2/ [new]
        /empty/b/1/2/4/5/6/ [new]
        /foo/1/a.txt [new]
        /foo/2/b.txt [new] 
        /foo/2/c.txt [new]
        /foo/3/      [new]
        /fie         [new]
    )]);
    
    $cleanup->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
    
    ## - - - Moment of truth - - -
    my @expected = _make_expected_list($test_root, [qw(
        /foo/1/a.txt
        /foo/2/b.txt
        /foo/2/c.txt
    )]);

    is_deeply(
        \@dirs_after_cleanup,
        \@expected, 
        'TEST F - Test prune_empty_directories works correctly (recursive, max_days=0)'
    );

    _subtest_ended();
}

##
## TEST F1 - Directories are pruned correctly (recursive mode, max_days=7)
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_F1',
    });
    _make_structure($test_root, [qw(
        /empty/a/1/2/ [new]
        /empty/b/1/2/4/5/6/ [new]
        /empty/c/1/2 [old]
        /empty/d/    [oldR]
        /foo/1/a.txt [new]
        /foo/2/b.txt [new] 
        /foo/2/c.txt [new]
        /foo/3/      [new]
        /fie         [new]
        /bla         [old]
    )]);
    
    $cleanup->run();
    
    my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
    
    ## - - - Moment of truth - - -
    my @expected = _make_expected_list($test_root, [qw(
        /empty/a/1/2/
        /empty/b/1/2/4/5/6/
        /foo/1/a.txt
        /foo/2/b.txt
        /foo/2/c.txt
        /foo/3/
        /fie
    )]);

    is_deeply(
        \@dirs_after_cleanup,
        \@expected, 
        'TEST F1 - Test prune_empty_directories works correctly (recursive, max_days=7)'
    ) or diag(_dump_arrays(\@dirs_after_cleanup, \@expected));

    _subtest_ended();
}

##
## TEST G - Test scenario
##
{
    my $task_name = 'TEST_G';
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => $task_name,
    });
    
    ## Check that we will be working in the test_root
    ##
    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');

    my @lookups = map { "$dir_to_cleanup$_" } qw(
        /uk.geov2.20120313.53011/ /es.geov2.20120313.53011/
        /de.geov2.20120312.52975/ /fr.geov2.20120312.52975/
        /es.geov2.20120309.52932/ /au.geov2.20120309.52932/
        /de.geov2.20120309.52932/ /br.geov2.20120308.52893/
        /br.geov2.20120307.52873/ /au.geov2.20120307.52873/
        /in.geov2.20120307.52873/ /es.geov2.20120307.52873/
        /de.geov2.20120306.52841/ /fr.geov2.20120305.52802/
        /uk.geov2.20120305.52802/ /es.geov2.20120305.52802/
        /it.geov2.20120302.52774/ /in.geov2.20120301.52733/
        /fr.geov2.20120302.52774/ /br.geov2.20120302.52774/
        /au.geov2.20120302.52774/ /uk.geov2.20120301.52733/
        /es.geov2.20120302.52774/ /au.geov2.20120227.52655/
        /au.geov2.20120228.52678/ /de.geov2.20120227.52655/
        /es.geov2.20120301.52733/ /br.geov2.20120301.52733/
        /au.geov2.20120229.52717/ /de.geov2.20120301.52733/
        /es.geov2.20120229.52717/ /in.geov2.20120227.52655/
        /br.geov2.20120226.52655/ /fr.geov2.20120221.52528/
        /it.geov2.20120222.52561/ /de.geov2.20120221.52528/
        /es.geov2.20120221.52528/ /it.geov2.20120217.52450/
        /uk.geov2.20120220.52490/ /uk.geov2.20120217.52450/
        /in.geov2.20120215.52369/ /it.geov2.20120215.52369/
        /au.geov2.20120210.52249/ /es.geov2.20120209.52208/
        /uk.geov2.20120208.52191/ /uk.geov2.20120207.52164/
        /es.geov2.20120206.52115/ /fr.geov2.20120203.52082/
        /es.geov2.20120203.52082/ /br.geov2.20120129.51864/
        /in.geov2.20120129.51864/ /de.geov2.20120202.52029/
        /es.geov2.20120130.51864/ /br.geov2.20120125.51757/
        /es.geov2.20120127.51832/ /it.geov2.20120115.51486/
        /in.geov2.20120115.51486/ /br.geov2.20120115.51486/
        /es.geov2.20120116.51486/ /it.geov2.20120106.51240/
        /in.geov2.20120105.51195/ /es.geov2.20111223.50990/
        /br.geov2.20111223.50988/ /fr.geov2.20111221.50898/
        /it.geov2.20111221.50898/ /it.geov2.20111213.50686/
        /de.geov2.20111208.50589/ /uk.geov2.20111206.50538/
        /fr.geov2.20111205.50505/ /uk.geov2.20111201.50422/
        /in.geov2.20111201.50422/ /es.geov2.20111201.50421/
        /de.geov2.20111201.50421/ /br.geov2.20111201.50422/
        /au.geov2.20111201.50422/
    );

    my @files = ();
    foreach (@lookups) {
        push (@files, $_);
        push (@files, "$_");
        push (@files, "${_}autosuggest.db"     );
        push (@files, "${_}geoid_attributes.db");
        push (@files, "${_}geoid_grid.asc"     );
        push (@files, "${_}geoid_grid.asc.db"  );
        push (@files, "${_}wordindex.db"       );
        push (@files, "${_}sitemap/index0001"  );
        push (@files, "${_}sitemap/index0002"  );
        push (@files, "${_}sitemap/index0003"  );
        push (@files, "${_}sitemap/sitemap9.gz");
        push (@files, "${_}sitemap/sitemap_index.xml");
    }

    _touch_am_time(
        \@files,  
        '978307200',
        $test_root,
        1,
    );

    SKIP:
    {
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${dir_keep_if_linked_in}/in",
                  target  => "$cwd/${test_root}/home/geobuild/common/geo/lookups/in.geov2.20120307.52873",
                },
                { symlink => "${dir_keep_if_linked_in}/br",
                  target  => "$cwd/${test_root}/home/geobuild/common/geo/lookups/br.geov2.20120308.52893",
                },
                { symlink => "${dir_keep_if_linked_in}/au",    
                  target  => "$cwd/${test_root}/home/geobuild/common/geo/lookups/au.geov2.20120309.52932",
                },
                { symlink => "${dir_keep_if_linked_in}/fr",    
                  target  => "$cwd/${test_root}/home/geobuild/common/geo/lookups/fr.geov2.20120312.52975",
                },
                { symlink => "${dir_keep_if_linked_in}/de",
                  target  => "de.geov2.20120312.52975",
                },
                { symlink => "${dir_keep_if_linked_in}/uk",
                  target  => "$cwd/${test_root}/home/geobuild/common/geo/lookups/uk.geov2.20120313.53011",
                },
                { symlink => "${dir_keep_if_linked_in}/es",
                  target  => "es.geov2.20120313.53011",
                },
                { symlink => "${dir_keep_if_linked_in}/it",
                  target  => "it.geov2.20120302.52774",
                },
            ]
        );
        skip('Symlink was not created. Does the OS support symlinks?', 1) if !$symlink_success;

        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
        
        ## - - - Moment of truth - - -
        ##
        ## All of the directories in TEST2 have been deleted...
        ## ... plus, /empty, and that's because all of it's subdirectories are old.
        ##
        my @expected = _make_expected_list($test_root, [qw(
            /home/geobuild/common/geo/lookups/in
            /home/geobuild/common/geo/lookups/br
            /home/geobuild/common/geo/lookups/au
            /home/geobuild/common/geo/lookups/fr
            /home/geobuild/common/geo/lookups/de
            /home/geobuild/common/geo/lookups/uk
            /home/geobuild/common/geo/lookups/es
            /home/geobuild/common/geo/lookups/it
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/autosuggest.db
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/geoid_attributes.db
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/geoid_grid.asc
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/wordindex.db
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/sitemap/index0001
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/sitemap/index0002
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/sitemap/index0003
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/it.geov2.20120302.52774/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/autosuggest.db
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/geoid_attributes.db
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/geoid_grid.asc
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/wordindex.db
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/sitemap/index0001
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/sitemap/index0002
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/sitemap/index0003
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/es.geov2.20120313.53011/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/autosuggest.db
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/geoid_attributes.db
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/geoid_grid.asc
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/wordindex.db
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/sitemap/index0001
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/sitemap/index0002
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/sitemap/index0003
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/uk.geov2.20120313.53011/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/autosuggest.db
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/geoid_attributes.db
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/geoid_grid.asc
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/wordindex.db
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/sitemap/index0001
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/sitemap/index0002
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/sitemap/index0003
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/de.geov2.20120312.52975/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/autosuggest.db
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/geoid_attributes.db
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/geoid_grid.asc
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/wordindex.db
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/sitemap/index0001
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/sitemap/index0002
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/sitemap/index0003
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/in.geov2.20120307.52873/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/autosuggest.db
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/geoid_attributes.db
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/geoid_grid.asc
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/wordindex.db
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/sitemap/index0001
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/sitemap/index0002
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/sitemap/index0003
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/br.geov2.20120308.52893/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/autosuggest.db
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/geoid_attributes.db
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/geoid_grid.asc
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/wordindex.db
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/sitemap/index0001
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/sitemap/index0002
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/sitemap/index0003
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/au.geov2.20120309.52932/sitemap/sitemap_index.xml
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/autosuggest.db
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/geoid_attributes.db
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/geoid_grid.asc
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/geoid_grid.asc.db
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/wordindex.db
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/sitemap/index0001
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/sitemap/index0002
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/sitemap/index0003
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/sitemap/sitemap9.gz
            /home/geobuild/common/geo/lookups/fr.geov2.20120312.52975/sitemap/sitemap_index.xml
        )]);

        is_deeply(\@dirs_after_cleanup, \@expected, 'TEST G - Test scenario');
    }

    _subtest_ended();
}


##
## TEST H - Links from within a subdirectory
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_H',
    });
    _make_structure($test_root, [qw(
        /x [newR]
        /y [newR]
        /z [newR]
        /old_file1 [newR]
        /old_file2 [newR]
        /old_file3 [newR]
        /control_area/special_old_file [newR]
    )]);

    SKIP:
    {
        ##
        ## Add links to the control area
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${test_root}/control_area/x.lnk",
                  target  => "$cwd/${test_root}/x",
                },
                { symlink => "${test_root}/control_area/y.lnk",
                  target  => "$cwd/${test_root}/y",
                },
                { symlink => "${test_root}/control_area/z.lnk",
                  target  => "$cwd/${test_root}/z",
                },
                { symlink => "${test_root}/control_area/xxxx.lnk",  # a broken symlink
                  target  => "$cwd/${test_root}/xxxx",
                  broken  => 1,
                },
        ]);

        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
        
        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
        
        ## - - - Moment of truth - - -
        my @expected = _make_expected_list($test_root, [qw(
            /x
            /y
            /z
            /control_area/x.lnk
            /control_area/y.lnk
            /control_area/z.lnk
            /control_area/xxxx.lnk
        )]);

        is_deeply(
            \@dirs_after_cleanup, 
            \@expected, 
            'TEST H - Test prune_empty_directories works correctly (recursive)'
        );
    }

    _subtest_ended();
}


##
## TEST I - Pattern is applied to the full directory pathname
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_I',
    });

    _make_structure($test_root, [qw(
        /old/files/1 [newR]
        /old/files/2 [newR]
        /old/files/3 [newR]
        /old.copy.done/file1 [newR]
        /old.copy.done/file2 [newR]
        /old.copy.done/file3 [newR]
        /old.copy.done/deeper_directory/file4 [newR]
    )]);

    SKIP:
    {
        ##
        ## Add links to the control area
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${test_root}/x.lnk",
                  target  => "$cwd/${test_root}/old/files/2",
                },
        ]);

        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
        
        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
        
        ## - - - Moment of truth - - -
        my @expected = _make_expected_list($test_root, [qw(
            /old/files/2
            /old.copy.done/file1
            /old.copy.done/file2
            /old.copy.done/file3
            /old.copy.done/deeper_directory/file4
            /x.lnk
        )]);

        is_deeply(
            \@dirs_after_cleanup,
            \@expected, 
            'TEST I - pattern is applied to the full pathname of a file'
        );
    }
    
    _subtest_ended();
}

##
## Test L - keep if linked in option
##
{
    my $task_name = 'TEST_L';
    my $cleanup_keep = File::CleanupTask->new(
	{
	    'conf'     => $task_file,
	    'taskname' => $task_name,
	});

    _make_structure($test_root, [qw(/a [newR])]);

    SKIP:
    {
	my $symlink_success = _make_symlinks( [ 
	    { symlink => "$test_root/b",
	      target  => "$cwd/$test_root/a",
	    },
	]);

	if (!$symlink_success) {
	    skip('Symlink was not created. Does the OS support symlinks?', 1);
	}


	$cleanup_keep->run();

	# Moment of truth. Find all the inodes still remaining in the temp. directory
	my @after_inodes = File::Find::Rule->in( $test_root );
	@after_inodes = sort(@after_inodes);

	my @expected = "$test_root";
	push (@expected, sort map { "$test_root/$_" } qw(a b) );

	is_deeply(
	    \@after_inodes,
	    \@expected, 
	    "TEST L - Because of the symlink, files a and b are kept"
	);

	# Cleanup
	unlink @after_inodes;
    }

    _subtest_ended();
}


##
## TEST M - a file gets deleted without a symlink
##
{
    my $task_name = 'TEST_M';

    _make_structure($test_root, [qw(/a [newR])]);

    my $cleanup_delete = File::CleanupTask->new({
        conf=> $task_file,
        taskname => $task_name,
    });
    $cleanup_delete->run();
    file_not_exists_ok(
        "$test_root/a", 
        "TEST M  without a symlink, the file is deleted"
    );

    _subtest_ended();
}


##
## TEST N - Test that we correctly handle releases scenario when a symlink is
## included in the pathname specified in the configuration file.
##
## Main problem here would be that, when following the symlink given by the
## user, the resulting path is resolved in the canonical path, which may be
## different from the specified path (hence, no file within it is deleted).
##
{
    my $task_name = "TEST_N";
    ## Check that we will be working in the test_root
    ##
    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');

    is(
        $dir_to_cleanup,
        "$test_root/homelink/test/releases", 
        "Got correct path from config"
    );

    is(
        $dir_keep_if_linked_in,
        "$test_root/homelink/test",
        "Got correct keep_if_linked_in from config"
    );
    
    ## Create code files - and make them old as hell
    ##
    _make_structure("$test_root/home/test/releases", [qw(
        /52873.activated/ [978307200R]
        /52808.activated/ [978307200R]
        /52930/           [978307200R]
        /52504.activated/ [978307200R]
        /52544.activated/ [978307200R]
        /52591.activated/ [978307200R]
        /52613.activated/somefile [978307200R]
        /52679.activated/ [978307200R]
        /52717.activated/ [978307200R]
        /52742.activated/somedir/somefile [978307200R]
        /52537.activated/ [978307200R]
        /52562.activated/someotherfile [978307200R]
        /52598.activated/ [978307200R]
        /52655.activated/ [978307200R]
        /52688.activated/ [978307200R]
        /52728.activating/ [978307200R]
        /52791.activated/  [978307200R]
        /code.copy.done/   [978307200R]
    )]);

    SKIP:
    {
        ## Create 'code/' and 'previous/' symlinks.  We use a double slash in
        ## the symlink to make sure that we are normalizing paths correctly
        ## (it is possible to create symlinks with multiple consecutive
        ## slashes that still work as expected).
        ##
        ## Possible situation in which symlinks can't be created: FAT32 FS
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "$test_root/homelink",
                  target  => "$cwd/$test_root/home",
                },
                { symlink => "$test_root/home/test/code",
                  target  => "$cwd/${dir_to_cleanup}//52873.activated/",
                },
                { symlink => "$test_root/home/test/previous",
                  target  => "releases//52808.activated",
                },
                { symlink => "$test_root/home/test/launch_candidate",
                  target  => "releases/52930",
                },
            ]
        );
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }

        my $cleanup = File::CleanupTask->new(
            {
                'conf'     => $task_file,   
                'taskname' => $task_name,
            }
        );
     
        ## Delete the files
        ## 
        $cleanup->run();

        ## - - - Moment of truth - - -
        ##
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
 
        # We should have the directories the symlinks link to plus other
        # unrelated old content still there...
        #
        my @expected = _make_expected_list($test_root, [ qw(
            /home/test/code
            /home/test/previous
            /home/test/launch_candidate
            /home/test/releases/52930/
            /home/test/releases/52873.activated/
            /home/test/releases/52808.activated/
            /homelink
        )]);

        is_deeply(
            \@dirs_after_cleanup, 
            \@expected, 
            'TEST N - Old Releases situation with symlinked path in the config'
        );
    }

    _subtest_ended();
}


##
## TEST O - Same as TEST N, but containing circular symlinks
##
{
    my $task_name = "TEST_O";
    ## Check that we will be working in the test_root
    ##
    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');
    is(
        $dir_to_cleanup, 
        "$test_root/homelink/test/releases", 
        "Got correct path from config"
    );

    is(
        $dir_keep_if_linked_in,
        "$test_root/homelink/test", 
        "Got correct keep_if_linked_in from config"
    );
    
    ## Create code files - and make them old as hell
    ##
    _make_structure("$test_root/home/test/releases", [qw(
        /52873.activated/ [oldR]
        /52808.activated/ [oldR]
        /52930/           [oldR]
        /52504.activated/ [oldR]
        /52544.activated/ [oldR]
        /52591.activated/ [oldR]
        /52613.activated/somefile [oldR]
        /52679.activated/ [oldR]
        /52717.activated/ [oldR] 
        /52742.activated/somedir/somefile [oldR]
        /52537.activated/ [oldR]
        /52562.activated/someotherfile [oldR]
        /52598.activated/ [oldR]
        /52655.activated/ [oldR]
        /52688.activated/ [oldR]
        /52728.activating/ [oldR]
        /52791.activated/ [oldR]
        /code.copy.done/  [oldR]
        /a/file_in_a [oldR]
        /b/file_in_b [oldR]
    )]);

    SKIP:
    {
        ##
        ## Addition: a/a.lnk -> b/    and b/b.lnk -> a/
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "$test_root/homelink",
                  target  => "$cwd/$test_root/home",
                },
                { symlink => "$test_root/home/test/code",
                  target  => "$cwd/${dir_to_cleanup}//52873.activated/",
                },
                { symlink => "$test_root/home/test/previous",
                  target  => "releases//52808.activated",
                },
                { symlink => "$test_root/home/test/launch_candidate",
                  target  => "releases/52930",
                },
                { symlink => "$test_root/home/test/releases/a/a.lnk",
                  target  => "$cwd/$test_root/home/test/releases/b/",
                },
                { symlink => "$test_root/home/test/releases/b/b.lnk",
                  target  => "$cwd/$test_root/home/test/releases/a/",
                },
            ]
        );
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }

        my $cleanup = File::CleanupTask->new(
            {
                'conf'     => $task_file,   
                'taskname' => $task_name,
            }
        );
     
        ## Delete the files
        ## 
        $cleanup->run();

        ## - - - Moment of truth - - -
        ##
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
 
        # We should have the directories the symlinks link to plus other
        # unrelated old content still there...
        #
        my @expected = _make_expected_list($test_root, [ qw(
            /home/test/code
            /home/test/previous
            /home/test/launch_candidate
            /home/test/releases/52930/
            /home/test/releases/52873.activated/
            /home/test/releases/52808.activated/
            /homelink
        )]);


        is_deeply(
            \@dirs_after_cleanup, 
            \@expected, 
            'TEST O - Old Releases situation with symlinked path in the config,'
            . ' plus circular references.'
        );
    }
    
    _subtest_ended();
}

##
## TEST P - Correct bubbling.
##
## Bubbling is the process that occurs on the intermediate plan when fixing
## symlink deletion and addition. Basically the initial plan is produced
## without taking into account symlinks (as if they were not existing into the
## filesystem at all). Symlinks are processed later. If a target of a symlink
## is inside the plan, and is going to be kept, also the symlink should be
## kept. When a symlink is kept, its parent directory is automatically set to
## be kept in the plan.  Bubbling is propagating the 'do nothing (keep)' status
## up to the topmost parent of a symlink meant to be kept.
##
{
    my $cleanup = File::CleanupTask->new({
        conf      => $task_file,
        taskname  => 'TEST_P',
    });
    _make_structure($test_root, [qw(
        /a/b/c/d/ [oldR]
        /x/w.txt  [oldR]
    )]);

    SKIP:
    {
        my $symlink_success = _make_symlinks( [ 
            { symlink => "$test_root/a/b/c/d/x.lnk",
              target  => "$cwd/$test_root/x/w.txt",
            },
        ]);
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
        
        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
        
        ## - - - Moment of truth - - -
        my @expected = _make_expected_list($test_root, [qw(
            /a/b/c/d/x.lnk
            /x/w.txt
        )]);

        is_deeply(\@dirs_after_cleanup, \@expected, 'TEST P - Correct bubbling');
    }

    _subtest_ended();
}


##
## TEST Q - Correct bubbling with a file in the middle of the path.
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_Q',
    });

    _make_structure($test_root, [qw(
        /a/b/c/d/e/f/g/h/i/l/ [oldR]
        /a/b/c/d/e/e1/e2/e3/  [oldR]
        /x/w.txt [oldR]
    )]);

    SKIP:
    {
        my $symlink_success = _make_symlinks( [ 
            { symlink => "$test_root/a/b/c/d/e/f/g/h/i/l/x.lnk",
              target  => "$cwd/$test_root/x/w.txt",
            },
            { symlink => "$test_root/a/b/c/d/e/e1/e2/e3/x.lnk",
              target  => "$cwd/$test_root/x/w.txt",
            },
        ]);
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }

        
        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in($test_root);
        
        ## - - - Moment of truth - - -
        my @expected = _make_expected_list($test_root, [qw(
            /a/b/c/d/e/f/g/h/i/l/x.lnk
            /a/b/c/d/e/e1/e2/e3/x.lnk
            /x/w.txt
        )]);

        is_deeply(
            \@dirs_after_cleanup,
            \@expected, 
            'TEST Q - Correct bubbling with symlink in the path'
        );
    }
    
    _subtest_ended();
}

##
## TEST R - Correct behaviour with symlinks that point to something that should
## be deleted.
##
{
    my $cleanup = File::CleanupTask->new({
        conf     => $task_file,
        taskname => 'TEST_R',
    });

    _make_structure($test_root, [qw(
        /a/b/c/d/e/f/g/h/i/l/ [oldR]
        /a/b/c/d/e/e1/e2/e3/  [oldR]
        /x/w.txt.unwanted     [oldR]
    )]);

    SKIP:
    {
        my $symlink_success = _make_symlinks( [ 
            { symlink => "$test_root/a/b/c/d/e/f/g/h/i/l/x.lnk",
              target  => "$cwd/$test_root/x/w.unwanted",
            },
            { symlink => "$test_root/a/b/c/d/e/e1/e2/e3/x.lnk",
              target  => "$cwd/$test_root/x/w.unwanted",
            },
        ]);
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
        
        $cleanup->run();
        
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
        
        ## - - - Moment of truth - - -
        my @expected = _make_expected_list($test_root, []);

        is_deeply(
            \@dirs_after_cleanup, 
            \@expected, 
            'TEST R - Correct behaviour with symlinks that point to something that'
            . ' should be deleted'
        );
    }

    _subtest_ended();
}

##
## TEST S - Test the delete_all_or_nothing option with the current releases
## situation
##
## This option implies the cleanup algorithm to whitelist the directories
## contained in the specified path. None of the content in the whitelisted
## directories is deleted if one or more file will survive in them according to
## the plan according to the plan.
##
{
    ## Check that we will be working in the test_root
    ##
    my $task_name = "TEST_S";
    my $dir_to_cleanup        = $Config->param($task_name.'.path');
    my $dir_keep_if_linked_in = $Config->param($task_name.'.keep_if_linked_in');

    is( 
        $dir_to_cleanup,
        "$test_root/home/test/releases",
        "Got correct path from config"
    );

    is(
        $dir_keep_if_linked_in, 
        "$test_root/home/test", 
        "Got correct keep_if_linked_in from config"
    );

    my $cleanup = File::CleanupTask->new(
        {
            'conf'     => $task_file,   
            'taskname' => $task_name,
        }
    );
    
    ## Create code files - and make them old as hell
    ##
    _make_structure($dir_to_cleanup, [qw(
        /52873.activated/ [oldR]
        /52808.activated/ [oldR]
        /52930/ [oldR]
        /52504.activated/ [oldR]
        /52544.activated/ [oldR]
        /52591.activated/ [oldR]
        /52613.activated/a/path/to/an/old_file [oldR]
        /52613.activated/another/path/to/an/old_file [oldR]
        /52613.activated/yet/another/path/to/an/old_file [oldR]
        /52679.activated/ [oldR] 
        /52717.activated/ [oldR]
        /52742.activated/ [oldR]
        /52537.activated/ [oldR]
        /52562.activated/ [oldR]
        /52598.activated/old_file [oldR]
        /52655.activated/ [oldR]
        /52688.activated/ [oldR]
        /52728.activating/ [oldR]
        /52791.activated/ [oldR]
        /code.copy.done/ [oldR]
        /52598.activated/some/path/to/new_file [new]
    )]);

    ## Also touch another old file and directory that we don't want to delete
    ##
    _make_structure($dir_keep_if_linked_in, [qw(
        .bashrc [oldR]
        /working/savio/hack.sh [oldR]
    )]);
     
    SKIP:
    {
        ##
        ## Create 'code/' and 'previous/' symlinks.  We use a double slash in
        ## the symlink to make sure that we are normalizing paths correctly (it
        ## is possible to create symlinks with multiple consecutive slashes that
        ## still work as expected).
        ##
        my $symlink_success = _make_symlinks( [ 
                { symlink => "${dir_keep_if_linked_in}/code",
                  target  => "$cwd/${dir_to_cleanup}//52873.activated",
                },
                { symlink => "${dir_keep_if_linked_in}/previous",
                  target  => "releases//52808.activated",
                },
                { symlink => "${dir_keep_if_linked_in}/launch_candidate",
                  target  => "releases/52930",
                },
            ]
        );
        if (!$symlink_success) {
            skip('Symlink was not created. Does the OS support symlinks?', 1);
        }
     
        ## Delete the files
        ## 
        $cleanup->run();

        ## - - - Moment of truth - - -
        ##
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
 
        # We should have the directories the symlinks link to plus other
        # unrelated old content still there...
        #
        my @expected = _make_expected_list($test_root, [ qw(
            /home/test/.bashrc
            /home/test/code
            /home/test/previous
            /home/test/launch_candidate
            /home/test/working/savio/hack.sh
            /home/test/releases/52930/
            /home/test/releases/52873.activated/
            /home/test/releases/52808.activated/
            /home/test/releases/52598.activated/old_file
            /home/test/releases/52598.activated/some/path/to/new_file
        )]);

        is_deeply(
            \@dirs_after_cleanup,
            \@expected,
            'TEST S - delete_all_or_nothing option in the releases scenario'
        );
    }

    _subtest_ended();
}

##
## TEST T - Test the pattern option, i.e., what to consider for deletion.
##
## If a 'pattern' is specified, we should only perform actions on files that
## match.
##
{
    my $task_name = "TEST_T";
    my $dir_to_cleanup  = $Config->param($task_name.'.path');
    is($dir_to_cleanup, $test_root, "Got correct path from config");

    my $cleanup = File::CleanupTask->new(
        {
            'conf'     => $task_file,   
            'taskname' => $task_name,
        }
    );
    
    _make_structure($dir_to_cleanup, [qw(
        /ib_logfile0 [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_15_09_05_02.frm [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_13_09_05_02.frm [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_14_09_05_02.frm [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_15_09_05_02.MYI [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_16_09_05_02.frm [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_14_09_05_02.MYI [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_14_09_05_02.MYD [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_16_09_05_02.MYI [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_13_09_05_02.MYI [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_16_09_05_02.MYD [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_15_09_05_02.MYD [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_13_09_05_02.MYD [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_17_09_05_02.frm [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_17_09_05_02.MYI [5oldR]
        /searchindex_uk_realestate_build/locations_cache_si_2012_03_17_09_05_02.MYD [5oldR]
        /ib_logfile1 [5oldR]
        /mysql/ndb_binlog_index.MYD [5oldR]
        /mysql/ndb_binlog_index.MYI [5oldR]
        /mysql/slow_log.CSV [5oldR]
        /mysql/slow_log.CSM [5oldR]
        /mysql/general_log.CSM [5oldR]
        /mysql/general_log.frm [5oldR]
        /mysql/ndb_binlog_index.frm [5oldR]
        /mysql/general_log.CSV [5oldR]
        /mysql/slow_log.frm [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_15_17_05_02.frm [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_13_17_05_03.frm [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_14_17_05_02.frm [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_15_17_05_02.MYI [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_16_17_05_02.frm [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_14_17_05_02.MYI [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_14_17_05_02.MYD [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_16_17_05_02.MYI [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_13_17_05_03.MYI [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_15_17_05_02.MYD [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_16_17_05_02.MYD [5oldR]
        /searchindex_it_realestate_build/locations_cache_si_2012_03_13_17_05_03.MYD [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_14_01_05_02.frm [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_16_01_05_02.frm [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_14_01_05_02.MYI [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_16_01_05_02.MYI [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_16_01_05_02.MYD [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_17_01_05_02.frm [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_17_01_05_02.MYI [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_17_01_05_02.MYD [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_14_01_05_02.MYD [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_15_01_05_03.frm [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_15_01_05_03.MYI [5oldR]
        /searchindex_es_realestate_build/locations_cache_si_2012_03_15_01_05_03.MYD [5oldR]
    )]);

    SKIP:
    {
        ## Delete the files
        ## 
        $cleanup->run();

        ## - - - Moment of truth - - -
        ##
        my @dirs_after_cleanup = sort File::Find::Rule->in( $test_root );
 
        # We should have the directories the symlinks link to plus other
        # unrelated old content still there...
        #
        my @expected = _make_expected_list($test_root, [ qw(
            /searchindex_es_realestate_build/
            /searchindex_it_realestate_build/
            /searchindex_uk_realestate_build/
            /ib_logfile0
            /ib_logfile1
            /mysql/ndb_binlog_index.MYD
            /mysql/ndb_binlog_index.MYI
            /mysql/slow_log.CSV
            /mysql/slow_log.CSM
            /mysql/general_log.CSM
            /mysql/general_log.frm
            /mysql/ndb_binlog_index.frm
            /mysql/general_log.CSV
            /mysql/slow_log.frm
        )]);

        is_deeply(
            \@dirs_after_cleanup,
            \@expected,
            'TEST T - test "pattern" option'
        );
    }
    
    _subtest_ended();
}

done_testing();

sub _subtest_ended {
    File::Path::rmtree($test_root);
}

## Modify access and modification time of the specified files and directories.
## exclude base_dir/ from being touched or modified.
## 
sub _touch_am_time {
    my $ra_files   = shift;
    my $time_epoch = shift;
    my $base       = shift;
    my $is_recursive_touch = shift;

    # Perl 5.8.9 compatibility
    $is_recursive_touch = defined $is_recursive_touch ? $is_recursive_touch : 0;
    $time_epoch = defined $time_epoch ? $time_epoch : time;
    $base       = defined $base       ? $base : "/";
    
    my $toucher = File::Touch->new(
        atime => $time_epoch, # GMT: Mon, 01 Jan 2001 00:00:00 GMT 
        mtime => $time_epoch
    );

    foreach my $file (@$ra_files) {

        my ($volume,$dir_to_touch,$file_to_touch) = 
        File::Spec->splitpath($file);

        # Create Dir & Touch file in it
        File::Path::mkpath($dir_to_touch) if $dir_to_touch;
        $toucher->touch($file) if (defined($file_to_touch));

        # Touch all parts if recursive
        if ($is_recursive_touch) {


            my $dir = '';
        foreach my $part ( File::Spec->splitdir($dir_to_touch)) {
        if ($part) {
            $dir = File::Spec->catpath($volume, $dir, $part);
            $volume = '';
        }
        if ( $dir && index($dir, $base) >= 0 ) {
            $toucher->touch($dir);
        }
            }


        }

    }
}

=head2 _days

Returns the specified number of days in seconds.

=cut
sub _days { my $x = shift; return 60 * 60 * 24 * $x; }

=head2 _make_symlinks

Make Symlinks according to the specified configuration
$rah_params => [
   {  symlink => "some/path",
      target => "some/other/path",
   },
   ...
]

=cut
sub _make_symlinks {
    my $rah_params = shift;

    my $can_symlink = eval { symlink("",""); 1 };
    return 0 unless $can_symlink; 

    foreach my $rh_param (@$rah_params) {

        if (!exists $rh_param->{broken}) {
            symlink($rh_param->{target}, $rh_param->{symlink});
        }
        else {
            # Make a broken symlink
            _touch_am_time( [$rh_param->{target}] );
            symlink($rh_param->{target}, $rh_param->{symlink});
            unlink($rh_param->{target});
        }

    }
    return 1;
}

=head2 _make_expected_list

Expand a list of concise pathnames relative to the given base pathname.

=cut
sub _make_expected_list {
    my $testroot = shift;
    my $ra_paths = shift;

    my @expected = ($testroot);

    # Expand all paths in ra_paths
    my %paths_expanded;
    foreach my $path (@$ra_paths) {
        my $dir = "";
        foreach my $part ( File::Spec->splitdir($path)) {
            if ($part) {
                $dir .= sprintf("/%s", $part);
                $paths_expanded{$dir} = 1;
            }
        }
    }
    push (@expected, sort map { "$test_root$_" } keys %paths_expanded);
    return @expected;
}

=head2

Make a structure of files within $base_dir and returns the list of files
specified in the input. Accepts an array ref of directions
as second argument. The elements of $ra_directions must be specified in pairs
of:

    path, "[command_on_pathname]"

Valid commands are:

    [old]  -> will set access and modification time of the file to 
              GMT: Mon, 01 Jan 2001 00:00:00 GMT

    [oldR] -> will set access and modification time of the file and its
              subfiles/subdirectories to GMT: Mon, 01 Jan 2001 00:00:00 GMT

=cut
sub _make_structure {
    my $base_dir      = shift;
    my $ra_directions = shift;

    my @all_files;
    my %to_make_leaves;
    my %to_make_recursively;

    my $tmp_f;
    while (@$ra_directions) {
        my $f = sprintf("%s/%s", $base_dir, shift @$ra_directions);
        my $cmd = shift @$ra_directions;
        push @all_files, $f;
        
        if ($cmd eq "[oldR]") { push @{ $to_make_recursively{978307200} }, $f;}
        elsif ($cmd eq "[newR]") { push @{ $to_make_recursively{time()} }, $f;}
        elsif ($cmd eq "[old]")  { push @{ $to_make_leaves{978307200} }, $f;  }
        elsif ($cmd eq "[new]")  { push @{ $to_make_leaves{time()} }, $f;     }
        elsif ($cmd =~ m/(\d+)R/ ) { push @{ $to_make_recursively{$1} }, $f;  }
        elsif ($cmd =~ m/(\d+)oldR/) {
            my $time = time - _days($1);
            push @{ $to_make_recursively{$time} }, $f;
        }
        else {
            die "Unknown cmd during file creation: $cmd";
        }
    }

    foreach my $time (keys %to_make_recursively) {
        _touch_am_time(
            \@{$to_make_recursively{$time}},
            $time,
            $base_dir,
            1, # recursive
        );
    }

    foreach my $time (keys %to_make_leaves) {
        _touch_am_time(
            \@{$to_make_leaves{$time}},
            $time,
            $base_dir,
            0, # non recursive
        );
    }

    # The code also looks at the mtime of directories when
    # prune_empty_directories is 1. To keep things simple, we'll make sure that
    # each directory's mtime is equal to the most recent mtime of its children

    File::Find::finddepth(sub {
        return if ! -d $_;
        my $greatest_epoch = undef;
        opendir my $dh, $_ or die;
        while (my $f = readdir($dh)) {
            next if $f eq '.' || $f eq '..';
            my $mtime = (stat($_ . "/" . $f))[9];
            if (! defined($greatest_epoch) || $greatest_epoch < $mtime) {
                $greatest_epoch = $mtime;
            }
        }
        closedir $dh or die;
        if ($greatest_epoch) {
            my $toucher = File::Touch->new(
                atime => $greatest_epoch,
                mtime => $greatest_epoch,
            );
            $toucher->touch($_);
        }
        return;
    }, $base_dir);

    return @all_files;
}

=head2 _dump_arrays

Simple helper to dump content of arrayrefs

=cut

sub _dump_arrays {
    my ($ra_got, $ra_expected) = @_;
    my $i = 0;
    my $j = 0;
    return sprintf("Got:\n %s \n Expected:\n %s",
         join("\n", map {$i++ ."] $_"} @$ra_got),
         join("\n", map {$j++ ."] $_"} @$ra_expected)
    );
}

=head2 _create_task_file

Creates a new task file for this test using $testdir_path as a base directory in
any path specified in the configuration file.

Returns the file name of the task file that was just created.

=cut
sub _create_task_file {
    my $testdir_path  = shift; # may exist

    my $config_content = <<"EOF";
[TEST_A]
    max_days                = 7
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path/home/test/releases\'
    keep_if_linked_in       = \'$testdir_path/home/test\'

[TEST_B]
    max_days                = 7
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path\'
    do_not_delete           = '.*[.]txt[.]gz'

[TEST_C]
    max_days                = 7
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path\'
    do_not_delete           = '.*[.]txt[.]gz'

[TEST_D]
    max_days                = 7
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path/foo\'
    keep_if_linked_in       = \'$testdir_path\'
    do_not_delete           = '.*[.]txt\$'

[TEST_E]
    max_days                = 0
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 0
    do_not_delete           = '.*[.]txt\$'

[TEST_E1]
    max_days                = 7
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 0
    do_not_delete           = '.*[.]txt\$'

[TEST_F]
    max_days                = 0
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 1
    do_not_delete           = '.*[.]txt\$'
    enable_symlinks_integrity_in_path = 1

[TEST_F1]
    max_days                = 7
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 1
    do_not_delete           = '.*[.]txt\$'
    enable_symlinks_integrity_in_path = 1

[TEST_G]
    max_days                = 0
    path                    = \'$testdir_path/home/geobuild/common/geo/lookups\'
    keep_if_linked_in       = \'$testdir_path/home/geobuild/common/geo/lookups\'
    prune_empty_directories = 1
    recursive               = 1

[TEST_H]
    recursive               = 1
    max_days                = 0
    path                    = \'$testdir_path\'
    keep_if_linked_in       = \'$testdir_path/control_area\'

[TEST_I]
    recursive               = 1
    max_days                = 0
    path                    = \'$testdir_path\'
    keep_if_linked_in       = \'$testdir_path\'
    do_not_delete           = 'copy[.]done'

[TEST_L]
    max_days                = 0
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path\'
    keep_if_linked_in       = \'$testdir_path\'

[TEST_M]
    max_days                = 0
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path\'
    keep_if_linked_in       = \'$testdir_path\'

[TEST_N]
    max_days                = 0
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path/homelink/test/releases\'
    keep_if_linked_in       = \'$testdir_path/homelink/test\'

[TEST_O]
    max_days                = 0
    recursive               = 1
    prune_empty_directories = 1
    path                    = \'$testdir_path/homelink/test/releases\'
    keep_if_linked_in       = \'$testdir_path/homelink/test\'

[TEST_P]
    max_days                = 0
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 1
    do_not_delete           = '.*[.]txt\$'
    enable_symlinks_integrity_in_path = 1

[TEST_Q]
    max_days                = 0
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 1
    do_not_delete           = '.*[.]txt\$'
    enable_symlinks_integrity_in_path = 1

[TEST_R]
    max_days                = 0
    path                    = \'$testdir_path\'
    prune_empty_directories = 1
    recursive               = 1
    do_not_delete           = '.*[.]txt\$'
    enable_symlinks_integrity_in_path = 1

[TEST_S]
    max_days                 = 7
    recursive                = 1
    prune_empty_directories  = 1
    path                     = \'$testdir_path/home/test/releases\'
    keep_if_linked_in        = \'$testdir_path/home/test\'
    delete_all_or_nothing_in = \'$testdir_path/home/test/releases\'

[TEST_T]
    max_days                = 3
    recursive               = 1
    path                    = \'$testdir_path\'
    do_not_delete           = .*[.]txt'
    pattern                 = /locations_cache_si_[0-9]{4}_/
EOF

    my ($fh, $taskfile_path) = tempfile("taskfile_XXXX", TMPDIR => 1);
    print $fh $config_content;
    close($fh);

    return $taskfile_path;
}

