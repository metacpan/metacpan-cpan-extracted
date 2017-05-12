#!/usr/bin/perl

use utf8;
use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 3;

use EBook::MOBI;
use Encode;
use File::Temp qw( tempfile );
use File::Slurp;

my $obj = EBook::MOBI->new();
$obj->set_encoding(':encoding(UTF-8)');

my ($fh, $filename) = tempfile( SUFFIX => '.mobi',
                                UNLINK => 1,
                              );
$obj->set_filename($filename);

my $text = encode_utf8("<p>Here is some Chinese text - 你好!</p>");
$obj->add_mhtml_content($text);
$obj->make();
$obj->save();

my $mobi_file = read_file($filename, {binmode => ':raw'} );

# The codepage should be set in the header: hex FDE9 = dec 65001
like($mobi_file, qr/\x{FD}\x{E9}/s, 'UTF-8 codepage set correctly');

$obj->reset();
$obj->set_encoding(':encoding(ISO-8859-1)');
$obj->set_filename($filename);
$obj->add_mhtml_content('<p>Here is some German text - Viele Grüße!</p>');
$obj->make();
$obj->save();

$mobi_file = read_file($filename, {binmode => ':raw'} );

# The codepage should be set in the header: hex 04E4 = dec 1252
like($mobi_file, qr/\x{04}\x{E4}/s, 'ISO-8859-1 codepage set correctly');

$obj->reset();
eval { $obj->set_encoding(':encoding(Some-Madeup-Encoding)'); };
like($@, qr/Encoding .* is not supported/, 'Invalid encoding detected OK');


########
# done #
########
1;

