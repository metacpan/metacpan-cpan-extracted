#!/usr/bin/env perl

use Test::More tests => 8;

BEGIN {
    use_ok('Carp');
    use_ok('Devel::TakeHashArgs');
    use_ok('List::MoreUtils');
    use_ok('WWW::FreeProxyListsCom');
    use_ok('WWW::Proxy4FreeCom');
    use_ok('Class::Data::Accessor');
	use_ok('LWP::UserAgent::ProxyHopper::Base');
}

diag( "Testing LWP::UserAgent::ProxyHopper:Base $LWP::UserAgent::ProxyHopper::Base::VERSION, Perl $], $^X" );


can_ok('LWP::UserAgent::ProxyHopper::Base', qw(
    proxify_load
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
    _proxify_try_request
    _proxify_set_proxy
    proxify_get
    proxify_post
    proxify_request
    proxify_head
    proxify_mirror
    proxify_simple_request
));