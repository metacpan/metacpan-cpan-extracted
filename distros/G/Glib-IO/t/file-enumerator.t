#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Glib::IO;

my $dir = Glib::IO::File::new_for_path ('.');
my $enumerator = $dir->enumerate_children ('standard::*', [], undef);

my $next_file = $enumerator->next_file (undef);
ok (defined $next_file->get_name ());

{
  my $loop = Glib::MainLoop->new ();
  $enumerator->next_files_async (2, 0, undef, \&next_files, [ 'bla', 23 ]);
  sub next_files {
    my ($enumerator, $res, $data) = @_;

    my $files = $enumerator->next_files_finish ($res);
    is (scalar @{$files}, 2);
    is_deeply ($data, [ 'bla', 23 ]);

    $loop->quit ();
  }

  $loop->run ();
}
