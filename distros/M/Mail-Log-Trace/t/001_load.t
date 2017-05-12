# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 16;
#use Test::More qw(no_plan);

BEGIN {
	use_ok( 'Mail::Log::Exceptions' );
	use_ok( 'Mail::Log::Parse' );
	use_ok( 'Mail::Log::Parse::Postfix' );
	use_ok( 'Mail::Log::Trace' );
	use_ok( 'Mail::Log::Trace::Postfix');
}

### Log Classes  ###

# Base Class
{
my $object = Mail::Log::Parse->new({log_file => 't/data/log'});
isa_ok ( $object, 'Mail::Log::Parse');
}

# Postfix Class
{
my $object = Mail::Log::Parse::Postfix->new({log_file => 't/data/log'});
isa_ok ($object, 'Mail::Log::Parse::Postfix');
}

### Data Classes ###

# Base Class
{
my $object = Mail::Log::Trace->new ({'log_file' => 't/data/log'});
isa_ok ($object, 'Mail::Log::Trace');
}

# Postfix Class
{
my $object = Mail::Log::Trace::Postfix->new({'log_file' => 't/data/log'});
isa_ok ($object, 'Mail::Log::Trace::Postfix');
}

### Exception Classes ###

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

