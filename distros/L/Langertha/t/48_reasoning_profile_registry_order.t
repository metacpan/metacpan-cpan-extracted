#!/usr/bin/env perl
# ABSTRACT: The reasoning registry builds without the gpt-5.N passthrough row (karr k196)

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Reasoning;
use Langertha::Reasoning::Profile;

# karr k196 (M3): each chat carve-out copies the profile its family id resolves
# to. When that id matches no family row it falls through to the provider
# default, so the default must exist before the carve-outs are built. Before
# k196 the carve-outs were built first: dropping the uncurated gpt-5\.\d
# passthrough row (a plausible curation step) made loading the registry die on
# an undefined default instead of degrading gpt-5.7 & co. to "unknown id".
#
# The registry is built lazily on the first for_model call, so this file must
# remove the row before anything resolves an id -- keep it the first call here.

{
  no warnings 'redefine';
  my $orig = \&Langertha::Reasoning::Profile::_family_profiles;
  *Langertha::Reasoning::Profile::_family_profiles = sub {
    # Identify the row by its model_match pattern, not by its source prose.
    my @rows = grep { $_->model_match ne qr/\Agpt-5\.\d(?!\d)/ } $orig->();
    die "passthrough row not found -- update this test\n"
      if @rows == scalar( () = $orig->() );
    return @rows;
  };
}

my $profile = eval { Langertha::Reasoning::Profile->for_model('gpt-5.7-chat') };
ok( defined $profile, 'registry builds without the gpt-5.N passthrough row' )
  or diag $@;

SKIP: {
  skip 'registry failed to build', 3 unless defined $profile;
  is( $profile->is_reasoning_model, 0, 'gpt-5.7-chat stays non-reasoning' );
  is( Langertha::Reasoning::Profile->for_model('gpt-5.7')->is_reasoning_model, 0,
    'gpt-5.7 degrades to the unknown-id default (non-reasoning)' );
  is_deeply(
    { Langertha::Reasoning->new( model => 'gpt-5.7-chat', effort => 'xhigh' )->to('openai') },
    { Langertha::Reasoning->new( model => 'some-unknown-model', effort => 'xhigh' )->to('openai') },
    'gpt-5.7-chat serializes like the unknown-id default' );
}

done_testing;
