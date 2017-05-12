use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::RFC5322;
use Test::More;

my $modulename = 'Haineko::SMTPD::RFC5322';
my $pkgmethods = [ 'is_emailaddress', 'is_domainpart' ];
my $objmethods = [ '' ];
my $emailaddrs = [ qw/
    kijitora@example.jp
    neko+nyanko@example.jp
    neko=nya---@example.jp
/ ];
my $isnotemail = [ qw/
    nyanko
    sabatora
    @
/ ];
my $domainpart = [ qw/
    example.jp
    example.org
    neko.example.com
/ ];

can_ok $modulename, @$pkgmethods;
for my $e ( @$emailaddrs ) {
    is $modulename->is_emailaddress( $e ), 1, '->is_emailaddress('.$e.')';
}

for my $e ( @$isnotemail ) {
    is $modulename->is_emailaddress( $e ), 0, '->is_emailaddress('.$e.')';
}

for my $e ( @$domainpart ) {
    is $modulename->is_domainpart( $e ), 1, '->is_domainpart('.$e.')';
}

for my $e ( @$emailaddrs, @$isnotemail ) {
    is $modulename->is_domainpart( $e ), 0, '->is_domainpart('.$e.')';
}

done_testing;
__END__
