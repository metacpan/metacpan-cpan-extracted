package HTML::WidgetValidator::Widget::ChonmageKacho;
use strict;
use warnings;
use base qw(HTML::WidgetValidator::Widget);

our $VERSION = '0.01';

__PACKAGE__->name('Chonmage Kacho');
__PACKAGE__->url('http://chonmage.netcinema.tv/download/');
__PACKAGE__->models([
   [
      {
         "name" => "script",
         "type" => "start",
         "attr" => {
            "language" => "JavaScript",
            "src" => qr|http://chonmage\.netcinema\.tv/blog/\d+\.js|,
            "charset" => "Shift_JIS"
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

HTML::WidgetValidator::Widget::ChonmageKacho

=head1 SYNOPSIS

  my $validator = HTML::WidgetValidator->new(widgets => [ 'ChonmageKacho' ]);
  my $result = $validator->validate($html);

=head1 DESCRIPTION

Validate widget "Chonmage Kacho"

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://chonmage.netcinema.tv/download/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See perlartistic.

=cut
