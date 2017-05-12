package Hatena::Keyword;
use strict;
use warnings;
use base qw(Class::Data::Inheritable Class::Accessor::Fast Class::ErrorHandler);
use overload '""' => \&as_string, fallback => 1;
use Carp;
use URI;
use RPC::XML;
use RPC::XML::Client;

our $VERSION = 0.05;

my @Fields = qw(refcount word score cname);
__PACKAGE__->mk_accessors(@Fields);
__PACKAGE__->mk_classdata(rpc_client => RPC::XML::Client->new(
    URI->new_abs('/xmlrpc', 'http://d.hatena.ne.jp/'),
    useragent => [ agent => join('/', __PACKAGE__, __PACKAGE__->VERSION) ],
));

sub extract {
    my $class = shift;
    my $body = shift or croak sprintf 'usage %s->extract($text)', $class;
    my $args = shift || {};
    $args->{mode} = 'lite';
    my $res = $class->_call_rpc_with_cache($body, $args)
        or $class->error($class->errstr);
    my @keywords = map { $class->_instance_from_rpcdata($_) }@{$res->{wordlist}};
    return wantarray ? @keywords : \@keywords;
}

sub markup_as_html {
    my $class = shift;
    my $body = shift or croak sprintf 'usage %s->markup_as_html($text)', $class;
    my $args = shift || {};
    $args->{mode} = '';
    my $res = $class->_call_rpc_with_cache($body, $args)
        or $class->error($class->errstr);
    return $res->value;
}

sub _call_rpc_with_cache {
    my $class = shift;
    my ($body, $args) = @_;
    $body = pack('C0A*', $body); # hacking for utf-8 flag
    my $cache = delete $args->{cache};
    return $class->_call_rpc($body, $args) unless ref($cache);
    croak "cache object must have get and set method."
        if not $cache->can('get') or not $cache->can('set');

    require Digest::MD5;
    require Storable;
    my $key = sprintf(
        '%s-%s-%s',
        $args->{mode} || '',
        Digest::MD5::md5_hex($body),
        Digest::MD5::md5_hex(Storable::freeze($args)),
    );
    my $res = Storable::thaw($cache->get($key));
    unless (defined $res) {
        $res = $class->_call_rpc($body, $args)
            or return $class->error($class->errstr);
        $cache->set($key =>Storable::freeze($res));
    }
    $res;
}

sub _call_rpc {
    my ($class, $body, $args) = @_;
    my $params = {
        body  => RPC::XML::string->new($body),
        score => RPC::XML::int->new($args->{score} || 0),
        mode  => RPC::XML::string->new($args->{mode} || ''),
        cname => defined $args->{cname} ? RPC::XML::array->new(
            map { RPC::XML::string->new($_) } @{$args->{cname}}
        ) : undef,
        a_target => RPC::XML::string->new($args->{a_target} || ''),
        a_class  => RPC::XML::string->new($args->{a_class} || ''),
    };

    # For all categories, It doesn't need an undefined cname value.
    delete $params->{cname} unless defined $params->{cname};

    my $res = $class->rpc_client->send_request(
        RPC::XML::request->new('hatena.setkeywordlink', $params),
    );
    return ref $res ? $res : $class->error(qq/RPC Error: "$res"/);
}

sub _instance_from_rpcdata {
    my ($class, $data) = @_;
    return $class->new({
        map {$_ => $data->{$_}->value  } @Fields,
    });
}

sub jcode {
    my $self = shift;
    $self->{_jcode} and return $self->{_jcode};
    require Jcode;
    return $self->{_jcode} = Jcode->new($self->as_string, 'utf8');
}

sub as_string { $_[0]->word }

1;

__END__

=head1 NAME

Hatena::Keyword - Extract Hatena Keywords in a string

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Hatena::Keyword;

    @keywords = Hatena::Keyword->extract("Perl and Ruby and Python.");
    print $_->score, "\t", $_ for @keywords;

    $keywords = Hatena::Keyword->extract("Hello, Perl!", {
        score => 20,
        cname => [qw(hatena web book)],
    });
    print $_->refcount, "\t", $_->jcode->euc for @$keywords;

    my $cache = Cache::File->new(
        cache_root      => '/path/to/cache',
        default_expires => '3600 sec',
    );
    $keywords = Hatena::Keyword->extract("Hello, Hatena!",  {
        cache => $cache,
    });

    $html = Hatena::Keyword->markup_as_html("Perl and Ruby");
    $html = Hatena::Keyword->markup_as_html("Hello, Perl!", {
        score    => 20,
        cname    => [qw(hatena web book)],
        a_class  => 'keyword',
        a_target => '_blank',
    });

=head1 DESCRIPTION

This module allows you to extract Hatena keywords used in an
arbitrary text and also allows you to mark up a text as HTML with
the keywords.

A Hatena keyword is an element in a suite of web sites *.hatena.ne.jp
having blogs and social bookmarks among others. Please refer to
http://d.hatena.ne.jp/keyword/ (in Japanese) for details.

In Hatena Diary, a blog hosting service, a Hatena keyword found in a
posting is linked to the keyword¡Çs page automatically. You can
implement the same kind of feature outside Hatena using this module.

It queries Hatena Keyword Link API internally for retrieving terms.

=head1 CLASS METHODS

=head2 extract($text, \%options)

Returns an array or an array reference which contains Hatena::Keyword
objects extracted from specified text as first argument.

This method works correctly for Japanese characters but their encoding
must be utf-8. And also returned words are encoded as utf-8 string.

Second argument is a option. Almost all key and values will be passed
through to the XML-RPC API, excluding cache option.

=head2 markup_as_html($text, \%options)

Returns a tagged html string with Hatena Keywords like this:

  <a href="http://d.hatena.ne.jp/keyword/Perl">Perl</a> and <a
  href="http://d.hatena.ne.jp/keyword/Ruby">Ruby</a>

It takes two arguments, same as C<extract()>.

=head1 INSTANCE METHODS

=head2 as_string

Returns a Hatena::Keyword object to a plain string, an alias for
C<word()>. Hatena::Keyword objects are also converted to plain strings
automatically by overloading. This means that objects can be used as
plain strings in most Perl constructs.

=head2 word

Returns a plain string of the word.

=head2 score

Returns a score of the word.

=head2 refcount

Returns a reference count of the word, which means used times of
the term whole over the Hatena Diary.

=head2 cname

Returns a category name of the word.

=head2 jcode

Returns a Jcode objet which contains the word.

=head1 CACHING

Responses returned by Web API(XML-RPC) can be cached locally.
C<extract> method and C<markup_as_html> accept a reference to a
C<Cache> object as cache option. This means that you can pick out one
of Cache's companions like C<Cache::Memory>, C<Cache::File>, etc. In
fact, any other type of cache implementation will do as well, see the
requirements below.

    use Cache::File;
    my $cache = Cache::File->new(
        cache_root        => '/tmp/mycache',
        default_expires   => '30 min',
    );

    my $keywords = Hatena::Keyword->extract(
        "Perl and Ruby",
        { cache => $cache },
    );

C<Hatena::Keyword> uses I<positive> caching only, errors won't be
cached.  Erroneous requests will be sent to API server every
time.

Caching isn't limited to the C<Cache> class. Any cache object which
adheres to the following interface can be used:

    # Set a cache value
    $cache->set($key, $value);

    # Return a cached value, 'undef' if it doesn't exist
    $cache->get($key);

=head1 ACKNOWLEDGEMENTS

Hideyo Imazu L<http://d.hatena.ne.jp/himazublog/> helped me writing
the English documents.

Hideyo and kosaki L<http://mkosaki.blog46.fc2.com/> and tsupo
L<http://watcher.moe-nifty.com/> helped my decision to change the name
of the method.

Kazuhiro Osawa L<http://yappo.jp/> and Yuichi Tateno
L<http://d.hatena.ne.jp/secondlife/> gave me an inspiration for
caching implementation.

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hatena-keyword at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hatena-Keyword>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hatena::Keyword

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hatena-Keyword>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hatena-Keyword>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hatena-Keyword>

=item * Search CPAN

L<http://search.cpan.org/dist/Hatena-Keyword>

=back

=head1 SEE ALSO

=over 4

=item Hatena Keyword Auto-Link API L<http://tinyurl.com/m5dkm> (redirect to
d.hatena.ne.jp)

=item Hatena Diary L<http://d.hatena.ne.jp/>

=item Hatena L<http://www.hatena.ne.jp/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
