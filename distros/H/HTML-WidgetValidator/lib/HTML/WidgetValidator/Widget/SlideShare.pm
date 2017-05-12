package HTML::WidgetValidator::Widget::SlideShare;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('SlideShare');
__PACKAGE__->url('http://www.slideshare.net/');
__PACKAGE__->models([
   [
      {
         "name" => "object",
         "type" => "start",
         "attr" => {
            "width" => qr{\d+},
            "data" => qr{http://s3\.amazonaws\.com/slideshare/ssplayer\.swf\?id=\d+&doc=[a-z0-9-]+},
            "type" => "application/x-shockwave-flash",
            "height" => qr{\d+}
         }
      },
      {
         "name" => "param",
         "type" => "start",
         "attr" => {
            "value" => qr{http://s3\.amazonaws\.com/slideshare/ssplayer\.swf\?id=\d+&doc=[a-z0-9-]+},
            "name" => "movie"
         }
      },
      {
         "name" => "param",
         "type" => "end"
      },
      {
         "name" => "object",
         "type" => "end"
      }
   ]
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::SlideShare

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'SlideShare' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "SlideShare"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.slideshare.net/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
