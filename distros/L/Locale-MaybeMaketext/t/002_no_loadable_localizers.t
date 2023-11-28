#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

# Check the appropriate error is emitted if there are no localizers available.
unload_mocks();
Locale::MaybeMaketext::maybe_maketext_reset();

my $error = dies {
    local @INC = ( base_inc() );
    Locale::MaybeMaketext::maybe_maketext_get_localizer();
};
ok( $error =~ /^Unable to load localizers/, 'Should not be able to find any localizers', $error );

my $base =
    '- %s: Unable to set as parent localizer due to "Can\'t locate %s in @'
  . 'INC (you may need to install the %s module)';

my $next = test_data_iterator();
while ( my $package = $next->() ) {
    my $substr = sprintf( $base, $package->get_name(), $package->get_path(), $package->get_name() );
    ok(
        index( $error, $substr ) != -1,    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        sprintf( 'Should be unable to find %s', $package->get_name() )
    );
}
done_testing();
