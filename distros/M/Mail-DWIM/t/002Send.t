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

plan tests => 10;

  # no raise_error
my $rc = mail(
  from    => 'foo@foo.com',
  to      => 'bar@bar.com',
  subject => 'subject test 1',
  text    => 'text test 2',
  transport => 'smtp',
  raise_error => 0,
);

ok(!$rc, "SMTP server missing");
like(Mail::DWIM::error(), qr/No smtp_server set/, "Error set in error()");

my($fh, $file) = tempfile( UNLINK=>1 );

$ENV{MAIL_DWIM_TEST} = $file;
  # 
mail(
  from    => 'foo@foo.com',
  to      => 'bar@bar.com',
  subject => 'subject test 1',
  text    => 'text test 2',
);

my $data = Mail::DWIM::slurp($file);

like($data, qr/\n\ntext test 2/, "regular mail");
like($data, qr/^To: bar\@bar.com/m, "regular mail");
Mail::DWIM::blurt("", $file);

SKIP: {

    if(! Mail::DWIM::html_requirements()) {
        skip "@Mail::DWIM::HTML_MODULES not installed", 3;
    }

      # html test
    mail(
      from    => 'foo@foo.com',
      to      => 'bar@bar.com',
      subject => 'subject test 1',
      text    => 'text <i>test</i> 2',
      html_compat => 1
    );
    
    $data = Mail::DWIM::slurp($file);
    
    like($data, qr/^Subject: subject test 1/m, "html mail");
    like($data, qr/^Content-Type: multipart\/alternative/m, "html mail");
    like($data, qr/multi-part/m, "html mail");
};

Mail::DWIM::blurt("", $file);
my($tfh, $tmpfile) = tempfile(UNLINK => 1);
Mail::DWIM::blurt("text yaya", $tmpfile);

SKIP: {

    if(! Mail::DWIM::attach_requirements()) {
        skip "@Mail::DWIM::ATTACH_MODULES not installed", 3;
    }

      # attach test
    mail(
      from    => 'foo@foo.com',
      to      => 'bar@bar.com',
      subject => 'subject test 1',
      text    => 'here is a pic',
      attach  => [ $tmpfile ],
    );
    
    $data = Mail::DWIM::slurp($file);
    
    like($data, qr/^Subject: subject test 1/m, "attach mail");
    like($data, qr/^Content-Type: multipart\/mixed/m, "attach mail");
    like($data, qr/multi-part/m, "attach mail");
};
