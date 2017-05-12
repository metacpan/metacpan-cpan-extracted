#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;

use Test::More tests => 1;

use File::Temp qw(tempfile);

use Log::Any qw($log);
use Log::Any::Adapter;

#---

my ( $fh, $file ) = tempfile();
binmode( $fh, ":utf8" );

Log::Any::Adapter->set(
    'Fille',
    file      => $file,
    log_level => 'debug',
);

my $message = 'Сообщение в лог';

$log->info($message);
like( <$fh>, "/INFO $message/", "Standard method" );
