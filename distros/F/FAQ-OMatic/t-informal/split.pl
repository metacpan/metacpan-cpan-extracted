#!/usr/local/bin/perl
#
# split.pl
# a demo FAQ::OMatic::API client that takes an answer and splits each
# of its text parts into separate answer. This is useful for splitting
# an overgrown answer into a categoryful of answers.
#

# The FAQ-O-Matic file= number of the answer we want to split apart
my $splitee = 38;

# The FAQ-O-Matic file= number of the category we'll create the new
# answers in.
my $target = 362;

#'use lib's to pick up FAQ::OMatic and the LWP stuff API depends upon
# use lib '/u/jonh/user_perl/lib/site_perl';
# use lib '/u/jonh/fom24dev/lib';

# get the FOM API
use FAQ::OMatic::API;

my $fom = new FAQ::OMatic::API();
#$fom->{'debug'} = 1;
# point at the FAQ you want to modify
$fom->setURL('http://site.example.tld/~user/fom.pl');

# ask user to give us login authentication info to pass to FAQ
#$fom->setAuth('test-login@test.dartmouth.edu', 'testpass');
$fom->setAuth('query');

# get the item we're going to split up
my $item = $fom->getItem($splitee);

# for each part in the item...
for ($i=0; $i<$item->numParts(); $i++) {

	# get its original text
	my $text = $item->getPart($i)->{'Text'};

	# get the authors of the part
	my @authors = 
		map { "<mailto:$_>" }
			grep { not m/jonh\@cs.dartmouth.edu/ } 
				$item->getPart($i)->{'Author-Set'}->getList();
	my $authors;
	if (@authors>0) {
		$authors = "\n\n".join(', ', @authors)."\n";
	} else {
		$authors = '';
	}
	# We have to preserve authors in text of part, since there's not yet an
	# API for "lying" about authors. (New items are authored by the
	# uid that ran the API code.)

	# come up with a proposed title for the new answer by schlorping
	# 7 words off the front of the text
	my @words = split(/(\s+)/, $text);
	my $title = join('', splice(@words, 0, 13));

	# request that the new answer be created in category $target
	($rc, my $msg) =
		$fom->newAnswer($target, $title, $text.$authors);
	die $msg if (not $rc);
}
