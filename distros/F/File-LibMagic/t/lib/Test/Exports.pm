package Test::Exports;

use strict;
use warnings;

use Test::AnyOf;
use Test::Fatal;
use Test::More 0.96;

use Exporter qw( import );
use File::LibMagic::Constants qw( constants );

our @EXPORT_OK = qw( test_complete test_easy );

sub test_complete {
    my $package     = shift;
    my $samples_dir = shift;

    subtest(
        'constants',
        sub { _test_constants($package) }
    );

    subtest(
        'custom magic file',
        sub {
            _test_complete_with_handle(
                $package,
                $samples_dir,
                "$samples_dir/magic",
            );
        }
    );
    subtest(
        'empty string for magic file name',
        sub { _test_complete_with_handle( $package, $samples_dir, q{} ) }
    );
    subtest(
        'undef for magic file name',
        sub { _test_complete_with_handle( $package, $samples_dir, undef ) }
    );
}

sub _test_constants {
    my $package = shift;

    foreach my $const ( grep { !/_MAX$/ } constants() ) {
        ## no critic (Variables::RequireInitializationForLocalVars)
        local $@;
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        my $ok = eval "${package}::$const() || 1";
        ## use critic

        if ($ok) {
            pass("$const is exported by :complete");
            next;
        }

        if ( $@ =~ /^Your vendor has not defined constants macro \Q$const/ ) {
            pass("$const is not defined for this version of libmagic");
        }
        else {
            fail("unexpected error for $const");
            diag($@);
        }
    }
}

sub _test_complete_with_handle {
    my $package     = shift;
    my $samples_dir = shift;
    my $custom_file = shift;

    my $handle
        = $package->can('magic_open')->( $package->can('MAGIC_NONE')->() );
    $package->can('magic_load')->( $handle, $custom_file );

    my $magic_buffer = $package->can('magic_buffer');
    my $magic_file   = $package->can('magic_file');

    is(
        $magic_buffer->( $handle, "Hello World\n" ),
        'ASCII text',
        'magic_buffer on ASCII text'
    );

    if ($custom_file) {
        is(
            $magic_buffer->( $handle, "Footastic\n" ),
            'A foo file',
            'magic_file on foo text (with custom magic)'
        );
        is(
            $magic_file->( $handle, "$samples_dir/foo.foo" ),
            'A foo file',
            'magic_file on foo file (with custom magic)'
        );
    }
    else {
        is(
            $magic_file->( $handle, "$samples_dir/foo.txt" ),
            'ASCII text',
            'magic_file on foo file (no custom magic)'
        );
        is(
            $magic_file->( $handle, "$samples_dir/foo.foo" ),
            'ASCII text',
            'magic_file on foo file (no custom magic)'
        );
    }

    is(
        $magic_file->( $handle, "$samples_dir/foo.txt" ),
        'ASCII text',
        'magic_file on ASCII text'
    );
    is_any_of(
        $magic_file->( $handle, "$samples_dir/foo.c" ),
        [ 'ASCII text', 'ASCII C program text', 'C source, ASCII text' ],
        'magic_file on C code'
    );

    $package->can('magic_close')->($handle);
}

sub test_easy {
    my $package     = shift;
    my $samples_dir = shift;

    my $MagicBuffer = $package->can('MagicBuffer');
    my $MagicFile   = $package->can('MagicFile');

    is(
        $MagicBuffer->("Hello World\n"),
        'ASCII text',
        'MagicBuffer on text'
    );
    is(
        $MagicFile->("$samples_dir/foo.txt"),
        'ASCII text',
        'MagicFile on ASCII text'
    );
    is_any_of(
        $MagicFile->("$samples_dir/foo.c"),
        [ 'ASCII C program text', 'C source, ASCII text' ],
        'MagicFile on C code'
    );

    like(
        exception { $MagicBuffer->(undef) },
        qr{MagicBuffer requires defined content},
        'MagicBuffer(undef)'
    );

    like(
        exception { $MagicFile->(undef) },
        qr{MagicFile requires a filename},
        'MagicFile(undef)'
    );

TODO: {
        local $TODO = 'May not fail sanely with all versions of libmagic';
        like(
            exception { $MagicFile->("$samples_dir/missing") },
            qr{libmagic cannot open .+ at .+},
            'MagicFile: missing file'
        );
    }
}

1;
