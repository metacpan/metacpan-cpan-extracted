use strict;
use warnings;
use English;
use Graphics::TIFF ':all';
use Test::More tests => 2;

my $git;
SKIP: {
    skip 'Need the git repository to compare the MANIFEST.', 1
      unless (
        -d '.git'
        and eval {
            $git = `git ls-tree --name-status -r HEAD | grep -E -v '^\.git'`;
        }
      );
    is( $git, `cat MANIFEST`, 'MANIFEST up to date' );
}

local $INPUT_RECORD_SEPARATOR = undef;
my $file = $INC{'Graphics/TIFF.pm'};
open my $fh, '<:encoding(UTF8)', $file
  or die "Error: cannot open $file\n";
my $text = <$fh>;
close $fh or die "Error: cannot close $file\n";

if ( $text =~ /=head1\s+VERSION\s+([0-9][.]?[0-9]*)/xsm ) {
    my $version = $1;
    is( $version, $Graphics::TIFF::VERSION,
        'version number correctly documented' );
}
else {
    fail 'version string not found';
}
