use File::Spec;
use Test::Exception;
use Test::More;

BEGIN {
    use_ok('File::ShareDir::Override');
}

use File::ShareDir::Override
    'Foo-Bar:/omnomnom/cookie;File::ShareDir::Override:/delicious/cherry/pie';

is(File::ShareDir::dist_dir('Foo-Bar'), '/omnomnom/cookie',
    'The expected dist_dir is returned');

is(File::ShareDir::dist_file('Foo-Bar', 'want/more'),
    File::Spec->catfile('/omnomnom/cookie', 'want/more'),
    'The expected dist_file is returned');

is(File::ShareDir::module_dir('File::ShareDir::Override'), '/delicious/cherry/pie',
    'The expected module_dir is returned');

is(File::ShareDir::module_file('File::ShareDir::Override', 'gimme.pl.z'),
    File::Spec->catfile('/delicious/cherry/pie', 'gimme.pl.z'),
    'The expected module_file is returned');

dies_ok { File::ShareDir::dist_dir('File-ShareDir-Override-Nonexisting') }
    'Dies with unknown dist';

dies_ok { File::ShareDir::module_dir('File::ShareDir::Override::Nonexisting') }
    'Dies with unknown module';

done_testing;
