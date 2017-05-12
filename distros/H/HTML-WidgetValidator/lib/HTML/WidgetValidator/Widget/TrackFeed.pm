package HTML::WidgetValidator::Widget::TrackFeed;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Track Feed');
__PACKAGE__->url('http://trackfeed.com/');
__PACKAGE__->models([
   [
      {
         "name" => "a",
         "type" => "start",
         "attr" => {
            "href" => "http://trackfeed.com/"
         }
      },
      {
         "name" => "img",
         "type" => "start",
         "attr" => {
            "alt" => "track feed",
            "src" => "http://img.trackfeed.com/img/tfg.gif",
            "name" => "trackfeed_banner",
            "border" => "0"
         }
      },
      {
         "name" => "a",
         "type" => "end"
      }
   ],
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => qr|http://script\.trackfeed\.com/usr/[[:alnum:]]{10}\.js|
         }
      },
      {
         "name" => "script",
         "type" => "end"
      }
   ]
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::TrackFeed

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'TrackFeed' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Track Feed"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://trackfeed.com/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
