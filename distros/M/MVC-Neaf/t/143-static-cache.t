#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use MVC::Neaf::X::Files;

my ($fd, $file) = tempfile( SUFFIX => '.txt' );

print $fd "Neaf static\n";
close $fd or die "Failed to sync $file: $!";

{
    open my $test, "<", $file
        or die "Can't open file back!";
    local $/;
    is <$test>, "Neaf static\n", "File readable at all";

    close $test;
};

my $st = MVC::Neaf::X::Files->new( root => $file, cache_ttl => 1_000_000 );

my $ret = $st->serve_file( '' );
note explain $ret;

is $ret->{-content}, "Neaf static\n", "Content returned";
is $ret->{-type}, "text/plain", "Content-type detected";

unlink $file or die "Failed to unlink $file: $!";

my $cached = $st->serve_file( '' );
is_deeply $cached, $ret, "File cached - deletion didn't affect it"
    or diag "initial file: ", explain $ret, "cached file: ", explain $cached;

my $fake = MVC::Neaf::X::Files->new( root => $file, in_memory => {
    'robots.txt' => [ "User-agent: *\nDisallow: /" ],
});

eval {
    $fake->serve_file( "/etc/passwd" );
};
like $@, qr/^404/, "No file there";

my $robot = eval { $fake->serve_file( "/robots.txt" ) };
is ref $robot, 'HASH', "File found"
    or diag "Error: $@";
is $robot->{-content}, "User-agent: *\nDisallow: /", "robots present";
note explain $robot;

done_testing;


