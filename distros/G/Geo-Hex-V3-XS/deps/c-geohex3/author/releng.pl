use strict;
use warnings;
use utf8;

use File::Spec;
use File::Basename qw/dirname/;
my $BASE_DIR = File::Spec->catdir(dirname(__FILE__), File::Spec->updir(dirname(__FILE__)));

sub slurp {
    my $file = shift;
    open my $fh, '<:encoding(utf-8)', $file;
    return do { local $/; <$fh> };
}

sub spew {
    my $file = shift;
    open my $fh, '>:encoding(utf-8)', $file;
    print $fh @_;
}

print "Next version: ";
chomp(my $version = <STDIN>);
if ($version =~ /\A([0-9])\.([0-9])([0-9])\z/m) {
    my $major_version = $1;
    my $minor_version = $2;
    my $patch_version = $3;

    my $geohex3_h_path = File::Spec->catfile($BASE_DIR, 'include', 'geohex3.h');
    my $geohex3_h_body = slurp($geohex3_h_path);
    $geohex3_h_body =~ s/(?<=^#define GEOHEX3_MAJOR_VERSION)(\s+)[0-9]/$1$major_version/m;
    $geohex3_h_body =~ s/(?<=^#define GEOHEX3_MINOR_VERSION)(\s+)[0-9]/$1$minor_version/m;
    $geohex3_h_body =~ s/(?<=^#define GEOHEX3_PATCH_VERSION)(\s+)[0-9]/$1$patch_version/m;
    $geohex3_h_body =~ s/(?<=^#define GEOHEX3_VERSION)(\s+)"[0-9]\.[0-9][0-9]"/$1"$version"/m;
    spew($geohex3_h_path, $geohex3_h_body);

    my $readme_path = File::Spec->catfile($BASE_DIR, 'README.md');
    my $readme_body = slurp($readme_path);
    $readme_body =~ s/(?<=^VERSION: )[0-9]\.[0-9][0-9]/$version/m;
    spew($readme_path, $readme_body);

    system 'git', 'commit', '-a', -m => "tagged version as $version";
    system 'git', 'tag', $version;
    system 'git', 'push';
    system 'git', 'push', '--tags';
}
else {
    die "Invalid format."
}
