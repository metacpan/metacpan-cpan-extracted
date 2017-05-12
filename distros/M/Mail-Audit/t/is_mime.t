#!perl
use strict;
use warnings;

use File::Spec ();
use File::Temp ();

use Test::More 'no_plan';

BEGIN { use_ok('Mail::Audit'); }

sub readfile {
  my ($name) = @_;
  local *MESSAGE_FILE;
  open MESSAGE_FILE, "<$name" or die "coudn't read $name: $!";
  my @lines = <MESSAGE_FILE>;
  close MESSAGE_FILE;
  return \@lines;
}

my $flat_message = readfile('t/messages/simple.msg');
my $mime_message = readfile('t/messages/mime-text.msg');

{
  my $audit = Mail::Audit->new(
    data      => $flat_message,
    log       => "/dev/null",
  );

  ok(!$audit->is_mime, "A flat message isn't MIME.");

  is($audit->subject, 'gorp', 'subject correct');
  is($audit->get('subject'), 'gorp', 'subject correct (via header)');

  my @subject = $audit->get('subject');
  is_deeply(\@subject, ["gorp"], "subject correct (via header, list context)");

}

{
  my $audit = Mail::Audit->new(
    data      => $mime_message,
    log       => "/dev/null",
  );

  ok($audit->is_mime, "A mime message is MIME, of course.");

  is($audit->subject, 'text attached', 'subject correct');
  is($audit->get('subject'), 'text attached', 'subject correct (via header)');

  my @subject = $audit->get('subject');
  is_deeply(
    \@subject,
    ["text attached"],
    "subject correct (via header, list context)"
  );
}
