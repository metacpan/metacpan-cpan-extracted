use strict;
use Test::More;
use Test::Exception;
use Test::DZil;
use JSON;

sub test_build {
    my($path, $cb, $ini) = @_;

    unless ($ini) {
        $ini = simple_ini('GatherDir', 'MetaJSON', 'License', [ 'LicenseFromModule', {source_file => 'lib/DZT/Nonexistent.pm',},]);
        $ini =~ s/^(?:author|license|copyright.*) = .*$//mg;
    }

    my $tzil = Builder->from_config(
        { dist_root => $path },
        { add_files => {
            'source/dist.ini' => $ini,
        } },
    );

    $tzil->build;

    my $json = $tzil->slurp_file('build/META.json');
    my $meta = JSON::decode_json($json);
    my $license = $tzil->slurp_file('build/LICENSE');

    $cb->($meta, $license);
};

dies_ok { test_build 't/dist/Perl5', sub {} },
  "Fails to build when nonexistent file is specified.";
dies_ok { test_build 't/dist/MIT', sub {} },
  "Fails to build when nonexistent file is specified.";

done_testing;
