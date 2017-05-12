#!/usr/bin/perl
use Test::More;
plan( tests => 8);
sub help { print "help"; };
sub version { print "version"; };
use strict;

sub getopt_test($$@){
	my $txt = shift;
	my $exp = shift;
	my $str = shift;
	if ( open(STDIN,"-|") ) {
		my $res = join("", <STDIN>);
		if ($res ne $exp ) {
			use Data::Dumper;
			$Data::Dumper::Useqq=1;
			printf STDERR 
				"\n\n----------------\nexpected %s, got %s\n\n\n",
				@{[
					map { &Data::Dumper::qquote($_) } 
					grep { chomp || 1}
					$exp, $res
				]};
		};
		is($res,$exp,$txt);
	} else {
		eval {
			open(STDERR,">/dev/null");
			use Getopt::WonderBra;
			print join("\n",getopt($str,@_));
			exit(0);
		};
	};
};
getopt_test("nada",  "--",         "");
getopt_test("ddash", "--",         "",            qw(--));
getopt_test("dasha", "-a\n--",     "a",           qw(-a));
getopt_test("long",     "--long\n--", "-",            qw(--long));
getopt_test("justx", "--\nx",      "x",           qw(x));
getopt_test("ddx",   "--\nx",      "x",           qw(-- x));
getopt_test("dv",    "-v\n--",     "v",           qw(-v));
getopt_test("bad--",    "",          "iu",           qw(--u));
