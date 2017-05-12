# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use HTTP::Status;

require 't/utils.pl';
use lib qw(./t/lib ./blib/lib ./lib);
use Test::More tests => 4;
#1
use_ok('HTTP::WebTest::Plugin::TagAttTest') ;
#2
use_ok('HTTP::WebTest::Plugin::FileRequest');
my $URL;
#3
use_ok('HTTP::WebTest');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Created on Jan 30, 2003 9:54:49 PM

use strict;



my $webpage='t/index.html';
	my @result;

	@result = (@result, {test_name => "title junk",
									url		 => 't/index.html',
									tag_forbid => [{ tag=>"title", tag_text=>"junk"}]});
	@result = (@result, {test_name => "title test page",
									url		 => 't/index.html',
									tag_require => [{tag=> "title", text=>"test page"}]});
	@result = (@result, {test_name => "type att with xml in value",
									url		 => 't/index.html',
									tag_forbid => [{attr=>"type", attr_text=>"xml" }]});
	@result = (@result, {test_name => "type class with body in value",
									url		 => 't/index.html',
									tag_require => [{attr=>"class", attr_text=>"body" }]});
	@result = (@result, {test_name => "class att",
									url		 => 't/index.html',
									tag_require => [{attr=>"class"}]})	;
	@result = (@result, {test_name => "script tag",
									url		 => 't/index.html',
									tag_forbid => [{tag=> "script"}]});
	@result = (@result, {test_name => "script tag with attribute language=javascript",
									url		 => 't/index.html',
									tag_forbid => [{tag=>"script",attr=>"language",attr_text=>"javascript"}]})	;
	my $tests=\@result;


    my $params = { 
                    plugins => ["::FileRequest","HTTP::WebTest::Plugin::TagAttTest"]
                 };
my $webtest= HTTP::WebTest->new;
#4
check_webtest(webtest =>$webtest, tests=>	 $tests,opts=>$params, check_file=>'t/test.out/1.out');
#$webtest->run_tests(	 $tests,$params);

