use strict;
use Test::More tests => 9;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib');
use GD::Tab::Ukulele;

my $uk = GD::Tab::Ukulele->new;

is(
    $uk->generate('C', [3,0,0,0])->png,
    $uk->chord('C')->png,
);

is(
    $uk->generate('BM7(9)', [4, 1, 3, 3])->png,
    $uk->chord('BM7(9)')->png,
);

is(238, scalar(@{$uk->all_chords}));

sub fileread {
    my $fh = IO::File->new(shift, 'r');
    return do {local $/ = undef; <$fh>};
}

my $file_dir = File::Spec->catdir( dirname(__FILE__), 'files');

is(
    fileread(File::Spec->catfile($file_dir, 'FOO_15_13_11_14.png')),
    $uk->generate('FOO',[15,13,11,14])->png
);
is(
    fileread(File::Spec->catfile($file_dir, 'BAR_1987.png')),
    $uk->generate('BAR', [1,9,8,7])->png
);

is(
    fileread(File::Spec->catfile($file_dir, 'D7_0202.png')),
    $uk->generate('D7',[0,2,0,2])->png
);

is(
    fileread(File::Spec->catfile($file_dir, 'C.png')),
    $uk->chord('C')->png
);

is(
    fileread(File::Spec->catfile($file_dir, 'D7.png')),
    $uk->chord('D7')->png
);

eval { $uk->chord('aaa') };
ok($@ =~ /^undefined chord aaa/);

