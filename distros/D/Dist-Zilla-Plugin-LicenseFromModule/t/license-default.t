use strict;
use Test::More;
use Test::DZil;
use JSON;

sub test_build {
    my($path, $cb, $ini) = @_;

    unless ($ini) {
        $ini = simple_ini('GatherDir', 'MetaJSON', 'License', 'LicenseFromModule');
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

test_build 't/dist/Perl5', sub {
    my($meta, $license) = @_;

    is $meta->{author}[0], 'John Doe';
    is $meta->{license}[0], 'perl_5';

    like $license, qr/2001- by John Doe/;
};

test_build 't/dist/MIT', sub {
    my($meta, $license) = @_;

    is $meta->{author}[0], 'John Doe <john.doe@sample.pod>';
    is $meta->{license}[0], 'mit';
    like $license, qr/2012 by John Doe/;
};


my $ini = simple_ini('GatherDir', 'MetaJSON', 'License', [ 'LicenseFromModule', { override_author => 1 } ]);
$ini =~ s/^(?:license|copyright_holder) = .*$//mg;
$ini =~ s/^author = .*$/author = Tom Hanks/m;

test_build 't/dist/MIT', sub {
    my($meta, $license) = @_;

    is $meta->{author}[0], 'Tom Hanks';
    is $meta->{license}[0], 'mit';
    like $license, qr/2012 by John Doe/;
}, $ini;

done_testing;
