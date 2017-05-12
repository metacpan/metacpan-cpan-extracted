#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use File::Temp qw(tempdir);
use Git::Wrapper;

my $dir = tempdir(CLEANUP => 1);

{
  my $git = Git::Wrapper->new({ dir        => $dir ,
                                git_binary => 'echo' });

  my @got = $git->RUN('marco');
  # apparently some versions of windows include extra bonus whitespace, so the
  # simple way of testing this fails sometimes. so...
  is( scalar @got , 1 , 'only get one line' );
  like( $got[0] , qr/^marco\s*$/ , 'Wrapper runs what ever binary we tell it to' );
}

{
  dies_ok { my $git = Git::Wrapper->new() } 'need a dir';
  dies_ok { my $git = Git::Wrapper->new(['foo']) } 'need to call properly';
  dies_ok { my $git = Git::Wrapper->new([dir => 'foo']) } 'no, really, need to call properly';
  dies_ok { my $git = Git::Wrapper->new({ git_binary => "$dir/echo" }) } 'just git_binary fails';
}

done_testing();
