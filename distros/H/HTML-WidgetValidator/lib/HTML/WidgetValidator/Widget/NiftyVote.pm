package HTML::WidgetValidator::Widget::NiftyVote;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;

__PACKAGE__->name('NiftyVote');
__PACKAGE__->url('http://vote.nifty.com/');
__PACKAGE__->models([
    [ { type => 'start', name => 'script',
    attr => {
        type     => 'text/javascript',
        charset  => 'utf8',
        src      => qr{http://files\.vote\.nifty\.com/individual/\d+/\d+/vote(?:_sidebar)?\.js},
    }},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::NiftyVote


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'NiftyVote' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "Nifty Vote".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://vote.nifty.com/>


=head1 AUTHOR

Taro Minowa  C<< <higepon@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
