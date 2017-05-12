package Egg::View::FeedPP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FeedPP.pm 187 2007-08-07 19:00:30Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;
use UNIVERSAL::require;
use base qw/Egg::View/;
use XML::FeedPP;

our $VERSION = '0.01';

=head1 NAME

Egg::View::FeedPP - XML::FeedPP for Egg::View.

=head1 SYNOPSIS

configuration.

  ...
  VIEW=> [
    [ FeedPP=> {
      content_type => 'application/rss+xml',
      charset      => 'UTF-8',
      } ],
    ],

example code.

  my $view= $e->view('FeedPP');
  my $feed= $view->feed;
  $feed->title('MY BLOG');
  $feed->link('http://myblog.domain.name/');
  for my $item (@items) {
  	$feed->add_item( $item->{url},
  	  title       => $item->{title},
  	  description => $item->{description},
  	  );
  }
  print $view->render;

=head1 DESCRIPTION

It is a module to use XML::FeedPP with VIEW.

I think that you should operate the XML::FeedPP object directly from the
feed method though some methods of XML::FeedPP do bind.

It has the function to cache feeding that XML::FeedPP generated.
* Egg::Plugin::Cache is used.

=head1 CONFIGURATION

'FeedPP' is added to the setting of VIEW.

  VIEW=> [ [ FeedPP=> { ... option ... } ] ],

=head2 content_type

Contents type when outputting it.

Default is 'application/rss+xml'.

=head2 charset

Character set when outputting it.

Default is 'UTF-8'.

=head2 cache_name

If the cash function is used, the cash name to use Egg::Plugin::Cache is set.

* Even if cash is used, it is not indispensable because the thing specified
  when the cash function is called can be done.

see L<Egg::Plugin::Cache>.

=head1 METHODS

=cut

__PACKAGE__->mk_accessors(qw/content_type charset/);

{
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	for my $accessor (qw/title pubDate link add_item merge
	  remove_item clear_item sort_item uniq_item limit_item normalize/) {
		*{__PACKAGE__."::$accessor"}= sub { shift->feed->$accessor(@_) };
	}
	*item= \&add_item;
  };

sub _setup {
	my($class, $e, $conf)= @_;
	$conf->{content_type} ||= 'application/rss+xml';
	$conf->{charset}      ||= 'UTF-8';
}

=head2 new

The object of this View is returned.

  my $view= $e->view('FeedPP');

=cut
sub new {
	my $view= shift->SUPER::new(@_);
	$view->{content_type}= $view->config->{content_type};
	$view->{charset}     = $view->config->{charset};
	$view;
}

=head2 cache ( [CACHE_KEY] or [CACHE_NAME], [CACHE_KEY] {, [EXPIRES] } )

The cash function is made effective.

* Thing that can be used by Egg::Plugin::Cache's being appropriately set.

CACHE_KEY is only passed if 'cache_name' is set with CONFIGURATION.

When CACHE_NAME is passed, the cash is used.
* It gives priority more than set of 'cache_name'.

EXPIRES is validity term to pass it to the set method when L<Cache::Memcached>
is used with L<Egg::Plugin::Cache>.
* It is not necessary usually.

  my $expr= 60* 60; # one hour.
  my $view= $e->view('FeedPP');
  unless ($view->cache('CACHE_NAME', 'CACHE_KEY', $expr)) {
    #
    # RSS feed generation code.
    #
    my $feed= $view->feed;
    $feed->title('MYBLOG');
    ....
    .... 
    # ----------------
  }

* 'RSS feed generation code' part from the unless sentence though the image
  might not be  gripped easily for a moment You only have to move as usual
  even if it removes.

Anything need not be done excluding this.
If cash becomes a hit, the content of cash is output with output.

=cut
sub cache {
	my $view= shift;
	my $name= shift || croak q{ I want cache name. };
	my $ckey= shift || do {
		my $tmp= $name;
		$name= $view->config->{cache_name}
		     || croak q{ I want setup 'cache_name'. };
		$tmp;
	  };
	$view->{cache}= { name=> $name, key=> $ckey, expir=> (shift || undef) };
	$view->{cache}{hit}= $view->e->cache($name)->get($ckey) ? 1: 0;
}

=head2 feed_type ( [FEED_TYPE] )

The type of the generation feeding to use it by the feed method is returned.

The value that can be specified for FEED_TYPE is rss, rdf, and atom.

FEED_TYPE returns and 'RSS' always returns when it is not given or wrong
specification is done.

  # Example of generating key to cash with value obtained from URI.
  # example uri = http://domain/xml/hoge/rdf
  #
  my $feed_type= $view->feed_type( $e->snip->[2] );
  $view->cache('FileCache', "xml_hoge_${feed_type}") || do {
    my $feed= $view->feed($feed_type);
    .....
    ...
    };

=cut
sub feed_type {
	my $view= shift;
	{ rss=> 'RSS', rdf=> 'RDF', atom=> 'Atom' }->{lc(shift)} || 'RSS';
}

=head2 feed ( [FEED_TYPE] )

The XML::FeedPP object is returned.

When FEED_TYPE is specified, the corresponding module is read.

If FEED_TYPE unspecifies it, 'RSS' is processed to have specified it.

  my $feed= $view->feed('Atom');

see L<XML::FeedPP>.

=cut
sub feed {
	$_[0]->{feed} ||= do {
		my $view= shift;
		my $pkg = "XML::FeedPP::". $view->feed_type(shift);
		$view->e->debug_out("# + view-FeedPP : $pkg" );
		$pkg->new(@_);
	  };
}

=head2 reset

The XML::FeedPP context set in View is erased.

=cut
sub reset { undef($_[0]->{feed}) if $_[0]->{feed} }

=head2 render

To_string of XML::FeedPP is called and feeding is generated.

If cash is effective, the content of cash is returned.

  my $feed_text= $view->render($feed);

=cut
sub render {
	my $view= shift;
	if (my $cc= $view->{cache}) {
		my $cache= $view->e->cache($cc->{name});
		$cc->{hit} ? $cache->get($cc->{key}): do {
			$view->e->debug_out("# + view-FeedPP cache hit : No." );
			my $feed= shift || $view->feed(@_);
			my $body= $feed->to_string($view->{charset});
			$cache->set($cc->{key}, $body, $cc->{expir});
			$body;
		  };
	} else {
		my $feed= shift || $view->feed(@_);
		$feed->to_string($view->{charset});
	}
}

=head2 output

The result of the render method is received, and set contents type and 
contents body are set in L<Egg::Response>.

  $view->output($feed);

* It is not necessary to call it from the project code because it is called
  by the operation of Egg usually.

=cut
sub output {
	my $view= shift;
	my $feed= shift || $view->feed;
	$view->e->response->content_type
	  ("$view->{content_type}; charset=$view->{charset}");
	my $body= $view->render($feed, @_);
	$view->e->response->body(\$body);
}

=head1 BINDING METHODS

Tentatively, Messod of following XML::FeedPP that seems to be necessary for
the feeding generation it is done and bind is done to this View.

=over 4

=item * item, title, pubDate, link, add_item, merge, remove_item, clear_item, sort_item, uniq_item, limit_item, normalize

=back

=head1 SEE ALSO

L<XML::FeedPP>,
L<Egg::Plugin::Cache>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
