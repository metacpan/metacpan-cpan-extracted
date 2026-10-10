use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2TestKeys;
use Mail::DKIM2;

# The SYNOPSIS in Mail::DKIM2 and the one in README are the first code a
# user copies; both once failed silently (review R10, R11: signing a message
# with no Message-Instance, verifying the unsigned message). Run the code
# from the module's POD, with only its placeholders replaced: the test
# domain and key, and a stand-in DNS resolver.

sub synopsis {
    my ($file, $start, $end) = @_;
    open my $fh, '<', $file or die "$file: $!";
    my $text = do { local $/; <$fh> };
    my ($block) = $text =~ /\Q$start\E\n(.*?)\n(?:\Q$end\E)/s
        or die "no SYNOPSIS in $file";
    return $block;
}

my $pod    = synopsis("$FindBin::Bin/../lib/Mail/DKIM2.pm", "=head1 SYNOPSIS\n", '=head1');
my $readme = synopsis("$FindBin::Bin/../README", "SYNOPSIS\n", 'SEE ALSO');
is($readme, $pod, 'README shows the same SYNOPSIS as Mail::DKIM2');

my $code = $pod;
$code =~ s/example\.com/test1.dkim2.com/g;
my $keyfile = DKIM2TestKeys::keys_dir() . '/sel1._domainkey.test1.dkim2.com.pem';
ok(-e $keyfile, "test key $keyfile");
$code =~ s{'/etc/dkim2/sel1\.pem'}{'$keyfile'};
$code =~ s/Mail::DKIM2::Verifier->new\b/Mail::DKIM2::Verifier->new(Resolver => DKIM2TestKeys::resolver())/g;

my $message = "From: sender\@test1.dkim2.com\r\nTo: recipient\@example.net\r\n"
            . "Subject: synopsis\r\n\r\nHello.\r\n";
my @chunks = ($message);
my $chunk;
my $out = '';
{
    local *STDOUT;
    open STDOUT, '>', \$out or die;
    eval "$code; 1" or die "SYNOPSIS died: $@";
}
like($out, qr/^pass \(i=1\.\.1 verified\)$/m, "the SYNOPSIS verifies what it signed: $out");

done_testing;
