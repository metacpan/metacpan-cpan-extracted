package HTML::WidgetValidator::Widget::HrcRaceTimer;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('HRC Race Timer');
__PACKAGE__->url('http://www.honda.co.jp/HRC/fun/blogparts/index.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => "http://www.honda.co.jp/HRC/fun/blogparts/swf/parts.js",
            "type" => "text/javascript"
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

HTML::WidgetValidator::Widget::HRCRaceTimer

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'HRCRaceTimer' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "HRC Race Timer"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.honda.co.jp/HRC/fun/blogparts/index.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
