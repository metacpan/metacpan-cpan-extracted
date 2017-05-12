#
# $Id: 10_subclass.t,v 1.1 2003/12/28 15:29:08 james Exp $
#

# a usable compressor class
package Foo;
use vars '@ISA';
@ISA = qw|IO::File::CompressOnClose|;
sub compress {}

# a non-usable compressor class (not a subclass of IO::File::CompressOnClose)
package Bar;
sub compress {}

# a non-usable compressor class (does not have a compress method)
package Baz;
use vars '@ISA';
@ISA = qw|IO::File::CompressOnClose|;

# the tester script
package main;

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use File::Path;

BEGIN {
    chdir 't' if -d 't';
}

mkdir 'compress' unless -d 'compress';
chdir 'compress' or die;

END {
    chdir("..") or die;
    rmtree 'compress' unless @ARGV;
}

use_ok('IO::File::CompressOnClose');

# open a file for write
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# set the compressor to a usable subclass
$io->compressor( 'Foo' );

# close the file
lives_ok {
    $io->close
} 'set compressor to usable subclass';

# open a file for write
lives_ok {
    $io = IO::File::CompressOnClose->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# set the compressor to an unusable subclass
$io->compressor( 'Bar' );

# close the file
throws_ok {
    $io->close
} qr/Bar is not a subclass/,
'set compressor to non-subclass of IO::File::CompressOnClose';

# open a file for write
lives_ok {
    $io = IO::File::CompressOnClose->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# set the compressor to an unusable subclass
$io->compressor( 'Baz' );

# close the file
throws_ok {
    $io->close
} qr/Baz cannot 'compress'/,
'set compressor to class without a compress method';

#
# EOF

