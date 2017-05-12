#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;

use Data::Dumper;

use Devel::PerlySense::Util;


use lib "lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Bookmark::Definition");
use_ok("Devel::PerlySense::Bookmark::Match");



#ok(my $oPerlySense = Devel::PerlySense->new(), "new PerlySense");



my $dirData = "t/data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm/ShaiHulud.pm";
my $source = slurp($fileOrigin);


my @aMatch;
my $oDefinitionTodo;
        


note("Find matches");

$oDefinitionTodo = Devel::PerlySense::Bookmark::Definition->newFromConfig(
    moniker => "test1",
    rex => 'qr/\# \s* TODO: \s* ( .+ )/x',
);


@aMatch = $oDefinitionTodo->aMatch(file => $fileOrigin, source => $source);
is(scalar @aMatch, 3, "Found correct number of matches");

my $oMatch = $aMatch[0];
isa_ok($oMatch, "Devel::PerlySense::Bookmark::Match");

is($oMatch->oDefinition, $oDefinitionTodo, "  oDefinition points to correct object");
is($oMatch->line, '    ##TODO: Fix something here', "  line ok");
is($oMatch->text, 'Fix something here', "  text ok");

isa_ok($oMatch->oLocation, "Devel::PerlySense::Document::Location");
like($oMatch->oLocation->file, qr|Worm.ShaiHulud.pm|, "  Location file ok");
is($oMatch->oLocation->row, 76, "  Location row ok");
is($oMatch->oLocation->col, 0, "  Location row ok");




note("Test multiple regexes, and that a definition only matches the first one");
$oDefinitionTodo = Devel::PerlySense::Bookmark::Definition->newFromConfig(
    moniker => "test1",
    rex => [
        'qr/(abc)/x',
        'qr/(123)/x',
    ],
);
$source = q {nope
abc
123
abc123};


@aMatch = $oDefinitionTodo->aMatch(file => $fileOrigin, source => $source);
is(scalar @aMatch, 3, "Found correct number of matches");

is_deeply(
    [ map { $_->text } @aMatch ],
    [ "abc", "123", "abc" ],
    "All matches matched only once, and in the correct order",
);
is_deeply(
    [ map { $_->oLocation->row } @aMatch ],
    [ 2, 3, 4 ],
    "All matches matched on the correct row",
);




__END__
