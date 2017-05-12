use strict;
use warnings;
no warnings "void";

=head1 NAME

LWP::UserAgent::Paranoid - A modern LWPx::ParanoidAgent for safer requests

=cut

package LWP::UserAgent::Paranoid;
use base 'LWP::UserAgent';

our $VERSION = "0.97";

use Scalar::Util          qw/ refaddr /;
use Time::HiRes           qw/ alarm /;
use LWPx::ParanoidHandler qw//;
use Net::DNS::Paranoid    qw//;
use Carp                  qw//;

=head1 SYNOPSIS

    use LWP::UserAgent::Paranoid;
    my $ua = LWP::UserAgent::Paranoid->new(
        request_timeout => 5   # seconds; may be fractional
    );

    # use $ua as a normal LWP::UserAgent...
    my $response = $ua->get("http://example.com");

    # allow requests to localhost and 127.0.0.1
    $ua->whitelisted_hosts('localhost', '127.0.0.1');

=head1 DESCRIPTION

This module is a more modern L<LWPx::ParanoidAgent> with cleaner internals and
a very similar feature set.  It is a not a drop-in replacement, however, since
the API differs.

The primary features provided by this module:

=head2 Overall request timeout

A configurable timeout from start to finish of a "logical" request made by
calling one of L<LWP::UserAgent>'s request methods.  It encompasses all
followed redirects to ensure that you can't be tarpitted by a series of
stalling redirects.  The default is 5 seconds.

=head2 Blocked private hosts and IP address ranges

All new agents are automatically made paranoid of private hostnames and IP
address ranges using L<LWPx::ParanoidHandler>.  You may access the
L<Net::DNS::Paranoid> resolver via the L</resolver> method in order to
customize its behaviour.

For simple whitelisting and blacklisting, you may call L</whitelisted_hosts> or
L</blocked_hosts>.  These methods are proxied to the corresponding methods
of L<Net::DNS::Paranoid>.  The only difference is that you may pass a list to
this class' methods.

=head1 EVEN MORE PARANOIA

You may also wish to tune standard L<LWP::UserAgent> parameters for greater
paranoria depending on your requirements:

=head2 Maximum number of redirects

Although generally unnecessary given the request timeout, you can tune
L<LWP::UserAgent/max_redirects> down from the default of 7.

=head2 Protocols/URI schemes allowed

If you don't want to allow requests for schemes other than http and https, you
may use L<LWP::UserAgent/protocols_allowed> either as a method or as an option
to I<new>.

    $ua->protocols_allowed(["http", "https"]);

=head1 WHY NOT LWPx::ParanoidAgent?

L<LWPx::ParanoidAgent>'s implemention involves a 2009-era fork of LWP's http
and https protocol handlers, and it is no longer maintained.  A more
maintainable approach is taken by this module and L<LWPx::ParanoidHandler>.

=head1 METHODS

All methods from L<LWP::UserAgent> are available via inheritence.  In addition,
the following methods are available:

=head2 request_timeout

Gets/sets the timeout which encapsulates each logical request, including any
redirects which are followed.  The default is 5 seconds.  Fractional seconds
are OK.

=head2 resolver

Gets the DNS resolver which is used to block private hosts.  There is little
need to set your own but if you do it should be an L<Net::DNS::Paranoid>
object.  This attribute is read-only, so if you want to replace the resolver
you need to call L</new> again to create a new L<LWP::UserAgent::Paranoid>.

Use the blocking and whitelisting methods on the resolver, or this class'
L</whitelisted_hosts> and L</blocked_hosts>, to customize the behaviour.

=head2 whitelisted_hosts / blocked_hosts

Accepts a single arrayref and proxies to the method of the same name on the
L</resolver>.  For convenience, you may pass a list which will be passed as an
arrayref to the resolver's method.

=cut

sub new {
    my ($class, %opts) = @_;

    my $timeout = delete $opts{request_timeout};
       $timeout = 5 unless $timeout;

    my $resolver = delete $opts{resolver};
       $resolver = Net::DNS::Paranoid->new unless $resolver;

    for my $acl (qw(blocked_hosts whitelisted_hosts)) {
        next unless $opts{$acl};
        $resolver->$acl( delete $opts{$acl} );
    }

    my $self = $class->SUPER::new(%opts);
    $self->request_timeout($timeout);
    $self->_elem("resolver", $resolver);

    LWPx::ParanoidHandler::make_paranoid($self, $self->_resolver);

    return $self;
}

sub request_timeout { shift->_elem("request_timeout", @_) }
sub resolver        {
    my $self = shift;
    Carp::croak("resolver is read-only; to use a new resolver, create a new user agent")
        if @_;
    return $self->_resolver;
}
sub _resolver {
    shift->_elem("resolver");
}

sub blocked_hosts     { shift->_resolver->blocked_hosts(ref $_[0] ? $_[0] : \@_) }
sub whitelisted_hosts { shift->_resolver->whitelisted_hosts(ref $_[0] ? $_[0] : \@_) }

sub __timed_out { Carp::croak("Client timed out request") }
sub __with_timeout {
    my $method  = shift;
    my $self    = shift;
    my $SUPER   = $self->can("SUPER::$method")
        or Carp::croak("No such method '$method'");

    my $our_alarm = (
                ref($SIG{ALRM}) eq "CODE"
        and refaddr($SIG{ALRM}) eq refaddr(\&__timed_out)
    );

    if (not $our_alarm) {
        local $SIG{ALRM} = \&__timed_out;
        alarm $self->request_timeout;
        my $ret = $self->$SUPER(@_);
        alarm 0;
        return $ret;
    } else {
        return $self->$SUPER(@_);
    }
};

sub request        { __with_timeout("request",        @_) }
sub simple_request { __with_timeout("simple_request", @_) }

"The truth is out there.";

=head1 CAVEATS

The overall request timeout is implemented using SIGALRM.  Any C<$SIG{ALRM}>
handler from an outer scope is replaced in the scope of
L<LWP::UserAgent::Paranoid> requests.

=head1 BUGS

All bugs should be reported via
L<rt.cpan.org|https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Paranoid>
or L<bug-LWP-UserAgent-Paranoid@rt.cpan.org>.

=head1 AUTHOR

Thomas Sibley <tsibley@cpan.org>

=head1 LICENSE AND COPYRIGHT
 
This software is primarily Copyright (c) 2013 by Best Practical Solutions,
with parts of it Copyright (c) 2014-2015 by Thomas Sibley.
 
This is free software, licensed under:
 
  The GNU General Public License, Version 2, June 1991

=cut
