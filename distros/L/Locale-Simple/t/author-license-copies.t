
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;

# The npm, PyPI and crates.io packages each ship their own LICENSE file,
# because each package is built from its own directory. All three carry the
# copyright line; the license text after it is the one in the root LICENSE.

sub slurp {
    my ( $file ) = @_;
    open my $fh, '<', $file or die "$file: $!";
    local $/;
    return scalar <$fh>;
}

sub words { my ( $text ) = @_; return join ' ', split ' ', $text }

my $js = slurp('js/LICENSE');
is slurp("$_/LICENSE"), $js, "$_/LICENSE matches js/LICENSE" for qw( python rust );

like $js, qr/^Copyright \(c\) \d{4} Torsten Raudssus$/m, 'the package copies name the copyright holder';

( my $body = $js ) =~ s/\A.*?^Copyright[^\n]*\n//ms;
( my $root = slurp('LICENSE') ) =~ s/\A[^\n]*\n//;
is words($body), words($root), 'the package copies carry the root license text';

done_testing;
