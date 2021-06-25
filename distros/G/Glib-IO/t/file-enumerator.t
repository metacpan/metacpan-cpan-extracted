#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw(tempdir tempfile);
use Glib::IO;

my $temp_dir = tempdir(CLEANUP => 1);
my $files_count = 4;
foreach (1 .. $files_count) {
	my (undef, $temp_file) = tempfile(DIR => $temp_dir);
}
my $dir = Glib::IO::File::new_for_path ($temp_dir);
my $enumerator = $dir->enumerate_children ('standard::*', [], undef);

my $next_file = $enumerator->next_file (undef);
ok (defined $next_file->get_name ());

{
  my $loop = Glib::MainLoop->new ();
  my $files_requested = 2;
  $enumerator->next_files_async ($files_requested, 0, undef, \&next_files, [ 'bla', 23 ]);
  sub next_files {
    my ($enumerator, $res, $data) = @_;

    my $files = $enumerator->next_files_finish ($res);
    is (scalar @{$files}, $files_requested);
    is_deeply ($data, [ 'bla', 23 ]);

    $loop->quit ();
  }

  $loop->run ();
}
