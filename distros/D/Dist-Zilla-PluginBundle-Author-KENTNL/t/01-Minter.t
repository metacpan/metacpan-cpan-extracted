
use strict;
use warnings;

use Test::More;
use FindBin;
use Test::Output qw();

use lib 't/lib';
use tshare;

use Test::DZil;
use Path::Tiny qw(path);

my $tzil;

subtest 'mint files' => sub {

  $tzil = tshare->mk_minter('default');

  pass('Loaded minter config');

  $tzil->chrome->logger->set_debug(1);

  pass("set debug");

  $tzil->mint_dist;

  pass("minted dist");

  my $pm = $tzil->slurp_file('mint/lib/DZT/Minty.pm');

  pass('slurped file');

  my %expected_files = map { $_ => 1 } qw(
    lib/DZT/Minty.pm
    weaver.ini
    perlcritic.rc
    Changes
    .perltidyrc
    .gitignore
    dist.ini
  );

  my %got_files;

  for my $file ( @{ $tzil->files } ) {
    my $name = $file->name;
    $got_files{$name} = 0 if not exists $got_files{$name};
    $got_files{$name} += 1;
  }

  # system("find",$tzil->tempdir );

  for my $dir (qw( .git .git/refs .git/objects lib )) {
    ok( -e path( $tzil->tempdir ,'mint', $dir), "output dir $dir exists" );
  }

  note explain [ $tzil->log_messages ];

  note explain { got => \%got_files, expected => \%expected_files };

  for my $file ( keys %expected_files ) {
    ok( exists $got_files{$file}, 'Expected mint file ' . $file . ' files exists' );
  }

};

use Capture::Tiny;
use Test::Fatal;

subtest 'build minting' => sub {

  my $tmpdir = path( $tzil->tempdir, 'mint')->absolute;

  pass("Got minted dir");

  subtest 'Mangle minted dist.ini for experimental purposes' => sub {

    my $old        = path( $tmpdir, 'dist.ini');
    my $new        = path( $tmpdir, 'dist.ini.new');
    my $distini    = $old->openr_raw();
    my $newdistini = $new->openw_raw();

    while ( defined( my $line = <$distini> ) ) {
      print $newdistini $line;
      if ( $line =~ /auto_prereqs_skip/ ) {
        note "Found skip line: ", explain( { line => $line } );
        pass "Found skip line: $.";
        print $newdistini "auto_prereqs_skip = Bogus\n";
        print $newdistini "auto_prereqs_skip = OtherBogus\n";
      }
    }

    close $distini;
    close $newdistini;

    $old->remove();

    rename "$new", "$old" or fail("Can't rename $new to $old");

  };

  my $pmfile;
  subtest 'Create fake pm with deps to be ignored' => sub {

    $pmfile = path( $tmpdir, 'lib','DZT','Mintiniator.pm');
    my $fh = $pmfile->openw_raw();

    print $fh <<'EOF';
use strict;
use warnings;
package DZT::Mintiniator;

# ABSTRACT: Test package to test auto prerequisites skip behaviour

if(0){ # Stop it actually failing
  require Bogus;
  require OtherBogus;
  require SomethingReallyWanted;
}

1;
EOF

    pass('Generated file');
    note "$pmfile";
    ok( -f $pmfile, "Generated file exists" );

  };
  subtest "Add generated file to git" => sub {
    require Git::Wrapper;
    my $git = Git::Wrapper->new("$tmpdir");
    $git->add("$pmfile");
    is( eval { $git->commit( { message => "Test Commit" } ); 'pass' }, 'pass', "Committed Successfully" );
    my (@files) = $git->ls_files();
    is( ( scalar grep { $_ =~ /Mintiniator\.pm$/ } @files ), 1, "Exactly one copy of Mintiniator.pm is found by git" );

  };

  my $bzil = Builder->from_config( { dist_root => $tmpdir }, {}, { global_config_root => tshare->global }, );

  pass("Loaded builder configuration");

  $bzil->chrome->logger->set_debug(1);

  pass("Set debug");

  $bzil->build;

  pass("Built Dist");

  # NOTE: ->test doesn't work atm due to various reasons unknown, so doing it manually.

  my $exception;
  my $target;
  my ( $stdout, $stderr ) = Capture::Tiny::capture(
    sub {
      $exception = exception {
        require File::pushd;
        $target = File::pushd::pushd( path($bzil->tempdir,'build') );
        system( $^X , 'Makefile.PL' ) and die "error with Makefile.PL\n";
        system('make') and die "error running make\n";
        system( 'make', 'test', 'TEST_VERBOSE=1' ) and die "error running make test TEST_VERBOSE=1\n";
      };
    }
  );
  note explain { 'output was' => { out => $stdout, err => $stderr } };

  if ( defined $exception ) {
    note explain $exception;

    #  system("urxvt -e bash"); # XXX DEVELOPMENT
    die $@;
  }

  #  system("find",$bzil->tempdir );

  my %expected_files = map { $_ => 1 } qw(
    lib/DZT/Minty.pm
    lib/DZT/Mintiniator.pm
    weaver.ini
    perlcritic.rc
    Changes
    .perltidyrc
    dist.ini
    Makefile.PL
    Changes
    LICENSE
    MANIFEST
    META.json
    META.yml
    README
    t/00-report-prereqs.t
    xt/author/critic.t
    xt/release/cpan-changes.t
    xt/release/distmeta.t
    xt/author/eol.t
    xt/release/kwalitee.t
    xt/release/minimum-version.t
  );

  my %got_files;
  my %got_files_refs;
  for my $file ( @{ $bzil->files } ) {
    my $name = $file->name;
    $got_files{$name} = 0 if not exists $got_files{$name};
    $got_files{$name} += 1;
    $got_files_refs{$name} = $file;
  }

  note explain { got => \%got_files, expected => \%expected_files };

  note explain [ $bzil->log_messages ];

  for my $file ( keys %expected_files ) {
    ok( exists $got_files{$file}, 'Expected mint file ' . $file . ' files exists' );
  }

  my $data = $bzil->distmeta;

  note explain $data;

  is_deeply(
    $data->{prereqs}->{configure}->{requires},
    { 'ExtUtils::MakeMaker' => '0', perl => '5.006', },
    'prereqs.configure is sane'
  );

};

done_testing;
