#!perl

use strict;
use warnings;

use Test::More;

use FindBin;
use File::Temp;
use Time::Piece;
use Time::Seconds;
use File::Path qw/make_path/;
use autodie;

require_ok( 'Enbld::Home' );
require Enbld::Feature;

eval { Enbld::Home->home };
like( $@, qr/ABORT:Not initialized Enbld home's path yet./, 'not initialized' );

SKIP: {
          skip "skip ... in root user", 2 unless ( $> );

          subtest 'create Enbld home' => sub {

              my $dir = File::Temp->newdir; 
              local $ENV{PERL_ENBLD_HOME} = File::Spec->catdir( $dir, '.enbld' );

              chmod 0444, $dir;

              eval { Enbld::Home->initialize };
              like( $@, qr/ERROR:Can't create Enbld's home/,
                      'no permission to higher level directory' );
              
              chmod 0755, $dir;
              chdir $FindBin::Bin;
          };

          subtest 'check write permission Enbld home' => sub {

              my $dir = File::Temp->newdir;

              local $ENV{PERL_ENBLD_HOME} = $dir;
              chmod 0444, $dir;

              eval { Enbld::Home->initialize };
              like( $@, qr/ERROR:No permission to write directory/,
                      "no permission to Enbld's home directory" );

              chmod 0755, $dir;
              chdir $FindBin::Bin;
          };
      };

local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;

ok( Enbld::Home->initialize, 'initialize method' );
is( Enbld::Home->home, $ENV{PERL_ENBLD_HOME}, 'home dir' );
ok( -d Enbld::Home->dists,        'dists dir' );
ok( -d Enbld::Home->depository,   'depository dir' );
ok( -d Enbld::Home->conf,         'conf dir' );
ok( -d Enbld::Home->etc,          'etc dir' );
ok( -d Enbld::Home->extlib,       'extlib dir' );
ok( -d Enbld::Home->log,          'log dir' );

my $dir = Enbld::Home->create_build_directory;
ok( -d $dir, 'build dir' );

eval { Enbld::Home->invalid };
like( $@, qr/Can't execute Enbld::Home's method/, 'invalid method' );

subtest 'remove build directory' => sub {

	local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;

	Enbld::Home->initialize;
	
	my $oldtime = localtime;
	$oldtime -= ONE_YEAR;

	my $newtime = localtime;
	$newtime -= ONE_DAY;

	my $old_dir = File::Spec->catdir( Enbld::Home->build, $oldtime->epoch );
	my $new_dir = File::Spec->catdir( Enbld::Home->build, $newtime->epoch );
	make_path( $old_dir );
	make_path( $new_dir );

    # test for skipping .DS_Store at Mac OS X
    my $other = File::Spec->catfile( Enbld::Home->build, 'dummyfile' );
    open my $fh, '>', $other;
    print $fh 'dummy';
    close $fh;

	ok( -d $old_dir, 'old build directory is in existence' );
	ok( -d $new_dir, 'new build directory is in existence' );

	Enbld::Home->initialize;

	ok( ! -d $old_dir, 'old build directory disappears' );
	ok( -d $new_dir,   'new build directory exists' );
    ok( -e $other,     'other file exists' );
};

subtest 'set deploy path' => sub {

	local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;

	Enbld::Home->initialize;
    is( Enbld::Home->library, Enbld::Home->home, 'library path is home' );
    is( Enbld::Home->install_path, Enbld::Home->home, 'install path is home' );


	local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;
    my $deploy_path = File::Temp->newdir;

    require Enbld::Feature;
    Enbld::Feature->initialize( deploy => $deploy_path );

    Enbld::Home->initialize;
    is( Enbld::Home->deploy_path, $deploy_path, 'set deploy path' );
    is( Enbld::Home->library, $deploy_path, 'library path is deploy path' );
    is( Enbld::Home->install_path, Enbld::Home->deploy_path,
            'install path is deploy path' );
};

done_testing();

