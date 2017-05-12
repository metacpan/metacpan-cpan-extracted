package LWPx::ParanoidHandler;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.07';
use parent qw/Exporter/;
use Net::DNS::Paranoid;

our @EXPORT = qw/make_paranoid/;

sub make_paranoid {
    my ($ua, $paranoid) = @_;
    $ua->add_handler(request_send => _paranoid_handler($paranoid));
}

sub _paranoid_handler {
    my ($paranoid) = @_;
    $paranoid ||= Net::DNS::Paranoid->new();

    sub {
        my ($request, $ua, $h) = @_;
        $request->{_time_begin} ||= time();

        my $host = $request->uri->host;
        my ($addrs, $errmsg) = $paranoid->resolve($host, $request->{_time_begin});
        if ($errmsg) {
            my $err_res = HTTP::Response->new(403, "Unauthorized access to blocked host($errmsg)");
            $err_res->request($request);
            $err_res->header("Client-Warning" => "Internal response");
            $err_res->header("Content-Type" => "text/plain");
            $err_res->content("403 Unauthorized access to blocked host\n");
            return $err_res;
        }
        return; # fallthrough
    }
}

1;
__END__

=encoding utf8

=head1 NAME

LWPx::ParanoidHandler - Handler for LWP::UserAgent that protects you from harm

=head1 SYNOPSIS

    use LWPx::ParanoidHandler;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    make_paranoid($ua);

    my $res = $ua->request(GET 'http://127.0.0.1/');
    # my $res = $ua->request(GET 'http://google.com/');
    use Data::Dumper; warn Dumper($res);
    warn $res->status_line;

=head1 DESCRIPTION

LWPx::ParanoidHandler is clever fire wall for LWP::UserAgent.
This module provides a handler to protect a request to internal servers.

It's useful to implement OpenID servers, crawlers, etc.

=head1 FUNCTIONS

=over 4

=item make_paranoid($ua[, $dns]);

Make your LWP::UserAgent instance to paranoid.

The $dns argument is instance of L<Net::DNS::Paranoid>. It's optional.

=back

=head1 FAQ

=over 4

=item How can I timeout per request?

Yes, L<LWP::UserAgent> does not timeouts per request.

I think it's my job. But L<LWPx::ParanoidAgent> do this.

You can do this by following form using alarm():

    my $res = eval {
        local $SIG{ALRM} = sub { die "ALRM\n" };
        alarm(10);
        my $res = $ua->get($url);
        alarm(0);
        $res;
    };
    $res = HTTP::Response->new(500, 'Timeout') unless $res;

And I recommend to use L<Furl>. Furl can handle per-request timeout cleanly.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<LWPx::ParanoidAgent> have same feature as this module. But it's not currently maintain, and it's too hack-ish. LWPx::ParanoidHandler uses handler protocol provided by LWP::UserAgent, it's more safety.

This module uses a lot of code taken from LWPx::ParanoidAgent, thanks.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
