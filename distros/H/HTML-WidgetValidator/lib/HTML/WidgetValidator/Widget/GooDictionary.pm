package HTML::WidgetValidator::Widget::GooDictionary;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Goo Dictionary');
__PACKAGE__->url('http://dictionary.goo.ne.jp/blog_parts.html');
__PACKAGE__->models([
    [ { type => 'start', name => 'script', 
	attr => {
	    charset => 'euc-jp',
	    src     => qr{http:\/\/dictionary\.goo\.ne\.jp\/dictionary\/blog_parts\/js\/blog_search_[a-z]{4,6}\.js},
	}},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::GooDictionary


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'GooDictionary' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Goo Dictionary".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://dictionary.goo.ne.jp/blog_parts.html>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

