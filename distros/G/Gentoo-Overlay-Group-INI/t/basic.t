use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Path::Tiny qw( path );
use FindBin;
use autodie;

my $base = path("$FindBin::Bin/../corpus");

my @overlays = ( $base->child("overlay_4")->stringify, $base->child("overlay_5")->stringify,, );

use File::Tempdir;

my $tmpdir  = File::Tempdir->new();
my $homedir = File::Tempdir->new();

my $dir = path( $tmpdir->name );

my $fh = $dir->child('config.ini')->openw;
$fh->print("[Overlays]\n");
$fh->print("directory = $_\n") for @overlays;
$fh->flush;
$fh->close;

local $ENV{GENTOO_OVERLAY_GROUP_INI_PATH} = $dir->stringify;
local $ENV{HOME}                          = $homedir->name;

# FILENAME: basic.t
# CREATED: 22/06/12 07:13:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic functionality

use Gentoo::Overlay::Group::INI;

is(
  exception {

    Gentoo::Overlay::Group::INI::_cf_paths();

  },
  undef,
  "Setup is success!"
);
is(
  exception {

    Gentoo::Overlay::Group::INI::_enumerate_file_list();

  },
  undef,
  "File list is success!"
);
my $first;

is(
  exception {
    $first = Gentoo::Overlay::Group::INI::_first_config_file();
  },
  undef,
  'Can find config'
);

note "Found File : " . $first->stringify;

my $config = Gentoo::Overlay::Group::INI->load();

isa_ok( $config, 'Gentoo::Overlay::Group' );
done_testing;

