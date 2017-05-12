#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Jmespath::Parser;
use Jmespath::Visitor;
use Jmespath::Ast;



my $parser = Jmespath::Parser->new;
isa_ok $parser, 'Jmespath::Parser';

done_testing();
