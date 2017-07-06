package # hidden from PAUSE indexer
Show;
our $VERSION = '0.000001';

use 5.012; use warnings;

use Keyword::Declare;

sub import {

    keyword show (Expr $expr) {
        use List::Util 'max';

        # Flatten the expression to a single line...
        $expr =~ s{\s+}{ }g;

        # Simple arrays and hashes need to be dumped by reference...
        my $ref = $expr =~ /^[\@%][\w:]++$/ ? q{\\} : q{};

        # Locate the call...
        my (undef, $filename, $linenum) = caller(1);

        # Compile the header...
        my $header = "#===[  $expr  ]";
        my $loc    = "( $filename line $linenum )===#";
        my $middle = '=' x max(5, 79-length($header)-length($loc));

        # Generate the source...
        return qq{
            use Data::Dump 'dump';

            say q{${header}${middle}${loc}} . "\n\n"
              . (dump($ref $expr) =~ s{^}{      }grxms)
              . "\n"
        };
    }

}

sub unimport {
    keyword show (Expr $expr) {};
}

1;
