#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More tests => 1;
use File::Copy;

if( $^O =~ m/mswin32/i )
{
  my $tmp = $ENV{TMP} || $ENV{TEMP};
  ok( copy( 't/email_blaster', "$tmp\\email_blaster" ), "Copied database to $tmp" );
}
else
{
  unlink( '/tmp/apache2_asp_applications' );
  ok( copy( 't/email_blaster', '/tmp/email_blaster' ), "Copied database to /tmp" );
}# end if()

