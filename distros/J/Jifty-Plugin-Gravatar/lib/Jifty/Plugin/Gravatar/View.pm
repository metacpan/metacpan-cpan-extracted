package Jifty::Plugin::Gravatar::View;
use warnings;
use strict;
use Cache::File;
use LWP::Simple qw();
use Gravatar::URL;
use Jifty::View::Declare -base;

template '/gravatar' => sub {
    my ( $self, $email ) = @_;
    my $gravatar_url = gravatar_url( email => $email );
    my $gravatar_id = gravatar_id($email);

    div { { class is 'gravatar-image-wrapper' };
        # check config 
        my $config = Jifty->find_plugin('Jifty::Plugin::Gravatar');
        if( $config->{LocalCache} ) {
            Jifty->log->debug("[Gravatar] LocalCache: /=/gravatar/$gravatar_id" );
            img { { id is 'g-i-' . $gravatar_id, class is 'gravatar-image', src is '/=/gravatar/' . $gravatar_id }; };
        }
        else {
            Jifty->log->debug("[Gravatar] Gravatar.com: $gravatar_url" );
            div { { class is 'gravatar-image-wrapper' };
                img { { id is 'g-i-' . $gravatar_id, class is 'gravatar-image', src is $gravatar_url }; };
            };
        }
    };

};

template '/=/gravatar/image' => sub {
    my $config = Jifty->find_plugin('Jifty::Plugin::Gravatar');
    Jifty->handler->apache->content_type("image/jpeg");
    Jifty->handler->apache->header_out(
        Expires => HTTP::Date::time2str( time() + ( $config->{CacheExpire} * 60 || 3 ))
    );
    my $id = get('id');
    my $gravatar_url = gravatar_url( id => $id );

    my $cache_root = $config->{CacheRoot} || '/tmp/gravatar';

    my $cache = Cache::File->new( cache_root => $cache_root );
    my $image = $cache->get($id);
    unless ($image) {
        Jifty->log->debug('[Gravatar] Download Icon from: ' . $gravatar_url );
        my $image = LWP::Simple::get($gravatar_url);
        my $cache_expire = $config->{CacheFileExpire} || 3;
        $cache->set( $id , $image , $cache_expire . ' minutes' );
        Jifty->log->debug( '[Gravatar] Icon Cached: ' . $id  . " ($cache_expire minutes)" );
    }
    outs_raw( $image );
};

1;
