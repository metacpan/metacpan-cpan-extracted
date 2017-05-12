#!/usr/bin/perl
# $Id$

use strict;
use warnings;

use HTML::PullParser::Nested;

my %ARGS = (
    start       => "'S',tagname,attr,attrseq,text",
    end         => "'E',tagname,text",
    );

my @tests = (

    # Test normal progression through data: tags, undef, error.
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting a token.
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->unget_token($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting undef (eof marker).
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->unget_token($token);
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting undef (eof marker) + another token with two calls to unget_token().
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my ($token, $token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c"); $token2 = $token;
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->unget_token($token);
	$p->unget_token($token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting undef (eof marker) + another token using a single call to unget_token().
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my ($token, $token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c"); $token2 = $token;
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->unget_token($token, $token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test pop_nest when not nested
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	eval { $p->pop_nest(); }; die unless ($@ =~ m/nesting level underflow/);
    },

    # Test normal progression through nested tags
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->pop_nest($token);
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test reading to the end of a nested section
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test pop_nest when not at end of nested section
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c></a><b>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	die unless (!$p->eol());
	$p->pop_nest();
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test normal progression through multiple levels of nested tags.
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><a><b></a><c></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->pop_nest($token);
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test detection of incorrectly nested tags
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/tokens don't nest correctly/);
    },

    # Test ungetting undef (eof marker) while nested
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->unget_token($token);
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->pop_nest();
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting undef (eof marker) + another token while nested
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><b><c></a>", %ARGS);
	my ($token, $token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c"); $token2 = $token;
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->unget_token($token);
	die unless (!$p->eol());
	$p->unget_token($token2);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->pop_nest();
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting tags of nested type
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><a><a><b></a></a></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->unget_token($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	$p->unget_token($token);
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	$p->pop_nest();
	die unless (!$p->eol());
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	die unless (!$p->eol());
	$token = $p->get_token(); die unless (!defined $token);
	die unless ($p->eol());
	eval { $token = $p->get_token(); }; die unless ($@ =~ m/read past eol/);
    },

    # Test ungetting tags of nested type too many times
    sub {
	my $p = HTML::PullParser::Nested->new('doc' => \ "<a><a><a><b></a></a></a>", %ARGS);
	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->push_nest($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->unget_token($token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->unget_token($token, $token);
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$p->unget_token($token, $token);
	eval {$p->unget_token($token); }; die unless ($@ =~ m/nesting tag underflow/);
    },

    # Test different argspec with text in it
    sub {
	my $p = HTML::PullParser::Nested->new(
	    'doc'         => \ "<a><b></a>TEXT<c>", 
	    'start'       => "'S',tagname,attr,attrseq,text",
	    'end'         => "'E',tagname,text",
	    'text'        => "'T',text,is_cdata",
	    );

	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "E" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "T" && $token->[1] eq "TEXT");
	$token = $p->get_token(); die unless ($token->[0] eq "S" && $token->[1] eq "c");
    },

    # Test different argspec with new order
    sub {
	my $p = HTML::PullParser::Nested->new(
	    'doc'         => \ "<a><b></a>TEXT<c>", 
	    'start'       => "tagname,'S',attr,attrseq,text",
	    'end'         => "tagname,'E',text",
	    'text'        => "text,'T',is_cdata",
	    );

	my $token;
	$token = $p->get_token(); die unless ($token->[1] eq "S" && $token->[0] eq "a");
	$token = $p->get_token(); die unless ($token->[1] eq "S" && $token->[0] eq "b");
	$token = $p->get_token(); die unless ($token->[1] eq "E" && $token->[0] eq "a");
	$token = $p->get_token(); die unless ($token->[1] eq "T" && $token->[0] eq "TEXT");
	$token = $p->get_token(); die unless ($token->[1] eq "S" && $token->[0] eq "c");
    },

    # Test argspec using event
    sub {
	my $p = HTML::PullParser::Nested->new(
	    'doc'         => \ "<a><b></a>TEXT<c>", 
	    'start'       => "event,tagname,attr,attrseq,text",
	    'end'         => "event,tagname,text",
	    'text'        => "event,text,is_cdata",
	    );

	my $token;
	$token = $p->get_token(); die unless ($token->[0] eq "start" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "start" && $token->[1] eq "b");
	$token = $p->get_token(); die unless ($token->[0] eq "end" && $token->[1] eq "a");
	$token = $p->get_token(); die unless ($token->[0] eq "text" && $token->[1] eq "TEXT");
	$token = $p->get_token(); die unless ($token->[0] eq "start" && $token->[1] eq "c");
    },

    # Test argspec without start
    sub {
	eval {
	    my $p = HTML::PullParser::Nested->new(
		'doc'         => \ "<a><b></a>TEXT<c>", 
		'end'         => "event,tagname,text",
		'text'        => "event,text,is_cdata",
		);
	};

	die unless ($@ =~ m/need argspec for start and end/);

    },

    # Test argspec without event or literal string
    sub {
	eval {
	    my $p = HTML::PullParser::Nested->new(
		'doc'         => \ "<a><b></a>TEXT<c>", 
		'start'       => "tagname,attr,attrseq,text",
		'end'         => "tagname,text",
		'text'        => "text,is_cdata",
		);
	};

	die unless ($@ =~ m/need either event or 'string' at a consistent index across all argspecs/);

    },

    # Test argspec with duplicate literal string (+ no event)
    sub {
	eval {
	    my $p = HTML::PullParser::Nested->new(
		'doc'         => \ "<a><b></a>TEXT<c>", 
		'start'       => "'TAG',tagname,attr,attrseq,text",
		'end'         => "'TAG',tagname,text",
		'text'        => "'TEXT',text,is_cdata",
		);
	};

	die unless ($@ =~ m/'string' must be unique across all argspecs/);

    },

    # Test argspec with event at different locations
    sub {
	eval {
	    my $p = HTML::PullParser::Nested->new(
		'doc'         => \ "<a><b></a>TEXT<c>", 
		'start'       => "event,tagname,attr,attrseq,text",
		'end'         => "event,tagname,text",
		'text'        => "text,event,is_cdata",
		);
	};

	die unless ($@ =~ m/need either event or 'string' at a consistent index across all argspecs/);

    },

    # Test argspec without tagname
    sub {
	eval {
	    my $p = HTML::PullParser::Nested->new(
		'doc'         => \ "<a><b></a>TEXT<c>", 
		'start'       => "event,attr,attrseq,text",
		'end'         => "event,text",
		'text'        => "event,text,is_cdata",
		);
	};

	die unless ($@ =~ m/need tagname in argspec for start and end tags/);

    },

    );

printf "%d..%d\n", 1, scalar @tests;

foreach (@tests) {

    eval { &$_(); };

    if ($@) {
	print "not ok\n";
    } else {
	print "ok\n";
    }
}
