use warnings;
no warnings "syntax";
no warnings "void";
use strict;

BEGIN {
	if("$]" < 5.013008) {
		require Test::More;
		Test::More::plan(skip_all =>
			"parse_*expr not available on this Perl");
	}
}

use Test::More tests => 3 + 8*13;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callparser1", "t", "proto");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("proto", "t", [Devel::CallParser::callparser_linkable()]);
ok 1;

my @three = qw(a b c);
sub unary($) { }
sub noproto { }
sub foo { [ map { ref($_) || $_ } @_ ] }

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1,2,3]];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c),4]];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH",1]];

t::proto::cv_set_call_parser_proto(\&foo, "");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), undef;
is_deeply scalar(eval(q{[ foo @three,4 ]})), undef;
is_deeply scalar(eval(q{[ foo {} ]})), undef;
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), undef;

t::proto::cv_set_call_parser_proto(\&foo, "\$");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1],2,3];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c)],4];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH"],1];

t::proto::cv_set_call_parser_proto(\&foo, ";\$");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1],2,3];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c)],4];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH"],1];

t::proto::cv_set_call_parser_proto(\&foo, \&unary);

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1],2,3];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c)],4];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH"],1];

t::proto::cv_set_call_parser_proto(\&foo, "\@");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1,2,3]];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c),4]];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH",1]];

t::proto::cv_set_call_parser_proto(\&foo, "&\@");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1,2,3]];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c),4]];
is_deeply scalar(eval(q{[ foo {} ]})), [["CODE"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), [["CODE",1]];
is_deeply scalar(eval(q{[ foo {}, 1 ]})), undef;

t::proto::cv_set_call_parser_proto(\&foo, undef);

is_deeply scalar(eval(q{foo()})), undef;
is_deeply scalar(eval(q{foo(1,2,3)})), undef;
is_deeply scalar(eval(q{[ foo ]})), undef;
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), undef;
is_deeply scalar(eval(q{[ foo @three,4 ]})), undef;
is_deeply scalar(eval(q{[ foo {} ]})), undef;
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), undef;

t::proto::cv_set_call_parser_proto(\&foo, \&noproto);

is_deeply scalar(eval(q{foo()})), undef;
is_deeply scalar(eval(q{foo(1,2,3)})), undef;
is_deeply scalar(eval(q{[ foo ]})), undef;
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), undef;
is_deeply scalar(eval(q{[ foo @three,4 ]})), undef;
is_deeply scalar(eval(q{[ foo {} ]})), undef;
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), undef;

t::proto::cv_set_call_parser_proto_or_list(\&foo, ";\$");

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1],2,3];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c)],4];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH"],1];

t::proto::cv_set_call_parser_proto_or_list(\&foo, \&unary);

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1],2,3];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c)],4];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH"],1];

t::proto::cv_set_call_parser_proto_or_list(\&foo, undef);

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1,2,3]];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c),4]];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH",1]];

t::proto::cv_set_call_parser_proto_or_list(\&foo, \&noproto);

is_deeply scalar(eval(q{foo()})), [];
is_deeply scalar(eval(q{foo(1,2,3)})), [1,2,3];
is_deeply scalar(eval(q{[ foo ]})), [[]];
is_deeply scalar(eval(q{[ foo 1,2,3 ]})), [[1,2,3]];
is_deeply scalar(eval(q{[ foo @three,4 ]})), [[qw(a b c),4]];
is_deeply scalar(eval(q{[ foo {} ]})), [["HASH"]];
is_deeply scalar(eval(q{[ foo {} 1 ]})), undef;
is_deeply scalar(eval(q{[ foo {}, 1 ]})), [["HASH",1]];

1;
