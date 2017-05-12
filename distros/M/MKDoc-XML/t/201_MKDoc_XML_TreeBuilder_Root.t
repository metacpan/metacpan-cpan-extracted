#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::Tokenizer;

{
    my @res = MKDoc::XML::TreeBuilder->process_file ('./t/data/root.html');
    ok (1); # if it didn't die then we're good :)
}


1;


__END__
