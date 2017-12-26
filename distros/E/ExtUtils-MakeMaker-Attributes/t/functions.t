use strict;
use warnings;
use Test::More;
use ExtUtils::MakeMaker::Attributes ':all';
use version;

my @attributes = known_eumm_attributes;
isnt 0+@attributes, 0, 'has known attributes';

ok is_known_eumm_attribute('NAME'), 'NAME is a known attribute';
ok !is_known_eumm_attribute('DEADBEEF'), 'DEADBEEF is not a known attribute';

is +version->parse(eumm_attribute_requires_version('NAME')),
  version->parse('0'), 'NAME does not require a version';
is +version->parse(eumm_attribute_requires_version('MAGICXS')),
  version->parse('6.8305'), 'MAGICXS requires version 6.8305';

is eumm_attribute_fallback('MAGICXS'), undef, 'MAGICXS has no fallback';
is_deeply eumm_attribute_fallback('TEST_REQUIRES'),
  {method => 'merge_prereqs', merge_target => 'PREREQ_PM'},
  'TEST_REQUIRES has a fallback';

my @supported = eumm_version_supported_attributes('6.55_03');
ok +(grep { $_ eq 'BUILD_REQUIRES' } @supported), '6.55_03 supports BUILD_REQUIRES';
ok !(grep { $_ eq 'TEST_REQUIRES' } @supported), '6.55_03 does not support TEST_REQUIRES';

@supported = perl_version_supported_attributes('v5.10.1');
ok +(grep { $_ eq 'INSTALLSCRIPT' } @supported), 'Perl 5.10.1 supports INSTALLSCRIPT';
ok !(grep { $_ eq 'NO_MYMETA' } @supported), 'Perl 5.10.1 does not support NO_MYMETA';

done_testing;
