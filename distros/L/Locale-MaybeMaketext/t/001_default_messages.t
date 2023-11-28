#!perl
use strict;
use warnings;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use MaybeMaketextTestdata;

no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

# Check appropriate messages are emitted if maketext is called without
# a localizer being available or maketext is called without a handle/localizer.
unload_mocks();
Locale::MaybeMaketext::maybe_maketext_reset();
my @expected_localizers = sort( 'Cpanel::CPAN::Locale::Maketext::Utils',
    'Locale::Maketext::Utils',
    'Locale::Maketext' );
my @received_localizers = sort( Locale::MaybeMaketext::maybe_maketext_get_localizer_list() );
is( \@received_localizers, \@expected_localizers, 'Localizer list should be as expected' );

my @reasoning = Locale::MaybeMaketext::maybe_maketext_get_reasoning();
ok(
    $#reasoning < 0,     'Should have no initial reasoning',
    'Size',              $#reasoning,
    'Current reasoning', Dumper(@reasoning)
);

# now try and load a localizer (but have no where to load them from).
my $error = dies {
    local @INC = ( base_inc() );
    Locale::MaybeMaketext::get_handle('example');
};
ok( $error =~ /^Unable to load localizers/, 'get_handle without localizer available should error', $error );
@reasoning = Locale::MaybeMaketext::maybe_maketext_get_reasoning();
my $attempt       = 'Attempting to load';
my $qmattempt     = quotemeta($attempt);
my $attempt_index = find_index_by_partial( $attempt, @reasoning );
my $next          = test_data_iterator();
while ( my $package = $next->() ) {
    my $package_name = $package->get_name();
    my $notloaded    = sprintf( '%s: No record of load attempt found', $package_name );
    my $expect       = sprintf(
        '%s: Unable to set as parent localizer due to "Can\'t locate %s in ', $package_name,
        $package->get_path()
    );
    my ( $qmnotloaded, $qmexpect ) = ( quotemeta($notloaded), quotemeta($expect) );
    ok(
        $error =~ /$qmnotloaded/,
        sprintf( 'Error message should list "%s" as not loaded', $package_name ),
        'Looked for ', $notloaded,
        'Full error',
        $error
    );
    ok(
        $error =~ /$qmexpect/,
        sprintf( 'Error message should list "%s" as attempted to load', $package_name ),
        'Looked for ', $expect,
        'Full error',
        $error
    );
    ok(
        $error =~ /$qmnotloaded.*$qmattempt.*$qmexpect/s,
        sprintf( 'Error message should list "%s" as not loaded and later attempt to load it', $package_name ),
        (
            'Looked for: ', "$qmnotloaded.*$qmattempt.*$qmexpect",
            'Error:',       $error
        )
    );
    my ( $notloaded_index, $expect_index ) =
      ( find_index_by_partial( $notloaded, @reasoning ), find_index_by_partial( $expect, @reasoning ) );
    ok(
        $notloaded_index < $attempt_index && $expect_index > $attempt_index,
        sprintf( '%s: "Not loaded" be before "attempting" which should be before "load attempt"', $package_name ),
        (
            'Not loaded index', $notloaded_index,
            'Attempt index',    $attempt_index,
            'Expect index',     $expect_index,
        )
    );
}

# now just try making text without a localizer
$error = dies {
    local @INC = ();
    Locale::MaybeMaketext->maketext('example');
};
ok( $error =~ /^maketext called without get_handle/, 'maketext should error if called without localizer', $error );
done_testing();

sub find_index_by_partial ( $text, @array ) {
    my $quoted = quotemeta($text);
    for my $index ( 0 .. $#array ) {
        if ( $array[$index] =~ /^$quoted/ ) {
            return $index;
        }
    }
    fail( 'Failed to find text in array', ( 'Looked for', $text, 'Array', @array ) );
    croak('Should fail');
}
