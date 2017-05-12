#
# $Id: libXML.pm,v 0.2 2009/02/21 11:47:58 dankogai Exp dankogai $
#
package HTML::Tidy::libXML;
use warnings;
use strict;
use Encode;
use XML::LibXML;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;

sub new {
    my $class = shift;
    my $lx    = XML::LibXML->new;
    $lx->validation(0);
    $lx->recover_silently(1);
    bless { lx => $lx }, $class;
}

sub html2dom {
    my ( $self, $html, $encoding ) = @_;
    $encoding ||= 'iso-8859-1';
    $html =~ s/\r\n?/\n/msg;               # normalize CRLF to LF
    $html = decode( $encoding, $html );    # leave the utf8 flag
    $self->{lx}->parse_html_string($html);
}

sub dom2xml {
    my ($self, $dom, $level) = @_;
    my $root = $dom->findnodes('/html')->shift;
    $root->setAttribute( xmlns => 'http://www.w3.org/1999/xhtml' );
    for my $meta ( $dom->findnodes('//meta[@http-equiv!=""]') ) {
        $meta->setAttribute( content => 'text/html; charset=utf-8' );
    }
    _tidy_dom($dom) if  $level > 0;
    my $xhtml = $root->toString( 0, 'utf-8' );    # utf8 flag off
    return <<EOT;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
$xhtml
EOT
}

sub html2xml {
    my ( $self, $html, $encoding, $level ) = @_;
    my $dom = $self->html2dom( $html, $encoding );
    $self->dom2xml($dom, $level);
}

sub _tidy_dom {
    my $dom = shift;
    # remove empty attributes (like <br clear="">)
    for my $node ( $dom->findnodes('//*[attribute::*=""]') ) {
        for my $attr ( $node->attributes ) {
            next if $attr->getValue;
            $node->removeAttribute( $attr->getName );
        }
    }
    # handle <script>
    for my $script ( $dom->findnodes('//script') ) {
        $script->getAttribute('type')
          or $script->setAttribute( type => "text/javascript" );
        if ( $script->hasChildNodes ) {
            $script->insertBefore( $dom->createTextNode("//"),
                $script->firstChild );
            $script->lastChild->appendData("\n//");
        }
        else { # <script src="..."/> => <script src=""></script>
            $script->appendChild( $dom->createTextNode("") );
        }
    }
    # handle <style>
    for my $style ( $dom->findnodes('//style') ) {
        $style->getAttribute('type')
          or $style->setAttribute( type => "text/css" );
        if ( $style->hasChildNodes ) {    # this one is trickier
            $style->insertBefore( $dom->createTextNode("/*"),
                $style->firstChild );
            $style->lastChild->insertData( 0, "*/" );
            $style->lastChild->appendData("/*");
            $style->appendChild( $dom->createTextNode("*/") );
        }else{
	    $style->appendChild( $dom->createTextNode("") );
	}
    }
    # fix <img>
    for my $img ( $dom->findnodes('//img') ) {
        next if $img->getAttribute('type');
	my $alt = $img->getAttribute('src');
	$alt =~ s{.*/}{}o; # basename only
        $img->setAttribute( alt => $alt || 'img' );
    }
    # <a name="foo"/> => <a name="foo"></a>
    for my $a ( $dom->findnodes('//a[@name!=""]') ) {
        my $empty = $dom->createTextNode("");
        $a->appendChild($empty);
    }
}

{
    no warnings 'once';
    *clean = \&html2xml;
}

if ($0 eq __FILE__){
    require LWP::UserAgent;
    require HTTP::Response::Encoding;
    my $uri     = shift || die;
    my $res = LWP::UserAgent->new->get($uri);
    die $res->status_line unless $res->is_success;
    my $html =  __PACKAGE__->new->clean($res->content, $res->encoding, 1);
    print $html;
    #my $xl = XML::LibXML->new;
    #$xl->validation(0);
    #print $xl->parse_string($html)->toString;
    #require XML::Simple;
    #require Data::Dumper;
    #print Data::Dumper::Dumper(XML::Simple::XMLin($html))
}

1; # End of HTML::Tidy::libXML

__END__
=head1 NAME

HTML::Tidy::libXML - Tidy HTML via XML::LibXML

=head1 VERSION

$Id: libXML.pm,v 0.2 2009/02/21 11:47:58 dankogai Exp dankogai $

=head1 SYNOPSIS

  use HTML::Tidy::libXML;
  my $tidy = HTML::Tidy::libXML->new();
  my $xml   = $tidy->clean($html, $encoding);    # clean enough as xml
  my $xhtml = $tidy->clean($html, $encoding, 1); # clean enough for browsers

=head1 EXPORT

none.

=head1 Functions

=head2 new

Creates an object.

  my $tidy = HTML::Tidy::libXML->new();

=head2 html2dom

  my $dom = $tidy->html2dom($string, $encoding);

This is analogus to

  my $lx = XML::LibXML->new;
  $lx->recover_silently(1);
  my $dom = $lx->parse_html_string($string);

Except one major difference.  L<HTML::Tidy::LibXML> does not trust
C<< <meta http-equiv="content-type" content="text/html; charset="foo"> >>
while L<XML::LibXML> tries to use one.  Consider this;

  my $dom = $lx->parse_html_string('http://example.com');

This B<kinda> works since L<XML::LibXML> is capable of fetching
document directly.  But L<XML::LibXML> does not honor HTTP header.
Here is the better practice.

  require LWP::UserAgent;
  require HTTP::Response::Encoding;
  my $uri = shift || die;
  my $res = LWP::UserAgent->new->get($uri);
  die $res->status_line unless $res->is_success;
  my $dom = $tidy->html2dom($res->content, $res->encoding);


=head2 dom2xml

  my $tidy->com2xml($dom, $level);


Tidies C<$dom> which is L<XML::LibXML::Document> object and returns an
XML string.  If the level is ommitted, the resulting XML is good
enough as XML -- valid but not very browser compliant (like C<< <br
clear=""> >>, C<< <a name="here" /> >>).  Set level to 1 or above for
tidier, browser-compliant xhtml.

=head2 html2xml

  my $xml = $tidy->html2xml($html, $encoding, $level)

Which is the shorthand for:

  my $dom = $tidy->html2dom($html, $encoding);
  my $xml = $tidy->dom2xml($dom, $level);

=head2 clean

An alias to C<html2xml>.

=head1 BENCHMARK

This is what happened trying to tidy L<http://www.perl.com/> on my
PowerBook Pro.  See F<t/bench.pl> for details.

                    Rate            H::T H::T::LibXML(1) H::T::LibXML(0)
  H::T            96.2/s              --            -25%            -49%
  H::T::LibXML(1)  128/s             33%              --            -31%
  H::T::LibXML(0)  187/s             95%             46%              --

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-tidy-libxml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Tidy-libXML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Tidy::libXML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Tidy-libXML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Tidy-libXML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Tidy-libXML>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Tidy-libXML/>

=back


=head1 ACKNOWLEDGEMENTS

L<HTML::Tidy>, L<XML::LibXML>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
