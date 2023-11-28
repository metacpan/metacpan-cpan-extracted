#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

unload_mocks();
Locale::MaybeMaketext::maybe_maketext_reset();
my $error = dies {
    local @INC = ( fault_inc(), base_inc() );
    local %INC = %INC;
    my $next = test_data_iterator();
    while ( my $package = $next->() ) {
        if ( $package->is_undef_needed_for_fault() ) {
            $INC{ $package->get_path() } = undef;    ## no critic (Variables::RequireLocalizedPunctuationVars)
        }
    }
    local $INC{'Locale/Maketext/Utils.pm'} = undef;
    Locale::MaybeMaketext::get_handle('example');
};
ok( $error =~ /^Unable to load localizers/, 'Should fail to load any localizers', $error );
my $next = test_data_iterator();
while ( my $package = $next->() ) {
    my $quotedmessage = quotemeta( $package->get_fault_message() );
    ok(
        $error =~ /$quotedmessage/,
        sprintf( '%s should have failed', $package->get_name() ),
        (
            'Expected to find:', $package->get_fault_message(),
            'Full error text:',  $error
        )
    );
}
done_testing();
