package Egg::Model::FeedPP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FeedPP.pm 187 2007-08-07 19:00:30Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;
use base qw/Egg::Model/;
use XML::FeedPP;

our $VERSION = '0.01';


=head1 NAME

Egg::Model::FeedPP - XML::FeedPP for Egg::Model.

=head1 SYNOPSIS

configuration.

  ...
  MODEL=> [
    .....
    [ FeedPP=> {} ],
    ],

example code.

  my $param= $view->params;
  my $feed = $e->model('FeedPP')->feed('http://mydomain.name/index.rdf');
  $param->{rss_title}= $feed->title;
  $param->{rss_link} = $feed->link;
  my @items;
  for $item ($feed->get_item) {
    push @items, {
      title=> $item->title,
      link => $item->link,
      date => $item->pubDate,
      };
  }
  $param->{rss_items}= \@items;

=head1 DESCRIPTION

It is a module to use XML::FeedPP with MODEL.

The XML::FeedPP object will be usually received by the feed method, and you
operate the object directly though you do the method of XML::FeedPP with
AUTOLOAD in bind.

* Functions other than relaying XML::FeedPP are not provided now.

=head1 CONFIGURATION

'FeedPP' is added to the setting of MODEL.

  MODEL => [
    [ FeedPP => {} ],
    ],

* There is no set item of the option now.

=head1 METHODS

=cut

our $AUTOLOAD;

=head2 feed ( [SOURCE] )

L<XML::FeedPP> object is returned.

SOURCE is an argument passed to the constructor of XML::FeedPP.

  my $feed= $e->model('FeedPP')->feed('http://domain.name/index.rss');

* Please see the document of L<XML::FeedPP> in detail.

=cut
sub feed {
	my $model = shift;
	my $source= shift || croak q{ I want source. };
	$model->{feed}= XML::FeedPP->new($source);
}
sub AUTOLOAD {
	my $model= shift;
	$model->{feed} || croak q{ feed is not prepared. };
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub { shift->{feed}->$method(@_) };
	$model->$method(@_);
}
sub DESTROY { }

=head1 SEE ALSO

L<XML::FeedPP>,
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
