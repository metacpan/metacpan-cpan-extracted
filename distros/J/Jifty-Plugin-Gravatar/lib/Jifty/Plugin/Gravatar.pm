use strict;
use warnings;

package Jifty::Plugin::Gravatar;
use base qw/Jifty::Plugin/;

our $VERSION = 0.02;

=head1 NAME

Jifty::Plugin::Gravatar - Jifty Plugin for Gravatar Icon Service

=head1 DESCRIPTION

=head1 SYNOPSIS

add options to config.yml

 framework:
   Plugins:
     - Gravatar:
        LocalCache: 1
        CacheExpire: 10
        CacheFileExpire: 10
        CacheRoot: /tmp/gravatar

to use gravatar icon in your template:

    package MyApp::View;
    use Jifty::View::Declare -base;

    template 'index.html' => page { } content {

        show '/gravatar' => 'email@host.com';

    };

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - Gravatar: {}

=head2 OPTIONS

=over 4

=item LocalCache: bool

show gravatar icon path by /=/gravatar/[id] , to use cache.

=item CacheExpire: integer

cache expiration time of header. for browser

=item CacheFileExpire: integer

cache expiration time for L<Cache::File> , save image cahce into CacheRoot.

=item CacheRoot: string

path for saving gravatar icon cache

=over

=head1 AUTHOR

Cornelius C<<cornelius.howl [at] gmail.com>>

=head1 SEE ALSO

L<Gravatar::URL>

=cut

1;
