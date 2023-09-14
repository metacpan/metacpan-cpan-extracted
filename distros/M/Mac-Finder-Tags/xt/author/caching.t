#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# The duration of this tests depends on the number of tags used on the system.
# If there is a large number of tags, it may take quite some time to complete.
plan skip_all => "potentially lengthy test" unless $ENV{AUTHOR_TESTING} || $ENV{EXTENDED_TESTING};

plan tests => 1 + 2 + 3 + $no_warnings;


use Mac::Finder::Tags;


my ($ft, $t, @tags);

lives_ok { $ft = Mac::Finder::Tags->new( caching => 1, impl => 'mdls' ) } 'new';

lives_ok { @tags = $ft->all_tags } 'all_tags lives';
subtest 'all_tags' => sub {
	for my $i (0 .. $#tags) {
		$t = $tags[$i];
		isa_ok $t, 'Mac::Finder::Tags::Tag', "tag [$i] type";
		ok defined $t->name, "tag [$i] name";
	}
};

lives_ok { ($t) = $ft->get_tags('/dev/null') } 'get_tags cache lives';
ok ! defined $t, 'get_tags cache miss';
subtest 'get_tags cache hit' => sub {
	plan skip_all => "mdfind utility required" unless `which mdfind`;
	my $name = $tags[int @tags / 2]->name;
	my $path;
	eval {
		$path = `mdfind "(kMDItemUserTags == '$name')" | head -n 1`;
		chomp $path;
	};
	plan skip_all => "at least one pre-existing tagged file required" unless $path;
	plan tests => 2;
	lives_ok { ($t) = $ft->get_tags($path) } 'get_tags';
	is $t->name, $name, 'tag name match';
};


done_testing;
