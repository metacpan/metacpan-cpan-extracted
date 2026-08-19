######################################################################
# Test suite for Mail::DWIM
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Mail::DWIM qw(mail);
use File::Temp qw(tempfile);
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

plan tests => 1;

my($fh, $file) = tempfile( UNLINK=>1 );

$ENV{MAIL_DWIM_TEST} = $file;

mail(
  from    => 'foo@foo.com',
  to      => 'bar@bar.com',
  subject => 'subject test 1',
  text    => 'text test 2',
  transport => "smtp",
  smtp_server => "smtp.wonko.com",
  user    => "testuser",
  password => "testpass",
);

my $data = Mail::DWIM::slurp($file);

like($data, qr/SSL 1/, "ssl set");
