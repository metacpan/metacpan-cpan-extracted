#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use File::Spec::Functions qw/catfile/;

BEGIN {
    use_ok( 'MarpaX::Languages::IDL::AST' ) || print "Bail out!\n";
}

my $obj = MarpaX::Languages::IDL::AST->new();
my $r = $obj->parse(catfile('data', 'dom.idl'));
my $output = $r->generate()->output();
ok(defined($r), "dom.idl is OK");
