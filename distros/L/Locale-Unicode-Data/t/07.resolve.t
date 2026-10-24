#!perl
# The data aliases of root point to the data of the locale being resolved, not of root, and
# resolve() must follow them after the locale inheritance, and before root.
# <https://www.unicode.org/reports/tr35/#Alias_Elements>
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;
use utf8;

my $cldr = Locale::Unicode::Data->new;
isa_ok( $cldr, 'Locale::Unicode::Data' );

# NOTE: data aliases
subtest 'data aliases' => sub
{
    my $all = $cldr->data_aliases( locale => 'und' );
    ok( ref( $all ) eq 'ARRAY' && scalar( @$all ), 'root has data aliases' );
    my $ref = $cldr->data_alias( locale => 'und', table_name => 'calendar_terms', source => '{"calendar":"japanese","term_type":"month"}' );
    is( ref( $ref ), 'HASH', 'japanese months alias' ) || diag( $cldr->error );
    is( $ref->{target}, '{"calendar":"gregorian","term_type":"month"}', 'japanese months point to gregorian months' ) if( $ref );
};

# NOTE: calendar terms
subtest 'calendar terms' => sub
{
    my $months = $cldr->resolve( calendar_terms =>
        locale          => 'fr',
        calendar        => 'japanese',
        term_type       => 'month',
        term_context    => 'format',
        term_width      => 'wide',
        order           => [term_name => 'integer'],
    );
    is( ref( $months ), 'ARRAY', 'array reference returned' ) || diag( $cldr->error );
    is( scalar( @$months ), 12, '12 months' );
    is( $months->[0]->{term_value}, 'janvier', 'japanese calendar months of fr are its gregorian months' );
    is( $months->[0]->{locale}, 'fr', 'found in fr' );
    is( $months->[0]->{calendar}, 'gregorian', 'from the gregorian calendar' );
    # Without resolution, the data of root, resolved within root, is what we would get.
    my $root = $cldr->calendar_terms( locale => 'und', calendar => 'japanese', term_type => 'month', term_context => 'format', term_width => 'wide', order => [term_name => 'integer'] );
    is( $root->[0]->{term_value}, 'M01', 'root itself still has its own data' );
    my $own = $cldr->resolve( calendar_terms => locale => 'fr', calendar => 'gregorian', term_type => 'month', term_context => 'format', term_width => 'wide' );
    is( scalar( @$own ), 12, 'non aliased data found directly' );
    my $inherited = $cldr->resolve( calendar_terms => locale => 'fr-CA', calendar => 'japanese', term_type => 'month', term_context => 'format', term_width => 'wide', order => [term_name => 'integer'] );
    is( $inherited->[0]->{term_value}, 'janvier', 'alias followed through the locale inheritance' );
    my $none = $cldr->resolve( calendar_terms => locale => 'fr', calendar => 'gregorian', term_type => 'month', term_context => 'format', term_width => 'nonexistent' );
    is( ref( $none ), 'ARRAY', 'array reference when nothing is found' );
    is( scalar( @$none ), 0, 'empty when nothing is found' );
};

# NOTE: eras
subtest 'eras' => sub
{
    my $narrow = $cldr->resolve( calendar_eras_l10n => locale => 'fr', calendar => 'gregorian', era_width => 'narrow' );
    my $abbr = $cldr->calendar_eras_l10n( locale => 'fr', calendar => 'gregorian', era_width => 'abbreviated' );
    ok( scalar( @$narrow ), 'narrow eras found' ) || diag( $cldr->error );
    # fr may have its own narrow eras; otherwise they are its abbreviated ones.
    my $own = $cldr->calendar_eras_l10n( locale => 'fr', calendar => 'gregorian', era_width => 'narrow' );
    if( scalar( @$own ) )
    {
        is( $narrow->[0]->{locale_name}, $own->[0]->{locale_name}, 'fr has its own narrow eras' );
    }
    else
    {
        is( $narrow->[0]->{locale_name}, $abbr->[0]->{locale_name}, 'narrow eras of fr are its abbreviated ones' );
    }
};

# NOTE: metazones
subtest 'metazones' => sub
{
    # Since CLDR v49, the British and Irish metazones are aliased in root to the GMT metazone of
    # the locale being resolved, which root itself does not have.
    my $mz = $cldr->metazone( metazone => 'British' );
    plan( skip_all => 'No British metazone in this CLDR version' ) if( !$mz );
    my $own = $cldr->metazone_names( locale => 'ckb', metazone => 'British', width => 'long' );
    plan( skip_all => 'ckb has its own British metazone names' ) if( $own );
    my $gmt = $cldr->metazone_names( locale => 'ckb', metazone => 'GMT', width => 'long' );
    my $ref = $cldr->resolve( metazone_names => locale => 'ckb', metazone => 'British', width => 'long' );
    is( ref( $ref ), 'HASH', 'British metazone names resolved' ) || diag( $cldr->error );
    is( $ref->{standard}, $gmt->{standard}, 'British metazone of ckb is its GMT metazone' ) if( $ref && $gmt );
    my $root = $cldr->resolve( metazone_names => locale => 'und', metazone => 'British', width => 'long' );
    ok( !defined( $root ), 'root has no data for the British metazone' );
};

# NOTE: errors
subtest 'errors' => sub
{
    local $SIG{__WARN__} = sub{};
    ok( !defined( $cldr->resolve( languages => locale => 'fr' ) ), 'unsupported method' );
    like( $cldr->error->message, qr/does not support data resolution/, 'error message' );
    ok( !defined( $cldr->resolve( calendar_terms => calendar => 'gregorian' ) ), 'missing locale' );
    like( $cldr->error->message, qr/No locale was provided/, 'error message' );
};

done_testing();

__END__
