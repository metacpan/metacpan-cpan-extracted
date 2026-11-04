use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover ();

my $lib = -d File::Spec->catdir('blib', 'lib') ? File::Spec->catdir('blib', 'lib') : 'lib';
my $script = File::Spec->catfile('bin', 'xs_cover');

sub xs_cover {
    my (@args) = @_;
    my $out = qx{"$^X" "-I$lib" "$script" @args 2>&1};
    return ($out, $? == -1 ? 127 : $? >> 8);
}

my ($out, $exit) = xs_cover('-h');
is($exit, 0, '-h exits 0');
like($out, qr/^Usage:/m, 'with the usage');
like($out, qr/^Options:\n\s+-report NAME\n/m, 'and the options with their meaning');

($out, $exit) = xs_cover('-v');
is($exit, 0, '-v exits 0');
is($out, "xs_cover version $Devel::XSCover::VERSION\n", 'with the version alone');

($out, $exit) = xs_cover('-bogus');
is($exit, 2, 'an unknown option exits 2');
like($out, qr/^Unknown option: bogus$/m, 'naming it');
like($out, qr/^Usage:/m, 'with the usage');
unlike($out, qr/^Options:/m, 'and not the long form');

($out, $exit) = xs_cover('-dry', 'extra');
is($exit, 2, 'a stray argument exits 2');
like($out, qr/^xs_cover: unexpected argument extra$/m, 'and is named');

done_testing;
