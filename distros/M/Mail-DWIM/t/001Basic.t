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

#Log::Log4perl->easy_init($DEBUG);

plan tests => 5;

my($fh, $file) = tempfile(UNLINK => 1);
$ENV{MAIL_DWIM_TEST} = $file;

my($fhg, $gcfg) = tempfile();
my($fhu, $ucfg) = tempfile();

  # Local overrides global
Mail::DWIM::blurt("from: goof\@goof.com\n", $gcfg);
Mail::DWIM::blurt("from: goof2\@goof.com\n", $ucfg);
my $m = Mail::DWIM->new(
  global_cfg_file => $gcfg,
  user_cfg_file   => $ucfg,
);
is($m->{from}, 'goof2@goof.com', "user cfg overrides global");

  # Test 'from' override of conf files
$m = Mail::DWIM->new(
  global_cfg_file => $gcfg,
  user_cfg_file   => $ucfg,
  from    => 'a@b.com',
  to      => 'c@d.com',
  subject => 'This is the subject line',
  text    => 'This is the mail text',
);
$m->send();
my $data = Mail::DWIM::slurp($file);
like($data, qr/From: a\@b.com/, "'From' override of cfg file");

  # No local, just global
Mail::DWIM::blurt("", $ucfg);
$m = Mail::DWIM->new(
  global_cfg_file => $gcfg,
  user_cfg_file   => $ucfg,
);
is($m->{from}, 'goof@goof.com', "global cfg");

  # Empty conf files
Mail::DWIM::blurt("", $ucfg);
Mail::DWIM::blurt("", $gcfg);
$m = Mail::DWIM->new(
  global_cfg_file => $gcfg,
  user_cfg_file   => $ucfg,
);
like($m->{from}, qr/\S\@\S/, "from: determined by user/domain");

  # No conf files
unlink $ucfg;
unlink $gcfg;
$m = Mail::DWIM->new(
  global_cfg_file => $gcfg,
  user_cfg_file   => $ucfg,
);
like($m->{from}, qr/\S\@\S/, "from: determined by user/domain");

