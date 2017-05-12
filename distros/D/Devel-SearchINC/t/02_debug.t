use strict;
use warnings;
use Test::More tests => 6;
use Capture::Tiny qw(capture_merged);
my $capture;

BEGIN {
    $capture = capture_merged {
        use_ok('Devel::SearchINC', qw(-clear t/lib -debug));
        use_ok('C::D::F');
    };
}

sub is_trimmed {
    my ($got, $expect, $name) = @_;
    s/(^\s*|\s*$)//g for $got, $expect;
    is $got, $expect, $name;
}

# Test only those captured lines that start with 'dir'
$capture =~ s/^(?!dir).*//mg;
is_trimmed($capture, <<EOEXPECT, 'dir debug output');
dir [t/lib]
dir [t/lib/C]
dir [t/lib/C/D]
dir [t/lib/C/D/lib]
dir [t/lib/C/D/lib/C]
dir [t/lib/C/D/lib/C/D]
dir [t/lib/C/D/lib/C/D/F]
EOEXPECT
is C::D::F::answer(), 42, 'C::D::F::answer is 42';
is_deeply \@Devel::SearchINC::PATHS, [qw(t/lib)], 'paths';
my $expected_cache = {
    'C/D/F.pm'   => 't/lib/C/D/lib/C/D/F.pm',
    'E.pm'       => 't/lib/C/D/lib/E.pm',
    'C/D/F/G.pm' => 't/lib/C/D/lib/C/D/F/G.pm'
};
is_deeply \%Devel::SearchINC::cache, $expected_cache, 'cache';
