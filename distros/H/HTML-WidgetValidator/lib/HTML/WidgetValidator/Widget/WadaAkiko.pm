package HTML::WidgetValidator::Widget::WadaAkiko;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Wada Akiko');
__PACKAGE__->url('http://www.akofc.com/index_new36.html');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "JavaScript",
            "src" => "http://www.cyberclone.jp/parts/ako160/ako.js",
            "charset" => "UTF-8",
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

HTML::WidgetValidator::Widget::WadaAkiko

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'WadaAkiko' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Wada Akiko"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.akofc.com/index_new36.html>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
