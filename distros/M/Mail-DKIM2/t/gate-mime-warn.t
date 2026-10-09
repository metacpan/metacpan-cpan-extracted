#!/usr/bin/perl
# Mail::DKIM2::Gate->check must not leak Email::MIME's parser warnings
# ("Extra semicolon after last parameter", "Illegal parameter ...") for
# real-world mail with a malformed Content-Type; the decision is unchanged.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mail::DKIM2::Gate;

my $EOL = "\015\012";
sub msg {
    my ($ct) = @_;
    return join($EOL, 'Message-Id: <a@example.com>', 'Date: Thu, 10 Sep 2026 15:47:11 +1000',
        'From: a@example.com', 'To: b@example.org', 'Subject: x', 'MIME-Version: 1.0',
        "Content-Type: $ct", '', 'hello', '');
}

for my $case (
    ['trailing semicolon', 'text/plain; charset=Windows-1252;'],
    ['illegal parameter',  'text/plain; Windows-1252'],
    ['well-formed',        'text/plain; charset=utf-8'],
) {
    my ($name, $ct) = @$case;
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    my $r = Mail::DKIM2::Gate->check(msg($ct));
    is_deeply(\@w, [], "$name: no warnings") or diag(@w);
    ok($r->{ok}, "$name: unsigned message still ok to sign");
}
done_testing;
