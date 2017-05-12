package LWP::UserAgent::ProxyHopper;

use warnings;
use strict;

our $VERSION = '0.004';

use base qw(LWP::UserAgent LWP::UserAgent::ProxyHopper::Base);

1;
__END__


=head1 NAME

LWP::UserAgent::ProxyHopper - LWP::UserAgent with proxi-hopping

=head1 SYNOPSIS

    use strict;
    use warnings;

    use LWP::UserAgent::ProxyHopper;

    my $ua = LWP::UserAgent::ProxyHopper->new( agent => 'fox', timeout => 10 );

    $ua->proxify_load;

    for ( 1..5 ) {
        my $response = $ua->proxify_get('http://www.privax.us/ip-test/');

        if ( $response->is_success ) {
            my $content = $response->content;
            if ( my ( $ip ) = $content
                =~ m|<p>.+?IP Address:\s*</strong>\s*(.+?)\s+|s
            ) {
                printf "\n\nSucces!!! \n%s\n", $ip;
            }
            else {
                printf "Response is successfull but seems like we got a wrong "
                        . " page... here is what we got:\n%s\n", $content;
            }
        }
        else {
            print '[script] Network error: ' . $response->status_line;
        }
    }

=head1 DESCRIPTION

The module is a subclass of L<LWP::UserAgent> with adds extra functionality
to make proxy-hopping requests. In other words each request can be sent
out from different proxy servers.

=head1 HOW GOOD IS IT?

Don't get your hopes up too high... unless you can feed the module 100%
working and fast proxies. Even though the module
does some basic checks on whether the request succeeded and blacklists
proxies that appear to be real bad there is still quite a good chance that
either (a) your request will timeout after several tries or worse: (b)
your request will succeed but will return not what you would expect it to
as some proxies tend to drop garbage on you. Depending on settings
your mileage will vary, it's speed for quality trade off.

=head1 HOW IT WORKS

The module fetches a list of proxy servers (see C<proxify_load()> method)
when one of C<proxify_*()> request methods is called it will get a proxy
from the list and try to make your request with the proxy in use. If
request succeeds it will check for a couple of "this is not what you wanted"
proxies and retry the request with a different proxy if that the case. If
this check did not raise any suspicion the result (L<HTTP::Response> object)
will be returned back to you and proxy which was used will be put into a
"working" list. If the request failed the module will do
a basic check on the return status code and decide whether to blacklist
proxy into a "bad" list or "real_bad" list after which it will retry.
The number of times it will retry depends on C<retry> setting to
C<proxify_load()> method.

When the original proxy list is exhausted the module will make a new list
out of proxies which it previously listed as "working", if that fails the
"bad" list which might have working proxies. The "real_bad" list will never
be used. If both "working" and "bad" lists do not have any proxies left
the module will call C<proxify_load()> automatically with the same
arguments you used it with the last time, therefore your program can live
long with just one call to C<proxify_load()> during startup.

=head1 PROVIDED METHODS

The module is a subclass of L<LWP::UserAgent> thus you can use any
L<LWP::UserAgent>'s methods as you would before.
All the methods are prefixed with C<proxify_>.

=head2 C<proxify_load>

    $your_ua->proxify_load; # plain defaults

    $your_ua->proxify_load(  # juicy override
        freeproxylists  => 1,
        plan_b          => 1,
        proxy4free      => 0,
        timeout         => 20,
        debug           => 0,
        retries         => 5,
        extra_proxies   => [],
        schemes         => [ 'http', 'ftp' ],
        get_list_args   => {
            freeproxylists  => [ type => 'anonymous' ],
            proxy4free      => [ [2,3] ],
        },
    );

Instructs the object to load up a list of proxies. You must call this
method at least once before calling any other C<proxify_*> request methods.
The return value is an arrayref of proxy addresses in a form
C<"http://122.122.122.122:8080/">. Will C<croak()> if after trying to fetch
proxy lists and after adding C<extra_proxies> (see below) the proxy list
is still empty. The method takes quite a bit of arguments, all of which
are given in a key/value fashion. I<All of them are optional>. Possible
argumens are as follows:

=head3 C<freeproxylists>

    $your_ua->proxify_load( freeproxylists => 1 );

B<Optional>. The module uses L<WWW::FreeProxyLists::Com> and
L<WWW::Proxy4FreeCom> modules to get the proxy list. If you set
C<freeproxylists> argument to a I<false> value the module will not attempt
to load any proxies from L<http://freeproxylists.com/> website.
B<Defaults to:> C<1>

=head3 C<proxy4free>

    $your_ua->proxify_load( proxy4free => 0 );

B<Optional>. The module uses L<WWW::FreeProxyLists::Com> and
L<WWW::Proxy4FreeCom> modules to get the proxy list. If you set
C<proxy4free> argument to a I<false> value (which is the default)
the module will not attempt to load any proxies from
L<http://www.proxy4free.com/> website. B<Defaults to:> C<0>

=head3 C<plan_b>

    $your_ua->proxify_load( plan_b => 1 );

B<Optional>. When set to a I<true value> will enable a "Plan B" mechanism.
In other words, when C<plan_b> and C<freeproxylists> both set to true values
and the fetch from L<http://freeproxylists.com/> did not give us any proxies
the module will fetch a list from L<http://www.proxy4free.com/> website
I<irrelevant> of whether or not C<proxy4free> is set to a true value. In
other words, this is sort of a fallback thing in case
L<http://freeproxylists.com> is down when C<proxy4free> is set to a false
value to speedup proxy list loading process. B<Defaults to:> C<1> (enabled)

=head3 C<timeout>

    $your_ua->proxify_load( timeout => 20 );

B<Optional>. Takes a positive integer value which will be passed to
L<WWW::FreeProxyLists::Com> and L<WWW::Proxy4FreeCom> constructors as
a C<timeout> argument. In other words, this specifies the timeout for
proxy list fetching. B<Defaults to:> C<20>

=head3 C<retries>

    $your_ua->proxify_load( retries => 5 );

B<Optional>. This argument specifies how many times the module
should retry the C<proxy_*> requests if they doesn't look as successfull
ones. Generally, setting the C<retries> argument to a higher value will
yield to more reliable requests but will also slow down the request process.
See C<HOW IT WORKS> section about to get the idea when the module
will retry the request. B<Defaults to:> C<5>.

=head3 C<extra_proxies>

    $your_ua->proxify_load( extra_proxies => [] );

B<Optional>. Takes an arrayref of proxy addresses in a format acceptable
to L<LWP::UserAgent>'s C<proxy()> method. These will be the extra proxies
to use which you can provide. Basically you can set C<freeproxylists>
and C<plan_b> arguments to false values and stuff your own proxies
into C<extra_proxies> arrayref in which case the module will not even
attempt to fetch any lists from proxy list sites (i.e. the loading will
be way faster). B<Defaults to:> C<[]> (no extra proxies)

=head3 C<schemes>

    $your_ua->proxify_load( schemes => [ 'http', 'ftp' ] );

    $your_ua->proxify_load( schemes => 'ftp' );

B<Optional>. Specifies the first argument to pass to L<LWP::UserAgent>'s
C<proxy()> method (i.e. the schemes to proxy for). I<Note:> any other
schemes besides C<'http'> were not tested and might not even work with
the proxy lists the module fetches by default. B<Defaults to:> C<http>

=head3 C<get_list_args>

    $your_ua->proxify_load(
        get_list_args   => {
            freeproxylists  => [ type => 'anonymous' ],
            proxy4free      => [ [1,2] ],
        },
    );

B<Optional>. Here you have a chance to specify specific arguments to
C<get_list()> methods of L<WWW::FreeProxyLists::Com> and
L<WWW::Proxy4FreeCom> modules used under the hood. The C<get_list_args>
takes a hashref with two keys as a value. The keys must be
C<freeproxylists> and C<proxy4free> values of which must be arrayrefs with
arguments to give to C<get_list()> methods of respecive modules.

=head3 C<debug>

    $your_ua->proxify_load( debug => 0 );

B<Optional>. When set to a true value will make the module C<carp()> out
some debugging info (including the time when proccessing of any C<proxify_*>
request methods). B<Defaults to:> C<0>

=head2 C<proxify_get>

    my $response = $your_ua->proxify_get('http://something.com/');

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<get()> method except
C<proxify_get()> will switch proxies before attempting the request.

=head2 C<proxify_post>

    my $response = $your_ua->proxify_post('http://something.com/');

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<post()> method except
C<proxify_post()> will switch proxies before attempting the request.
B<Note:> during my tests a lot (almost all) proxies from
L<http://www.freeproxylist.com/> did not permit POST requests. You might
have better luck with setting L<proxy4free> to a true value disabling
L<freeproxylists> argument and setting higher C<retries> argumnet (see
C<proxify_load()> method above), 

=head2 C<proxify_request>

    my $response = $your_ua->proxify_request( $req_obj );

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<request()> method except
C<proxify_request()> will switch proxies before attempting the request.

=head2 C<proxify_head>

    my $response = $your_ua->proxify_head('http://something.com/');

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<head()> method except
C<proxify_head()> will switch proxies before attempting the request.

=head2 C<proxify_mirror>

    my $response = $your_ua->proxify_mirror(
        'http://something.com/file.tar.gz',
        'here.tar.gz',
    );

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<mirror()> method except
C<proxify_mirror()> will switch proxies before attempting the request.
B<Note:> use this method with caution as some proxies return an HTML document
insted of actual content you requested.

=head2 C<proxify_simple_request>

    my $response = $your_ua->proxify_simple_request('http://something.com/');

Must be called after a successfull call to C<proxify_load()> method.
The method is the same as C<LWP::UserAgent>'s C<simple_request()> method
except C<proxify_simple_request()> will switch proxies before attempting
the request.

=head2 C<proxify_list>

    my $proxies_list_ref = $your_ua->proxify_list;

Must be called after a successfull call to C<proxify_load()> method.
Takes no arguments, returns an arrayref of proxies used internally for
requests. This list will shrink as more requests are made (until it's
depleted and reloaded see C<HOW IT WORKS> section). Note: you can
C<shift>, C<push>, etc. on this arrayref to dinamically set what
proxies will be used. The proxy to be used on the next C<proxify_*> request
is the first element of this arrayref.

=head2 C<proxify_working_list>

    my $proxies_working_list_ref = $your_ua->proxify_working_list;

Must be called after a successfull call to C<proxify_load()> method.
Takes no arguments, returns an arrayref of proxies listed as "working". See
C<HOW IT WORKS> section above for details. Note: you can
C<shift>, C<push>, etc. on this arrayref to dinamically change it.

=head2 C<proxify_bad_list>

    my $proxies_bad_list_ref = $your_ua->proxify_bad_list;

Must be called after a successfull call to C<proxify_load()> method.
Takes no arguments, returns an arrayref of proxies listed as "bad". See
C<HOW IT WORKS> section above for details. Note: you can
C<shift>, C<push>, etc. on this arrayref to dinamically change it.

=head2 C<proxify_real_bad_list>

    my $proxies_real_bad_list_ref = $your_ua->proxify_real_bad_list;

Must be called after a successfull call to C<proxify_load()> method.
Takes no arguments, returns an arrayref of proxies listed as "real bad". See
C<HOW IT WORKS> section above for details.

=head2 C<proxify_schemes>

    my $used_schemes = $your_ua->proxify_schemes;

    $your_ua->proxify_schemes( [ 'http', 'ftp' ] );

Returns a currently used value for the C<proxify_load()> method's
C<schemes> argument. If called with an optional argument will use it as a
new value. See C<proxify_load()> method above for details.
B<Note:> the value will be reset on the next C<proxify_load()> call, which
can happen automatically if proxy lists are exhausted. See C<HOW IT WORKS>
section for details.

=head2 C<proxify_retries>

    my $used_retries = $your_ua->proxify_retries;

    $your_ua->proxify_retries( 10 );

Returns a currently used value for the C<proxify_load()> method's
C<retries> argument. If called with an optional argument will use it as a
new value.
See C<proxify_load()> method above for details.
B<Note:> the value will be reset on the next C<proxify_load()> call, which
can happen automatically if proxy lists are exhausted. See C<HOW IT WORKS>
section for details.

=head2 C<proxify_debug>

    my $used_debug = $your_ua->proxify_debug;

    $your_ua->proxify_debug( 1 );

Returns a currently used value for the C<proxify_load()> method's
C<debug> argument. If called with an optional argument will use it as a
new value. See C<proxify_load()> method above for details.
B<Note:> the value will be reset on the next C<proxify_load()> call, which
can happen automatically if proxy lists are exhausted. See C<HOW IT WORKS>
section for details.

=head2 C<proxify_current>

    my $current_proxy = $your_ua->proxify_current;

Takes no arguments, returns a last proxy used in C<proxify_*> request
methods. Why is is called "current"? Because it changes several times during
the calls to C<proxify_*> request methods depending on the C<retries>
argument's setting ( in the proxify_load() method ).

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-useragent-proxyhopper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-ProxyHopper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::ProxyHopper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-UserAgent-ProxyHopper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-UserAgent-ProxyHopper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-UserAgent-ProxyHopper>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-UserAgent-ProxyHopper>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

