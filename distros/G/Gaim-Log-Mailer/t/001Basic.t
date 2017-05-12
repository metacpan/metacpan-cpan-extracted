######################################################################
# Test suite for Gaim::Log::Mailer
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use File::Temp qw(tempfile);

plan tests => 2;

my($fh, $file) = tempfile(UNLINK => 1);

print $fh <<EOT;
logfile: somewhere
email_to: foo\@bar.com
EOT

close $fh;

use Gaim::Log::Mailer;

my $mailer = Gaim::Log::Mailer->new(config_file => $file);

is($mailer->{conf}->{logfile}, "somewhere");
is($mailer->{conf}->{email_to}, 'foo@bar.com');
