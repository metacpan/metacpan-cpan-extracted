use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

BEGIN {
  package MyExporter;
  $INC{"MyExporter.pm"} = __FILE__;

  use base qw(Exporter);

  our @EXPORT_OK = qw(thing);

  sub thing { 'thing' }
}

my @importcaller;
my @versioncaller;
my $version;
BEGIN {
  package CheckFile;
  $INC{"CheckFile.pm"} = __FILE__;

  sub import {
    @importcaller = caller;
  }
  sub VERSION {
    $version = $_[1];
    @versioncaller = caller;
  }
}

BEGIN {
  package MultiExporter;
  $INC{"MultiExporter.pm"} = __FILE__;

  use Import::Into;

  sub import {
    my $target = caller;
    warnings->import::into($target);
    MyExporter->import::into($target, 'thing');
    CheckFile->import::into(1);
  }
}

eval q{
  package TestPackage;

  no warnings FATAL => 'all';

#line 1 "import_into_inline.pl"
  use MultiExporter;

  sub test {
    thing . undef
  }
  1;
} or die $@;

my @w;

is(do {
  local $SIG{__WARN__} = sub { push @w, @_; };
  TestPackage::test();
}, 'thing', 'returned thing ok');

is(scalar @w, 1, 'Only one entry in @w');

like($w[0], qr/uninitialized/, 'Correct warning');

is $importcaller[0], 'TestPackage',
  'import by level has correct package';
is $importcaller[1], 'import_into_inline.pl',
  'import by level has correct file';
is $importcaller[2], 1,
  'import by level has correct line';
is scalar @versioncaller, 0, 'VERSION not called when not specified';

@importcaller = ();
@versioncaller = ();
$version = undef;
CheckFile->import::into({
  package  => 'ExplicitPackage',
  filename => 'explicit-file.pl',
  line     => 42,
  version  => 219,
});

is $importcaller[0], 'ExplicitPackage',
  'import with hash has correct package';
is $importcaller[1], 'explicit-file.pl',
  'import with hash has correct file';
is $importcaller[2], 42,
  'import with hash has correct line';
is $versioncaller[0], 'ExplicitPackage',
  'VERSION with hash has correct package';
is $versioncaller[1], 'explicit-file.pl',
  'VERSION with hash has correct file';
is $versioncaller[2], 42,
  'VERSION with hash has correct line';
is $version, 219,
  'import with hash has correct version';

BEGIN {
  package LevelExporter;
  $INC{'LevelExporter.pm'} = __FILE__;

  sub import {
    CheckFile->import::into({
      level    => 1,
      version  => 219,
    });
  }
}

@importcaller = ();
@versioncaller = ();
$version = undef;
eval q{
  package ExplicitLevel;

#line 42 "explicit-level.pl"
  use LevelExporter;
  1;
} or die $@;

is $importcaller[0], 'ExplicitLevel',
  'import with level in hash has correct package';
is $importcaller[1], 'explicit-level.pl',
  'import with level in hash has correct file';
is $importcaller[2], 42,
  'import with level in hash has correct line';
is $versioncaller[0], 'ExplicitLevel',
  'VERSION with level in hash has correct package';
is $versioncaller[1], 'explicit-level.pl',
  'VERSION with level in hash has correct file';
is $versioncaller[2], 42,
  'VERSION with level in hash has correct line';
is $version, 219,
  'import with level in hash has correct version';

ok( !IPC::Open3->can("open3"), "IPC::Open3 is unloaded" );
IPC::Open3->import::into("TestPackage");
ok( TestPackage->can("open3"), "IPC::Open3 was use'd and import::into'd" );
