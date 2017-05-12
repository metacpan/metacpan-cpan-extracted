use strict;
use warnings;

package Jifty::Plugin::YouTube::Dispatcher;
use Jifty::Dispatcher -base;

# take youtube hash key here
on qr|/youtube/(\w+)/| => sub {
    # render a youtube widget
    set 'hash',$1;
    show '/_youtube';
};


1;
