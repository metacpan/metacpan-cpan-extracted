package Developer::Dashboard::Web::Server::Daemon;

use strict;
use warnings;

our $VERSION = '2.02';

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

Perl module in the Developer Dashboard codebase. This file provides daemon-specific server glue used by the web server runtime.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::Web::Server::Daemon> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::Web::Server::Daemon -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
