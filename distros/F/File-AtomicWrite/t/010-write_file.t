#!perl
#
# Tests for standalone write_file class method interface.
#
# Note that these tests could easily run afoul various perlport(1)
# related issues or other operating system idiosyncrasies. Some efforts
# have been made to avoid running certain operating specific tests on
# certain other operating systems.

use warnings;
use strict;
use Carp qw(croak);

use Test::More tests => 34;
BEGIN { use_ok('File::AtomicWrite') }

can_ok( 'File::AtomicWrite', qw{write_file} );

# See if File::Spec makes sense...
BEGIN { use_ok('File::Spec') }
can_ok( 'File::Spec', qw{catfile tmpdir} );

BEGIN { use_ok('File::Temp') }
BEGIN { use_ok('File::Path') }

# FAILURE TO READ THE DOCS
{
  eval {
    File::AtomicWrite->write_file();    # should fail
  };
  like( $@, qr/missing \S+ option/, 'empty invocation' );

  eval {
    File::AtomicWrite->write_file( { file => 'test.tmp' } );    # should fail
  };
  like( $@, qr/missing \S+ option/, 'incomplete invocation' );
}

my $work_dir = File::Temp::tempdir( CLEANUP => 1 );

END {
  File::Path::rmtree($work_dir);
}

SKIP: {
  skip( "no work directory", 9 ) unless defined $work_dir and -d $work_dir;

  my $test_file = File::Spec->catfile( $work_dir, 'test1' );
  my $test_data = "test$$";

  my $written_data =
    test_write_file( { file => $test_file, input => \$test_data } );
  cmp_ok( $test_data, 'eq', $written_data, 'write string to test file' );

  # Portability concern: some OS may be reluctant to rename() over an
  # existing file. Try to expose this, as this module will be unsuitable
  # for these systems.
  my $new_data = "test\ning\n";
  my $new_written_data =
    test_write_file( { file => $test_file, input => \$new_data } );
  cmp_ok( $new_data, 'eq', $new_written_data,
    'replace existing test file with new data' );

  # min_size option
  my $min_size_file1 = File::Spec->catfile( $work_dir, 'min_size1' );
  my $min_size_input = "this should suffice";

  my $min_size_output = test_write_file(
    { file => $min_size_file1, input => \$min_size_input, min_size => 1 } );
  cmp_ok( $min_size_input, 'eq', $min_size_output, 'data exceeds min_size' );

  eval {
    my $min_size_file2 = File::Spec->catfile( $work_dir, 'min_size1' );
    File::AtomicWrite->write_file(
      { file     => $min_size_file2,
        input    => \$min_size_input,
        min_size => 99_999
      }
    );
  };
  like( $@, qr/failed to exceed min_size/, 'data does not exceed min_size' );

  # MKPATH - positive test (might fail with "could not create..." if
  # there is a File::Path or related OS problem.
  my $mkpath_file1 =
    File::Spec->catfile( $work_dir, qw{and some more dirs mkpath1} );
  my $mkpath_result = test_write_file(
    { file => $mkpath_file1, input => \"whatever", MKPATH => 1 } );
  is( "whatever", $mkpath_result, "tmp file with dir tree to create" );

  # Module default is not to create a missing directory tree
  my $mkpath_file2 =
    File::Spec->catfile( $work_dir, qw{tree not to be made mkpath2} );
  eval {
    File::AtomicWrite->write_file(
      { file  => $mkpath_file2,
        input => \"blah",
      }
    );
  };
  like(
    $@,
    qr/parent directory does not exist/,
    'cannot create dir by default'
  );

  # tmpdir - with and without MKPATH (which kinda ties the second test
  # to the first passing, and this test to the MKPATH results but if
  # mkpath isn't working, life isn't grand for this module...)
  my $tmp_dir   = File::Spec->catfile( $work_dir, qw{some new tmp dir} );
  my $real_file = File::Spec->catfile( $work_dir, "tmpdir_test" );
  is(
    test_write_file(
      { file   => $real_file,
        input  => \"whatever",
        tmpdir => $tmp_dir,
        MKPATH => 1
      }
    ),
    "whatever",
    'tmpdir with MKPATH'
  );
  is(
    test_write_file(
      { file   => "${real_file}2",
        input  => \"whatever",
        tmpdir => $tmp_dir,
      }
    ),
    "whatever",
    'tmpdir with MKPATH'
  );

  # BINMODE - pretty weak test...
  my $binary_data = join( '', map { chr($_) } 128 .. 192 );
  my $binary_result = test_write_file(
    { file    => File::Spec->catfile( $work_dir, "binmode1" ),
      input   => \$binary_data,
      BINMODE => 1
    },
    1
  );
  is( $binary_result, $binary_data, 'BINMODE write test' );

  # http://www.cpantesters.org/cpan/report/ab5bf11a-79f6-11df-ae63-e0e88fbefd91
SKIP: {
    skip ":utf8 not supported on older versions", 1 unless $] >= 5.7;

    # binmode_layer - "wide" character test... might only cause "wide char"
    # diagnostic warnings, depending on what is wrong...
    my $utf8_data = "\x{80AA}";
    eval {
      File::AtomicWrite->write_file(
        { file          => File::Spec->catfile( $work_dir, "utf8" ),
          input         => \$utf8_data,
          binmode_layer => ':utf8'
        }
      );
    };
    if ($@) {
      chomp $@;
      diag("Unexpected write_file failure: $@\n");
    }

    my $utf8_fh;
    open( $utf8_fh, '<', File::Spec->catfile( $work_dir, "utf8" ) )
      or diag("Cannot open utf8 file: $!\n");
    binmode( $utf8_fh, ':utf8' );
    my $utf8_result = do { local $/ = undef; <$utf8_fh> };
    is( $utf8_result, $utf8_data, 'utf8 write test' );
  }

  # template - for failure only, cannot really inspect tempfile name
  # without some annoying trickery with only a write_file method...
  my $template_test_file = File::Spec->catfile( $work_dir, 'template1' );
  eval {
    File::AtomicWrite->write_file(
      { file     => $template_test_file,
        input    => \"blah",
        template => "thisshouldfail"
      }
    );
  };
  like( $@, qr/template/, 'check for invalid tempfile template' );
}

# CHECKSUM - that the module can generate a checksum, and then obtain
# the same checksum on the data written to disk. Obviously, this
# requires that the code, disks, and any stray cosmic rays all work
# together...
SKIP: {
  eval { require Digest::SHA1; };
  skip( "lack Digest::SHA1 so sorry", 2 ) if $@;

  my $really_important = "Can't corrupt this\n http://xkcd.com/108/ \n";

  is(
    test_write_file(
      { file     => File::Spec->catfile( $work_dir, 'checksum' ),
        input    => \$really_important,
        CHECKSUM => 1
      }
    ),
    $really_important,
    'Digest::SHA1 internal generated checksum'
  );

  # next, supply our own checksum
  my $digest   = Digest::SHA1->new;
  my $checksum = $digest->add($really_important)->hexdigest;

  is(
    test_write_file(
      { file     => File::Spec->catfile( $work_dir, 'checksum2' ),
        input    => \$really_important,
        checksum => $checksum,
        CHECKSUM => 1
      }
    ),
    $really_important,
    'Digest::SHA1 external supplied checksum'
  );
}

SKIP: {
  skip( "not on this OS", 4 ) if $^O =~ m/Win32/;

  # mode -
  for my $mode (qw(0600 0700)) {
    my $octo_mode = oct($mode);

    my $octmode_test_file = File::Spec->catfile( $work_dir, "octmode$mode" );
    test_write_file(
      { file => $octmode_test_file, input => \"whatever", mode => $octo_mode } );
    my $file_mode = ( stat $octmode_test_file )[2] & 07777;
    is( $file_mode, $octo_mode, "test octal mode $mode" );

    my $stringmode_test_file =
      File::Spec->catfile( $work_dir, "stringmode$mode" );
    test_write_file(
      { file => $stringmode_test_file, input => \"whatever", mode => $mode } );
    $file_mode = ( stat $stringmode_test_file )[2] & 07777;
    is( $file_mode, $octo_mode, "test string mode $mode" );

  }
}

# owner - confirm that the module code is not buggy, as cannot expect to
# have the rights to chown a file to a different account. Might be able
# to test the group code, as the group could vary, depending on whether
# BSD or Solaris directory group id semantics are in play, but detecting
# that would be annoying.
SKIP: {
  my ( $user_name, $user_uid, $group_name, $group_gid );
  # getpwuid unimplemented on a certain OS, try to skip.
  eval {
    $user_name  = getpwuid($<) || undef;
    $user_uid   = $<           || '';
    $group_name = getgrgid($() || undef;
    $group_gid  = $(           || '';
  };

  skip( "no suitable login data to test owner option", 5 )
    unless defined $user_name
    and $user_uid =~ m/^[0-9]+$/
    and defined $group_name
    and $group_gid =~ m/^[0-9]+$/;

  my @owner_strings = (
    $user_uid, $user_name, "$user_uid:$group_gid", "$user_name:$group_gid",
    "$user_name:$group_name"
  );

  for my $owner (@owner_strings) {
    my $test_name = $owner;
    $test_name =~ tr/:./ab/;    # keep special chars out of filenames

    my $test_file = File::Spec->catfile( $work_dir, "owner$test_name" );

    test_write_file(
      { file => $test_file, input => \"whatever", owner => $owner } );

    # mostly just testing that the above call does not blow up...
    my ( $file_uid, $file_gid ) = ( stat $test_file )[ 4, 5 ];
    is( "$user_uid:$group_gid", "$file_uid:$file_gid",
      qq{owner set to "$owner"} );
  }
}

# utime - confirm that the module code is not buggy
SKIP: {
  # atime is not supported on FAT / Win32
  skip( "not on this OS", 2 ) if $^O =~ m/Win32/;

  my $mtime     = 1000;
  my $test_file = File::Spec->catfile( $work_dir, "mtime" );
  my $now       = time();
  test_write_file(
    { file => $test_file, input => \"whatever", mtime => $mtime } );

  # TODO parse `mount` output for noatime, or module that checks for that?
  my ( $file_atime, $file_mtime ) = ( stat $test_file )[ 8, 9 ];
  diag("notice: filesystem mounted noatime may fail atime test");
  ok( $file_atime >= $now, "atime is now (not modified)" );

  is( $file_mtime, $mtime, "mtime set with mtime $mtime" );
}

# backup
SKIP: {

  my $test_file = File::Spec->catfile( $work_dir, "backup" );
  my $test_backup = "$test_file.old";
  my ( $fh, $backup_txt );

  # make backup
  test_write_file( { file => $test_backup, input => \"whatever_old" } );

  test_write_file(
    { file => $test_file, input => \"whatever", backup => '.old' } );

  open( $fh, '<', $test_backup );
  $backup_txt = do { local $/; <$fh> };
  close($fh);
  is( $backup_txt, "whatever_old",
    "existing backupfile is not modified/deleted when no destination file exists"
  );

  test_write_file(
    { file => $test_file, input => \"whatever_new", backup => '.old' } );

  open( $fh, '<', $test_backup );
  $backup_txt = do { local $/; <$fh> };
  close($fh);
  is( $backup_txt, "whatever",
    "backupfile is modified (and is backup of previous file)" );
}

# Accepts hash_ref to pass to write_file, returns data (if any) written
# to the expected output file. Use for tests expected to pass.
sub test_write_file {
  my $param_ref = shift;
  my $binmode = shift || 0;

  eval { File::AtomicWrite->write_file($param_ref); };
  if ($@) {
    chomp $@;
    diag("Unexpected write_file failure: $@\n");
  }

  my $fh;
  open( $fh, '<', $param_ref->{file} )
    or croak( "Cannot open output file '" . $param_ref->{file} . "': $!" );
  if ($binmode) {
    binmode($fh);
  }
  return do { local $/; <$fh> };
}
