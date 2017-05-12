package HTML::WidgetValidator::Widget::Harbot;
use base qw(HTML::WidgetValidator::Widget);
use strict;
use warnings;

__PACKAGE__->name('Harbot');
__PACKAGE__->url('http://gate-harbot.so-net.ne.jp/gate/index.html');
__PACKAGE__->models([
    [
	{ type => 'start', name => 'script',
	  attr => {
	      language => 'JavaScript',
	      src      => qr{http://harbox-harbot[.]so-net[.]ne.jp/h[.]jsp[?]hbxid=\d+},
	  }},
	{ type => 'end', name=>'script' }
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::Harbot


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'Harbot' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate "Harbot" Harbox.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://gate-harbot.so-net.ne.jp/gate/index.html>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
