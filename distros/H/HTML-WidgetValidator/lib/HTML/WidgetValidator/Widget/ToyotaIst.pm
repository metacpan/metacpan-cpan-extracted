package HTML::WidgetValidator::Widget::ToyotaIst;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->name('Toyota IST');
__PACKAGE__->url('http://ist.blogdeco.jp/');
__PACKAGE__->models([
    [
        {
            type => 'start',
            name => 'script',
            attr => {
                src     => qr|http://ist\.blogdeco\.jp/js/istbp\.js\?id=\d{13}&color=[a-z]+|,
                charset => 'utf-8',
                type    => 'text/javascript',
            },
        },
        { type => 'end', name => 'script' },
    ],
    [
        { type => 'start', name => 'noscript' },
        {
            type => 'start',
            name => 'a',
            attr => {
                href   => 'http://www.blogdeco.jp/',
                target => '_blank',
            },
        },
        {
            type => 'start',
            name=>'img',
            attr => {
                src    => 'http://www.blogdeco.jp/img/jsWarning.gif',
                width  => '140',
                height => '140',
                border => '0',
                alt    => 'Blogdeco',
            },
        },
        { type => 'end', name=>'img' },
        { type => 'end', name=>'a' },
        { type => 'end', name=>'noscript' },
    ],
]);

1;

__END__

=head1 NAME

HTML::WidgetValidator::Widget::ToyotaIst

=head1 SYNOPSIS

  my $validateor = HTML::WidgetValidator->new(widgets => [ 'ToyotaIst' ]);
  my $result  = $validateor->validate($html);

=head1 DESCRIPTION

Validate widget "IST" (BlogDeco)

=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://ist.blogdeco.jp/>

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentaro@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
