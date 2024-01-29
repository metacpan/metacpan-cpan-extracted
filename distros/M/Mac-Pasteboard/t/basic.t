package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Mac::Pasteboard'
    or BAIL_OUT 'Can not continue without loadable Mac::Pasteboard';

SKIP: {
    Mac::Pasteboard->set( fatal => 0 );
    if ( my $pb = Mac::Pasteboard->new() ) {
	isa_ok $pb, 'Mac::Pasteboard'
    } else {
	my $status = Mac::Pasteboard->get( 'status' );
	$status == Mac::Pasteboard::coreFoundationUnknownErr()
	    and skip 'No access to desktop (maybe running as ssh session or cron job?)', 1;
	fail "Failed to instantiate Mac::Pasteboard: $status";
    }
    Mac::Pasteboard->set( fatal => 1 );
}

is( Mac::Pasteboard->flavor_flag_names( 0 ), 'kPasteboardFlavorNoFlags',
    'Flavor flag 0 is kPasteboardFlavorNoFlags' );

is( Mac::Pasteboard->flavor_flag_names( 1 ), 'kPasteboardFlavorSenderOnly',
    'Flavor flag 1 is kPasteboardFlavorSenderOnly' );

is( Mac::Pasteboard->flavor_flag_names( 2 ),
    'kPasteboardFlavorSenderTranslated',
    'Flavor flag 2 is kPasteboardFlavorSenderTranslated' );

is( Mac::Pasteboard->flavor_flag_names( 3 ),
    'kPasteboardFlavorSenderOnly, kPasteboardFlavorSenderTranslated',
    'Flavor flag 3 is kPasteboardFlavorSenderOnly, kPasteboardFlavorSenderTranslated' );

is( Mac::Pasteboard->flavor_flag_names( 4 ), 'kPasteboardFlavorNotSaved',
    'Flavor flag 4 is kPasteboardFlavorNotSaved' );

is( Mac::Pasteboard->flavor_flag_names( 8 ), 'kPasteboardFlavorRequestOnly',
    'Flavor flag 8 is kPasteboardFlavorRequestOnly' );

is( Mac::Pasteboard->flavor_flag_names( 256 ),
    'kPasteboardFlavorSystemTranslated',
    'Flavor flag 256 is kPasteboardFlavorSystemTranslated' );

is( Mac::Pasteboard->flavor_flag_names( 512 ), 'kPasteboardFlavorPromised',
    'Flavor flag 512 is kPasteboardFlavorPromised' );

is( Mac::Pasteboard->flavor_tags(
	'com.apple.traditional-mac-plain-text' )->{os},
    ( Mac::Pasteboard::xs_pbl_is_at_least_monterey() ? undef : 'TEXT' ),
    'OS flavor tag for com.apple.traditional-mac-plain-text' );

done_testing;

1;

# ex: set textwidth=72 :
