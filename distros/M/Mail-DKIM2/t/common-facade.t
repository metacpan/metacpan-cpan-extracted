use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Until 0.31 Mail::DKIM2::Common held everything the modules shared. Most of
# it now lives in Canon, Fold, Address, Key and RecipeJSON, but callers
# outside this distribution (Topicbox, hm's lmtpprox) import these names
# from Common and call them as Mail::DKIM2::Common::NAME. Both must go on
# working, and give the same function as the module that now owns it.

use Mail::DKIM2::Common ();

my %moved = (
    Canon      => [qw(build_signing_input check_ignore_prefixes dkim2_canonicalize_header
                      dkim2_canonicalize_sig_header field_name header_values should_skip)],
    Fold       => [qw(fold_header)],
    Address    => [qw(domain_of extract_domain from_authentic from_domain from_mailbox
                      from_pair_error from_refusal_note parent_from_matcher
                      relaxed_domain_match to_alabel to_rfc5321_path)],
    Key        => [qw(domain_policy key_records load_private_key load_private_key_data
                      parse_dkim_key_record parse_dkim_pubkey policy_from_source
                      query_domain_policy signature_algorithm signature_algorithm_for_key)],
    RecipeJSON => [qw(decode_tag_json encode_tag_json)],
);
my @stayed = qw(
    DKIM2_DATE DKIM2_DRAFT DKIM2_REPO EXPIRY FUTURE_LIMIT MAX_CHAIN_LENGTH MAX_CHAIN_NUMBER
    MAX_SIGNATURE_ITEMS MI_MISSING_M_ERROR UNKEYABLE_SIGNATURE_ERROR
    chain_length_error chain_number_error combine_sets duplicate_number_error
    extract_mi_version mi_version_tag parse_mime split_any_all strip_mi_versions
    unkeyable_signature_error valid_sequence
);

for my $module (sort keys %moved) {
    my $package = "Mail::DKIM2::$module";
    for my $name (@{ $moved{$module} }) {
        my $here = Mail::DKIM2::Common->can($name);
        ok($here, "Mail::DKIM2::Common::$name is callable");
        is($here, $package->can($name), "... and is ${package}'s");
        ok(eval { Mail::DKIM2::Common->import($name); 1 }, "... and importable from Common")
            or diag $@;
        ok(eval { $package->import($name); 1 }, "... and from $package") or diag $@;
    }
}
for my $name (@stayed) {
    ok(Mail::DKIM2::Common->can($name), "Mail::DKIM2::Common::$name is still here");
    ok(eval { Mail::DKIM2::Common->import($name); 1 }, '... and importable') or diag $@;
}

# As an outside caller writes it.
is(Mail::DKIM2::Common::extract_domain('<a@Example.com>'), 'Example.com', 'extract_domain');
ok(Mail::DKIM2::Common::from_authentic('example.com', 'A <a@lists.example.com>'), 'from_authentic');
ok(Mail::DKIM2::Common::relaxed_domain_match('a.example.com', 'example.com'), 'relaxed_domain_match');
ok(Mail::DKIM2::Common::should_skip('X-Anything'), 'should_skip');
like(Mail::DKIM2::Common::fold_header('X-DKIM2-Info: ' . join('; ', map { "tag$_=value$_" } 1 .. 12)),
     qr/\r\n\t/, 'fold_header');
is(Mail::DKIM2::Common::load_private_key_data('not a key'), undef, 'load_private_key_data');

done_testing;
