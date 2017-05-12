#!perl
use strict;

use Test::More tests => 7;

use File::Basename ();
use File::Find ();
use File::Spec;
use File::Temp;

sub readpairsfile {
  my ($filename) = @_;

  my %datum;

  open my $file, '<', $filename or die "couldn't open $filename: $!";
  while (my $line = <$file>) {
    chomp $line;
    my ($key, $value) = $line =~ /^(.+)\s*:\s*(.+)/;
    $datum{$key} = $value;
  }

  return \%datum;
}

use_ok('File::LinkTree::Builder');

my $metadata_getter = sub {
  my $filename = shift;

  my ($name, $path, $suffix) = File::Basename::fileparse(
    $filename,
    qr{\.txt}i,
  );

  my $pairs_file = File::Spec->catfile($path, "$name.data");
  my $pairs = readpairsfile($pairs_file);
};

my $tempdir = File::Temp::tempdir(CLEANUP => 1);

File::LinkTree::Builder->build_tree({
  storage_roots   => File::Spec->catdir(qw(eg storage)),
  file_filter     => sub { /\.txt\z/i },
  link_root       => $tempdir,
  metadata_getter => $metadata_getter,
  link_paths      => [
    [ qw(religion date) ],
    [ qw(tradition date) ],
  ],
});

sub ok_d {
  my ($path) = @_;

  my $dir = File::Spec->catdir($tempdir, @$path);

  ok(-d $dir, "$dir exists as a directory");
}

sub ok_l {
  my ($path, $target)  = @_;

  my $link = File::Spec->catfile($tempdir, @$path);

  ok(-l $link, "$link exists as a symlink");
  is(
    readlink $link,
    File::Spec->rel2abs($target, "eg/storage"),
    "...and points to correct target"
  );
}

ok_d( [ qw(Christian Dec25) ] );
ok_d( [ 'American Patriotism', 'Jul04' ]);
ok_l( [ qw(Christian Dec25 christmas.txt) ], "christmas.txt");

my $files = 0;
my $dirs  = 0;
File::Find::find(sub { -d $File::Find::name ? $dirs++ : $files++ }, $tempdir);

is($files, 4, "there are four symlink files created");
is($dirs, 9, "there are nine dirs created");
