use Test::Carp;

use Test::More tests => 10;

use Locale::Maketext::Utils::Phrase::Norm;

package TestApp::Localize;

use Locale::Maketext::Utils;
use base 'Locale::Maketext::Utils';

our $Encoding = 'utf8';

our %Lexicon = (
    '_AUTO'    => 42,
    'Fallback' => 'Fallback orig',
    'One Side' => 'I am not one sides',
);

__PACKAGE__->make_alias( 'i_alias1', 1 );

package TestApp::Localize::en;
use base 'TestApp::Localize';

sub chuck_norris {
    return 'PAIN';
}

package main;

my $ok_obj = TestApp::Localize->get_handle();

my $no_arg = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Compiles', { 'skip_defaults_when_given_filters' => 1 } );
my $good_arg = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Compiles', { 'skip_defaults_when_given_filters' => 1, 'maketext_object' => $ok_obj } );

does_carp_that_matches(
    sub {
        my $o = Locale::Maketext::Utils::Phrase::Norm->new_source( { 'maketext_object' => Locale::Maketext::Utils::Phrase::Norm->new_source() } );
        ok( !$o, 'new_source() returns false' );
    },
    qr/Given maketext object does not have a makethis\(\) method\./,
);
does_carp_that_matches(
    sub {
        my $o = Locale::Maketext::Utils::Phrase::Norm->new_source( { 'maketext_object' => 'not a ref' } );
        ok( !$o, 'new_source() returns false' );
    },
    qr/Given maketext object is not a reference./,
);

ok( !$no_arg->normalize('Hello [chuck_norris]!')->get_status(),  'default fails on unknown method' );
ok( $good_arg->normalize('Hello [chuck_norris]!')->get_status(), 'given works with otherwise unknown method' );

# get_maketext_object();
is( ref( $no_arg->get_maketext_object() ),   'Locale::Maketext::Utils::Mock::en', 'no maketext_object argument defaults to class name' );
is( ref( $good_arg->get_maketext_object() ), 'TestApp::Localize::en',             'maketext_object argument is returned by get_maketext_object()' );

# set_maketext_object()
is( ref( $no_arg->set_maketext_object($ok_obj) ), 'TestApp::Localize::en', 'maketext_object argument returned in set_maketext_object()' );
is( ref( $no_arg->get_maketext_object() ),        'TestApp::Localize::en', 'set_maketext_object() did chnage the object' );
