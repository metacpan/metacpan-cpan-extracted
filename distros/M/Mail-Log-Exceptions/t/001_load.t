#!/usr/bin/perl

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use diagnostics;
use Test::More tests => 9;

BEGIN { use_ok( 'Mail::Log::Exceptions' ); }

my $object = Mail::Log::Exceptions->new ();
isa_ok ($object, 'Mail::Log::Exceptions');

# Exceptions Classes
{
my $object = Mail::Log::Exceptions->new();
isa_ok ($object, 'Mail::Log::Exceptions');

$object = Mail::Log::Exceptions::Unimplemented->new();
isa_ok ($object, 'Mail::Log::Exceptions');
isa_ok ($object, 'Mail::Log::Exceptions::Unimplemented');

$object = Mail::Log::Exceptions::LogFile->new();
isa_ok ($object, 'Mail::Log::Exceptions');
isa_ok ($object, 'Mail::Log::Exceptions::LogFile');

$object = Mail::Log::Exceptions::Message->new();
isa_ok ($object, 'Mail::Log::Exceptions');
isa_ok ($object, 'Mail::Log::Exceptions::Message');
}
