#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

plan skip_all => "set RELEASE_TESTING to run this test"
  unless $ENV{RELEASE_TESTING};

TODO: {
  local $TODO = "need to hash out what's what";

  all_pod_coverage_ok({
    coverage_class => 'Pod::Coverage::CountParents',
    also_private   => [ qr/^encode_/ ],
    trustme        => [ qw(
      extract_full_addrs
      extract_only_addrs
      fields_as_string
      fold
      gen_boundary
      is_mime_field
      my_extract_full_addrs
      my_extract_only_addrs
      print_for_smtp
      print_simple_body
      send_by_smtp_simple
      send_by_sub
      stringify
      stringify_body
      stringify_header
      suggest_encoding
      suggest_type
      top_level
    ) ],
  });
}
