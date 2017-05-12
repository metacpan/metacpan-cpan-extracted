use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp;
use Locale::Maketext::Extract;
use Locale::Maketext::Extract::Plugin::Xslate;

my $ext = Locale::Maketext::Extract->new(
    plugins => {
        xslate => {
            syntax     => 'TTerse',
            extensions => ['html'],
        },
    },
    warnings => 1,
    verbose  => 0,
);
$ext->extract_file( File::Spec->catfile(qw/ t data hello.html /) );
$ext->compile(1);

is_deeply [ sort $ext->msgids ], ['hello', 'nest1', 'nest2', 'nest3', 'term', 'values: %1 %2', 'word', 'xslate syntax'];

my $tmp = File::Temp->new(UNLINK => 1);
$ext->write_po($tmp->filename);
like slurp($tmp->filename), qr{t/data/hello\.html:13}, 'contains line number';

done_testing;

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    do { local $/; <$fh> }
}
