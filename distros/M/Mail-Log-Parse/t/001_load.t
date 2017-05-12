# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN { use_ok( 'Mail::Log::Parse' ); }
BEGIN { use_ok( 'Mail::Log::Parse::Postfix' ); }

my $object = Mail::Log::Parse->new ();
isa_ok ($object, 'Mail::Log::Parse');

### Log Classes  ###

# Base Class
{
my $object = Mail::Log::Parse->new({log_file => 't/data/log'});
isa_ok ( $object, 'Mail::Log::Parse');
}

# Postfix Class
{
my $object = Mail::Log::Parse::Postfix->new({log_file => 't/data/log'});
isa_ok ($object, 'Mail::Log::Parse');
}
