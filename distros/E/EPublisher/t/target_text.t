#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher::Target::Plugin::Text;

my $target = EPublisher::Target::Plugin::Text->new({
    width => 80,
});

{
    my $output = $target->deploy;
    is $output, undef;
}

{
    my $output = $target->deploy( {} );
    is $output, undef;
}

{
    my $output = $target->deploy( "=head1 TEST\n\nHello World!" );
    ok $output;
    my $text = do { local (@ARGV, $/) = $output; <> };
    is $text, "TEST\n    Hello World!\n\n";
}


done_testing();
