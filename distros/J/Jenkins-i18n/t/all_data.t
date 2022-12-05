use strict;
use warnings;
use Test::More;

# TODO: this must be a temporary workaround, we should be able to point
# to a different directory
use Cwd;
my $path = 't/samples/mixed';
chdir($path) or die "Cannot cd to $path: $!";
my $current_dir = getcwd;

use Jenkins::i18n::ProcOpts;
use Jenkins::i18n qw(all_data);

my $processor = Jenkins::i18n::ProcOpts->new(
    {
        source_dir  => $current_dir,
        target_dir  => $current_dir,
        use_counter => 0,
        is_remove   => 0,
        is_add      => 0,
        is_debug    => 0,
        lang        => 'pt_BR',
        search      => undef
    }
);

my $file = 'buildCaption.jelly';
note("Using $file as input for all_data");

my ( $jelly_entries_ref, $lang_entries_ref, $english_entries_ref )
    = all_data( $file, $processor );
is( ref($jelly_entries_ref), 'HASH', 'first result is the proper reference' );
my $current_keys = sorted_keys($jelly_entries_ref);
is_deeply(
    $current_keys,
    [ 'Progress', 'cancel', 'confirm' ],
    'got the expected keys from the Jelly file'
) or diag( explain($jelly_entries_ref) );

is( ref($lang_entries_ref), 'HASH', 'second result is the proper reference' );
$current_keys = sorted_keys($lang_entries_ref);
is_deeply(
    $current_keys,
    [ 'Progress', 'cancel', 'confirm' ],
    'got the expected keys from the current language Properties file'
) or diag( explain($lang_entries_ref) );

is( ref($english_entries_ref),
    'HASH', 'third result is the proper reference' );
is_deeply( sorted_keys($english_entries_ref),
    ['confirm'], 'got the expected keys from the English properties file' )
    or diag( explain($english_entries_ref) );

done_testing;

sub sorted_keys {
    my $hash_ref = shift;
    my @values   = sort( keys( %{$hash_ref} ) );
    return \@values;
}
