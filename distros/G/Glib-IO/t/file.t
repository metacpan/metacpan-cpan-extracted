#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;
use Glib::IO;

{
  my $file = Glib::IO::File::new_for_path ($0);
  ok (defined $file->hash ());
}

{
  my $file = Glib::IO::File::new_for_path ('non-existent');
  eval { $file->read () };
  isa_ok ($@, 'Glib::IO::IOErrorEnum');
  is ($@->value, 'not-found');
}

{
  my $loop = Glib::MainLoop->new ();

  my $file = Glib::IO::File::new_for_path ($0);
  $file->query_info_async ('*', [], 0, undef, \&info, [ 23, 'bla' ]);
  sub info {
    my ($file, $res, $data) = @_;

    my $info = $file->query_info_finish ($res);
    ok (defined $info->get_name ());
    ok (defined $info->get_size ());
    is_deeply ($data, [ 23, 'bla' ]);

    $loop->quit ();
  }

  $loop->run ();
}

SKIP: {
  skip 'copy_async is not introspectable currently', 5;

  my $loop = Glib::MainLoop->new ();

  my $src = Glib::IO::File::new_for_path ($0);
  my $dst = Glib::IO::File::new_for_path ($0 . '.bak');
  $src->copy_async ($dst, [], 0, undef, \&progress, [ 23, 'bla' ], \&read, [ 42, 'blub' ]);

  my $progress_called = 0;
  sub progress {
    my ($current, $total, $data) = @_;
    return if $progress_called++;
    ok (defined $current);
    ok (defined $total);
    is_deeply ($data, [ 23, 'bla' ]);
  }
  sub read {
    my ($file, $res, $data) = @_;
    my $success = $file->copy_finish ($res);
    ok ($success);
    is_deeply ($data, [ 42, 'blub' ]);
    $loop->quit ();
  }

  $loop->run ();

  $dst->delete ();
}
