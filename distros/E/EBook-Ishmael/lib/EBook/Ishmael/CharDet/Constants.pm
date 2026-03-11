package EBook::Ishmael::CharDet::Constants;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(TAKE_OK TAKE_BAD TAKE_MUST_BE);
our %EXPORT_TAGS = (
    CONSTANTS => [ @EXPORT_OK ],
);

use constant {
    TAKE_OK      => 0,
    TAKE_BAD     => 1,
    TAKE_MUST_BE => 2,
};

our %ASCII_SPACE_SET = map { $_ => 1 } (
    "\x00", "\x09", "\x0a", "\x0b", "\x0d", "\x20",
);

our %ASCII_LETTER_SET = map { $_ => 1 } (
    'a' .. 'z',
    'A' .. 'Z',
);

1;
