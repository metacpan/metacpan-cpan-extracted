use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

plan skip_all => "This test doesn't work in win32" if $^O eq 'MSWin32';

my $envdir_pl = catfile($Bin, qw(.. bin envdir.pl));
my $dir = catfile($Bin, 'env');

my $stdout = `$^X $envdir_pl $dir $^X -le "print \\"\\\$_=\\\$ENV{\\\$_}\\" for sort keys \%ENV"`;
is $stdout, <<ENV, "stdout ok";
FOO=foo
PATH=/env/bin
ENV

done_testing;
