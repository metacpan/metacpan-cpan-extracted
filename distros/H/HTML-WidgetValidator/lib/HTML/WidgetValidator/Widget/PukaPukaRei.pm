package HTML::WidgetValidator::Widget::PukaPukaRei;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('PukaPukaRei');
__PACKAGE__->url('http://www.evastore.jp/blog_acce.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "src" => qr{http://blogtool.evastore.jp/puka_rei/pukapuka\d+.js},
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

HTML::WidgetValidator::Widget::PukaPukaRei

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'PukaPukaRei' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "PukaPukaRei"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.evastore.jp/blog_acce.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
