use strict;
use warnings;

use Test::More;
use Test::File qw/file_exists_ok/;
use File::Temp qw/tempdir/;
use File::Touch qw/touch/;
use File::Find::Rule qw//;
use File::Basename qw/dirname/;
use File::Path  qw/mkpath/;
use File::Spec qw/catpath/;

use_ok('File::CleanupTask');

my $Cleanup = File::CleanupTask->new();
ok($Cleanup, 'created File::CleanupTask instance');

my $temp_dir = tempdir("file_cleanup_test_XXXXX", CLEANUP => 1);

my $rah_tests = [
    {
        name => 'backup, no gzip',
        filenames_given => [ qw( 
            abc.txt
            def.xml.gz
            )],
        filenames_expected => [ qw(
            backup/abc.txt
            backup/def.xml.gz
            )],
        task_config => {
            path        => 'TEMPDIR',
            backup_path => 'TEMPDIR/backup', # note: doesn't exist yet
        },
    },
    {
        name => 'backup and gzip',
        filenames_given => [ qw( 
            abc.txt
            def.xml.gz
            )],
        filenames_expected => [ qw(
            backup/abc.txt.gz    
            backup/def.xml.gz
            )],
        task_config => {
            path        => 'TEMPDIR',
            backup_gzip => 1,
            backup_path => 'TEMPDIR/backup', # note: doesn't exist yet
        },
    },
    {
        name => 'backup and gzip, file already exists',
        filenames_given => [ qw( 
            abc.txt
            def.xml.gz
            backup/abc.txt.gz    
            backup/def.xml.gz
            )],
        filenames_expected => [ qw(
            backup/abc.txt.gz    
            backup/def.xml.gz
            )],
        task_config => {
            path        => 'TEMPDIR',
            backup_gzip => 1,
            backup_path => 'TEMPDIR/backup', # note: doesn't exist yet
        },
    },
    {
        name => 'backup with symlinks',
        filenames_given => [ qw( 
            abc.txt
            def.xml.gz
            )],
        symlinks_given => [
            { symlink => 'sym.link',
              target => 'abc.txt',
            }
        ],
        filenames_expected => [ qw(
            backup/abc.txt.gz    
            backup/def.xml.gz
            )],
        task_config => {
            path        => 'TEMPDIR',
            backup_gzip => 1,
            backup_path => 'TEMPDIR/backup', # note: doesn't exist yet
        },
    }
    

];

foreach my $rh_test ( @$rah_tests ){
    my @a_filenames_given = sort @{$rh_test->{filenames_given}};
    my $temp_dir = create_test_files(\@a_filenames_given);
	
    SKIP:
    {
	    
        ## create symlinks if any
        if ($rh_test->{symlinks_given}) {
    	_make_symlinks( $rh_test->{symlinks_given}, $temp_dir )
    	    or skip("Unable to create symlinks", 1);
        }
    
        my @a_filenames_expected = sort @{$rh_test->{filenames_expected}};
    
        my %task_config = 
            map { s!TEMPDIR!$temp_dir!; $_ } %{$rh_test->{task_config}};
    
    
        $Cleanup->run_one_task(\%task_config, $rh_test->{name});
        
        my @a_filenames_after = 
            sort File::Find::Rule->file()->relative()->in( $temp_dir );
    
        is_deeply(
    	\@a_filenames_after,
    	\@a_filenames_expected,
    	"$rh_test->{name} -- directory contains the expected files",
        );
    }
}


########################################################################
#
# 1. created a temporary directory
# 2. creates all files given in $ra_filenames
# 3. changes $ra_filenames: prefixes the directory
#
sub create_test_files {
    my $ra_filenames = shift;
    
    my $temp_dir = tempdir( 
        TEMPLATE => 'ops_cleanup_backup_t_XXXXX',
        DIR => $temp_dir, 
        CLEANUP => 1
    );

    ok( -d $temp_dir, "created test dir '$temp_dir'");
    
    my @a_created = ();
    foreach my $filename ( map { "$temp_dir/$_" } @$ra_filenames ) {

        ## Create the parent up to the path
        _ensure_path($filename);

        touch($filename);
        file_exists_ok($filename);
        push(@a_created, $filename);
    }
    @$ra_filenames = @a_created;
    return $temp_dir;
}


done_testing();

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
	my $make_in_dir  = shift;

    my $can_symlink = eval { symlink("",""); 1 };
    return 0 unless $can_symlink; 

    foreach my $rh_param (@$rah_params) {

		my $sym_name = 
			File::Spec->catpath('', $make_in_dir, $rh_param->{"symlink"});

		my $target_name = 
			File::Spec->catpath('', $make_in_dir, $rh_param->{"target"});

        if (!exists $rh_param->{broken}) {
            symlink($target_name, $sym_name);
        }
        else {
            # Make a broken symlink
            _touch_am_time( [$target_name]);
			symlink($target_name, $sym_name);
            unlink($target_name);
        }

    }
    return 1;
}


=head2 _ensure_path
    
Given a path to a file, makes sure that the path to its parent directory exists.
If not, this directory is created.

=cut
sub _ensure_path {
    my $filename = shift;

    my $dir;
    if ( $filename =~ m!/$! ) {
        $dir = $filename;
    }
    else {
        $dir = dirname($filename);
    }

    File::Path::mkpath($dir) if $dir;
}
