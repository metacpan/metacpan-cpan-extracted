package FCGI::EV::Std;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.0';

use Scalar::Util qw( weaken );

use if $INC{'CGI.pm'}, 'CGI::Stateless';


use constant HTTP_417_EXPECTATION_FAILED =>
    "Status: 417 Expectation Failed\r\n"
  . "Content-Type: text/html\r\n"
  . "\r\n"
  . '<html><head><title>417 Expectation Failed</title></head>'
  . '<body><h1>Expectation Failed</h1>'
  . '<p>Request entity too large or incomplete.</p></body></html>'
  ;

use constant MiB => 1*1024*1024;    ## no critic (Capitalization)

our $BLOCKING   = 1;
our $MAX_STDIN  = MiB;
our $MAIN       = \&main::main;
our $HUP        = undef;


sub new {
    my ($class, $server, $env) = @_;
    my $len = $env->{CONTENT_LENGTH} || 0;
    my $self = bless {
        server  => $server,
        env     => $env,
        stdin   => q{},
        allow   => $len <= $MAX_STDIN,
    }, $class;
    weaken($self->{server});
    return $self;
}

# No protection against reading STDIN larger than CONTENT_LENGTH - because
# FastCGI protocol FORBID this so web server shouldn't send so much data
# ( http://www.fastcgi.com/devkit/doc/fcgi-spec.html#S6.2 ).
#
# If huge files will be uploaded it MAY have sense to save STDIN to
# secure tempfile - but code which parse POST data from STDIN in CGI also
# shouldn't read all STDIN into memory, or this feature will not help.
sub stdin {
    my ($self, $stdin, $is_eof) = @_;
    if ($self->{allow}) {
        $self->{stdin} .= $stdin;
    }
    if ($is_eof) {
        if (length $self->{stdin} != ($self->{env}{CONTENT_LENGTH} || 0)) {
            $self->{server}->stdout(HTTP_417_EXPECTATION_FAILED, 1);
        }
        else {
            local *STDIN;
            open STDIN, '<', \$self->{stdin}        or die "open STDIN: $!\n";
            local %ENV = %{ $self->{env} };
            if ($INC{'CGI/Stateless.pm'}) {
                local $CGI::Q = CGI::Stateless->new();
                $self->_run();
            }
            else {
                $self->_run();
            }
        }
    }
    return;
}

sub _run {
    my ($self) = @_;
    if ($BLOCKING) {
        local *STDOUT;
        my $reply = q{};
        open STDOUT, '>', \$reply           or die "open STDOUT: $!\n";
        $MAIN->();
        $self->{server}->stdout($reply, 1);
    }
    else {
        $MAIN->($self->{server});
    }
    return;
}

sub DESTROY {
    my ($self) = @_;
    if (!$BLOCKING && $HUP) {
        $HUP->($self->{server});
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

FCGI::EV::Std - Handler class to use with FCGI::EV


=head1 VERSION

This document describes FCGI::EV::Std version v2.0.0


=head1 SYNOPSIS

    use FCGI::EV::Std;

    # configuration example
    $FCGI::EV::Std::BLOCKING   = 0;
    $FCGI::EV::Std::MAX_STDIN  = 10*1024*1024;
    $FCGI::EV::Std::MAIN       = \&nonblocking_main;
    $FCGI::EV::Std::HUP        = \&hup;

    # for usage example see FCGI::EV module SYNOPSIS

=head1 DESCRIPTION

This module must be used together with FCGI::EV. It will handle CGI
requests received by FCGI::EV. Both blocking and non-blocking CGI request
handling supported.

It will validate size of STDIN: do not accept size larger than configured
in $MAX_STDIN (1 MB by default), do not accept incomplete STDIN (less
than $ENV{CONTENT_LENGTH} bytes) - in both cases HTTP reply "417
Expectation Failed" will be returned to browser.

In non-blocking mode it optionally may call user callback function if web
server disconnect before CGI sent it reply (to interrupt processing this
request, if possible).

It compatible with CGI.pm (CGI.pm must be loaded before FCGI::EV::Std
to activate this feature, and you'll need CGI::Stateless module), but may
also work with other modules which parse CGI parameters - in this case
these modules must support work in persistent environment and user
probably has to re-initialize that module state between requests.


=head1 INTERFACE 

There no user-callable methods in this module. Instead, it will call user
functions.

In default configuration it will work in blocking mode and
will call main::main() on each incoming request, with prepared %ENV,
STDIN and STDOUT, so user code may work just as usual CGI application.
Other CGI requests will not be processed until main::main() returns.
Data printed by main::main() to STDOUT will be sent to web server only
after main::main() returns.

It also possible to configure FCGI::EV::Std to work in non-blocking mode.
In this case on each incoming requests it will call main::main($server),
where $server is FCGI::EV object. In this case main::main() shouldn't
do any blocking operations (like using SQL database) but may setup any
events (I/O, timer, etc.) using EV module and should returns quickly.
Other CGI requests will be processed in parallel while this CGI request
wait for events. After CGI will have some data to send, it should use
$server->stdout($data, $is_eof) method (if $server is still defined - it
may become undef if connection to web server related to this CGI request
was already closed). In addition, FCGI::EV::Std may be configured to call
any user function, say, main::hup($server) if connection to web server will
be closed before CGI sent it reply. WARNING! User shouldn't keep
non-weaken() references to $server in it code!

See also L<FCGI::EV::Std::Nonblock> - it's helper module which make
writing non-blocking CGI ease.

Use these global variables to configure FCGI::EV::Std:

=over

=item $FCGI::EV::Std::BLOCKING = 1

If true, then user function set in $FCGI::EV::Std::MAIN will be called in
blocking mode and without any parameters.

If false, then user function set in $FCGI::EV::Std::MAIN will be called in
non-blocking mode, with parameter $server. Also, if $FCGI::EV::Std::HUP set
to user function, then it will be called if connection to web server is
closed before CGI sent it reply.

=item $FCGI::EV::Std::MAX_STDIN = 1*1024*1024

Limit on STDIN size. Increase if you need to receive large files using POST.

=item $FCGI::EV::Std::MAIN = \&main::main

User function called to process (or start processing in non-blocking mode)
incoming CGI request.

=item $FCGI::EV::Std::HUP = undef

User function called only in non-blocking mode to
notify about closed connection and, if possible, interrupt current CGI
request.

This function got one parameter - $server object. It's same $server as was
given to $FCGI::EV::Std::MAIN function when this request was started (this
is how user can identify which of currently executing requests was
interrupted). The $server object will be destroyed shortly after that.

=back

=head1 DIAGNOSTICS

=over

=item C<< open STDIN: %s >>

=item C<< open STDOUT: %s >>

If anybody will see that, then probably your perl is broken. :)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-FCGI-EV-Std/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-FCGI-EV-Std>

    git clone https://github.com/powerman/perl-FCGI-EV-Std.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=FCGI-EV-Std>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/FCGI-EV-Std>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FCGI-EV-Std>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=FCGI-EV-Std>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/FCGI-EV-Std>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
