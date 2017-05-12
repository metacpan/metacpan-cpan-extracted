use strict;
use warnings;
use Test::More tests => '5';
use HTML::Template::Convert::TT 'convert';

SKIP: {

		eval { require HTML::Template; };
		skip 'HTML::Template is not installed', 3 if $@;
		eval { require Template; };
		skip 'TemplateToolkit is not installed', 3 if $@;

		use HTML::Template;
		use Template;

		chdir 'templates';
		my $fname = 'loop-if.tmpl';
		my $text = convert $fname;

		my $tt = Template->new;
		my $tt_out;
		$tt->process(\$text, {}, \$tt_out);
		ok($tt_out =~ /Loop not filled in/);

		my $vars = { LOOP_ONE => [{VAR => 'foo'}] };
		my $tmpl = HTML::Template->new(filename => $fname);
		$tmpl->param($vars);
		$tt_out = undef;
		$tt->process(\$text, { LOOP_ONE => [{VAR => 'foo'}] }, \$tt_out);
		is
			$tt_out,
			$tmpl->output;

		$fname = 'counter.tmpl';
		$text = convert($fname, loop_context_vars => 1);
		$vars = 
			{ 
				foo => [ {a => 'a'}, {a => 'b'}, {a => 'c'} ],
				outer => [ {inner => [ {a => 'a'}, {a => 'b'}, {a => 'c'} ] },
								   {inner => [ {a => 'x'}, {a => 'y'}, {a => 'z'} ] }
					]
			};
		$tmpl = HTML::Template->new(filename => $fname, loop_context_vars => 1);
		$tmpl->param($vars);
		$tt_out = undef;
		$tt->process(\$text, $vars, \$tt_out);
		is
			$tt_out,
			$tmpl->output;

		$fname = 'context.tmpl';
		$text = convert($fname, loop_context_vars => 1);
		$vars = {
			FRUIT => [
				{ KIND => 'Apples' },
				{ KIND => 'Oranges' },
				{ KIND => 'Brains' },
				{ KIND => 'Toes' },
				{ KIND => 'Kiwi' }
			],
			PINGPONG => [ {}, {}, {}, {}, {}, {} ] 
		};
		$tmpl = HTML::Template->new(filename => $fname, loop_context_vars => 1);
		$tmpl->param($vars);
		$tt_out = undef;
		$tt->process(\$text, $vars, \$tt_out);
		is
			$tt_out,
			$tmpl->output;

		$fname = 'loop-context.tmpl';
		$text = convert($fname, loop_context_vars => 1);
		$vars = {
				TEST_LOOP => [ { NUM => 1 } ]
		};
		$tt_out = undef;
		$tt->process(\$text, $vars, \$tt_out) or die $tt->error;
		ok($tt_out =~ /1:FIRST::LAST:ODD/);
		print $text;
		print $tt_out;
}
