package LWP::UserAgent::ProxyHopper::Base;

use warnings;
use strict;

our $VERSION = '0.003';

use Carp;
use Devel::TakeHashArgs;
use List::MoreUtils 'uniq';
use WWW::FreeProxyListsCom;
use WWW::Proxy4FreeCom;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw(
    proxify_list
    proxify_bad_list
    proxify_real_bad_list
    proxify_working_list
    proxify_schemes
    proxify_retries
    proxify_debug
    proxify_current
    _proxify_last_load_args
    _proxify_freeproxylists_obj
    _proxify_proxy4free_obj
);

sub proxify_load {
    my $self = shift;
    get_args_as_hash(\@_, \my %args, {
            freeproxylists  => 1,
            plan_b          => 1,
            proxy4free      => 0,
            timeout         => 20,
            debug           => 0,
            retries         => 5,
            extra_proxies   => [],
            schemes         => 'http',
            get_list_args   => {
                freeproxylists  => [ ],
                proxy4free      => [ ],
            },
        },
    ) or croak $@;

    $self->_proxify_last_load_args( \%args );

    my @proxies;

    if ( $args{freeproxylists} ) {
        my $obj = $self->_proxify_freeproxylists_obj(
            WWW::FreeProxyListsCom->new( timeout => $args{timeout} )
        );

        my $list_ref
        = $obj->get_list( @{$args{get_list_args}{freeproxylists}} );
        if ( defined $list_ref ) {
            push @proxies, map { "http://$_->{ip}:$_->{port}/" } @$list_ref;
        }
        else {
            $args{debug}
                and carp 'Failed while trying to get a proxy list from '
                            . 'http://freeproxylists.com: ' . $obj->error;
        }
    }

    if ( $args{proxy4free} or ( !@proxies and $args{plan_b} ) ) {
        my $obj = $self->_proxify_proxy4free_obj(
            WWW::Proxy4FreeCom->new( timeout => $args{timeout} )
        );

        my $list_ref = $obj->get_list( @{$args{get_list_args}{proxy4free}} );

        if ( defined $list_ref ) {
            push @proxies, map { "http://$_->{ip}:$_->{port}/" } @$list_ref;
        }
        else {
            $args{debug}
                and carp 'Failed while trying to get a proxy list from '
                            . 'http://proxy4free.com: ' . $obj->error;
        }
    }

    unshift @proxies, @{ $args{extra_proxies} };

    croak q|Don't have ANY proxy addresses :(|
        unless @proxies;

    @proxies = uniq @proxies;

    $args{debug}
        and carp "Got " . @proxies . " proxies in total";

    $self->proxify_retries( $args{retries} );
    $self->proxify_schemes( $args{schemes} );
    $self->proxify_debug(   $args{debug  } );
    $self->proxify_working_list( [] );
    $self->proxify_bad_list( [] );
    $self->proxify_real_bad_list( [] );

    return $self->proxify_list( \@proxies );
}

sub proxify_get { return shift->_proxify_try_request( 'get', \@_ ); }
sub proxify_post { return shift->_proxify_try_request( 'post', \@_ ); }
sub proxify_request { return shift->_proxify_try_request( 'request', \@_ ); }
sub proxify_head { return shift->_proxify_try_request( 'head', \@_ ); }
sub proxify_mirror { return shift->_proxify_try_request( 'mirror', \@_ ); }
sub proxify_simple_request {
    return shift->_proxify_try_request( 'simple_request', \@_ );
}

sub _proxify_try_request {
    my ( $self, $req_type, $args_ref ) = @_;

    my $current_proxy = $self->_proxify_set_proxy;
    my $tries;
    my $max_tries = $self->proxify_retries;
    TRY_REQ: {
        $tries++;

        my $response = $self->$req_type( @$args_ref );
        if ( $response->is_success ) {
            # a lot of proxies seem to be run by this company and it will
            # give us a 200 but display their page with timeout
            # all we need to do is redo the request
            if ( $response->content =~ /\Qcodeen.cs.princeton.edu">CoDeeN/ ) {
                redo TRY_REQ;
            }
            elsif ( not $self->_proxify_check_success($response->content) ) {
                push @{ $self->proxify_real_bad_list }, $current_proxy;
            }

            push @{ $self->proxify_working_list }, $self->proxify_current;
            return $response;

            redo TRY_REQ
                unless $tries > $max_tries;

            return $response;
        }
        else {
            $self->proxify_debug
                and carp 'Failed on proxify_get(): '
                    . $response->status_line;

            if ( $response->status_line =~ /500.+\Q$current_proxy/
                or $response->code == 400
                or $response->code == 504
                or $response->code == 502
            ) {
                # BAD PROXY!!! NO COOKIE!
                push @{ $self->proxify_real_bad_list }, $current_proxy;
            }
            else {
                push @{ $self->proxify_bad_list }, $current_proxy;
            }
            $current_proxy = $self->_proxify_set_proxy;

            redo TRY_REQ
                unless $tries > $max_tries;

            # if we got here $response is not successfull but that might have
            # nothing to do with proxies at all
            return $response;
        }
    } # TRY_GET:{}
    croak 'I should never get to this point. Please email this message '
            . 'to zoffix@cpan.org. Thank you very much';
}

sub _proxify_set_proxy {
    my $self = shift;

    my $proxy = $self->proxify_current( shift @{ $self->proxify_list } );

    unless ( defined $proxy ) {
        $self->proxify_debug
            and carp 'proxify_list() is exhausted, trying "working" list';
    
        $self->proxify_list( $self->proxify_working_list );
        $self->proxify_working_list([]);
        $proxy = $self->proxify_current( shift @{ $self->proxify_list } );
    }

    unless ( defined $proxy ) {
        $self->proxify_debug
           and carp 'proxify_working_list() is exhausted, trying "bad" list';

        $self->proxify_list( $self->proxify_bad_list );
        $self->proxify_bad_list([]);
        $proxy = $self->proxify_current( shift @{ $self->proxify_list } );
    }

    unless ( defined $proxy ) {
        $self->proxify_debug
           and carp 'lists are exhausted, trying to proxify_load now';

        $self->proxify_load( %{ $self->_proxify_last_load_args || {} });
        $proxy = $self->proxify_current( shift @{ $self->proxify_list } );

        defined $proxy
            or croak 'After trying so hard I still could not get any more'
                . ' proxies to play with :(';
    }

    $self->proxify_debug
        and carp "Using proxy $proxy";
    
    $self->proxy($self->proxify_schemes, $proxy );

    return $proxy;
}

sub _proxify_check_success {
    my ( $self, $content ) = @_;
    return 1 if length $content > 4000;
    if ( $content =~ m|\s*
\Qhttp/1.1 401 Unauthorized\E\s*
\QServer:\E\s*
.+?
\QWWW-Authenticate: Basic realm="ADSL Router \(ANNEX A\)"\E\s*
\QContent-Type: text/html\E\s*
\QConnection: close\E\s*
\s*
\Q<html>\E\s*
\Q<head>\E\s*
\Q<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-9">\E\s*
\Q<META http-equiv="Pragma" CONTENT="no-cache">\E\s*
\Q<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">\E\s*
\Q<meta HTTP-EQUIV="Expires" CONTENT="Mon, 06 Jan 1990 00:00:01 GMT">\E\s*
|xsm
    ) {
        return 0; # failed 
    }

    if ( $content =~ m|<title>ESPOCH Acceso denegado</title>| ) {
        return 0; # failed
    }
    return 1; # success
}

1;
__END__


=head1 NAME

LWP::UserAgent::ProxyHopper::Base - base class for LWP::UserAgent based modules which want to proxy-hop their requests

=head1 SYNOPSIS

    package LWP::UserAgent::Prox;

    use base 'LWP::UserAgent';
    use base 'LWP::UserAgent::ProxyHopper::Base';

    package main;

    use strict;
    use warnings;

    my $ua = LWP::UserAgent::Prox->new( agent => 'fox', timeout => 2);

    $ua->proxify_load( debug => 1 );

    for ( 1..10 ) {
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
            printf "\n[SCRIPT] Network error: %s\n", $response->status_line;
        }
    }

=head1 DESCRIPTION

The module is a base class for LWP::UserAgent based modules which want to
proxy-hop their requests. In other words each request can be sent
out from different proxy servers.
Originally, this module was ment to be released
as LWP::UserAgent::ProxyHopper
but I figured it would be more useful as a base class.

=head1 WHAT'S IN IT?

By adding C<use base 'LWP::UserAgent::ProxyHopper::Base';> to your code it should
be possible to enable extra functionality this base class provides without
trouble. Your code should be a subclass of L<LWP::UserAgent> or at least
properly support the C<proxy()> and one or more of L<LWP::UserAgent>'s
request methods returning L<HTTP::Response> objects.

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

All public methods are prefixed with C<proxify_> all private methods
are prefixed with C<_proxify_>.

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
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

Thanks for reporting bugs and/or providing a patches goes to: I<lordnynex>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-useragent-proxyhopper-base at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-ProxyHopper-Base>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::ProxyHopper::Base

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-UserAgent-ProxyHopper-Base>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-UserAgent-ProxyHopper-Base>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-UserAgent-ProxyHopper-Base>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-UserAgent-ProxyHopper-Base>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

