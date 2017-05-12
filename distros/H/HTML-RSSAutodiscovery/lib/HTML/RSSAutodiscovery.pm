use strict;

package HTML::RSSAutodiscovery;
use base qw (HTML::Parser);

# $Id: RSSAutodiscovery.pm,v 1.5 2004/10/17 04:13:06 asc Exp $

=head1 NAME

HTML::RSSAutodiscovery - methods for retreiving RSS-ish information from an HTML document.

=head1 SYNOPSIS

 use HTML::RSSAutodiscovery;
 use Data::Dumper;

 my $url = "http://www.diveintomark.org/";

 my $html = HTML::RSSAutodiscovery->new();
 print &Dumper($html->parse($url));

 # Mark's gone a bit nuts with this and
 # the list is too long to include here...

 # see the POD for the 'parse' method for
 # details of what it returns.

=head1 DESCRIPTION

Methods for retreiving RSS-ish information from an HTML document.

=cut

use LWP::UserAgent;
use HTTP::Request;
use Carp;

$HTML::RSSAutodiscovery::VERSION   = '1.21';

use constant SYNDIC8_PROXY     => "http://www.syndic8.com/xmlrpc.php";
use constant SYNDIC8_CLASS     => "syndic8";
use constant SYNDIC8_FINDSITES => join(".",SYNDIC8_CLASS,"FindSites");
use constant SYNDIC8_FEEDINFO  => join(".",SYNDIC8_CLASS,"GetFeedInfo");

use constant MIMETYPE_RSS      => "application/rss+xml";

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new()

Object constructor. Returns an object. Woot!

=cut

sub new {
  my $pkg = shift;
  
  my $self = {};
  bless $self,$pkg;
  
  if (! $self->init(@_)) {
    return undef;
  }
  
  return $self;
}

sub init {
  my $self = shift;
  $self->SUPER::init(start_h=> [\&_start,"self,tagname,attr"]);
  return 1;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->parse($arg)

Parse an HTML document and return RSS-ish &lt;link> information.

I<$arg> may be either:

=over 4

=item *

An HTML string, passed as a scalar reference.

=item *

A URI.

=back

Returns an array reference of hash references whose keys are :

=over 4

=item *

I<title>

=item *

I<type>

=item *

I<rel>

=item *

I<href>

=back

=cut

sub parse {
  my $self = shift;
  my $uri  = shift;

  my $data = $uri;

  if (ref($data) ne "SCALAR") {
    $data = $self->_fetch($uri) || return undef;
  }

  $self->{'__embedded'} ||= [];
  $self->{'__links'}    ||= [];

  $self->SUPER::parse($$data);
  return $self->{'__links'};
}

=head2 $obj->locate($uri,\%args)

Like the I<parse> method, but will perform additional lookups, if necessary or specified.

Valid arguments are 

=over 4

=item *

B<uri>

String. A live, breathing URI to slurp and parse.

I<Required>

=item *

Hash ref whose keys may be

=over 4

=item *

B<noparse>

Boolean. Don't bother parsing the document, this will also prevent you 
from checking for embedded links.

I don't know why you want to do this, but you can.

False, by default.

=item *

B<embedded>

Boolean. Check all embedded links ending in '.xml', '.rss' or '.rdf' 
(and then 'xml', 'rss' or 'rdf') for RSS-ness.

False, by default, unless the initial parsing of the URI returns no
RSS links.

=item *

B<embedded_and_remote>

Boolean.

Boolean. Check all embedded links whose root is not the same as I<$uri> 
for RSS-ness.

False, by default.

=item *

B<syndic8>

Boolean. Check the syndic8 servers for sites matching I<$uri>

False, by default, unless the initial parsing of the URI and any embedded links
returns no RSS links.

=back

=back

Returns an array reference of hash references whose keys are :

=over 4

=item *

I<title>

=item *

I<type>

=item *

I<rel>

=item *

I<href>

=back

=cut

sub locate {
  my $self = shift;
  my $uri  = shift;
  my $args = shift;

  $self->{'__embedded'} = [];
  $self->{'__links'}    = [];

  my $parse    = 1;
  my $embedded = 0;
  my $syndic8  = 0;

  if (ref($args) eq "HASH") {
    $parse    = ((defined($args->{noparse}))  && ($args->{noparse}))              ? 0 : 1;
    $embedded = ((defined($args->{embedded})) && ($args->{embedded})) ? 1 : 0;
    $syndic8  = ((defined($args->{syndic8}))  && ($args->{syndic8}))              ? 1 : 0;
  }

  if ($parse) {

    # This is a hack. Do as I say, not as I do
    if ($embedded) {
      $self->{'__check_embedded'} = ($args->{embedded_and_remote}) ? 2 : 1;
    }

    $self->parse($uri);
  }

  if (($parse) && (($embedded) || (scalar(@{$self->{'__links'}}) < 1))) {
    $self->_check_embedded($uri);
  
    if (scalar(@{$self->{'__links'}}) < 1) {
      $self->_check_embedded($uri,{liberal=>1});
    }
  }

  if (($syndic8) || (scalar(@{$self->{'__links'}}) < 1)) {
    $self->_check_syndic8($uri);
  }

  return $self->{'__links'};
}

sub _fetch {
  my $self = shift;
  my $uri  = shift;

  $self->{'__ua'} ||= LWP::UserAgent->new();
  
  my $res = $self->{'__ua'}->request(HTTP::Request->new(GET=>$uri));

  if (! $res->is_success()) {
    return undef;
  }

  return \$res->content();
}

sub _check_embedded {
  my $self = shift;
  my $uri  = shift;
  my $args = shift;

  my $rss = $self->_rss()
    || return 0;

  # How anal...I mean, liberal do I need to be about this?

  my $pattern = $args->{'liberal'} ? "r([dfs]+)" : "\\.r([dfs]+)";
  my @links = grep { $_ =~ /(?:$pattern)$/ } @{$self->{'__embedded'}};

  if (! @links) {
    return 1;
  }

  # We just get this out of the way
  # now in case $link is a relative
  # URL

  unless ($uri =~ /\/$/) { 
    $uri .= "/"; 
  }

  foreach my $link (@links) {

    if (($link =~ /^http/) && ($self->{'__check_embedded'} < 2)) {
      next unless $link =~ /^$uri/;
    }

    elsif ($link =~ /^http/) {
      next if $link =~ m!127.0.0!
    }

    else {
      $link = $uri.$link;
    }

    next if ($self->_linked($link));

    my $data = $self->_fetch($link);

    if (! $data) {
      carp "Failed to fetch '$uri', skipping.\n";
      next;
    }

    eval { $rss->parse($$data); };

    if ($@) {
      # carp "Not RSS, $@\n";
      next;
    }

    next unless (defined($rss->{'_internal'}{'version'}));

    push @{$self->{'__links'}} ,{
				 rel   => "alternate",
				 href  => $uri,
				 title => $rss->{"channel"}{"description"},
				 type  => MIMETYPE_RSS,
				};

  }

  return 1;
}

sub _check_syndic8 {
  my $self = shift;
  my $uri  = shift;

  my $rpc  = $self->_xmlrpc({proxy=>SYNDIC8_PROXY})
    || return 0;

  $uri =~ m!^(?:http://)?(?:www)?([^/]+)(?:/.*)?$!;

  if (! $1) {
    carp "Failed to parse URI '$uri', skipping lookup.\n";
    return 0;
  }

  my $ids  = $rpc->call(SYNDIC8_FINDSITES,$1)->result()
    || return 1;

  my $info = $rpc->call(SYNDIC8_FEEDINFO,$ids)->result()
    || return 1;

  foreach my $site (@$info) {
    next unless ($site->{"fetchable"});
    next unless ($site->{status} eq "Syndicated");

    next if ($self->_linked($site->{"dataurl"}));

    push @{$self->{'__links'}} ,{
				 rel   => "alternate",
				 href  => $site->{"dataurl"},
				 title => $site->{"description"},
				 type  => MIMETYPE_RSS,
				};
  }

  return 1;
}

sub _rss {
  my $self = shift;

  if (ref($self->{'__rss'}) eq "ARRAY") {
    return undef;
  }

  #

  if (! $self->{'__rss'}) {

    eval "require XML::RSS";

    if ($@) {
      carp "Unable to load RSS parser.\n";

      $self->{'__xmlrpc'} = [$@];
      return undef;
    }

    $self->{'__rss'} = XML::RSS->new();
  }

  return $self->{'__rss'};
}

sub _xmlrpc {
  my $self = shift;
  my $args = shift;

  if (ref($self->{'__xmlrpc'}) eq "ARRAY") {
    return undef;
  }

  #

  if ((! $self->{'__xmlrpc'}) ||
      (($args->{'proxy'}) && ($self->{'__xmlrpc'}->proxy() ne $args->{'proxy'}))) {

    eval "require XMLRPC::Lite";

    if ($@) {
      carp "Unable to load XMLRPC class. Syndic8 lookup disabled.\n";

      $self->{'__xmlrpc'} = [$@];
      return undef;
    }

    $self->{'__xmlrpc'} = XMLRPC::Lite->new();
    $self->{'__xmlrpc'}->proxy($args->{'proxy'});
#    $self->{'__xmlrpc'}->on_debug(sub{print@_});
  }

  return $self->{'__xmlrpc'};
}

sub _linked {
  my $self = shift;
  my $uri  = shift;

  if (defined($self->{'__linked'}{$uri})) {
    return $self->{'__linked'}{$uri};
  }

  foreach (@{$self->{'__links'}}) {
    if ($_->{href} eq $uri) {
      $self->{'__linked'}{$uri} = 1;
      return 1;
    }
  }

  $self->{'__linked'}{$uri} = 0;
  return 0;
}

sub _start {
  my $self  = shift;
  my $tag   = shift;
  my $attrs = shift;

  # Anything to check?
  # We may not actually need to check anchors
  # but in the interests of keeping things
  # simple (read-ability) we defer that check
  # for later...

  unless ($tag =~ /^(link|a)$/) {
    return;
  }

  # Check anchors
  # See note re: __check_emebedded in &locate()

  if (($self->{'__check_embedded'}) && ($tag eq "a")) {
    if ($attrs->{'href'} =~ /(?:\.)?r(?:df|ss)$/i) {
      push @{$self->{'__embedded'}} , $attrs->{'href'};
    }

    return;
  }
      
  # Check links
    
  if ((defined($attrs->{'name'})) && 
      ($attrs->{'name'} =~ /^(XML|RSS)$/)) {
      return;
  }

  if ((defined($attrs->{'name'})) &&
      ($attrs->{'type'} ne "application/rss+xml") &&
      ($attrs->{'type'} ne "text/xml")) {

      return;
  }

  delete $attrs->{"/"};
  push @{$self->{'__links'}},$attrs;
}

=head1 VERSION

1.21

=head1 DATE

$Date: 2004/10/17 04:13:06 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

Because you shouldn't need all that white space to do cool stuff ;-)

http://diveintomark.org/archives/2002/05/30.html#rss_autodiscovery

http://diveintomark.org/archives/2002/08/15.html

http://diveintomark.org/projects/misc/rssfinder.py.txt

=head1 REQUIREMENTS

=head2 BASIC

These packages are required to actually parse an HTML document or URI.

=over 4

=item *

B<HTML::Parser>

=item *

B<LWP::UserAgent>

=item *

B<HTTP::Request>

=back

=head2 EMBEDDED

These packages are required to check the embedded links in a URI for RSS files. 
They are not loaded until run-time so they are not required for doing basic parsing

=over 4

=item *

B<XML::RSS>

=back

=head2 SYNDIC8

These packages are required to query the syndic8 servers for RSS files associated with a URI.
They are not loaded until run-time so they are not required for doing basic parsing

=over 4

=item *

B<XMLRPC::Lite>

=back

=head1 LICENSE

Copyright (c) 2002-2004, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

