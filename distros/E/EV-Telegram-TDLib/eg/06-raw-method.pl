#!/usr/bin/env perl
# 06-raw-method.pl - the escape hatch: send() and execute() with raw requests
#
# Demonstrates: calling TDLib methods the mixins do not wrap.
#   call({...}) is the usual way in: it fills in @type from the method
#   name and rejects an argument name TDLib does not have, so a typo
#   fails here instead of coming back as an opaque server error.
#   execute({...}) is synchronous td_execute: no network, no authorization.
#   send({...}) is asynchronous: the reply arrives on the loop, correlated
#   by @extra. @extra is assigned by send() itself (and returned), so it
#   must never be set by hand; a caller-supplied value is overwritten.
# Both requests used here (getOption, parseTextEntities) work without any
# credentials, so auto_auth is off and no session database is written.
#
# Environment: none required. TD_API_ID/TD_API_HASH are picked up if set,
# but the requests below do not need them.
#
# Run: perl eg/06-raw-method.pl   (add -Mblib to run from a built checkout)

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

my $td = EV::Telegram::TDLib->new(
    api_id     => $ENV{TD_API_ID} // 0,
    api_hash   => $ENV{TD_API_HASH} // '',
    auto_auth  => 0,
    on_error   => sub { warn "tdlib: $_[0]\n" },
);

my $version = $td->execute({ '@type' => 'getOption', name => 'version' });
print "TDLib version: ", ($version ? $version->{value} : 'unknown'), "\n";

my $parsed = EV::Telegram::TDLib->execute({
    '@type' => 'parseTextEntities',
    text  => 'bold *here*',
    parse_mode => { '@type' => 'textParseModeMarkdown', version => 2 },
});
if ($parsed && ($parsed->{'@type'} // '') ne 'error') {
    print "entities: ", scalar(@{ $parsed->{entities} }), "\n";
}

# call() checks argument names against the shipped catalogue of every
# TDLib function before anything reaches the wire
my $bad = do {
    local $@;
    eval { $td->call(getOption => { nmae => 'version' }, sub {}) };
    $@;
};
print "call() rejected a typo: $bad" if $bad;

$td->call(getOption => { name => 'version' }, sub {
    my ($res, $err) = @_;
    print $err ? "call() failed: $err->{message}\n"
               : "call() reply: $res->{value}\n";
});

# a die inside a callback is contained and reported, not propagated, so it
# would leave the loop running and the script hanging: break out instead
my $status = 0;

my $extra = $td->send({ '@type' => 'getOption', name => 'version' }, sub {
    my ($res, $err) = @_;
    if ($err) {
        warn "getOption failed: $err->{message}\n";
        $status = 1;
        return EV::break;
    }
    print "async getOption reply: $res->{value}\n";
    $td->close(sub { EV::break });
});
print "request sent, assigned \@extra $extra\n";

EV::run;
exit $status;
