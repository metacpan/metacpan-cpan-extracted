package HTML::WidgetValidator::Widget::UranaiParts;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Uranai Parts');
__PACKAGE__->url('http://www.pixmax.jp/uranai_parts/index.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "JavaScript",
            "src" => "http://www.pixmax.jp/uranai_parts/BlogNavigator.js"
         }
      },
      {
         "name" => "script",
         "type" => "end"
      }
   ],
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "JavaScript"
         }
      },
      {
          "text" => qr{writeBlogNavigator\("vippix","[a-z]+"\)},
          "type" => "text"
      },
      {
         "name" => "script",
         "type" => "end"
      }
   ],
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::UranaiParts

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'UranaiParts' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "UranaiParts"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.pixmax.jp/uranai_parts/index.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
