#!/usr/bin/env perl
use strict;
use warnings;
use Path::Class;
use JSON;

my ($root_dir) = @ARGV;
die "Usage: $0 <data-directory>\n" unless $root_dir;
die "Directory '$root_dir' doesn't exist\n" unless -d $root_dir;
$root_dir = dir($root_dir)->absolute;
my $public_archive = $root_dir->subdir(qw/public archive/);
$public_archive->mkpath;
my $public_index   = $root_dir->file(qw/public index/);
my $secret_archive = $root_dir->subdir(qw/secret archive/);
$secret_archive->mkpath;
my $secret_index   = $root_dir->file(qw/secret index/);

my $config = {
  'Model::Metabase' => {
    gateway => {
      autocreate_profile => 1,
      librarian => {
        archive => { root_dir   => "$public_archive" },
        index   => { index_file => "$public_index"   },
      },
      secret_librarian => {
        archive => { root_dir   => "$secret_archive" },
        index   => { index_file => "$secret_index"   },
      },
    },
    fact_classes => [
      'Metabase::User::Profile',
      'CPAN::Testers::Report',
    ],
  }
};

my $config_file = $root_dir->file('config.json');
my $fh = $config_file->openw;
print { $fh } JSON->new->encode($config);
close $fh;
print "Wrote '$config_file'\n";

