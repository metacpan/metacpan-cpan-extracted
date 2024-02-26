use strict;
use warnings;

use Test::More tests => 33;
use Expect;

my $e = Expect->new;
$e->raw_pty(1);
$e->log_stdout(0);
$e->spawn($^X . q{ -ne 'chomp; print "My\nHello\n"; print scalar reverse; print "\nWorld\nAnd\nMore\n"' });

{
	my $reply;
	$e->send("abc\n");
	$e->expect(1, ['^cba$' => sub { $reply = $e->match } ]);
	is $reply, 'cba', 'reply';
	is $e->before, "My\nHello\n";
	is $e->after, "\nWorld\nAnd\nMore\n";
}
my $wam = "\nWorld\nAnd\nMore\n";

{
	$e->send("def\n");
	$e->expect(1, ['^fed$']);
	is $e->match, 'fed', 'match';
	is $e->clear_accum, $wam;

}

{
	$e->send("dnAX\n");
	$e->expect(1, '-re', '(?:^X(.*d))');
	is $e->match, 'XAnd', 'match';
	is_deeply [$e->matchlist], ['And'], 'matchlist';
	is $e->clear_accum, $wam;

	#[   qr/(?m:^uc:\s*(\w+))/,
}

{
	$e->send("dnAX\n");
	$e->expect(1, '-re', '^X.*d$');
	is $e->match, 'XAnd', 'match';
	is $e->clear_accum, $wam;
}

{
	$e->send("eroM\n");
	$e->expect(1, '-re', '^M(..)e$');
	is $e->match, 'More', 'match';
	is $e->clear_accum, $wam;
}


{
	$e->send("dnAX\n");
	$e->expect(1, '-re', '^X(?s:.*)d$');
	is $e->match, "XAnd\nWorld\nAnd", 'match';
	is $e->clear_accum, "\nMore\n";
}


{
	$e->send("ghi\n");
	$e->expect(1, '-re', '^ihg$');
	is $e->match, 'ihg', 'match';
	is $e->clear_accum, $wam;
}

{
	local $Expect::Multiline_Matching = 0;
	my $reply;
	$e->send("abc\n");
	$e->expect(1, ['^cba$' => sub { $reply = $e->match } ]);
	is $reply, undef, 'reply';
}

{
	local $Expect::Multiline_Matching = 0;
	is $e->clear_accum, "My\nHello\ncba$wam";
	$e->send("def\n");
	$e->expect(1, ['^fed$']);
	#diag $e->before;
	is $e->match, undef, 'match';
	is $e->match, undef;
}

{
	local $Expect::Multiline_Matching = 0;
	$e->send("mno\n");
	$e->expect(1, '-re', '^onm$');
	is $e->match, undef, 'match';
	is $e->match, undef;
}

{
	local $Expect::Multiline_Matching = 0;
	$e->send("dnAX\n");
	$e->expect(1, '-re', '^X.*d$');
	is $e->match, undef;
	is $e->clear_accum, "My\nHello\nfed${wam}My\nHello\nonm${wam}My\nHello\nXAnd${wam}";
}

{
	local $Expect::Multiline_Matching = 0;
	$e->send("dnAX\n");
	$e->expect(1, '-re', '^X(?s:.*)d$');
	is $e->match, undef;
	is $e->clear_accum, "My\nHello\nXAnd$wam";
}


{
	local $Expect::Multiline_Matching = 0;
	$e->send("dnAX\n");
	$e->expect(1, '-re', 'X.*d');   # no ^ and $
	is $e->match, 'XAnd', 'match';
	is $e->clear_accum, $wam;
}

{
	local $Expect::Multiline_Matching = 0;
	$e->send("dnAX\n");
	$e->expect(1, '-re', 'X(?s:.*)d'); # no ^ and $
	is $e->match, "XAnd\nWorld\nAnd", 'match';
	is $e->clear_accum, "\nMore\n";
}


{
	#diag 'localized $Expect::Multiline_Matching = 0;  has no effect after the block:';
	$e->send("abc\n");
	$e->expect(1, ['^cba$']);
	is $e->match, 'cba', 'match';
}

TODO: {
	local $TODO = 'Multiline_Maching does not work when qr// is passed. (Should it work?)' if $] >= 5.010;
	# see the regex subtest checking this thing and see http://www.perlmonks.org/?node_id=1097316
	my $reply;
	$e->send("zorg\n");
	$e->expect(1, [qr/^groz$/ => sub { $reply = $e->match } ]);
	is $reply, 'groz';
}

subtest regex => sub {
	plan tests => 4;

	my $str = "x\nab\ny";
	my $re = '^ab$';
	ok $str !~ /$re/,  're';
	ok $str =~ /$re/m, 're/m';

	my $qre = qr/^ab$/;
	unlike $str, qr/$qre/,  'qre';
	unlike $str, qr/$qre/m, 'qre/m bug in perl 5.8.x'; # see http://www.perlmonks.org/?node_id=1097316
};


