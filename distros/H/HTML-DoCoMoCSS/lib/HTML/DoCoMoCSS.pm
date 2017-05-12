package HTML::DoCoMoCSS;
use strict;
use warnings;
use CSS::Tiny::Style;
use CSS::Tiny;
use File::Spec;
use Carp;
use HTML::Selector::XPath 'selector_to_xpath';
use XML::LibXML;
use XML::LibXML::XPathContext;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %args = @_;

    unless (exists $args{base_dir}) {
        croak "base_dir is required";
    }

    bless {%args}, $class;
}

sub apply {
    my ($self, $content) = @_;
    croak "HTML::DoCoMoCSS->apply is instance method" unless ref $self;

    # escape Numeric character reference.
    $content =~ s/&#(\d+);/HTMLCSSINLINERESCAPE$1::::::::/g;

    my $xml = XML::LibXML->new();
    my $doc = $xml->parse_string($content);
    my $xc = XML::LibXML::XPathContext->new($doc);

    my $root = $doc->documentElement();
    my $namespace = $root->getAttribute('xmlns');

    my $namespace_prefix = '';
    if ( $namespace ) {
        # xhtml
        $xc->registerNs('x', $namespace);
        $namespace_prefix = 'x:';
    } 


    # read css from <style>
    for my $stylenode ($doc->getElementsByTagName('style')) {
        my $css = CSS::Tiny->read_string($stylenode->textContent);
        $self->_apply_css($css, $doc, $xc, $namespace_prefix);
    }

    # read css from <link rel="stylesheet" href="/css/foo.css" />
    my @linknodes = $xc->findnodes('//' . $namespace_prefix . 'link[@rel="stylesheet"]');
    for my $linknode (@linknodes) {
        my $href = $linknode->getAttribute('href') or next;

        # read css
        my $css;
        if ($href =~ m{^https?://}) {
            require LWP::UserAgent;
            my $ua = $self->{user_agent} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
            my $res = $ua->get($href);
            if ($res->is_success) {
                $css = CSS::Tiny->read_string($res->content) or croak "Can't parse '$href' by @{[ __PACKAGE__ ]}";
            } else {
                croak "can't get $href";
            }
        } else {
            my $cssfile = File::Spec->catfile(
                $self->{base_dir}, $href
            );
            $cssfile =~ s/\?.+//g; # remove query string. e.g. /css/mobile.css?d=20070807
            $css = CSS::Tiny->read($cssfile) or croak "Can't open '$cssfile' by @{[ __PACKAGE__ ]}";
        }
        
        $self->_apply_css($css, $doc, $xc, $namespace_prefix);
    }

    $content = $doc->toString();

    # unescape Numeric character reference.
    $content =~ s/HTMLCSSINLINERESCAPE(\d+)::::::::/&#$1;/g;

    return $content;
}

sub _apply_css {
    my ($self, $css, $doc, $xc, $namespace_prefix) = @_;

    # iCSS can use a:link, a:focus, a:visited at <style>
    my @pseudo_selectors = grep /a:(link|focus|visited)/, keys %$css;
    if (@pseudo_selectors) {
        my $style_style = bless { map { $_ => $css->{$_} } @pseudo_selectors }, 'CSS::Tiny';

        my $style = $doc->createElement('style');
        $style->appendText($style_style->write_string);
        $style->setAttribute('type' => 'text/css');

        my ($head,) = $doc->getElementsByTagName('head') or croak "Can't find head";
        $head->appendChild($style);

        delete $css->{$_} for @pseudo_selectors;
    }

    # apply inline css
    for my $style ( $css->styles ) {
        my $xpath = selector_to_xpath($style->selector);
        $xpath =~ s|^//|//$namespace_prefix|;
        for my $element ( $xc->findnodes( $xpath ) ) {
            my $style_attr = $element->getAttribute('style');
            $style_attr = (!$style_attr) ? $style->stringify : (join ";", ($style_attr, $style->stringify));
            $element->setAttribute('style', $style_attr);
        }
    }
}


1;
__END__

=head1 NAME

HTML::DoCoMoCSS - css inliner

=head1 SYNOPSIS

  # src
  use HTML::DoCoMoCSS;
  my $inliner = HTML::DoCoMoCSS->new(base_dir => '/path/to/documentroot/');
  $inliner->apply(<<'...');
  <html>
  <head>
    <link rel="stylesheet" href="/css/foo.css" />
  </head>
  <body>
    <div class="title">bar</div>
  </body>
  </html>
  ...

  # foo.css
  .title {
    color: red;
  }
  
  # result
  <html>
  <head>
    <link rel="stylesheet" href="/css/foo.css" />
  </head>
  <body>
    <div class="title" style="color: red;">bar</div>
  </body>
  </html>

=head1 DESCRIPTION

HTML::DoCoMoCSS is css in-liner.

DoCoMo(Japanese cell-phone carrier)'s UA cannot use <link rel="stylesheet" />
style css, only can use in-line CSS.

That calls iCSS.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom+cpan@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CSS::Tiny>, L<CSS::Tiny::Style>, L<XML::LibXML>,
L<http://www.nttdocomo.co.jp/service/imode/make/content/xhtml/outline/s1.html#1_1_1>(Japanese)

=cut
