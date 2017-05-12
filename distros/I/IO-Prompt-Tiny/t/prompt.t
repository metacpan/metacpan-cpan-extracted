use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Capture::Tiny 0.12 qw/capture/;
use File::Temp qw/tempfile/;

use IO::Prompt::Tiny qw/prompt/;

delete $ENV{PERL_MM_USE_DEFAULT}; # need our own, ignore external one

sub _set_tempfile {
    my $text = shift;
    my $temp = tempfile;
    select $temp;
    local $| = 1;
    select STDOUT;
    print {$temp} $text;
    seek $temp, 0, 0;
    return $temp;
}

sub _prompt {
    my @args = @_;
    my ( $out, $err, $result ) = capture { scalar prompt(@args) };
    return $result;
}

{
    no warnings 'redefine';
    local *IO::Prompt::Tiny::_is_interactive = sub { 1 }; # fake it for testing
    local *STDIN = _set_tempfile("yes");
    is( _prompt( "Yes or no?", "no" ), "yes", "prompt read from STDIN" );
    is( _prompt( "Yes or no?", "no" ),
        "no", "prompt returned default when input exhausted" );
};

{
    no warnings 'redefine';
    local *IO::Prompt::Tiny::_is_interactive = sub { 1 };           # fake it for testing
    local *STDIN                             = _set_tempfile("yes");
    local $ENV{PERL_MM_USE_DEFAULT}          = 1;
    is( _prompt( "Yes or no?", "no" ),
        "no", "prompt returned default under PERL_MM_USE_DEFAULT" );
};

{
    local *STDIN = _set_tempfile("yes");
    is( _prompt( "Yes or no?", "no" ),
        "no", "prompt returned default when not interactive" );
};

done_testing;
#
# This file is part of IO-Prompt-Tiny
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
