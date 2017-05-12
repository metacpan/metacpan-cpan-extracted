use strict;
use Test::More tests => 9;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib');
use GD::Tab::Guitar;

my $uk = GD::Tab::Guitar->new;

is(
    $uk->generate('G', [3,0,0,0,2,3])->png,
    $uk->chord('G')->png,
);

is(
    $uk->generate('G', '320003')->png,
    $uk->chord('G')->png,
);

is(493, scalar(@{$uk->all_chords}));

sub fileread {
    my $fh = IO::File->new(shift, 'r');
    $fh->binmode();
    return do {local $/ = undef; <$fh>};
}

my $file_dir = File::Spec->catdir( dirname(__FILE__), 'files');

is(
    fileread(File::Spec->catfile($file_dir, 'FOO_x_10_12_12_11_10.png')),
    $uk->generate('FOO',[10,11,12,12,10,'x'])->png
);

is(
    fileread(File::Spec->catfile($file_dir, 'BAR_206791.png')),
    $uk->generate('BAR', '197602')->png
);

is(
    fileread(File::Spec->catfile($file_dir, 'G_334553.png')),
    $uk->generate('G', [3,3,4,5,5,3])->png
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
