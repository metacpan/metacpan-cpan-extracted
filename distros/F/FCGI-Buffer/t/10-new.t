#!/usr/bin/perl -wT

use strict;
use warnings;

use Test::Most tests => 12;

BEGIN { use_ok('FCGI::Buffer') }

isa_ok(FCGI::Buffer->new(), 'FCGI::Buffer', 'Creating FCGI::Buffer object');
ok(!defined(FCGI::Buffer::new()));

# Set a dummy SERVER_PROTOCOL environment variable for testing
local $ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

# Test cases

# Test object creation without arguments
my $obj = new_ok('FCGI::Buffer');

# Test default values
is($obj->{'generate_304'}, 1, 'generate_304 is set to 1 by default');
is($obj->{'generate_last_modified'}, 1, 'generate_last_modified is set to 1 by default');
is($obj->{'compress_content'}, 1, 'compress_content is set to 1 by default');
is($obj->{'optimise_content'}, 0, 'optimise_content is set to 0 by default');
is($obj->{'lint_content'}, 0, 'lint_content is set to 0 by default');
is($obj->{'generate_etag'}, 1, 'generate_etag is set to 1 based on SERVER_PROTOCOL');

# Test object creation with arguments
my $obj_with_args = FCGI::Buffer->new({
	compress_content => 0,
	optimise_content => 1,
});
is($obj_with_args->{'compress_content'}, 0, 'compress_content is set to 0');
is($obj_with_args->{'optimise_content'}, 1, 'optimise_content is set to 1');

# Restore the original output buffer
select($obj->{'old_buf'});
