package Hatena::Keyword::Similar;
use warnings;
use strict;
use base qw 'Hatena::Keyword';

our $VERSION = 0.01;

use Carp;
use RPC::XML;

sub similar {
    my $class = shift;
    @_ or croak sprintf 'usage %s->similar(@words)', $class;
    my $res = $class->_call_rpc_with_cache(@_);
    my @similar = map { $class->SUPER::new({ word => $_->{word}->value }) } @{$res->{wordlist}};
    return wantarray ? @similar : \@similar;
}

sub _call_rpc_with_cache {
    my $class = shift;
    my $args = ref $_[-1] eq 'HASH' ? pop : {};
    my @words = map {pack('C0A*', $_) }@_ ; # hacking for utf-8 flag
    my $cache = delete $args->{cache};
    return $class->_call_rpc(@words) unless ref ($cache);
    croak "cache object must have get and set method."
        if not $cache->can('get') or not $cache->can('set');
    require Digest::MD5;
    require Storable;
    my $key = sprintf('%s', Digest::MD5::md5_hex(@words));
    my $res = Storable::thaw($cache->get($key));
    unless (defined $res) {
        $res = $class->_call_rpc(@words)
            or return $class->error($class->errstr);
        $cache->set($key => Storable::freeze($res));
    }
    $res;
}

sub _call_rpc {
    my $class = shift;
    my $res = $class->rpc_client->send_request(
        RPC::XML::request->new('hatena.getSimilarWord', {
            wordlist => RPC::XML::array->new(
                map { RPC::XML::string->new($_)  } @_,
            ),
        }),
    );
    return ref $res ? $res : $class->error(qq/RPC Error: "$res"/);
}

1;

=head1 NAME

Hatena::Keyword::Similar - Retrieve similarity Hatena Keywords.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Hatena::Keyword::Similar;

    @keywords = Hatena::Keyword::Similar->similar(qw(Perl Ruby Python));
    print $_ for @keywords;

    my $cache = Cache::File->new(
        cache_root      => '/path/to/cache',
        default_expires => '3600 sec',
    );
    $keywords = Hatena::Keyword::Similar->similar(qw(Perl Ruby),  {
        cache => $cache,
    });
    print $_->jcode->euc for @$keywords;

=head1 DESCRIPTION

This module allows you to retrieve Hatena keywords similar to given
words with Web API.

A Hatena keyword is an element in a suite of web sites *.hatena.ne.jp
having blogs and social bookmarks among others. Please refer to
http://d.hatena.ne.jp/keyword/ (in Japanese) for details.

It queries Hatena Keyword Similarity API internally for retrieving
terms.

=head1 CLASS METHODS

=head2 similar(@words, \%options)

Returns an array or an array reference which contains Hatena::Keyword
objects similar to given words as argument.

This method works correctly for Japanese characters but their encoding
must be utf-8. And also returned words are encoded as utf-8 string.

Last argument is a optional. It can be contained a cache object, same
as L<Hatena::Keyword>.

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hatena-keyword-similar at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hatena-Keyword-Similar>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hatena::Keyword::Similar

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hatena-Keyword-Similar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hatena-Keyword-Similar>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hatena-Keyword-Similar>

=item * Search CPAN

L<http://search.cpan.org/dist/Hatena-Keyword-Similar>

=back

=head1 SEE ALSO

=over 4

=item L<Hatena::Keyword>

=item Hatena Keyword Similarity API L<http://tinyurl.com/qjh84> (redirect to d.hatena.ne.jp)

=item Hatena Diary L<http://d.hatena.ne.jp/>

=item Hatena L<http://www.hatena.ne.jp/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

