#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use Pod::Simple::XHTML;
use EPublisher::Target::Plugin::OTRSDoc;

my $simple = Pod::Simple::XHTML->new;


{
    $simple->{scratch} = '';
    $simple->start_L({
        type    => 'man',
        to      => 'grep',
        section => '',
    });

    is $simple->{scratch}, '<a href="http://man.he.net/man1/grep">';
}

{
    $simple->{scratch} = '';
    $simple->start_L({
        type    => 'anything',
        to      => 'grep',
        section => '',
    });

    is $simple->{scratch}, '<a>';
}

done_testing();

