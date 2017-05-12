use Test::More tests => 30;
use Test::Warn;

use Locale::Maketext::Utils::Phrase::Norm;
use Locale::Maketext::Utils::Phrase::cPanel;

$INC{"Locale/Maketext/Utils/Phrase/Norm/TEST.pm"} = 1;
no warnings 'once';
*Locale::Maketext::Utils::Phrase::Norm::TEST::normalize_maketext_string = sub { };

for my $type ( 0 .. 2 ) {

    # diag explain(Locale::Maketext::Utils::Phrase::Norm->new_source($type == 1 ? 'TEST' : ())->{'filternames'});

    my $label = $type == 1 ? ': additional added' : $type == 2 ? ': excluded not added' : '';
    {
        my $label = $type == 2 ? '' : $label;
        is_deeply(

            Locale::Maketext::Utils::Phrase::Norm->new_source( $type == 1 ? 'TEST' : () )->{'filternames'},
            [
                'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
                'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
                'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
                'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
                'Locale::Maketext::Utils::Phrase::Norm::Markup',
                'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
                'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
                'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
                'Locale::Maketext::Utils::Phrase::Norm::Consider',
                'Locale::Maketext::Utils::Phrase::Norm::Escapes',
                'Locale::Maketext::Utils::Phrase::Norm::Compiles',
                (
                    $type == 1
                    ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                    : ()
                )
            ],
            "Norm->new_source() filters" . $label
        );

        is_deeply(
            Locale::Maketext::Utils::Phrase::cPanel->new_source( $type == 1 ? 'TEST' : () )->{'filternames'},
            [
                'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
                'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
                'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
                'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
                'Locale::Maketext::Utils::Phrase::Norm::Markup',
                'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
                'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
                'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
                'Locale::Maketext::Utils::Phrase::Norm::Consider',
                'Locale::Maketext::Utils::Phrase::Norm::Escapes',
                'Locale::Maketext::Utils::Phrase::Norm::Compiles',
                (
                    $type == 1
                    ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                    : ()
                )
            ],
            "cPanel->new_source() filters" . $label
        );
    }

    is_deeply(
        Locale::Maketext::Utils::Phrase::Norm->new_target( $type == 1 ? 'TEST' : $type == 2 ? 'BeginUpper' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
            'Locale::Maketext::Utils::Phrase::Norm::Markup',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "Norm->new_target() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_target( $type == 1 ? 'TEST' : $type == 2 ? 'BeginUpper' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
            'Locale::Maketext::Utils::Phrase::Norm::Markup',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_target() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_legacy_source( $type == 1 ? 'TEST' : $type == 2 ? 'Markup' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
            'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_legacy_source() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_legacy_target( $type == 1 ? 'TEST' : $type == 2 ? 'Markup' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_legacy_target() filters" . $label
    );
}

for my $ns (qw(Locale::Maketext::Utils::Phrase::Norm Locale::Maketext::Utils::Phrase::cPanel)) {
    my $obj;
    warning_is {
        is( ref( $obj = $ns->new() ), $ns, "$ns->new() still returns and object" );
    }
    "new() is deprecated, use new_source() instead", "$ns->new() complains about being deprecated";

    warning_is {
        is_deeply( [ $obj->normalize() ], [], 'normalize() with no arg return;s' );
    }
    'You must pass a value to normalize()', 'normalize() with no arg complains';

    warning_is {
        is_deeply( [ $obj->normalize( undef() ) ], [], 'normalize() with undef arg return;s' );
    }
    'You must pass a value to normalize()', 'normalize() with undef arg complains';
}
