use strict;
use warnings;

package Jifty::Plugin::Gravatar::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

on q|/=/gravatar/*| => sub {
    my $id = $1;
    set id => $id;
    show '/=/gravatar/image';
};


1;
