#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Warn;

package My::P1;
use Log::ger::Plugin 'WithCarp';
use Log::ger;

my $log = Log::ger->get_logger;

sub x1a { log_warn_carp   ("warnCarpA") }
sub x1b { $log->warn_carp ("warnCarpB") }

sub x2a { log_warn_cluck  ("warnCluckA") }
sub x2b { $log->warn_cluck("warnCluckB") }

sub x3a { log_error_croak  ("errorCroakA") }
sub x3b { $log->error_croak("errorCroakB") }

sub x4a { log_error_confess  ("errorConfessA") }
sub x4b { $log->error_confess("errorConfessB") }

sub x5a { log_fatal_croak  ("fatalCroakA") }
sub x5b { $log->fatal_croak("fatalCroakB") }

sub x6a { log_fatal_confess  ("fatalConfessA") }
sub x6b { $log->fatal_confess("fatalConfessB") }

package main;

warning_like { My::P1::x1a() } qr/warnCarpA/;
warning_like { My::P1::x1b() } qr/warnCarpB/;

warning_like { My::P1::x2a() } qr/warnCluckA/;
warning_like { My::P1::x2b() } qr/warnCluckB/;

dies_ok { My::P1::x3a() } qr/errorCroakA/;
dies_ok { My::P1::x3b() } qr/errorCroakB/;

dies_ok { My::P1::x4a() } qr/errorConfessA/;
dies_ok { My::P1::x4b() } qr/errorConfessB/;

dies_ok { My::P1::x5a() } qr/fatalCroakA/;
dies_ok { My::P1::x5b() } qr/fatalCroakB/;

dies_ok { My::P1::x6a() } qr/fatalConfessA/;
dies_ok { My::P1::x6b() } qr/fatalConfessB/;

done_testing;
