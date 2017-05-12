package HTML::WidgetValidator::Widget::Wassr;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Wassr');
__PACKAGE__->url('http://wassr.jp/');
__PACKAGE__->models([
   [
      {
         "text" => "<script type=\"text/javascript\" src=\"http://wassr.jp/js/WassrBlogParts.js\">",
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => "http://wassr.jp/js/WassrBlogParts.js",
            "type" => "text/javascript"
         }
      },
      {
         "text" => "</script>",
         "name" => "script",
         "type" => "end"
      }
   ],
   [
      {
         "text" => "<script type=\"text/javascript\">",
         "name" => "script",
         "type" => "start",
         "attr" => {
            "type" => "text/javascript"
         }
      },
      {
         "text" => qr{\s*(?:wassr_host\s*=\s*"wassr\.jp";\s*|\s*wassr_userid\s*=\s*"\w+";\s*|\s*wassr_defaultview\s*=\s*"(?:user|friends|public|)";\s*|\s*wassr_bgcolor\s*=\s*"(?:[0-9A-Fa-f]{6}|)";\s*|\s*wassr_titlecolor\s*=\s*"(?:[0-9A-Fa-f]{6}|)";\s*|\s*wassr_textcolor\s*=\s*"(?:[0-9A-Fa-f]{6}|)";\s*|\s*wassr_boxcolor\s*=\s*"(?:[0-9A-Fa-f]{6}|)";\s*|WassrFlashBlogParts\(\);\s*)+\s*},
         "type" => "text"
      },
      {
         "text" => "</script>",
         "name" => "script",
         "type" => "end"
      }
   ]
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::Wassr

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'Wassr' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Wassr"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://wassr.jp/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
