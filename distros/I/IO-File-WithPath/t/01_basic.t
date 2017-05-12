use strict;
use Test::More tests => 6 * 2;

use IO::File::WithPath;
use FindBin;
use File::Spec;

my $absolute_path = File::Spec->rel2abs("$FindBin::Bin/01_basic.t");
my $relative_path = File::Spec->abs2rel($absolute_path);

check(IO::File::WithPath->new($absolute_path));
check(IO::File::WithPath->new($relative_path));


sub check {
    my $f = shift;

    is ref $f => 'IO::File::WithPath';

    ok $f->can('path');
    is $f->path => $absolute_path;

    is $f->getline => "use strict;\n";

    while ( my $line = <$f> ) {
        is $line => "use Test::More tests => 6 * 2;\n";
        last;
    }

    my @lines = <$f>;
    is $lines[1] => "use IO::File::WithPath;\n";
}
