#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::Policy::Element::Destination;

=lala
has fwId => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has ruleSign => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has ranges => (
    is => 'ro',
    isa => 'Firewall::Utils::Set',
    builder => '_buildRanges',
);
=cut

my $destination;

ok(
  do {
    eval { $destination = Firewall::Policy::Element::Destination->new( fwId => 1, ruleSign => 3 ); };
    warn $@ if $@;
    $destination->isa('Firewall::Policy::Element::Destination');
  },
  ' 生成 Firewall::Policy::Element::Destination 对象'
);
