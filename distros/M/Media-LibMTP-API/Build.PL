#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use Module::Build;
use ExtUtils::PkgConfig;

sub abort_build
{
  ++$|;                         # flush STDOUT now
  print STDERR shift . <<"ABORT_MSG";
 first:
  http://libmtp.sourceforge.net/

libmtp version 1.1.0 or later is required.
ABORT_MSG
  exit 0;        # bail out if libmtp too old
} # end abort_build

say 'Looking for installed libmtp with pkg-config...';
my %libmtp = eval { ExtUtils::PkgConfig->find('libmtp') };

abort_build('It looks like you need to install libmtp') unless %libmtp;

say "Found libmtp " . $libmtp{modversion} || 'UNKNOWN VERSION';

abort_build('You need to upgrade to libmtp 1.1.0 or newer')
    unless $libmtp{modversion} =~ /^(\d+)\.(\d+)/
       and ($1 > 1 or ($1 == 1 and $2 >= 1));

if (eval {require ExtUtils::Constant; 1}) {
  say 'Regenerating constants...';
  require 'lib/Media/LibMTP/API/Constants.pm';

  my @names = (
    map { /LIBMTP_(?:DEBUG|STORAGE)_/ ? $_ : { name => $_, macro => '1' } }
    @{ $Media::LibMTP::API::EXPORT_TAGS{all} }
  );
  ExtUtils::Constant::WriteConstants(
     NAME         => 'Media::LibMTP::API',
     NAMES        => \@names,
     DEFAULT_TYPE => 'IV',
     C_FILE       => 'lib/Media/LibMTP/const-c.inc',
     XS_FILE      => 'lib/Media/LibMTP/const-xs.inc',
  );
} # end if ExtUtils::Constant available

my $build = Module::Build->new(
  dist_name            => 'Media-LibMTP-API',
  dist_version_from    => 'lib/Media/LibMTP/API.pm',
  dist_abstract        => 'Low-level interface to libmtp',
  dist_author          => 'Christopher J. Madsen <perl@cjmweb.net>',
  module_name          => 'Media::LibMTP::API', # for packlist
  extra_compiler_flags => $libmtp{cflags},
  extra_linker_flags   => $libmtp{libs},
  'build_requires' => {
    'ExtUtils::CBuilder' => '0.15',
    'ExtUtils::ParseXS' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'ExtUtils::PkgConfig' => '0',
    'Module::Build' => '0.3601',
    'perl' => '5.010'
  },
  'requires' => {
    'Carp' => '0',
    'Exporter' => '5.57',
    'XSLoader' => '0',
    'perl' => '5.010'
  },
);

$build->create_build_script;
