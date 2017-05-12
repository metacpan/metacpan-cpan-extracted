package HTML::HTML5::Builder;

use 5.010;
use base qw[Exporter];
use common::sense;
use constant { FALSE => 0, TRUE => 1 };
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use overload;
use utf8;
use warnings::register;

BEGIN {
	$HTML::HTML5::Builder::AUTHORITY = 'cpan:TOBYINK';
}
BEGIN {
	$HTML::HTML5::Builder::VERSION   = '0.004';
}

use Carp 0 qw();
use HTML::HTML5::Builder::Document;
use HTML::HTML5::Entities 0.001 qw();
use Scalar::Util 0 qw(blessed);
use XML::LibXML 1.60 qw();

my (@elements, @uc_elements, @conforming);
our (@EXPORT_OK, @EXPORT, %EXPORT_TAGS);
BEGIN
{	
	@elements = qw{
		a abbr acronym address applet area article aside audio b base
		basefont bb bdo bgsound big blink blockquote body br button canvas
		caption center cite code col colgroup command datagrid datalist
		dd del details dfn dialog dir div dl dt em embed fieldset figure
		figcaption font footer form frame frameset h1 h2 h3 h4 h5 h6
		head header hgroup hr html i iframe img input ins isindex kbd
		keygen label legend li link listing map mark marquee menu meta
		meter nav nobr noembed noframes noscript object ol optgroup
		option output p param plaintext pre progress q rp rt ruby s
		samp script select section small source spacer span strike
		strong style sub sup summary table tbody td textarea tfoot th
		thead time title tr track tt u ul var video wbr xmp
		};
	@uc_elements = qw{Q Sub Time Map Meta Link S};
	@conforming = qw{
		a abbr address area article aside audio b base bb bdo blockquote
		body br button canvas caption cite code col colgroup command
		datagrid datalist dd del details dfn dialog div dl dt em embed
		fieldset figure footer form h1 h2 h3 h4 h5 h6 head header hr html
		i iframe img input ins kbd label legend li mark menu
		meter nav noscript object ol optgroup option output p param
		pre progress rp rt ruby samp script section select small source
		span strong style sup table tbody td textarea tfoot th thead
		title tr ul var video
		};
	my @cool_stuff  = qw{COMMENT CHUNK XML_CHUNK RAW_CHUNK ELEMENT TEXT};
	my @boilerplate = qw{JQUERY CREATIVE_COMMONS OPENGRAPH};

	@EXPORT_OK   = (@elements, @cool_stuff, @uc_elements, @boilerplate);
	@EXPORT      = ();
	%EXPORT_TAGS = (
		all      => \@EXPORT_OK,
		standard => [@conforming, @cool_stuff, qw{Q Sub Time Map Meta Link}],
		default  => \@EXPORT,
		metadata => [qw(head title base Link Meta style)],
		sections => [qw(body div section nav article aside h1 h2 h3 h4 h5 h6 header footer address)],
		grouping => [qw(p hr br pre dialog blockquote ol ul li dl dt dd)],
		text     => [qw(a cite em strong small mark dfn abbr progress
			meter code var samp kbd sup span i b bdo ruby rt rp Q Sub Time)],
		embedded => [qw(figure img iframe embed object param video audio source
			canvas area Map)],
		tabular  => [qw(table thead tbody tfoot th td colgroup col caption)],
		form     => [qw(form fieldset label input button select datalist
			optgroup option textarea output)],
		);		
}

sub new
{
	my ($class, %options) = @_;
	bless \%options, $class;
}

sub ELEMENT
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	my ($el, @params) = @_;

	if (warnings::enabled())
	{
		Carp::carp("Non-standard HTML element <$el>")
			unless grep { lc $el eq $_ } @elements;
	}

	my $EL = XML::LibXML::Element->new($el);
	$EL->setNamespace(XHTML_NS, undef, TRUE);
	
	if ($el eq 'time' and blessed($params[0]) and $params[0]->isa('DateTime'))
	{
		my $dt = shift @params;
		my $string = $dt->strftime('%FT%T');
		if ($dt->time_zone->is_utc)
		{
			$string .= 'Z';
		}
		elsif (!$dt->time_zone->is_floating)
		{
			my $zone = $dt->strftime('%z');
			$zone =~ s/^(.\d{2})(\d{2})$/$1:$2/;
			$string .= $zone;
		}
		$EL->setAttribute('datetime', $string);
		if (!@params)
		{
			push @params, "$dt";
		}
	}
	
	PARAM: while (@params)
	{
		my $thing = shift @params;
		
		if (blessed($thing) and $thing->isa('XML::LibXML::Element'))
		{
			$EL->appendChild($thing);
		}
		elsif (blessed($thing) and $thing->isa('XML::LibXML::Text'))
		{
			$EL->appendChild($thing);
		}
		elsif (blessed($thing) and $thing->isa('XML::LibXML::Comment'))
		{
			$EL->appendChild($thing);
		}
		elsif (blessed($thing) and $thing->isa('XML::LibXML::PI'))
		{
			$EL->appendChild($thing);
		}
		elsif (blessed($thing) and $thing->isa('XML::LibXML::NodeList'))
		{
			$EL->appendChild($_) foreach $thing->get_nodelist;
		}
		elsif (blessed($thing) and $thing->isa('XML::LibXML::Attr'))
		{
			$EL->setAttribute($thing->nodeName, $thing->getValue);
		}
		elsif (ref $thing eq 'IO')
		{
			local $/ = undef;
			my $string = <$thing>;
			$EL->appendText($string);
		}
		elsif (ref $thing eq 'SCALAR')
		{
			$$thing = $EL;
		}
		elsif (ref $thing eq 'ARRAY')
		{
			unshift @params, map
				{ ref $_ ? $_ : XML::LibXML::Text->new($_); }
				@$thing;
			redo PARAM;
		}
		elsif (ref $thing eq 'HASH')
		{
			while (my ($k, $v) = each %$thing)
			{
				$k =~ s/^-//g;
				$EL->setAttribute($k, "$v");
			}
		}
		elsif (!ref $thing and $thing =~ /^-(\S+)$/ and @params)
		{
			my $attr  = $1;
			my $value = shift @params;
			$EL->setAttribute($attr, "$value");			
		}
		elsif (defined $thing)
		{
			if (warnings::enabled())
			{
				if (defined ref($thing) and ref($thing) =~ /^(CODE|REF|GLOB|LVALUE|FORMAT|Regexp)$/)
					{ Carp::carp(sprintf("Passed a %s reference", ref($thing))); }
				elsif (blessed($thing) and !overload::Method($thing, '""'))
					{ Carp::carp(sprintf("Passed a blessed reference (%s) that does not overload stringification", ref($thing))); }
			}
			
			$EL->appendText("$thing");
		}
	}
	
	if ($el eq 'html')
	{
		my $doc = HTML::HTML5::Builder::Document->new('1.0', 'utf-8');
		$doc->adoptNode($EL);
		$doc->setDocumentElement($EL);
		return $doc;
	}
	
	return $EL;
}

sub _mksub
{
	no strict 'refs';
	
	my ($function, $element) = @_;
	$element = lc $function unless defined $element and length $element;
	
	my $sub = sub
	{
		shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
		return ELEMENT($element, @_);
	};
	
	return $sub;
}

sub AUTOLOAD
{
	my ($func) = our $AUTOLOAD =~ /::(\w+)$/;
	Carp::croak("Undefined function") unless $func =~ /^(([A-Za-z][a-z]*)|([Hh][1-6]))$/;
	Carp::croak("Undefined function") unless grep { lc $func eq $_ } @elements;	
	my $sub = *{$func} = _mksub($func);
	return $sub->(@_);
}

sub DESTROY {} # not AUTOLOAD

# Thanks to AUTOLOAD, UNIVERSAL::can is a little broken here, so instead
# we define out own can.
sub can
{
	my ($class, $func) = @_;
	
	my $answer = UNIVERSAL::can(__PACKAGE__, $func)
		|| __PACKAGE__->SUPER::can($func);
	return $answer if $answer;
	
	if ($func =~ /^(([A-Za-z][a-z]*)|([Hh][1-6]))$/
	and grep { lc $func eq $_ } @elements)
	{
		return _mksub($func);
	}
	
	return;
}

sub TEXT
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	return XML::LibXML::TextNode->new($_[0]);
}

sub COMMENT
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	return XML::LibXML::Comment->new($_[0]);
}

{
	my $parser = undef;
	sub CHUNK
	{
		shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
		
		unless ($parser)
		{
			eval 'use HTML::HTML5::Parser; 1;'
				or Carp::croak("This feature requires HTML::HTML5::Parser.\n");
			$parser = HTML::HTML5::Parser->new;
		}
		
		my $dom  = $parser->parse_string($_[0]);
		my @kids = $dom->getElementsByTagName('body')->shift->childNodes;
		return @kids;
	}
}

{
	my $parser = undef;
	sub XML_CHUNK
	{
		shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
		
		unless ($parser)
		{
			$parser = XML::LibXML->new;
		}
		
		my $dom  = $parser->parse_balanced_chunk($_[0]);
		my @kids = $dom->childNodes;
		return @kids;
	}
}

{
	my $dummyDoc = XML::LibXML::Document->new;
	sub RAW_CHUNK
	{
		shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
		return $dummyDoc->createPI('decode', HTML::HTML5::Entities::encode_numeric($_[0]));
	}
}

sub _find_version
{
	my ($req, @versions) = @_;

	return $versions[-1] unless defined $req;

	my $requested = do {
		my ($maj, $min, $rev) = split /\./, $req;
		($maj||0)*1_000_000 + ($min||0)*1_000 + ($rev||0);
		};
	foreach my $v (@versions)
	{
		my $thisver = do {
			my ($maj, $min, $rev) = split /\./, $v;
			($maj||0)*1_000_000 + ($min||0)*1_000 + ($rev||0);
			};
		if ($thisver >= $requested)
		{
			return $v;
		}
	}
	return $req;
}

sub JQUERY
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	my (%opts) = (scalar @_==1) ? (-version => $_[0]) : @_;
	my @rv;
	
	my $templates = {
		official => {
			jQuery     => 'http://code.jquery.com/jquery-%s.%s',
			jQuery_v   => '1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6, 1.3.0, 1.3.1, 1.3.2, 1.4.0, 1.4.1, 1.4.2, 1.4.3, 1.4.4, 1.5.0, 1.5.1, 1.5.2, 1.6.0, 1.6.1, 1.6.2, 1.6.3, 1.6.4',
			jQueryUI   => 'http://code.jquery.com/ui/%s/jquery-ui.%s',
			jQueryUI_v => '1.7.0, 1.7.1, 1.7.2, 1.7.3, 1.8.0, 1.8.1, 1.8.2, 1.8.4, 1.8.5, 1.8.6, 1.8.7, 1.8.8, 1.8.9, 1.8.10, 1.8.11, 1.8.12, 1.8.13, 1.8.14, 1.8.15, 1.8.16',
			Style      => 'http://code.jquery.com/ui/%s/themes/%s/jquery-ui.css',
			Themes     => 'base black-tie blitzer cupertino dark-hive dot-luv eggplant excite-bike flick hot-sneaks humanity le-frog mint-choc overcast pepper-grinder redmond smoothness south-street start sunny swanky-purse trontastic ui-darkness ui-lightness vader',
			},
		google    => {
			jQuery     => 'https://ajax.googleapis.com/ajax/libs/jquery/%s/jquery.%s',
			jQuery_v   => '1.2.3, 1.2.6, 1.3.0, 1.3.1, 1.3.2, 1.4.0, 1.4.1, 1.4.2, 1.4.3, 1.4.4, 1.5.0, 1.5.1, 1.5.2, 1.6.0, 1.6.1, 1.6.2, 1.6.3, 1.6.4',
			jQueryUI   => 'https://ajax.googleapis.com/ajax/libs/jqueryui/%s/jquery-ui.%s',
			jQueryUI_v => '1.5.2, 1.5.3, 1.6.0, 1.7.0, 1.7.1, 1.7.2, 1.7.3, 1.8.0, 1.8.1, 1.8.2, 1.8.4, 1.8.5, 1.8.6, 1.8.7, 1.8.8, 1.8.9, 1.8.10, 1.8.11, 1.8.12, 1.8.13, 1.8.14, 1.8.15, 1.8.16',
			Style      => 'http://ajax.googleapis.com/ajax/libs/jqueryui/%s/themes/%s/jquery-ui.css',
			Themes     => 'base black-tie blitzer cupertino dark-hive dot-luv eggplant excite-bike flick hot-sneaks humanity le-frog mint-choc overcast pepper-grinder redmond smoothness south-street start sunny swanky-purse trontastic ui-darkness ui-lightness vader',
			},
		microsoft => {
			jQuery     => 'http://ajax.aspnetcdn.com/ajax/jquery/jquery-%s.%s',
			jQuery_v   => '1.3.2, 1.4, 1.4.1, 1.4.2, 1.4.3, 1.4.4, 1.5, 1.5.1, 1.5.2, 1.6, 1.6.1, 1.6.2, 1.6.3, 1.6.4',
			jQueryUI   => 'http://ajax.aspnetcdn.com/ajax/jquery.ui/%s/jquery-ui.%s',
			jQueryUI_v => '1.8.5, 1.8.6, 1.8.7, 1.8.8, 1.8.9, 1.8.10, 1.8.11, 1.8.12, 1.8.13, 1.8.14, 1.8.15, 1.8.16',
			Style      => 'http://ajax.aspnetcdn.com/ajax/jquery.ui/%s/themes/%s/jquery-ui.css',
			Themes     => 'base black-tie blitzer cupertino dark-hive dot-luv eggplant excite-bike flick hot-sneaks humanity le-frog mint-choc overcast pepper-grinder redmond smoothness south-street start sunny swanky-purse trontastic ui-darkness ui-lightness vader',
			},
		};
	my $template = $templates->{ lc $opts{-source}||'google' } || $templates->{'google'};

	my @jquery_versions = split /\s*\,\s*/, $template->{jQuery_v};
	my $url = sprintf($template->{jQuery},
		_find_version($opts{-version}, @jquery_versions),
		(!defined $opts{-min} or $opts{-min})?'min.js':'js',
		);	
	push @rv, script(
		-type  => 'text/javascript',
		-src   => $url,
		);
	
	if ((defined $opts{-ui} or defined $opts{-ui_version} or defined $opts{-theme})
	and not (defined $opts{-ui} and !$opts{-ui}))
	{
		my @jqueryui_versions = split /\s*\,\s*/, $template->{jQueryUI_v};
		my $url = sprintf($template->{jQueryUI},
			_find_version($opts{-ui_version}, @jqueryui_versions),
			(!defined $opts{-min} or $opts{-min})?'min.js':'js',
			);	
		push @rv, script(
			-type  => 'text/javascript',
			-src   => $url,
			);
		
		if (defined $opts{-theme})
		{
			my $theme = $opts{-theme};
			$theme = 'base' unless $template->{Themes} =~ /\b$theme\b/;
			
			my $url = sprintf($template->{Style},
				_find_version($opts{-ui_version}, @jqueryui_versions),
				$theme,
				);	
			push @rv, Link(
				-rel   => 'stylesheet',
				-media => 'screen',
				-type  => 'text/css',
				-src   => $url,
				);
		}
	}
	
	return wantarray ? @rv : XML::LibXML::NodeList->new_from_ref(\@rv, 1);
}

sub CREATIVE_COMMONS
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	my (%opts) = (scalar @_==1) ? (-licence => $_[0]) : @_;
	$opts{-licence} ||= delete $opts{-license}; # be kind to Americans
	$opts{-licence} ||= 'by-sa';
	my @rv;
	
	if (warnings::enabled())
	{
		Carp::carp("Unknown licence")
			unless lc $opts{-licence} =~ /^by(-(sa|nd|nc|nc-sa|nc-nd))?$/;
	}
	
	my $size = {
		'small'  => '80x15',
		'large'  => '88x31',
		'80x15'  => '80x15',
		'88x31'  => '88x31',
		}->{ lc $opts{-size} || 'large' } || '88x31';
	
	push @rv, a(
		-rel   => 'license',
		-href  => sprintf("http://creativecommons.org/licenses/%s/3.0/", lc $opts{-licence}),
		img(
			-alt   => ($opts{-alt} || sprintf("Creative Commons %s Licence", uc $opts{-licence})),
			-style => 'border:0',
			-src   => sprintf("http://i.creativecommons.org/l/%s/3.0/%s.png", lc $opts{-licence}, $size),
			),
		);
		
	if (defined $opts{-attributionName}
	or  defined $opts{-attributionURL}
	or  defined $opts{-type}
	or  defined $opts{-title})
	{
		my ($this_work, $attribution);
		push @rv, br(), span(
			span(\$this_work, $opts{-title}||'This work'),
			defined $opts{-attributionName} ? [' by ', span(\$attribution, -property=>'cc:attributionName', [$opts{-attributionName}])] : [],
			' is licensed under a ',
			a(
				-rel   => 'license',
				-href  => sprintf("http://creativecommons.org/licenses/%s/3.0/", lc $opts{-licence}),
				[$opts{-alt} || sprintf("Creative Commons %s Licence", uc $opts{-licence})],
				),
			);
		
		if (defined $opts{-title})
		{
			$this_work->setAttribute(property => 'dc:title');
		}
		if (defined $opts{-type} and length $opts{-type})
		{
			$this_work->setAttribute(rel      => 'dc:type');
			$this_work->setAttribute(resource => sprintf('http://purl.org/dc/dcmitype/%s', ucfirst lc $opts{-type}));
		}
		if (defined $attribution and defined $opts{-attributionURL})
		{
			$this_work->setAttribute(rel      => 'cc:attributionURL');
			$this_work->setAttribute(resource => $opts{-attributionURL});
		}
	}

	return span(@rv,
		-class=>'creative_commons',
		(defined $opts{-url} ? { -about => $opts{-url} } : {}),
		);
}

sub OPENGRAPH
{
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	my (%opts) = (scalar @_==1) ? %{$_[0]} : @_;
	
	my $map = {
		title       => 'og:title dc:title',
		url         => 'og:url dc:identifier',
		description => 'og:description dc:description',		
		};
	
	my @rv;
	while (my ($key, $value) = each %opts)
	{
		$key = lc $key;
		$key =~ s/^-//;
		
		push @rv, Meta(-property => ($map->{$key}||sprintf('og:%s', $key)), -content => $value);
	}
	
	return wantarray ? @rv : XML::LibXML::NodeList->new_from_ref(\@rv, 1);
}

1;

__END__

=head1 NAME

HTML::HTML5::Builder - erect some scaffolding for your documents

=head1 SYNOPSIS

  use HTML::HTML5::Builder qw[:standard JQUERY];

  open my $fh, '<', 'inline-script.js';
  
  print html(
    -lang => 'en',
    head(
      title('Test'),
      Meta(-charset => 'utf-8'),
    ),
    body(
      h1('Test'),
      p('This is a test.'),
      JQUERY(-version => '1.6.4'),
      script(-type => 'text/javascript', $fh),
    ),
  );

=head1 DESCRIPTION

This module can export function names corresponding to any HTML5 element.

Each function returns an XML::LibXML::Element with the same name as the
function. The arguments to each function are processed as a list, and
used to set the attributes and contents of that element.

For each item on the list:

=over

=item * if it's an XML::LibXML::Element, XML::LibXML::TextNode,
XML::LibXML::Comment, or XML::LibXML::PI, it's appended as a
child of the returned element.

=item * if it's an XML::LibXML::NodeList, each item on the list is
appended as a child of the returned element.

=item * if it's an XML::LibXML::Attr, it's set as an attribute on
the returned element

=item * if it's an IO::Handle, then it will be slurped and appended
to the returned element as a text node.

=item * if it's a scalar reference, then the returned element is also
assigned to it. (This feature is B<at risk>.)

=item * if it's a scalar (string) some guesswork is conducted to figure
out whether you're setting an attribute and value, or whether the string
should be used as a text node. The presence of a hyphen at the start of
the string is the main deciding factor.

  p('-class', 'warning', '$LordLucan not found.');

In this example, a paragraph element is returned, with the class attribute
set to 'warning' and the textual contents '$LordLucan not found.'.

Sometimes it's necessary to protect values against this guesswork. By
passing a hashref, all the keys and values are interpreted as setting
attributes; by passing an arrayref, all values are interpreted as setting
the contents of the element.

  p(['-class'], { warning => '$LordLucan not found.' });

In this example, a paragraph element is returned, with the warning attribute
set to '$LordLucan not found.' and the textual contents '-class'.

=item * Anything else is stringified and added as a text node. This is
useful for things with sensible stringification defined, such as C<DateTime>
and C<URI> objects, but less so for some other objects, so you will
sometimes get a warning if warnings are enabled. Warnings can be disabled
using:

  no warnings 'HTML::HTML::Builder';

=back

=head2 Exceptional Cases

The C<html> function does not return an C<XML::LibXML::Element>, but rather a
C<HTML::HTML5::Builder::Document> object.

There is special handling for C<time> (or C<Time>). If the first parameter passed to
it is a L<DateTime> object, then that object is used to set its datetime attribute.
If there are no subsequent parameters, then the stringified form of the object is also
used to form the content of the <time> element.

Note that the functions that generate <meta>, <link>, <q>, <time>, <sub>, <s> and <map>
HTML elements are named C<< Meta() >>, C<< Link() >>, C<< Q() >>, C<< Time() >>, C<< Sub() >>,
C<< S() >> and C<< Map() >> respectively, with an upper-case first letter. This is
because each of these names corresponds to a built-in perl keyword (except meta,
which is used by Moose). The lower-case versions of these do exist, and can be
exported if you ask for them explicitly. The lower-case versions are also
available as methods using the object-oriented syntax. (In fact, lower case and ucfirst
versions exist for all HTML elements - they're just not always exportable.)

=head2 General Purpose Functions

=over

=item C<< ELEMENT($tagname, @arguments) >>

If you need to insert an element which doesn't have its own function.

=item C<< TEXT($string) >>

Produces a text node.

=item C<< COMMENT($string) >>

Produces an HTML comment.

=item C<< CHUNK($string) >>

Parses the string as HTML, and produces a list of elements, text nodes and
comments.

This should be a so-called "balanced chunk". Due to limitations in
L<HTML::HTML5::Parser>, this only works for body content. Croaks if
L<HTML::HTML5::Parser> is not installed.

=item C<< XML_CHUNK($string) >>

More useful version of C<CHUNK>, without the restriction on content,
but input needs to be a balanced and well-formed XML chunk.

=item C<< RAW_CHUNK($string) >>

This allows you to include stuff that isn't anything close to valid 
HTML into the output document, such as a PHP block. e.g.

  html(
    head(
      title('Funny test'),
      ),
    body(
      h1('Funny test'),
      RAW_CHUNK("<p>Here's a fish: <=><"),
      ),
    );

A processing instruction is used to represent this data in the DOM.
HTML::HTML5::Writer can detect that processing instruction and use it to
output the raw data. If you're not using HTML::HTML5::Writer to serialise
the document, then you may need to post-process the serialised document.

With great power comes great responsibility.

=back

=head2 Boiler-Plate Functions

There are also a number of functions that create lists of multiple HTML
elements, for boiler-plate code. 

=over

=item C<< JQUERY(-version => $ver, %options) >>

Link to jQuery at a CDN.

Other options include B<-source>, to indicate where to link to jQuery (currently
allowed values are "Google", "Microsoft" and "official"); and B<-min>, a boolean
which indicates whether the minified version should be linked to (true by
default).

Setting option B<-ui> to true, also includes jQuery UI. A version number can be
indicated using B<-ui_version>. A theme can be included setting B<-theme>. Setting
either B<-ui_version> or B<-theme> will imply B<-ui>.

  JQUERY(
    -source     => 'official',
    -version    => '1.6.4',
    -ui_version => '1.8.16',
    -theme      => 'eggplant',
    );

If versions aren't provided, defaults to the latest versions of the libraries
that the author of HTML::HTML5::Builder was aware of at the time of publication.
If you choose a version which is known to be unavailable at the selected CDN,
the function should automatically choose a slightly later version.

=item C<< CREATIVE_COMMONS($licence) >>

=item C<< CREATIVE_COMMONS(-licence => $licence, %options) >>

C<$licence> can be one of 'by', 'by-nd', 'by-nc', 'by-sa', 'by-sa-nc',
or 'by-sa-nd'.

Other options supported are:

=over

=item * B<-url> - URL of the thing being licensed (if not the page itself)

=item * B<-size> - 'large' or 'small' for the image

=item * B<-title> - title of the work

=item * B<-attributionName> - name people should use for attribution

=item * B<-attributionURL> - link people should use for attribution

=back

=item C<< OPENGRAPH(%data) >>

Returns a list of <meta> elements providing Open Graph Protocol data
for your page.

  OPENGRAPH(
    -title       => "Hello World",
    -type        => "example",
    -description => "A global greeting.",
    );

=back

=head2 Exporting Functions

None by default. Pretty much anything can be exported on request.

Export tags:

=over

=item * C<:all> - everything

=item * C<:standard> - elements that are not obsolete in HTML5, plus ELEMENT, TEXT, COMMENT, CHUNK, XML_CHUNK and RAW_CHUNK

=item * C<:metadata> - head title base Link Meta style

=item * C<:sections> - body div section nav article aside h1 h2 h3 h4 h5 h6 header footer address

=item * C<:grouping> - p hr br pre dialog blockquote ol ul li dl dt dd

=item * C<:text> - a Q cite em strong small mark dfn abbr progress meter code var samp kbd Sub sup span i b bdo ruby rt rp Time

=item * C<:embedded> - figure img iframe embed object param video audio source canvas area

=item * C<:tabular> - table thead tbody tfoot th td colgroup col caption

=item * C<:form> - form fieldset label input button select datalist optgroup option textarea output

=back

=head2 Object Oriented Interface

You can also use these functions as methods of an object blessed into
the L<HTML::HTML5::Builder> package.

  my $b = HTML::HTML5::Builder->new;
  my $document = $b->html(
    -lang => 'en',
    $b->head(
      $b->title('Test', \(my $foo)),
      $b->meta(-charset => 'utf-8'),
    ),
    $b->body(
      $b->h1('Test'),
      $b->p('This is a test.')
    ),
  );

=head2 Using with RDF::RDFa::Generator

L<RDF::RDFa::Generator> has a C<nodes> method which returns a handy list of
C<XML::LibXML::Node> objects.

  use DateTime;
  use HTML::HTML5::Builder qw[:standard];
  use RDF::RDFa::Generator;
  use RDF::Trine;
  
  my $url   = 'http://dbpedia.org/data/Charles_Darwin';
  my $model = RDF::Trine::Model->new;
  RDF::Trine::Parser->parse_url_into_model($url, $model);
  
  my $gen = RDF::RDFa::Generator->new(style=>'HTML::Pretty');
  
  print html(
    head(
      title("Some Data About Charles Darwin"),
      ),
    body(
      h1("Some Data About Charles Darwin"),
      $gen->nodes($model),
      hr(),
      address(
        "Source: $url", br(),
        "Generated: ", Time(DateTime->now),
        ),
      ),
    );

Nice?

=head2 Using with XML::LibXML::PrettyPrint

HTML::HTML5::Builder doesn't nicely indent your markup, but
L<XML::LibXML::PrettyPrint> can.

  use HTML::HTML5::Builder qw(:standard);
  use XML::LibXML::PrettyPrint qw(print_xml);
  print_xml html(
    head(title("Test")),
    body(h1("Test"), p("This is a test.")),
    );

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-Builder>.

=head1 SEE ALSO

L<XML::LibXML>,
L<HTML::HTML5::Writer>,
L<HTML::HTML5::Builder::Document>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

