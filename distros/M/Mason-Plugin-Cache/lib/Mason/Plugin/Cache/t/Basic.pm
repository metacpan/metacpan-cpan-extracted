package Mason::Plugin::Cache::t::Basic;
BEGIN {
  $Mason::Plugin::Cache::t::Basic::VERSION = '0.05';
}
use Test::Class::Most parent => 'Mason::Test::Class';

__PACKAGE__->default_plugins( [ '@Default', 'Cache' ] );

sub test_cache_defaults : Tests {
    my $self = shift;
    $self->run_test_in_comp(
        path => '/cache/defaults.mc',
        test => sub {
            my $comp = shift;
            foreach my $cache ( $comp->cache, $comp->m->cache ) {
                is( $cache->label,     'File',             'cache->label' );
                is( $cache->namespace, $comp->cmeta->path, 'cache->namespace' );
            }
        }
    );
}

sub test_cache_method : Tests {
    my $self = shift;
    $self->test_comp(
        path => '/cache.mc',
        src  => '
<%shared>
$.count => 0
</%shared>

<%method getset ($key)>
<%perl>$.count($.count+1);</%perl>
<% $.cache->compute($key, sub { $key . $.count }) %>
</%method>

namespace: <% $m->cache->namespace %>
<% $.getset("foo") %>
<% $.getset("bar") %>
<% $.getset("bar") %>
<% $.getset("foo") %>
',
        expect => '
namespace: /cache.mc
foo1

bar2

bar2

foo1
',
    );
}

sub test_cache_filter : Tests {
    my $self = shift;

    $self->test_comp(
        src => '
% my $i = 1;
% foreach my $key (qw(foo bar)) {
%   $.Repeat(3), $.Cache($key) {{
i = <% $i++ %>
%   }}
% }
',
        expect => '
i = 1
i = 1
i = 1
i = 2
i = 2
i = 2
',
    );

    $self->test_comp(
        src => '
% my $i = 1;
% foreach my $key (qw(foo foo)) {
%   $.Cache($key), $.Repeat(3) {{
i = <% $i++ %>
%   }}
% }
',
        expect => '
i = 1
i = 2
i = 3
i = 1
i = 2
i = 3
'
    );
}

sub test_cache_with_defer : Tests {
    return "not yet implemented";

    my $self = shift;

    my $path = '/cache/defer.mc';
    $self->add_comp(
        path => $path,
        src  => '
% $.Cache("all") {{
foo = <% $m->defer(sub { $Foo::foo }) %>
% $Foo::foo++;
% }}
'
    );
    $Foo::foo = 5;
    $self->test_existing_comp( path => $path, expect => 'foo = 6' );
    $Foo::foo = 10;
    $self->test_existing_comp( path => $path, expect => 'foo = 6' );
}

sub test_cache_memoization : Tests {
    my $self = shift;
    $self->run_test_in_comp(
        path => '/cache/memoize.mc',
        test => sub {
            my $comp = shift;

            is( $comp->cache_memoized, undef, 'Cache not memoized by default' );
            $comp->cache_memoized('buu!');
            is( $comp->cache_memoized, 'buu!', 'Memoization updated' );
        }
    );

    $self->run_test_in_comp(
        path => '/cache/memoize.mc',
        test => sub {
            my $comp = shift;

            is( $comp->cache_memoized, 'buu!', 'Cache memoization works across requests' );
        }
    );
}
