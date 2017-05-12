package Foorum;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use parent qw/Catalyst/;
use Catalyst qw/
    ConfigLoader
    Static::Simple
    Authentication
    Cache
    Session::DynamicExpiry
    Session
    Session::Store::DBIC
    Session::State::Cookie
    I18N
    FormValidator::Simple
    Captcha
    +Foorum::Plugin::FoorumUtils
    /;

our $VERSION = '1.001000';

__PACKAGE__->config( { VERSION => $VERSION } );

__PACKAGE__->setup();

if ( __PACKAGE__->config->{function_on}->{page_cache} ) {
    __PACKAGE__->setup_plugins( ['PageCache'] );

    ## set $c->language before create a key in PageCache
    __PACKAGE__->config->{'Plugin::PageCache'}->{key_maker} = sub {
        my $c = shift;

        # something as the same as in Root.pm
        # while it is called before we call sub auto in Root.pm
        # and we may not call this if request doesn't call $c->cache_page
        my $lang;
        $lang = $c->req->cookie('lang')->value if ( $c->req->cookie('lang') );
        $lang ||= $c->user->lang if ( $c->user_exists );
        $lang ||= $c->config->{default_lang};
        $lang = $c->req->param('lang') if ( $c->req->param('lang') );
        $lang =~ s/\W+//isg;
        $c->languages( [$lang] );

        return '/' . $c->req->path;
    };
} else {
    {
        no strict 'refs';    ## no critic (ProhibitNoStrict)
        my $class = __PACKAGE__;
        *{"$class\::cache_page"}        = sub {1};
        *{"$class\::clear_cached_page"} = sub {1};
    }
}

1;
__END__

=head1 NAME

Foorum - forum system based on Catalyst

=head1 DESCRIPTION

nothing for now.

=head1 LIVE DEMO

L<http://www.foorumbbs.com/>

=head1 FEATURES

=over 4

=item open source

u can FETCH all code from L<http://github.com/fayland/foorum/tree> any time any where.

=item Win32 compatibility

Linux/Unix/Win32 both OK.

=item templates

use L<Template> for UI.

=item built-in cache

use L<Cache::Memcached> or use L<Cache::FileCache> or others;

=item reliable job queue

use L<TheSchwartz::Moosified>

=item Multi Formatter

L<HTML::BBCode>, L<Text::Textile>, L<Pod::Xhtml>, L<Text::GooglewikiFormat>

=item Captcha

To keep robot out.

=back

=head1 JOIN US

Welcome to fork it in L<http://github.com/fayland/foorum/tree> and pull requests back.

=head1 TODO

L<http://code.google.com/p/foorum/issues/list>

=head1 SEE ALSO

L<Catalyst>, L<DBIx::Class>, L<Template>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
