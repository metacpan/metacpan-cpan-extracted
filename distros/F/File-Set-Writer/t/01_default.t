#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use File::Set::Writer;
use Test::More;

ok my $writer = File::Set::Writer->new(
    max_handles => 100,
);


# Standard Defaults have been set.
is( $writer->max_handles, 100, "Max handles set" );
is( $writer->max_files, 100, "Max files set." );
is( $writer->max_lines, 500, "Max lines set." );
is( $writer->expire_handles_batch_size, 20, "Expire Handles set" );
is( $writer->expire_files_batch_size, 20, "Expire Files set" );
is( $writer->line_join, "\n", "Line Join set." );

# Update our limits.
ok( $writer->max_handles( 500 ), "Can Set Max Handles" );
ok( $writer->max_files( 1000 ), "Can Set Max Files" );
ok( $writer->max_lines( 1000 ), "Can Set Max Lines" );

# Ensure everything was properly set.
is( $writer->max_handles, 500, "Max Handles reset" );
is( $writer->max_files, 1000, "Max files reset." );
is( $writer->max_lines, 1000, "Max lines reset." );
is( $writer->expire_handles_batch_size, 100, "Expire Handles reset" );
is( $writer->expire_files_batch_size, 200, "Expire Files reset" );

# Make sure once we hard-set the expires, they stay as the user
# wanted them.
ok( $writer->expire_handles_batch_size( 500 ), "Can set expire handles" );
ok( $writer->expire_files_batch_size( 500 ), "Can set expire handles" );
ok( $writer->max_handles( 100 ), "Can Set Max Handles" );
ok( $writer->max_files( 100 ), "Can Set Max Files" );
ok( $writer->max_lines( 100 ), "Can Set Max Lines" );

is( $writer->max_handles, 100, "Max handles new setting." );
is( $writer->max_files, 100, "Max files new setting." );
is( $writer->max_lines, 100, "Max lines new setting." );
is( $writer->expire_handles_batch_size, 500, "Expire handle respects user" );
is( $writer->expire_files_batch_size, 500, "Expire files respects user" );

# Settings given to object.
ok $writer = File::Set::Writer->new(
    max_handles => 500,
    max_files   => 600,
    max_lines   => 700,
    line_join   => "foo",
), "Can create new object.";

is( $writer->max_handles, 500, "Set max_handles on object creation." );
is( $writer->max_files, 600, "Set max_files on object creation." );
is( $writer->max_lines, 700, "Set max_lines on object creation." );
is( $writer->expire_handles_batch_size, 100, "expire_handles set automatically." );
is( $writer->expire_files_batch_size, 120, "expire_files set automatically." );
is( $writer->line_join, "foo", "Set line_join on object creation." );

# Same, with manual expires_
ok $writer = File::Set::Writer->new(
    max_handles                 => 500,
    max_files                   => 600,
    max_lines                   => 700,
    line_join                   => "foo",
    expire_handles_batch_size   => 50,
    expire_files_batch_size     => 75,
), "Can create new object.";

is( $writer->max_handles, 500, "Set max_handles on object creation." );
is( $writer->max_files, 600, "Set max_files on object creation." );
is( $writer->max_lines, 700, "Set max_lines on object creation." );
is( $writer->expire_handles_batch_size, 50, "expire_handles set on creation." );
is( $writer->expire_files_batch_size, 75, "expire_files set on creation." );
is( $writer->line_join, "foo", "Set line_join on object creation." );


done_testing();
