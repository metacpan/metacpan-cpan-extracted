#!perl
use Test::More skip_all => 'Unimplemented';

#
#use strict;
#use warnings;
#use Config '%Config';
#
#pipe my($rd,$wr) or die $!;
#my $pid = fork;
#die $! if ! defined $pid;
#if ( ! $pid ) {
#  open STDOUT, '<&=', fileno $wr;
#  exec $^X, '-MInternals::graph_arenas', '-e', 'Internals::graph_arenas()';
#}
#
#require Test::More;
#Test::More->import( tests => 1 );
#$/ = \ 3 + $Config{ptrsize};
#
#while ( my $buf = <$rd> ) {
#  my ( $arena, $header, $body ) = unpack 'l3', $buf;
#  print "$arena\t$header\t$body\n";
#}
