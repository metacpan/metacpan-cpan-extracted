use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

my $dtx = DateTimeX::Web->new;

# no "Can't call method "isa" without a package or object reference"

eval { $dtx->_datetime( 123456 ) };

ok $@ =~ /Odd number of/, $@;

eval { $dtx->from( 123456 ) };

ok $@ =~ /Odd number of/, $@;

eval { $dtx->time_zone( 123456 ) };

ok !$@, ref $dtx->time_zone; # happen to be DT::TZ::OffsetOnly

eval { $dtx->time_zone( 'foo' ) };

ok $@ =~ /Invalid /, $@;

eval { $dtx->locale( 123456 ) };

ok $@ =~ /Invalid /, $@;


eval { $dtx->_datetime( { epoch => 123456 } ) };

ok !$@; # As of 0.03, constructors get looser

eval { $dtx->from( { epoch => 123456 } ) };

ok !$@;  # As of 0.03, constructors get looser

eval { $dtx->time_zone( { } ) };

ok $@ =~ /(?:not one of the allowed types|Validation failed for type)/, $@;

eval { $dtx->locale( { } ) };

ok $@ =~ /(?:not one of the allowed types|Validation failed for type)/, $@;

eval { $dtx->_datetime( [ epoch => 123456 ] ) };

ok !$@;  # As of 0.03, constructors get looser

eval { $dtx->from( [ epoch => 123456 ] ) };

ok !$@;  # As of 0.03, constructors get looser

eval { $dtx->time_zone( [ ] ) };

ok $@ =~ /(?:not one of the allowed types|Validation failed for type)/, $@;

eval { $dtx->locale( [ ] ) };

ok $@ =~ /(?:not one of the allowed types|Validation failed for type)/, $@;
