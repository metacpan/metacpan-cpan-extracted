package Developer::Dashboard::Web::Server::Daemon;

use strict;
use warnings;

our $VERSION = '3.14';

# new(%args)
# Constructs the lightweight daemon descriptor used by RuntimeManager.
# Input: resolved host and port values.
# Output: daemon descriptor object.
sub new {
    my ( $class, %args ) = @_;
    return bless {
        host          => $args{host},
        port          => $args{port},
        internal_host => $args{internal_host},
        internal_port => $args{internal_port},
    }, $class;
}

# sockhost()
# Returns the resolved listen host for the daemon descriptor.
# Input: none.
# Output: host string.
sub sockhost {
    return $_[0]{host};
}

# sockport()
# Returns the resolved listen port for the daemon descriptor.
# Input: none.
# Output: port integer.
sub sockport {
    return $_[0]{port};
}

# internal_sockhost()
# Returns the resolved internal backend host when the daemon fronts an SSL proxy.
# Input: none.
# Output: host string or undef.
sub internal_sockhost {
    return $_[0]{internal_host};
}

# internal_sockport()
# Returns the resolved internal backend port when the daemon fronts an SSL proxy.
# Input: none.
# Output: port integer or undef.
sub internal_sockport {
    return $_[0]{internal_port};
}

1;

__END__

=head1 NAME

Developer::Dashboard::Web::Server::Daemon - Lightweight daemon descriptor for the PSGI server wrapper

=head1 SYNOPSIS

  my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
      host => '127.0.0.1',
      port => 17891,
  );

=head1 DESCRIPTION

This module stores the resolved listen host and port that the runtime manager
and PSGI server wrapper use when reserving and starting the dashboard web
listener.

=head1 METHODS

=head2 new, sockhost, sockport, internal_sockhost, internal_sockport

Construct and query the lightweight daemon descriptor.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the small value object that carries resolved listen addresses for the web server. It records the public host and port, and when SSL is enabled it also records the internal backend host and port used behind the public TLS frontend.

=head1 WHY IT EXISTS

It exists so daemon resolution can be passed around as a typed object instead of loose hashes. That keeps the public and internal socket details explicit in the runtime manager and web server code.

=head1 WHEN TO USE

Use this file when changing what metadata the web server carries between port reservation, runner setup, and SSL frontend proxying.

=head1 HOW TO USE

Create it with the resolved host and port values, then pass it into C<Developer::Dashboard::Web::Server> methods that need to build URLs or runners from those values.

=head1 WHAT USES IT

It is used only by the web server lifecycle code and the tests that verify public versus internal daemon metadata under SSL and non-SSL serving.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Web::Server::Daemon -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/03-web-app.t t/08-web-update-coverage.t t/web_app_static_files.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
