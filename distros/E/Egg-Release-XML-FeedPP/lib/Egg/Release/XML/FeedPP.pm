package Egg::Release::XML::FeedPP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FeedPP.pm 211 2007-11-03 14:41:11Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Egg::Release::XML::FeedPP - XML::FeedPP module kit for Egg.

=head1 DESCRIPTION

When RSS Feed is treated, XML::FeedPP is very convenient.

MODEL and VIEW to use the XML::FeedPP were enclosed.

=head1 EXAMPLE

Mounting Model arrives and the method of XML::FeedPP is called with AUTOLOAD easily.

Therefore, it is recommended to receive the XML::FeedPP object by the feed method,
and to operate it directly.

  my $feed= $e->model('FeedPP')->feed('http://domain.name/index.rdf');
  
  ....

Please see the document of L<XML::FeedPP> in detail.

see L<Egg::Model::FeedPP>.

=head2 VIEW

Mounting VIEW is a little tactful from MODEL.

After content_type and charset are set, the content trained to XML::FeedPP is output.

The character-code should be likely to be converted.
You will use the Encode plug-in for it.

  my $feed= $e->default_view('FeedPP')->feed;
  $feed->title('MY BLOG');
  $feed->link('http://myblog.domain.name/');
  for my $item (@items) {
  	$feed->add_item( $item->{url},
  	  title       => $e->utf8_conv(\$item->{title}),
  	  description => $e->utf8_conv(\$item->{description}),
  	  );
  }
  # The output is left to Egg.

see L<Egg::View::FeedPP>.

=head1 SEE ALSO

L<Egg::Model::FeedPP>,
L<Egg::View::FeedPP>,
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
