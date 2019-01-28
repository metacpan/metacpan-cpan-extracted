#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher::Target::Plugin::Text;

my $debug = '';
my $target = EPublisher::Target::Plugin::Text->new({
    width      => 80,
},
    publisher => Mock::Publisher->new
);

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

my $publisher = $target->publisher;
isa_ok $publisher, 'Mock::Publisher';


done_testing();

{
    package
        Mock::Publisher;

    sub new { bless {}, shift }
    sub debug { $debug = $_[1] };
}

