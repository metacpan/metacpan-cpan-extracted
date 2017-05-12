use strict;
use warnings;
use Test::More;

use File::Spec ();
use File::Spec::Native ();

plan tests => 3;

my @path = qw(dumb module);
is(File::Spec->catfile(@path), File::Spec::Native->catfile(@path), 'base == Native');

use File::Spec::Functions qw(catdir);
is(catdir(@path), File::Spec::Native->catdir(@path), 'base == Native');

# try to find something that isn't the current OS
my $prefix = 'File::Spec';
my $detected = $File::Spec::ISA[0];

my $fsclass = "${prefix}::" . ($detected eq "${prefix}::Win32" ? 'Unix' : 'Win32');
eval "require $fsclass" or die $@;

my $foreign = $fsclass->catfile(@path);

isnt($foreign, File::Spec::Native->catfile(@path), "foreign ($fsclass) != native ($detected)");
