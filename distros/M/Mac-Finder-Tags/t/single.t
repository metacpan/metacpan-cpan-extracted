#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;


plan skip_all => "mdfind utility required" unless `which mdfind`;

my $path;
eval {
	$path = `mdfind "(kMDItemUserTags == '*')" | head -n 1`;
	chomp $path;
};
plan skip_all => "at least one pre-existing tagged file required" unless $path;

plan tests => 10 + 1;


use Mac::Finder::Tags;

my ($ft, $t, @tags);

$ft = Mac::Finder::Tags->new( caching => 0, impl => 'mdls' );
lives_ok { ($t) = @tags = $ft->get_tags($path) } 'mdls get_tags';
isa_ok $t, 'Mac::Finder::Tags::Tag', 'mdls get_tags result type';
my $name = $t->name;
my $color = $t->color;
ok defined $name, 'mdls tag name';
SKIP: {
	skip "mdls doesn't provide color name for multi-tag result", 1 if @tags > 1;
	ok defined $color, 'mdls tag color';
}

$ft = Mac::Finder::Tags->new( caching => 0, impl => 'xattr' );
lives_ok { ($t) = $ft->get_tags($path) } 'xattr get_tags';
isa_ok $t, 'Mac::Finder::Tags::Tag', 'xattr get_tags result type';
ok defined $t->name, 'mdls tag name';
ok defined $t->color, 'mdls tag color';
ok $t->name eq $name, 'tag names match';
SKIP: {
	skip "mdls doesn't provide color name for multi-tag result", 1 unless defined $color;
	ok $t->color eq $color, 'tag colors match';
}


done_testing;
