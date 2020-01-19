#!perl

use Test::More;

plan skip_all => "\$ENV{RELEASE_TESTING} required for these tests" if(!$ENV{RELEASE_TESTING});

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 1;

#my $private_subs = { private => [qr/^(BUILD|_callback_maker|_init_jabber|_process_jabber_message|_request_version|_send_individual_message)$/] };
pod_coverage_ok('IO::Stty', $private_subs, "Test IO::Stty for docs. Private functions not listed in docs");
