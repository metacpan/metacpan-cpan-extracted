#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use IO::String;

use File::Dir::Dumper::Stream::JSON::Writer;
use File::Dir::Dumper::Stream::JSON::Reader;

{
    my $buffer = <<"EOF";
# JSON Stream by Shlomif - Version 0.2.0
{"want":"me"}
--/f
{"want":"you"}
--/f
EOF

    my $in = IO::String->new($buffer);
    my $reader = File::Dir::Dumper::Stream::JSON::Reader->new(
        {
            input => $in,
        }
    );

    # TEST
    ok ($reader, "Reader was initialised");

    # TEST
    is_deeply($reader->fetch(),
        {want => "me",},
        "->fetch() works for first token",
    );

    # TEST
    is_deeply($reader->fetch(),
        {want => "you",},
        "->fetch works for second token",
    );

    # TEST
    ok(!defined($reader->fetch), "No more tokens");
}

{
    my $buffer = <<"EOF";
# JSON Stream by Shlomif - Version 0.2.0
{"type":"wonder","param1":["one","two","three"],"param2":"Lo and behold"}
--/f
{"type":"global","byte":{"zero":"conf"}}
--/f
EOF

    my $in = IO::String->new($buffer);
    my $reader = File::Dir::Dumper::Stream::JSON::Reader->new(
        {
            input => $in,
        }
    );

    # TEST
    ok ($reader, "Reader was initialised");

    # TEST
    is_deeply($reader->fetch(),
        {
            type => "wonder",
            "param1" => [qw(one two three)],
            "param2" => "Lo and behold",
        },
        "->fetch() works for first token - containing an arrayref",
    );

    # TEST
    is_deeply($reader->fetch(),
        {
            type => "global",
            byte => { zero => "conf", },
        },
        "->fetch works for second token (containing a hashref)",
    );

    # TEST
    ok(!defined($reader->fetch), "No more tokens");
}

{
    my $buffer = "";

    my $buf_out = IO::String->new($buffer);

    my $writer = File::Dir::Dumper::Stream::JSON::Writer->new(
        {
            output => $buf_out,
        }
    );

    $writer->put({type => "FooType", place => "home"});

    $writer->put({type => "BarType", array => [qw(the perl gods help them that help themselves)],});

    $writer->close();

    my $in = IO::String->new($buffer);

    my $reader = File::Dir::Dumper::Stream::JSON::Reader->new(
        {
            input => $in,
        }
    );

    # TEST
    ok ($reader, "Reader was initialised");

    # TEST
    is_deeply(scalar($reader->fetch()),
        {type => "FooType", place => "home"},
        "->fetch() reads what writer wrote",
    );

    # TEST
    is_deeply(scalar($reader->fetch()),
        {
            type => "BarType",
            array => [qw(the perl gods help them that help themselves)],
        },
        "->fetch works for second token (containing a hashref)",
    );

    # TEST
    ok(!defined($reader->fetch), "No more tokens");
}

