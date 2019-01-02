use strict;
use warnings;
use Env qw( @PATH );
use Test::More tests => 19;
use File::Spec ();
use File::Which qw(which where);

{

  local $ENV{PATH} = $ENV{PATH};

  # Check that it returns undef if no file is passed
  is(
    scalar(which('')), undef,
    'Null-length false result',
  );
  is(
    scalar(which('non_existent_very_unlinkely_thingy_executable')), undef,
    'Positive length false result',
  );

  # Where is the test application
  my $test_bin = File::Spec->catdir( 'corpus', File::Which::IS_WIN ? 'test-bin-win' : 'test-bin-unix' );
  ok( -d $test_bin, 'Found test-bin' );

  # Set up for running the test application
  @PATH = $test_bin;
  push @PATH, File::Spec->catdir( 'corpus', 'test-bin-win' ) if File::Which::IS_CYG;
  unless (
    File::Which::IS_VMS
    or
    File::Which::IS_MAC
    or
    File::Which::IS_WIN
  ) {
    my $test3 = File::Spec->catfile( $test_bin, 'test3' );
    chmod 0755, $test3;
  }

  SKIP: {
    skip("Not on DOS-like filesystem", 3) unless File::Which::IS_WIN;
    is( lc scalar which('test1'), 'corpus\test-bin-win\test1.exe', 'Looking for test1.exe' );
    is( lc scalar which('test2'), 'corpus\test-bin-win\test2.bat', 'Looking for test2.bat' );
    is( scalar which('test3'), undef, 'test3 returns undef' );
  }

  SKIP: {
    skip("Not on a UNIX filesystem", 1) if File::Which::IS_WIN;
    skip("Not on a UNIX filesystem", 1) if File::Which::IS_MAC;
    skip("Not on a UNIX filesystem", 1) if File::Which::IS_VMS;
    is(
      scalar(which('test3')),
      File::Spec->catfile( $test_bin, 'test3'),
      'Check test3 for Unix',
    );
  }

  SKIP: {
    skip("Not on a cygwin filesystem", 2) unless File::Which::IS_CYG;

    # Cygwin: should make test1.exe transparent
    is(
      scalar(which('test1')),
      File::Spec->catfile( 'corpus', 'test-bin-win', 'test1' ),
      'Looking for test1 on Cygwin: transparent to test1.exe',
    );
    is(
      scalar(which('test4')),
      undef,
      'Make sure that which() doesn\'t return a directory',
    );
  }

  # Make sure that .\ stuff works on DOSish, VMS, MacOS (. is in PATH implicitly).
  SKIP: {
    unless ( File::Which::IS_WIN or File::Which::IS_VMS ) {
      skip("Not on a DOS or VMS filesystem", 1);
    }

    chdir( $test_bin );
    is(
      lc scalar which('test1'),
      File::Spec->catfile(File::Spec->curdir(), 'test1.exe'),
      'Looking for test1.exe in curdir',
    );
    chdir File::Spec->updir;
    chdir File::Spec->updir;
  }

}

{

  local $ENV{PATH} = $ENV{PATH};

  # Where is the test application
  my $test_bin = File::Spec->catdir( 'corpus', $^O =~ /^(MSWin32|dos|os2)$/ ? 'test-bin-win' : 'test-bin-unix' );
  ok( -d $test_bin, 'Found test-bin' );

  # Set up for running the test application
  @PATH = ($test_bin);
  push @PATH, File::Spec->catdir( 'corpus', 'test-bin-win' ) if $^O =~ /^(cygwin|msys)$/;
  unless (
    File::Which::IS_VMS
    or
    File::Which::IS_MAC
    or
    File::Which::IS_WIN
  ) {
    my $all = File::Spec->catfile( $test_bin, 'all' );
    chmod 0755, $all;
  }

  my @result = which('all');
  like( $result[0], qr/all/i, 'Found all' );
  ok( scalar(@result), 'Found at least one result' );

  # Should have as many elements.
  is(
    scalar(@result),
    scalar(where('all')),
    'Scalar which result matches where result',
  );

  my $zero = which '0';

  ok(
    $zero,
    "zero = $zero"
  );
  
  my $empty_string = which '';

  is(
    $empty_string,
    undef,
    "empty string"
  );

}

{

  # Look for a very common program
  my $tool = 'perl';
  my $path = which($tool);
  ok( defined $path, "Found path to $tool" );
  ok( $path, "Found path to $tool" );
  ok( -f $path, "$tool exists" );

}

