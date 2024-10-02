# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;

use Devel::Events::Handler::Callback;

use ok 'Devel::Events::Generator::Require';

my @log;

my $g = Devel::Events::Generator::Require->new(
	handler => Devel::Events::Handler::Callback->new(sub { push @log, [@_] } ),
);

$g->enable();

is_deeply( \@log, [], "log empty" );

eval { +require "this_file_does_not_exist.pm" }; my $line = __LINE__;

my $inc_contains = "$]" >= 5.037007 ? '@INC entries checked' : '@INC contains';

my $error = quotemeta("Can't locate this_file_does_not_exist.pm in \@INC ") . ".*" . quotemeta("$inc_contains: @INC) at " . __FILE__ . " line $line.") . "\n";
cmp_deeply(
        [ @log[0..1] ],
	[
		[ try_require      => generator => $g, file => "this_file_does_not_exist.pm", ],
		[ require_finished =>
			generator => $g,
			file => "this_file_does_not_exist.pm",
			matched_file => undef,
			error => re(qr{^$error}),
		],
	],
	"log events"
);

@log = ();

eval { +require This::Module::Does::Not::Exist }; $line = __LINE__;

$error = quotemeta("Can't locate This/Module/Does/Not/Exist.pm in \@INC ") . ".*" . quotemeta("($inc_contains: @INC) at " . __FILE__ . " line $line.") . "\n";
cmp_deeply(
	\@log,
	[
		[ try_require      => generator => $g, file => "This/Module/Does/Not/Exist.pm", ],
		[ require_finished =>
			generator => $g,
			file => "This/Module/Does/Not/Exist.pm",
			matched_file => undef,
			error => re(qr{^$error}),
		],
	],
	"log events"
);

@log = ();

eval { +require File::Find };

@log = @log[0,-1]; # don't care about what File::Find.pm required

is_deeply(
	\@log,
	[
		[ try_require      => generator => $g, file => "File/Find.pm", ],
		[ require_finished =>
			generator => $g,
			file => "File/Find.pm",
			matched_file => $INC{"File/Find.pm"},
			return_value => 1,
		],
	],
	"log events"
);

done_testing;
