=head1 NAME

83_execute_callbacks_deterministic_order.t - HAC-110: _execute_callbacks()
iterated 'keys %$sth' in Perl's randomized hash order while mutating
$sth in place, so a data callback reading a SIBLING data key's value (via
$o{data}{other_key}) saw either the resolved value or the raw CODE ref
depending purely on which order Perl's per-process hash randomization
happened to pick - the exact same script, run repeatedly, gave different
results. This is only observable across separate process invocations
(each with its own hash seed), not within a single process, so this test
spawns several perl subprocesses and asserts they all agree.
_execute_callbacks now sorts keys before iterating, so the same %data/
%headers structure resolves identically on every run.

=cut

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);

my $libdir = "$FindBin::Bin/../lib";

my ( $fh, $filename ) = tempfile( SUFFIX => '.pl', UNLINK => 1 );
print {$fh} <<"PERL";
use lib "$libdir";
use HTTP::API::Client;
my \$api = HTTP::API::Client->new();
my \$req = \$api->post("http://x/", {
    aaa => sub { "A_VALUE" },
    bbb => sub { my (undef,%o) = \@_; ref(\$o{data}{aaa}) eq "CODE" ? "UNRESOLVED" : "RESOLVED" },
}, {}, { test_request_object => 1 });
print \$req->content;
PERL
close $fh;

my %seen;
for my $seed ( 0, 1, 42, 12345, 999999 ) {
    local $ENV{PERL_HASH_SEED} = $seed;

    # Isolate the child from whatever instrumentation this test itself is
    # running under (e.g. PERL5OPT=-MDevel::Cover) - inheriting that would
    # make the child write to (and corrupt) the same coverage database the
    # parent process is using.
    local $ENV{PERL5OPT} = '';

    my $out = `"$^X" "$filename" 2>&1`;
    $seen{$out}++;
}

is scalar( keys %seen ), 1,
    "the same interdependent-callback data structure produces identical output across every hash seed tried: "
    . join( " | ", keys %seen );

done_testing;
