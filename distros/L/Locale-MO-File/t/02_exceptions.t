#!perl -T

use strict;
use warnings;

use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
require IO::File;

use Test::More tests => 8;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;

BEGIN {
    require_ok 'Locale::MO::File';
}

my $filename = '02_exceptions.mo';

throws_ok
    sub {
        Locale::MO::File->new->write_file;
    },
    qr{\QFilename not set}xms,
    'write without parameters set';

my $file_handle = IO::File->new($filename, '> :raw')
    or confess "Can not write $filename\n$OS_ERROR";

throws_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_file_handle($file_handle);
        $mo->write_file;
    },
    qr{\QFilename not set}xms,
    'write without filename';

throws_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_messages([ undef ]);
        $mo->write_file;
    },
    qr{\Qmessages[0] is not a hash reference}xms,
    'message is not a hash reference';

throws_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_messages([
            {
                msgstr        => q{},
                msgstr_plural => [],
            }
        ]);
        $mo->write_file;
    },
    qr{\Q'msgstr not set' callback}xms,
    'msgstr and msgstr together makes no sense';

throws_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_messages([
            {
                msgid => $Locale::MO::File::CONTEXT_SEPARATOR,
            }
        ]);
        $mo->write_file;
    },
    qr{\Q'no control chars' callback}xms,
    'control chars in msgid';

throws_ok
    sub {
        my $mo = Locale::MO::File->new;
        $mo->set_filename($filename);
        $mo->set_messages([
            {
                msgid_plural  => 'dummy',
                msgstr_plural => [ $Locale::MO::File::PLURAL_SEPARATOR ],
            }
        ]);
        $mo->write_file;
    },
    qr{\Q'no control chars' callback}xms,
    'control chars in msgstr_plural';
