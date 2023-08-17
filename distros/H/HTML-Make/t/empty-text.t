# Test we get the correct warnings and errors with bad text entries.
# It's a common error in practice to get either empty text or
# undefined text. We don't warn or error if the text is empty, but we
# do if it is undefined.

use FindBin '$Bin';
use lib "$Bin";
use HMT;

my $warnings;
$SIG{__WARN__} = sub {
    $warnings = "@_";
};
my $text = HTML::Make->new ('h1', text => '');
ok (! $warnings, "No warnings with empty text");
my $undef = HTML::Make->new ('h1', text => undef);
ok ($warnings, "Warnings with undef text");
done_testing ();
