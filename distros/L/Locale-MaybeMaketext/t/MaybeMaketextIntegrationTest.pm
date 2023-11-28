package MaybeMaketextIntegrationTest;
use strict;
use warnings;
use utf8;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use Carp         qw/carp croak/;
use parent       qw/Exporter/;
use Data::Dumper qw/Dumper/;
use DateTime;
use charnames qw/:full/;
use MaybeMaketextTestdata;
use Locale::MaybeMaketext::Tests::Integration;

no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

# Export all the tags and the contents therein automatically.
our @EXPORT;    ## no critic (Modules::ProhibitAutomaticExportation)
our %EXPORT_TAGS = %MaybeMaketextTestdata::EXPORT_TAGS;
$EXPORT_TAGS{'integration_tests'} = [qw/test_integration_package/];
for my $subs ( values(%EXPORT_TAGS) ) {
    push @EXPORT, @{$subs};
}
$EXPORT_TAGS{'all'} = [@EXPORT];
our @EXPORT_OK = @EXPORT;

# Which modules require an appropriate "locale" module
my %require_locale = (
    'Cpanel::CPAN::Locale::Maketext::Utils' => 'Cpanel::CPAN::Locales::DB::Language::en',
    'Locale::Maketext::Utils'               => 'Locales::DB::Language::en'
);

# what is the current year
my $year = ( ( ( localtime() )[5] ) + 1900 );    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

# Detail what punctiontion unicode characters should be used for consistency.
# I've got no idea why ...Locales::Maketext::Utils uses two characters for NBSP.
my ( $start_quote, $end_quote, $nbsp ) = (
    "\N{LEFT DOUBLE QUOTATION MARK}", "\N{RIGHT DOUBLE QUOTATION MARK}",
    "\N{LATIN CAPITAL LETTER A WITH CIRCUMFLEX}\N{NO-BREAK SPACE}"
);

# when a "join" is given in the expected results, what quotes should be used.
my @join_quotes = ( $start_quote, $end_quote ) x 4;

# what results are we expecting from each package.
my %integration_expected_results = (
    'Cpanel::CPAN::Locale::Maketext::Utils' => {
        'asis'         => 'Asis: Test name here.',
        'boolean'      => 'Boolean: a 2nd: b 3rd: c.',
        'comment'      => 'Comment: .',
        'current_year' => sprintf( 'Current year: %d.', $year ),
        'datetime'     => 'Datetime: November 10, 2023.',
        'format_bytes' => sprintf( 'format_bytes: 1.583%sGB.', $nbsp ),
        'is_defined'   =>
          'Is defined: "localhost" defined for domain 2nd: undefined for example 3rd: false for something.',
        'is_future'       => 'Is future: past 2nd: in future.',
        'join'            => 'Join: 1-2-3-4-5 2nd: 12345 3rd: 1,2,3,4,5.',
        'list_and'        => 'List and: Rhiannon, Parker, Char, and Bean.',
        'list_and_quoted' =>
          sprintf( 'List and quoted: %sRhiannon%s, %sParker%s, %sChar%s, and %sBean%s.', @join_quotes ),
        'list_or'        => 'List or: Rhiannon, Parker, Char, or Bean.',
        'list_or_quoted' => sprintf( 'List or quoted: %sRhiannon%s, %sParker%s, %sChar%s, or %sBean%s.', @join_quotes ),
        'quant'          => 'Quant 1 sing 2nd: 23 plur 3rd:neg.',
        'numf'           => 'Format 23 2nd: 984,293,823 3rd: 29,382.43.',
        'numerate'       => 'Numerate sing 2nd: plur 3rd: neg.',
    },
    'Locale::Maketext::Utils' => {
        'asis'         => 'Asis: Test name here.',
        'boolean'      => 'Boolean: a 2nd: b 3rd: c.',
        'comment'      => 'Comment: .',
        'current_year' => sprintf( 'Current year: %d.', $year ),
        'datetime'     => 'Datetime: November 10, 2023.',
        'format_bytes' => sprintf( 'format_bytes: 1.583%sGB.', $nbsp ),
        'is_defined'   =>
          'Is defined: "localhost" defined for domain 2nd: undefined for example 3rd: false for something.',
        'is_future'       => 'Is future: past 2nd: in future.',
        'join'            => 'Join: 1-2-3-4-5 2nd: 12345 3rd: 1,2,3,4,5.',
        'list_and'        => 'List and: Rhiannon, Parker, Char, and Bean.',
        'list_and_quoted' =>
          sprintf( 'List and quoted: %sRhiannon%s, %sParker%s, %sChar%s, and %sBean%s.', @join_quotes ),
        'list_or'        => 'List or: Rhiannon, Parker, Char, or Bean.',
        'list_or_quoted' => sprintf( 'List or quoted: %sRhiannon%s, %sParker%s, %sChar%s, or %sBean%s.', @join_quotes ),
        'quant'          => 'Quant 1 sing 2nd: 23 plur 3rd:neg.',
        'numf'           => 'Format 23 2nd: 984,293,823 3rd: 29,382.43.',
        'numerate'       => 'Numerate sing 2nd: plur 3rd: neg.',
    },
    'Locale::Maketext' => {
        'quant'    => 'Quant 1 sing 2nd: 23 plur 3rd:neg.',
        'numf'     => 'Format 23 2nd: 984,293,823 3rd: 29,382.4.',
        'numerate' => 'Numerate sing 2nd: plur 3rd: plur.',
    }
);
my %test_data = (
## no critic (ValuesAndExpressions::ProhibitMagicNumbers,ValuesAndExpressions::RequireNumberSeparators)
    'quant' => [
        'text' => 'Quant [quant,_1,sing,plur,neg] 2nd: [quant,_2,sing,plur,neg] 3rd:[quant,_3,sing,plur,neg].',
        'data' => [ 1, 23, 0 ]
    ],
    'numf' => [
        'text' => 'Format [numf,_1,2] 2nd: [numf,_2,2] 3rd: [numf,_3,2].',
        'data' => [ 23, 984293823, 29382.43432 ]
    ],
    'numerate' => [
        'text' =>
          'Numerate [numerate,_1,sing,plur,neg] 2nd: [numerate,_2,sing,plur,neg] 3rd: [numerate,_3,sing,plur,neg].',
        'data' => [ 1, 23, 0 ]
    ],

    #{
    #    'name' => 'sprintf',
    #    'text' => 'Sprintf: [sprintf,%10x=~[%s~],_1,_2].',
    #    'data' => [qw/Stuff thingamabob/],
    #},
    'join' => [
        'text' => 'Join: [join,-,_*] 2nd: [join,,_*] 3rd: [join,~,,_*].',
        'data' => [ 1, 2, 3, 4, 5 ],
    ],
    'list_and' => [
        'text' => 'List and: [list_and,_*].',
        'data' => [qw/Rhiannon Parker Char Bean/],
    ],
    'list_or' => [
        'text' => 'List or: [list_or,_*].',
        'data' => [qw/Rhiannon Parker Char Bean/],
    ],
    'list_and_quoted' => [
        'text' => 'List and quoted: [list_and_quoted,_*].',
        'data' => [qw/Rhiannon Parker Char Bean/],
    ],
    'list_or_quoted' => [
        'text' => 'List or quoted: [list_or_quoted,_*].',
        'data' => [qw/Rhiannon Parker Char Bean/],
    ],
    'datetime' => [
        'text' => 'Datetime: [datetime,_1,date_format_long].',
        'data' => [1699653289],
    ],
    'current_year' => [
        'text' => 'Current year: [current_year].',
    ],
    'format_bytes' => [
        'text' => 'format_bytes: [format_bytes,_1,3].',
        'data' => [1699653289],
    ],

    #{
    #    'name' => 'convert', - needs Math::Units
    #    'text' => 'Convert: [convert,_1,_2,_3].',
    #    'data' => [ 2, 'ft', 'in' ],
    #},
    'boolean' => [
        'text' => 'Boolean: [boolean,_1,a,b,c] 2nd: [boolean,_2,a,b,c] 3rd: [boolean,_3,a,b,c].',
        'data' => [ 1, 0, undef ],
    ],
    'is_defined' => [
        'text' =>
          'Is defined: [is_defined,_2,"_2" defined,undefined,false] for [_1] 2nd: [is_defined,_4,"_4" defined,undefined,false] for [_3] '
          . '3rd: [is_defined,_6,"_6" defined,undefined,false] for [_5].',
        'data' => [ 'domain', 'localhost', 'example', undef, 'something', 0 ],
    ],
    'is_future' => [
        'text' => 'Is future: [is_future,_1,in future,past] 2nd: [is_future,_2,in future,past].',
        'data' => [ DateTime->new( 'year' => 1066 ), DateTime->new( 'year' => 2963 ) ],
    ],
    'comment' => [
        'text' => 'Comment: [comment,There is nothing here].',
    ],
    'asis' => [
        'text' => 'Asis: Test [asis,name] here.',
    ],
);

sub test_integration_package ($package_name) {
  SKIP: {
        if ( !check_installed($package_name) ) {
            skip( sprintf( '%s: Skipping as module does not exist', $package_name ) );
        }
        if ( defined( $require_locale{$package_name} ) ) {
            my $locale = $require_locale{$package_name};
            if ( !check_installed($locale) ) {
                skip( sprintf( '%s: Skipping as required locale module %s is missing', $package_name, $locale ) );
            }
            note( sprintf( '%s: Setting quotation markers for %s', $package_name, $locale ) );
            no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
            ${"${locale}::misc_info"}{'delimiters'}{'quotation_start'} = "\N{LEFT DOUBLE QUOTATION MARK}";
            ${"${locale}::misc_info"}{'delimiters'}{'quotation_end'}   = "\N{RIGHT DOUBLE QUOTATION MARK}";
        }

        unload_mocks();
        Locale::MaybeMaketext::maybe_maketext_reset();
        Locale::MaybeMaketext::maybe_maketext_set_localizer_list($package_name);

        local @INC = @INC;
        unshift @INC, base_inc();
        if ( !defined( $integration_expected_results{$package_name} ) ) {
            fail( sprintf( '%s: Could not find package in list of test data packages', $package_name ) );
        }
        my $handle = Locale::MaybeMaketext::Tests::Integration->get_handle('en');
        if ( $handle->can('set_context_plain') ) {
            note( sprintf( '%s: Setting context plain', $package_name ) );
            $handle->set_context_plain();
        }
        is(
            Locale::MaybeMaketext::maybe_maketext_get_localizer(),
            $package_name,
            sprintf( '%s: Localizer should be being used', $package_name )
        );

        isa_check(
            $handle,
            [
                $package_name,
                'Locale::MaybeMaketext',
                'Locale::MaybeMaketext::Tests::Integration',
                'Locale::MaybeMaketext::Tests::Integration::en'
            ],
            sprintf( '%s: Should have correct parents set', $package_name )
        );

        # simple test
        is(
            $handle->maketext('basic'), 'This is working',
            sprintf( '%s: Simple replacement should work', $package_name )
        );
        run_all_localization_tests( $package_name, $handle );
    }
    return 1;
}

sub run_all_localization_tests ( $package_name, $handle ) {

    # complete test set
    my %expected_results = %{ $integration_expected_results{$package_name} };
    for my $data_name ( sort( keys(%test_data) ) ) {
        my %data = @{ $test_data{$data_name} };

        my @additional = ();
        if ( defined( $data{'data'} ) ) { @additional = @{ $data{'data'} }; }
        my $returned;
        my $is_defined = defined( $expected_results{$data_name} );
        if (
            eval {
                $returned = $handle->maketext( $data{'text'}, @additional );
                1;
            }
        ) {
            if ($is_defined) {
                is(
                    $returned, $expected_results{$data_name},
                    sprintf( '%s: Testing bracket notation: %s', $package_name, $data_name ),
                    'Returned:', $returned
                );
            }
            else {
                fail( sprintf( '%s: Expected %s to fail - but passed! %s', $package_name, $data_name, $returned ) );
            }
        }
        else {
            my $error = $@ || 'unknown';
            if ( defined( $expected_results{$data_name} ) ) {
                fail(
                    sprintf( '%s: Error encountered when trying to use "%s" : %s', $package_name, $data_name, $error )
                );
            }
            elsif ( index( $error, "Can\'t locate object method \"$data_name\" via package" ) >= 0 ) {
                pass(
                    sprintf( '%s: Localizer does not support "%s" - failed as expected', $package_name, $data_name ) );
            }
            else {
                fail(
                    sprintf(
                        '%s: Unexpected error encountered when trying to use "%s" : %s', $package_name, $data_name,
                        $error
                    )
                );
            }
        }
    }
    return 1;
}

# Checks if a certain module is installed/available.
sub check_installed ($package_name) {
    my $path = ( $package_name =~ tr{:}{\/}rs ) . '.pm';
    if ( eval { require $path; 1 } ) {
        return 1;
    }
    my $error = $@;
    if ( $error =~ m/Can't locate \Q$path\E in \@INC/ ) {
        return 0;
    }
    croak( sprintf( 'Unable to check module %s', $package_name ) );
}

1;

=encoding utf8

=head1 NAME

MaybeMaketextIntegrationTest - Provides integration test related data for Locale::MaybeMaketext

=cut
