package HTML::WidgetValidator::Widget::CubeThrowinGame;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('CUBE Throw-in Game');
__PACKAGE__->url('http://blog.nissan.co.jp/CUBE/CREATES/2006/03/100orange_2.shtml#seal2');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => "http://www.nissan.co.jp/CUBE/PARTS/throw_in/throw.js",
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

HTML::WidgetValidator::Widget::CubeThrowinGame

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'CubeThrowinGame' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "CUBE Throw-in Game"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://blog.nissan.co.jp/CUBE/CREATES/2006/03/100orange_2.shtml#seal2>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
