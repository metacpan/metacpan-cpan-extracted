package HTML::WidgetValidator::Widget::PostPet;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('PostPet');
__PACKAGE__->url('http://www.postpet.so-net.ne.jp/webmail/blog/');
__PACKAGE__->models([
    [ { type => 'start', name => 'script', 
	attr => {
	    language => 'JavaScript',
	    type     => 'text/javascript',
	    src      => 'http://www.so-net.ne.jp/ad/pp-uranai/postpet.js',
	}},
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name => 'script', 
	attr => {
	    type     => 'text/javascript',
	    src      => qr{http://www\.postpet\.so-net\.ne\.jp/webmail/blog/clock_v[12]_[a-z]+\.js},
	}},
      { type => 'end', name=>'script' } ],
    [ { type => 'start', name => 'script', 
	attr => {
	    language => 'javascript',
	    type     => 'text/javascript',
	    src      => qr{http://ppwin\.so\-net\.ne\.jp/webmail/petwindow/script\.do\?window_id=[0-9a-fA-F]+},
	}},
      { type => 'end', name=>'script' } ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::PostPet


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'PostPet' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate widget "PostPet".


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.postpet.so-net.ne.jp/webmail/blog/>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
