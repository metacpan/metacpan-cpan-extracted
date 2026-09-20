package ForgeOps::Tracker::Integrations::PSGI;

use strict;
use warnings;
use parent 'Plack::Middleware';
use ForgeOps::Tracker;

# PSGI/Plack middleware: works under any PSGI-speaking framework (plain PSGI apps, Dancer2 via
# its own Plack integration, Mojolicious under Plack::Handler::???). Wrap your app with it:
#
#   use Plack::Builder;
#   builder {
#       enable '+ForgeOps::Tracker::Integrations::PSGI'; # '+': see Plack::Builder's own docs on
#                                                         # enable(): without it, a bare name is
#                                                         # looked up under Plack::Middleware::*
#                                                         # instead of taken as an exact class name.
#       $app;
#   };
#
# Wraps the downstream app call in an eval, reports, then re-raises the *original* exception
# unchanged: so Plack's own error handling (Plack::Middleware::StackTrace in development, or the
# PSGI server's own 500 response in production) continues exactly as if this middleware weren't
# there. Only an exception the app itself catches and handles is invisible to this, same as every
# other framework integration in this repo.
sub call {
    my ($self, $env) = @_;

    # A fresh breadcrumb trail per request: a prefork worker serves many requests in a row.
    ForgeOps::Tracker::clear_breadcrumbs();

    my @response = eval { @{ $self->app->($env) } };
    if (my $error = $@) {
        ForgeOps::Tracker::report($error, {
            path   => $env->{PATH_INFO},
            method => $env->{REQUEST_METHOD},
        });
        die $error;
    }

    return \@response;
}

1;
