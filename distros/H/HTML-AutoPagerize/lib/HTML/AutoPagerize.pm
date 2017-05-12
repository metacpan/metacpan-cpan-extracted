package HTML::AutoPagerize;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use Carp;
use HTML::TreeBuilder::XPath;
use URI;

sub new {
    my $class = shift;
    bless { sites => [] }, $class;
}

sub sites {
    my $self = shift;
    $self->{sites} = shift if @_;
    $self->{sites};
}

sub sorted_sites {
    my $self = shift;
    return [ sort { length $b->{url} <=> length $a->{url} } @{ $self->sites } ];
}

sub add_site {
    my($self, %site) = @_;

    for my $key (qw( url nextLink )) {
        unless (defined $site{$key}) {
            croak "key '$key' needed for SITEINFO";
        }
    }

    $site{url} = qr/$site{url}/; # compile the regexp
    push @{$self->{sites}}, \%site;
}

sub handle {
    my($self, $uri, $html) = @_;

    my $siteinfo = $self->site_info_for($uri) or return;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($html);

    my $res;

    my $next_link = $siteinfo->{nextLink};
    if (my $nodes = $tree->findnodes($next_link)) {
        $res->{next_link} = URI->new_abs($nodes->shift->attr('href'), $uri);
    }

    if (my $page_element = $siteinfo->{pageElement}) {
        if (my $nodes = $tree->findnodes($page_element)) {
            $res->{page_element} = $nodes;
        }
    }

    return $res;
}

sub site_info_for {
    my($self, $uri) = @_;

    for my $site (@{ $self->sorted_sites }) {
        if ($uri =~ $site->{url}) {
            return $site;
        }
    }

    return;
}

1;
__END__

=for stopwords AutoPagerize SITEINFO userscript

=head1 NAME

HTML::AutoPagerize - Utility to load AutoPagerize SITEINFO stuff

=head1 SYNOPSIS

  use HTML::AutoPagerize;

  my $autopager = HTML::AutoPagerize->new;
  $autopager->add_site(
      url         => 'http://.+.tumblr.com/',
      nextLink    => '//div[@id="content" or @id="container"]/div[last()]/a[last()]',
      pageElement => '//div[@id="content" or @id="container"]/div[@class!="footer" or @class!="navigation"]',
  );

  my $uri  = 'http://otsune.tumblr.com/';
  my $html = LWP::Simple::get($uri);

  my $res = $autopager->handle($uri, $html);
  if ($res) {
      my $next_link = $res->{next_link};    # URI object
      my $content   = $res->{page_element}; # XML::XPathEngine::NodeSet object. may be empty
  }

=head1 DESCRIPTION

HTML::AutoPagerize is an utility module to load SITEINFO defined in
AutoPagerize. AutoPagerize is an userscript to automatically figure
out the L<next link> of the current page, then fetch the content and
insert the content by extracting the L<page element>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Mechanize::AutoPager>, L<http://swdyh.infogami.com/autopagerize>

=cut
