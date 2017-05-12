# -----------------------------------------------------------------------------
#  HTML::Detoxifier - strips harmful HTML from user input   v0.02 - 03/01/2004
#
#  Copyright (c) 2004 Patrick Walton <pwalton@metajournal.net>
#  but freely redistributable under the same terms as Perl itself.
# -----------------------------------------------------------------------------

package HTML::Detoxifier;

use strict;
use warnings FATAL => 'all';
use HTML::TokeParser;
use HTML::Entities;

use base qw<Exporter>;
@HTML::Detoxifier::EXPORT_OK = qw(detoxify); 

$HTML::Detoxifier::VERSION = 0.01;

=head1 NAME

HTML::Detoxifier - practical module to strip harmful HTML

=head1 SYNOPSIS

	use HTML::Detoxifier qw<detoxify>;
	
	my $clean_html = detoxify $html;
	
	my $cleaner_html = detoxify($html, disallow =>
		[qw(dynamic images document)]);
	
	my $stripped_html = detoxify($html, disallow => [qw(everything)]);

=head1 DESCRIPTION

HTML::Detoxifier is a practical module to remove harmful tags from HTML input.
It's intended to be used for web sites that accept user input in the form of
HTML and then present that information in some form.

Accepting all HTML from untrusted users is generally a very bad idea;
typically, all HTML should be run through some kind of filter before being
presented to end users. Cross-site scripting (XSS) vulnerabilities can run
rampant without a filter. The most common and obvious HTML vulnerability lies
in stealing users' login cookies through JavaScript.

Unlike other modules, HTML::Detoxifier is intended to be a practical solution
that abstracts away all the specifics of whitelisting certain tags easily 
and securely. Tags are divided into functional groups, each of which can be
disallowed or allowed as you wish. Additionally, HTML::Detoxifier knows how to
clean inline CSS; with HTML::Detoxifier, you can securely allow users to use
style sheets without allowing cross-site scripting vulnerabilities. (Yes, it is
possible to execute JavaScript from CSS!)

In addition to this main purpose, HTML::Detoxifier cleans up some common
mistakes with HTML: all tags are closed, empty tags are converted to valid
XML (that is, with a trailing /), and images without ALT text as required in
HTML 4.0 are given a plain ALT tag. The module does its best to emit valid
XHTML 1.0; it even adds XML declarations and DOCTYPE elements where needed.

=cut

use constant TAG_GROUPS => {
	links => {
		a => undef,
		area => undef,
		link => undef,
		map => undef
	},
	document => {
		base => undef,
		basefont => undef,
		bdo => undef,
		head => undef,
		body => undef,
		html => undef,
		link => undef,
		meta => undef,
		style => undef,
		title => undef
	},
	aesthetic => {
		b => undef,
		basefont => undef,
		big => undef,
		blink => undef,
		em => undef,
		h1 => undef,
		h2 => undef,
		h3 => undef,
		h4 => undef,
		h5 => undef,
		h6 => undef,
		i => undef,
		kbd => undef,
		marquee => undef,
		pre => undef,
		s => undef,
		small => undef,
		strike => undef,
		strong => undef,
		style => undef,
		'sub' => undef,
		sup => undef,
		tt => undef,
		u => undef,
		var => undef
	},
	'size-changing' => {
		big => undef,
		h1 => undef,
		h2 => undef,
		h3 => undef,
		h4 => undef,
		h5 => undef,
		h6 => undef,
		small => undef,
		style => undef,
		'sub' => undef,
		sup => undef
	},
	block => {
		blockquote => undef,
		br => undef,
		code => undef,
		div => undef,
		dl => undef,
		h1 => undef,
		h2 => undef,
		h3 => undef,
		h4 => undef,
		h5 => undef,
		h6 => undef,
		hr => undef,
		li => undef,
		marquee => undef,
		ol => undef,
		p => undef,
		pre => undef,
		q => undef,
		samp => undef,
		style => undef,
		ul => undef
	},
	forms => {
		button => undef,
		fieldset => undef,
		form => undef,
		input => undef,
		label => undef,
		legend => undef,
		optgroup => undef,
		option => undef,
		select => undef,
		textarea => undef
	},
	layout => {
		caption => undef,
		col => undef,
		colgroup => undef,
		style => undef,
		table => undef,
		tbody => undef,
		td => undef,
		tfoot => undef,
		th => undef,
		thead => undef,
		tr => undef
	},
	images => {
		img => undef,
		map => undef,
		style => undef
	},
	annoying => {
		marquee => undef,
		blink => undef
	},
	dynamic => {
		applet => undef,
		embed => undef,
		noscript => undef,
		object => undef,
		param => undef,
		script => undef
	},
	misc => {
		abbr => undef,
		cite => undef,
		dd => undef,
		del => undef,
		dfn => undef,
		dt => undef,
		span => undef
	}
};

=head1 HTML TAG GROUPS

The following groups can be disallowed or allowed as you choose. Some tags are
present in more than one group. In these cases, the tag must be present in
I<every> allowed group, or the tag will be removed.

=head2 everything

All HTML.

=head2 document

Markup that defines the basic structure of a document (e.g. html, head, body).

=head2 aesthetic

Markup that alters the appearance of text (e.g. strong, strike, b, i, em).

=head2 size-altering

Markup that can alter the size of text (e.g. big, small).

=head2 block

Most block-level markup as defined in the HTML4 specification.

=head2 comments

HTML comments.

=head2 forms

Markup used to create fill-in forms.

=head2 layout

Markup that creates tables or otherwise controls page layout.

=head2 images

Markup that creates images.

=head2 annoying

Markup that creates "annoying" effects undesirable by the majority of web users
(marquee, blink). 

=head2 dynamic

Markup that specifies JavaScript or some other embedded format (SVG, Flash,
Java, etc.) Possibly dangerous.

=head2 misc

Usually seldom-used, typically-harmless HTML tags that specify special types
of inline text. (e.g. abbr, dd, span). 

=cut

use constant TAGS => {
	a => undef,
	abbr => undef,
	acronym => undef,
	address => undef,
	applet => undef,
	area => undef,
	b => undef,
	base => undef,
	basefont => undef,
	bdo => undef,
	big => undef,
	blink => undef,
	blockquote => undef,
	body => undef,
	br => undef,
	button => undef,
	caption => undef,
	cite => undef,
	code => undef,
	col => undef,
	colgroup => undef,
	dd => undef,
	del => undef,
	dfn => undef,
	div => undef,
	dl => undef,
	dt => undef,
	em => undef,
	embed => undef,
	fieldset => undef,
	form => undef,
	h1 => undef,
	h2 => undef,
	h3 => undef,
	h4 => undef,
	h5 => undef,
	h6 => undef,
	head => undef,
	hr => undef,
	html => undef,
	i => undef,
	img => undef,
	input => undef,
	ins => undef,
	kbd => undef,
	label => undef,
	legend => undef,
	li => undef,
	link => undef,
	map => undef,
	marquee => undef,
	meta => undef,
	noscript => undef,
	object => undef,
	ol => undef,
	optgroup => undef,
	option => undef,
	p => undef,
	param => undef,
	pre => undef,
	q => undef,
	s => undef,
	samp => undef,
	script => undef,
	select => undef,
	small => undef,
	span => undef,
	strike => undef,
	strong => undef,
	style => undef,
	'sub' => undef,
	sup => undef,
	table => undef,
	tbody => undef,
	td => undef,
	textarea => undef,
	tfoot => undef,
	th => undef,
	thead => undef,
	title => undef,
	tr => undef,
	tt => undef,
	u => undef,
	ul => undef,
	var => undef
};

use constant EMPTY_ELEMENTS => {
	area => undef,
	base => undef,
	basefont => undef,
	br => undef,
	col => undef,
	frame => undef,
	hr => undef,
	img => undef,
	input => undef,
	isindex => undef,
	link => undef,
	meta => undef,
	param => undef
};

use constant STYLES_ALLOWED_IF => {
	aesthetic => undef,
	block => undef,
	layout => undef,
	'size-changing' => undef,
	images => undef
};

# -- Helper routine to do the common task of removing scripts from CSS --------

sub remove_scripts_from_css
{
	local $_ = shift;

	# This is fairly rough.
	$_ = decode_entities $_; 
	s/[a-z]+script://gis;
	s/\@import//gis;

	$_;
}

# -- Now the actual detoxify routine ------------------------------------------

=head1 INVOCATION

	detoxify(html, options)

Call I<detoxify> to detoxify I<html> with the given I<options>. The most common
key in for the I<options> hash is I<disallow>, which disallows certain features
of HTML. See above for the list of acceptable values. Pass a reference to an
array of strings specifying groups as the value to the optional I<disallow>
hash. You may also specify I<allow_only>, which has the same syntax but
performs the reverse action: only the specified tag sets are allowed. If no
options are specified, dynamic content only is removed.

If you want to detoxify a document in multiple stages, set the I<section>
key in the I<options> hash to the value 'first' on the first page and 'next'
on every subsequent page. This will postpone the tag closing mechanism until
you pass 'last' as the value to the I<section> key.

=cut 

sub detoxify
{
	local $_ = shift;
	my $out = "";

	my $parser = new HTML::TokeParser(\$_);
	our (@tagstack, @oldtagstacks);
	my %opts = @_;
	my $checkcss = 0;

	if (not exists $opts{section} or $opts{section} eq 'first') {
		# Tag stack stacks?
		push @oldtagstacks, [@tagstack];
		@tagstack = ();
	}

	if ($opts{allow_only}) {
		my %allowed = map { $_, undef } @{$opts{allow_only}};
		$opts{disallow} = { map { $_, undef } grep { not exists $allowed{$_} }
			keys %{TAG_GROUPS()} }
	} elsif ($opts{disallow}) {
		$opts{disallow} = { map { $_, undef } @{$opts{disallow}} }
	} else {	
		$opts{disallow} = { dynamic => undef }
	}

	my $styles_allowed = 1;
	foreach my $restriction (keys %{$opts{disallow}}) {
		$styles_allowed = 0, last if exists STYLES_ALLOWED_IF->{$restriction}
	}

	TOKEN: while (my $token = get_token $parser) {
		if ($token->[0] eq 'S') {
			next TOKEN if exists $opts{disallow}{everything};
			next TOKEN unless exists TAGS->{lc $token->[1]};

			foreach my $restriction (keys %{$opts{disallow}}) {
				next TOKEN if
					exists TAG_GROUPS->{$restriction}{lc $token->[1]}
			}

			my %attrs;
			while (my ($key, $value) = each %{$token->[2]}) {
				next unless $key =~ /^[a-z]/i;

				if (exists $opts{disallow}{dynamic}) {
					next if $key =~ /^on/is;
					next if lc($key) eq 'href' and
						$value =~ /^[a-z]+?script:/is;
				}

				$attrs{lc $key} = $value
			}

			# As a special case, external style sheets must be disabled if
			# dynamic content is disallowed.
			next TOKEN if lc $token->[1] eq 'link' and (
				exists $attrs{rel} && lc $attrs{rel} =~
				/^\s*style\s*sheet\s*$/is or
				exists $attrs{type} && lc $attrs{type} =~
				m(^\s*text/css\s*$));

			# If this is a style declaration and dynamic content is
			# disallowed, we need to flag it for checking.
			$checkcss = 1 if lc $token->[1] eq 'style' and exists
				$opts{disallow}{dynamic};

			# Add an ALT tag to images if it's needed.
			$attrs{alt} = '[' .
				(($attrs{src} =~ m{([^/.]*)\.[a-z]+$}gi)[0] or 'image') .
				']' if lc $token->[1] eq 'img' and $attrs{src} and not
				$attrs{alt};

			if (not $styles_allowed) {
				delete $attrs{style} if exists $attrs{style};
				delete $attrs{class} if exists $attrs{class};
				delete $attrs{id} if exists $attrs{id}
			} elsif (exists $opts{disallow}{dynamic}) {
				$attrs{style} = remove_scripts_from_css $attrs{style} if
					$attrs{style}
			}
			
			if (lc $token->[1] eq 'html') {	
				# Add a valid XML declaration and a doctype. HTML::Detoxifier
				# converts everything to XHTML 1.0, so we might as well
				# qualify it!

				$out = <<"ENDDECL" . $out;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
ENDDECL

				$attrs{xmlns} = "http://www.w3.org/1999/xhtml"
					unless $attrs{xmlns};
				$attrs{lang} = "en-US" unless $attrs{lang};	
			}

			$out .= "<" . lc $token->[1];
			while (my ($key, $value) = each %attrs) {
				$value = encode_entities $value;
				$out .= qq( $key="$value");
			}

			if (exists EMPTY_ELEMENTS->{lc $token->[1]}) {
				$out .= " />";
			} else {
				unshift @tagstack, $token->[1];
				$out .= ">";
			}
		} elsif ($token->[0] eq 'E') {
			next TOKEN unless exists TAGS->{lc $token->[1]};
			foreach my $restriction (keys %{$opts{disallow}}) {
				next TOKEN if
					exists TAG_GROUPS->{$restriction}{lc $token->[1]}
			}

			while (@tagstack) {
				my $tag = shift @tagstack;
				$out .= "</$tag>";
				last if $tag eq lc $token->[1]; 	
			}

			$checkcss = 0 if lc $token->[1] eq 'style' and exists
				$opts{disallow}{dynamic};  
		} elsif ($token->[0] eq 'T') {
			local $_ = $token->[1];
			$_ = remove_scripts_from_css $_ if $checkcss;
			
			$out .= $_;
		} elsif ($token->[0] eq 'C') {
			local $_ = $token->[1];
			$_ = remove_scripts_from_css $_ if $checkcss;

			s/(?:<!--\s*|\s*-->)//g;

			$out .= "<!-- $_ -->" unless exists $opts{disallow}{comments}
				or exists $opts{disallow}{everything};
		}
	}	

	if (not exists $opts{section} or $opts{section} eq 'last') { 
		foreach my $unclosedtag (@tagstack) {
			$out .= "</$unclosedtag>";
		}

		@tagstack = @oldtagstacks ? @{pop @oldtagstacks} : ();
	}

	$out;
}

=head1 AUTHOR

Patrick Walton <pwalton@metajournal.net>

=head1 SEE ALSO

L<HTML::Sanitizer>, L<HTML::Scrubber>, L<HTML::StripScripts>, L<HTML::Parser>

=head1 COPYRIGHT

Copyright (c) 2004 Patrick Walton. You may redistribute this module under the
same terms as Perl itself. For more information, see the appropriate LICENSE
file.

=cut

1;

