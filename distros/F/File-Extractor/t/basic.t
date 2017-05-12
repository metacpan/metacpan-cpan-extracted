#!perl

use strict;
use warnings;
use IO::File;
use Test::Exception;
use Test::NoWarnings;
use Test::More tests => 28;

BEGIN { use_ok('File::Extractor'); }

{
    my @default_libs = File::Extractor->getDefaultLibraries;
    is(+@default_libs, +grep { /^libextractor/ } @default_libs, 'default libraries look sane');
}

{
    my $e;
    lives_ok(sub {
            $e = File::Extractor->loadDefaultLibraries;
    }, 'loadDefaultLibraries');
    isa_ok($e, 'File::Extractor');

    {
        my %keywords;
        lives_ok(sub {
                %keywords = $e->getKeywords( IO::File->new('t/data/7peoples.png', 'r') );
        }, 'getKeywords from fh');

        is_deeply(\%keywords, {
                'modification date' => '2005-09-24 16:38:15',
                'mimetype'          => 'image/png',
                'size'              => '266x266',
        }, 'keywords');
    }

    {
        my %keywords;
        lives_ok(sub {
                %keywords = $e->getKeywords(do {
                    local $/;
                    my $fh = IO::File->new('t/data/7peoples.png', 'r');
                    <$fh>;
                });
        }, 'getKeywords from buffer');

        is_deeply(\%keywords, {
                'modification date' => '2005-09-24 16:38:15',
                'mimetype'          => 'image/png',
                'size'              => '266x266',
        }, 'keywords');
    }

    {
        my %keywords;
        lives_ok(sub {
                %keywords = $e->getKeywords('foo');
        }, 'getKeywords from nonsense buffer');

        is(+%keywords, 0, 'returns empty list when no keywords were found');
    }
}

lives_ok(sub {
        my $e;
        lives_ok(sub {
                $e = File::Extractor->loadConfigLibraries('libextractor_hash_md5');
        }, 'loadConfigLibraries class');
        isa_ok($e, 'File::Extractor');

        my $e2;
        lives_ok(sub {
                $e2 = $e->loadConfigLibraries('libextractor_hash_sha1');
        }, 'loadConfigLibraries instance');
        isa_ok($e2, 'File::Extractor');

        throws_ok(sub {
                $e->getKeywords('foo');
        }, qr/invalidates/, 'loadConfigLibraries instance method invalidates instance');

        my $e3;
        lives_ok(sub {
                $e3 = $e2->removeLibrary('libextractor_hash_md5');
        }, 'removeLibrary');
        isa_ok($e3, 'File::Extractor');

        throws_ok(sub {
                $e2->getKeywords('foo');
        }, qr/invalidates/, 'removeLibrary invalidates instance');
}, 'destroying invalidated instances doesn\'t croak');

{
    my $e;
    lives_ok(sub {
            $e = File::Extractor->addLibrary('libextractor_hash_md5');
    }, 'addLibrary class');
    isa_ok($e, 'File::Extractor');

    my $e2;
    lives_ok(sub {
            $e2 = $e->addLibrary('libextractor_hash_sha1');
    }, 'addLibrary instance');

    throws_ok(sub {
            $e->getKeywords('foo');
    }, qr/invalidates/, 'addLibrary instance method invalidates instance');
}

{
    my $e;
    lives_ok(sub {
            $e = File::Extractor->addLibraryLast('libextractor_hash_md5');
    }, 'addLibraryLast class');
    isa_ok($e, 'File::Extractor');

    my $e2;
    lives_ok(sub {
            $e2 = $e->addLibraryLast('libextractor_hash_sha1');
    }, 'addLibraryLast instance');

    throws_ok(sub {
            $e->getKeywords('foo');
    }, qr/invalidates/, 'addLibraryLast instance method invalidates instance');
}
