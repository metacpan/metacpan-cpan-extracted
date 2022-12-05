use strict;
use warnings;
use Test::More tests => 4;

use Jenkins::i18n
    qw(find_files load_properties load_jelly find_langs all_data merge_data find_missing );
use Jenkins::i18n::Stats;
use Jenkins::i18n::Warnings;
use Jenkins::i18n::ProcOpts;
use Jenkins::i18n::Assertions qw(has_empty can_ignore has_hudson);

my $path = 't/samples/mixed';

# TODO: this must be a temporary workaround, we should be able to point
# to a different directory
use Cwd;
chdir($path) or die "Cannot cd to $path: $!";
my $current_dir = getcwd;

# TODO: copied from the CLI, must be refactored to import functions instead

my $all_langs = find_langs($current_dir);
my $result    = find_files( $current_dir, $all_langs );
is( $result->size, 2, 'Got the expected number of files' );
my $stats     = Jenkins::i18n::Stats->new;
my $warnings  = Jenkins::i18n::Warnings->new(1);
my $processor = Jenkins::i18n::ProcOpts->new(
    {
        source_dir  => $current_dir,
        target_dir  => $current_dir,
        use_counter => 0,
        is_remove   => 0,
        is_add      => 0,
        is_debug    => 1,
        lang        => 'pt_BR',
        search      => 'foobar'
    }
);

my $next_file = $result->files;

while ( my $file = $next_file->() ) {
    $stats->inc_files;

    # we need only the current language file to compare the translations
    # that's why we are double calling define_files()
    my $curr_lang_file = ( $processor->define_files($file) )[0];
    my ( $jelly_entries_ref, $lang_entries_ref, $english_entries_ref )
        = all_data( $file, $processor );

    # TODO: invoke merge_data() from all_data(), since only merged keys
    # will be in use?
    my $merged_ref = merge_data( $jelly_entries_ref, $english_entries_ref );
    find_missing( $merged_ref, $lang_entries_ref, $stats, $warnings );

    foreach my $entry ( keys %{$lang_entries_ref} ) {
        unless ( defined $jelly_entries_ref->{$entry} ) {
            $stats->inc_unused;
            $warnings->add( 'unused', $entry );
        }
    }

    foreach my $entry ( keys %{$lang_entries_ref} ) {
        if (   $lang_entries_ref->{$entry}
            && $english_entries_ref->{$entry}
            && $lang_entries_ref->{$entry} eq $english_entries_ref->{$entry} )
        {
            unless ( can_ignore( $lang_entries_ref->{$entry} ) ) {
                $stats->inc_same;
                $warnings->add( 'same', $entry );
            }
            else {
                $warnings->add( 'ignored', $entry );
            }
        }
    }

    foreach my $entry ( keys %{$lang_entries_ref} ) {
        if ( $lang_entries_ref->{$entry}
            && has_hudson( $lang_entries_ref->{$entry} ) )
        {
            $warnings->add( 'non_jenkins',
                ( "$entry -> " . $lang_entries_ref->{$entry} ) );
            $stats->inc_no_jenkins;
        }
    }

    if ( $processor->is_to_search ) {
        my $term = $processor->search_term;

        foreach my $entry ( keys %{$lang_entries_ref} ) {
            if (   $lang_entries_ref->{$entry}
                && $lang_entries_ref->{$entry} =~ $term )
            {
                $warnings->add( 'search_found',
                    ( "$entry -> " . $lang_entries_ref->{$entry} ) );
            }
        }

    }

    $warnings->summary($curr_lang_file);
    $warnings->reset;
}

is( $stats->perc_done, 100, 'Got 100% translated' );
is( $stats->get_unique_keys, 3,
    'Have identified the expected number of unique translation keys' );
is( $stats->get_keys, 6,
    'Have identified the expected number of translation keys processed' );
