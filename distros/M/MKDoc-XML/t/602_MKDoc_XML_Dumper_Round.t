#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Dumper;

sub testit ($)
{
    my $struct = shift;
    my $xml    = MKDoc::XML::Dumper->perl2xml ($struct);
    is_deeply (MKDoc::XML::Dumper->xml2perl ($xml), $struct);
}


testit 'hello';
testit \'hello';
testit \\'hello';
testit \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'hello';
testit [];
testit [ qw /foo bar baz/ ];
testit {};
testit { foo => 'bar', baz => 'buz' };
testit [ qw /foo bar baz/, [], { hello => 'world', yo => \\'boo' } ];
testit \[ \[ qw /foo bar baz/ ], \[], \{ hello => 'world', yo => \\'boo' } ];


__END__
