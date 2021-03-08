package HTML::Make::Page;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/make_page/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.01';
use HTML::Make '0.15';

sub add_meta
{
    my ($head, $meta) = @_;
    if (ref $meta ne 'ARRAY') {
	carp "meta is not an array reference";
	return;
    }
    my $i = -1;
    for my $m (@$meta) {
	$i++;
	if (ref $m ne 'HASH') {
	    carp "meta element $i is not a hash reference";
	    next;
	}
	$head->push ('meta', attr => $m);
    }
}

sub add_link
{
    my ($head, $link, $quiet) = @_;
    if (ref $link ne 'ARRAY') {
	carp "link is not an array reference";
	return;
    }
    my $i = -1;
    for my $l (@$link) {
	$i++;
	if (ref $l ne 'HASH') {
	    carp "link element $i is not a hash reference";
	    next;
	}
	if (! $l->{rel}) {
	    carp "link element $i has no value for 'rel', skipping";
	    next;
	}
	if (! $l->{href}) {
	    if (! $quiet) {
		carp "link element $i ($l->{rel}) has no href";
	    }
	}
	$head->push ('link', attr => $l);
    }
}

sub make_page
{
    my (%options) = @_;
    my $quiet;
    if ($options{quiet}) {
	$quiet = $options{quiet};
	delete $options{quiet};
    }
    my $html = HTML::Make->new ('html');
    if ($options{lang}) {
	$html->add_attr (lang => $options{lang});
	delete $options{lang};
    }
    my $head = $html->push ('head');
    $head->push (
	'meta',
	attr => {
	    charset => 'UTF-8'
	}
    );
    $head->push (
	'meta',
	attr => {
	    name => 'viewport',
	    content =>
	    'width=device-width, initial-scale=1.0'
	}
    );
    if ($options{css}) {
	for my $css (@{$options{css}}) {
	    $head->push (
		'link',
		attr => {
		    rel => 'stylesheet',
		    type => 'text/css',
		    href => $css,
		}
	    );
	}
	delete $options{css};
    }
    if ($options{js}) {
	my $i = -1;
	for my $js (@{$options{js}}) {
	    $i++;
	    if (ref $js eq 'HASH') {
		if (! $js->{src}) {
		    if (! $quiet) {
			carp "No src specified for js element $i";
		    }
		    next;
		}
		$head->push ('script', attr => $js);
	    }
	    else {
		$head->push (
		    'script',
		    attr => {
			src => $js,
		    },
		)
	    }
	}
	delete $options{js};
    }
    if ($options{title}) {
	$head->push ('title', text => $options{title});
	delete $options{title};
    }
    else {
	if (! $quiet) {
	    carp "No title";
	}
    }
    if ($options{style}) {
	$head->push ('style', text => $options{style});
	delete $options{style};
    }
    if ($options{meta}) {
	add_meta ($head, $options{meta});
	delete $options{meta};
    }
    if ($options{link}) {
	add_link ($head, $options{link}, $quiet);
	delete $options{link};
    }
    if (! $quiet) {
	for my $k (keys %options) {
	    carp "Unknown option $k";
	    delete $options{$k};
	}
    }
    my $body = $html->push ('body');
    return ($html, $body);
}

1;
