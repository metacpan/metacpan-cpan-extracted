#!/usr/bin/perl

use Markup::Content;

my $content = Markup::Content->new( target => 'noname.html',
				template => 'noname.xml',
				target_options => {
					no_squash_whitespace => [qw(script style pi code pre textarea)]
				},
				template_options => {
					callbacks => {
						title => sub {
							print shift()->get_text();
						}
					}
				});

$content->extract();

$content->tree->save_as(\*STDOUT);