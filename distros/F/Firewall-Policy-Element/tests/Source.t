#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::Policy::Element::Source;

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

my $source;

ok(
  do {
    eval { $source = Firewall::Policy::Element::Source->new( ruleSign => 3, fwId => 5 ); };
    warn $@ if $@;
    $source->isa('Firewall::Policy::Element::Source');
  },
  ' 生成 Firewall::Policy::Element::Source 对象'
);
