package LWP::UserAgent::OfflineCache;
use Moose;
extends 'LWP::UserAgent', 'Moose::Object';
use IO::All;
use HTTP::Message;
use Digest::MD5 qw/md5_hex/;
use File::Path qw/mkpath/;
use Fatal qw/mkpath/;
use Log::Log4perl;

=head1 ABSTRACT

LWP::UserAgent::OfflineCache - a caching user agent

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use constant DEFAULT_CACHE_DIR_NAME => 'cache';


=head1 SYNOPSIS

This module will cache all GET requests to disk.  It otherwise
behaves the same as LWP::UserAgent.

Caching performs regardsless of any returned HTTP headers.

Simple example:

    #!/usr/bin/perl -w
    use strict;
    use LWP::UserAgent::OfflineCache;
    my $ua = LWP::UserAgent::OfflineCache->new;
    print $ua->get("http://www.yahoo.com/index.html");


More advanced example

    #!/usr/bin/perl -w
    use strict;
    use LWP::UserAgent::OfflineCache;
    use Log::Log4perl;

    my $logConf = q(
        log4perl.category.lwp.useragent.offlinecache = INFO, Screen
        log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr  = 0
        log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
    );
    Log::Log4perl::init( \$logConf );


    my $ua = LWP::UserAgent::OfflineCache->new(cache_dir=> 'cache', delay=>3, use_gzip=>1);
    # The same as my $ua = LWP::UserAgent::OfflineCache->new;

    print $ua->get("http://www.yahoo.com/index.html");

=head1 DESCRIPTION

The C<LWP::UserAgent::OfflineCache> is a class-wrapper for C<LWP::UserAgent>.

::OfflineCache module allows to use offline cache for debug and logging purpose.

Also by default ::OfflineCache tries to use 'Accept-Encoding' HTTP header 
for using less bandwidth.

Cached content stored as a files with names md5($url) in the specified directory.

=head1 CONSTRUCTOR METHOD

=over 4

=item $ua = LWP::UserAgent::OfflineCache->new(%options)

In additional to standard LWP::UserAgent's options the following 
key/pairs values are available:

   KEY                  DEFAULT
 ----------             ------------------
 cache_dir              cache (means './cache')
 delay                  3 (seconds)
 use_gzip               1

=head1 ATTRIBUTES

=over

=item $ua->cache_dir 

Get directory where cached content stored as files with names as md5 hash 
from requested url.

=item $ua->delay

Get/set delay in seconds after each request to the server.
Default value is 3.

=item $ua->use_gzip

Get/set boolean flag for automatic usage of 'gzip' (HTTP::Message::decodable()) in 
'Accept-Encoding' header.
Switched on by default.

=cut

# as suggested in Moose FAQ
# explicit constructor for non-Moose superclasses
sub new {
        my $class = shift;
        my $self;
        {
                local $^W; # switch off Unrecognized LWP::UserAgent options...
                            # specific only for implementation of LWP::UserAgent
                my $obj = $class->SUPER::new(@_);
                $self=  $class->meta->new_object(__INSTANCE__ => $obj, @_);
        }
        $self->BUILD();
        $self;
}


has 'cache_dir' => (
    is         => 'ro',
    isa        => 'Str',
    default    => DEFAULT_CACHE_DIR_NAME
);

has 'delay' => (
    is         => 'rw',
    isa        => 'Int',
    default    => 3
);

has 'use_gzip' => (
    is         => 'rw',
    isa        => 'Bool',
    default    => '1'
);

has 'logger' => (
    is         => 'ro',
    isa        => 'Object'
);


sub BUILD {
        my $self = shift;
        $self->{logger} = Log::Log4perl->get_logger('lwp.useragent.offlinecache');
        my $dir = $self->cache_dir;

        if (!-d $dir) {
            mkpath($dir);
        }
}

around 'get' => sub {
    my $orig = shift;
    my $self = shift;
    my $url  = shift;

    my $logger = $self->logger;
    my $file = $self->_url_to_file($url);
    if (-e $file) {
            $logger->info("Returning $url from $file");
        return io($file)->all();
    }

        my $html;
    if ($self->use_gzip) {
                my $can_accept = HTTP::Message::decodable;
                my $resp = $orig->($self, $url, 'Accept-Encoding' => $can_accept);
                my $msg = 'Raw '. length ($resp->content). ' bytes,';
                $html = $resp->decoded_content('charset'=> 'none');
            $logger->info($msg ,' uncompressed ', length $html, ' bytes');
        }
        else {
            my $resp = $orig->($self, $url);
                $html = $resp->content;
        }

        io($file)->print($html);
        $logger->info("Saved $url to $file");
    sleep $self->delay;
    return $html;
};


sub _url_to_file {
    my $self = shift;
    my $cd   = $self->cache_dir;
    return join '/', $cd, md5_hex(shift);
}


=head1 AUTHORS

=over

=item Luke Closs, C<< <cpan at 5thplane.com> >>

=item Dmytro Gorbunov, C<< <gdm at savesources.com> >>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::OfflineCache

=head1 ACKNOWLEDGEMENTS

Thanks to Luke Closs for an idea and perfect implementation of 
Net::Parliament::UserAgent module.

=head1 SEE ALSO

=over

=item LWP::UserAgent::Snapshot  - same purpose as this module

=item LWP::Online               - answer the question "Am I online?"

=item LWP::UserAgent::WithCache - acts like a browser with cache

=item LWP::Simple::WithCache    - simplify an access to previous one

=item LWP::UserAgent::Cache::Memcached - same, but with memcache

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright 2009 Luke Closs, all rights reserved.

=item Copyright 2010 Dmytro Gorbunov, all rights reserved.

=back

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

