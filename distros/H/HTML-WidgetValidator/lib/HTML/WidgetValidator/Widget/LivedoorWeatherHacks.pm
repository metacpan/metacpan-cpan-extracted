package HTML::WidgetValidator::Widget::LivedoorWeatherHacks;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('livedoor Weather Hacks');
__PACKAGE__->url('http://weather.livedoor.com/weather_hacks/plugin.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "javascript",
            "src" => qr{http://weather\.livedoor\.com/plugin/common/forecast/[a-z0-9]{2}\.js},
            "type" => "text/javascript",
            "charset" => "euc-jp"
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

HTML::WidgetValidator::Widget::LivedoorWeatherHacks

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'LivedoorWeatherHacks' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "livedoor Weather Hacks"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://weather.livedoor.com/weather_hacks/plugin.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
