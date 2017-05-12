package HTML::WidgetValidator::Widget::AboutMe;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.02';

__PACKAGE__->name('About Me');
__PACKAGE__->url('http://aboutme.jp/');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "JavaScript",
            "src"      => qr{http://p\.aboutme\.jp/p/qjs/\d+/\d+\.js},
            "charset"  => "utf-8",
            "type"     => "text/javascript"
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
            "language" => "JavaScript",
            "type"     => "text/javascript"
         }
      },
      {
         "text" => qr{\s*var\s*AbUnum='[a-zA-Z0-9]{40}';},
         "type" => "text"
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
            "language" => "JavaScript",
            "src"      => "http://p.aboutme.jp/p/js/blogp.js",
            "type"     => "text/javascript"
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

HTML::WidgetValidator::Widget::AboutMe

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'AboutMe' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "About Me"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://aboutme.jp/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
