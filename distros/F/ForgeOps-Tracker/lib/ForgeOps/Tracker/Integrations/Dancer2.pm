package ForgeOps::Tracker::Integrations::Dancer2;

use strict;
use warnings;
use Dancer2::Plugin;
use Dancer2::Core::Hook;
use ForgeOps::Tracker;

# Dancer2 plugin. Named ForgeOps::Tracker::Integrations::Dancer2 rather than the ecosystem's usual
# Dancer2::Plugin::* convention, to stay consistent with this repo's own
# ForgeOps::Tracker::Integrations::* namespace (see Integrations/PSGI.pm): Dancer2 instantiates
# any package that `use Dancer2::Plugin;` and is itself `use`d from an app, regardless of
# namespace, so this works exactly the same as a conventionally-named one:
#
#   use Dancer2;
#   use ForgeOps::Tracker::Integrations::Dancer2;   # that's it, no further wiring
#
# Registers an on_route_exception hook: Dancer2's own documented hook, fired whenever a route
# throws an exception that reaches Dancer2's own top-level handling, *before* Dancer2 renders its
# error page. Reporting from a hook, rather than wrapping every route by hand, is what makes this
# automatic with no per-route changes, the same "no further wiring" story every other framework
# integration in this repo provides for its own framework. The hook only observes; it doesn't
# change what Dancer2 does with the exception afterward, so Dancer2's own error page (or a
# registered error handler) still renders exactly as if this plugin weren't installed.
sub BUILD {
    my ($plugin) = @_;

    $plugin->app->add_hook(Dancer2::Core::Hook->new(
        name => 'on_route_exception',
        code => sub {
            my ($app, $error) = @_;
            my $request = $app->request;
            ForgeOps::Tracker::report($error, {
                path   => $request ? $request->path : undef,
                method => $request ? $request->method : undef,
            });
        },
    ));
}

1;
