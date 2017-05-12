use strict;
use warnings FATAL => 'all';
use IO::Pipeline;
use Test::More qw(no_plan);

my $source = <<'END';
2010-03-21 16:15:30 1NtNoI-000658-6V Completed
2010-03-21 16:17:29 1NtNlx-00062B-0R Completed
2010-03-21 16:20:37 1NtNtF-0006AE-G6 Completed
2010-03-21 16:28:37 no host name found for IP address 218.108.42.254
2010-03-21 16:28:51 H=(ZTZUWWCRQY) [218.108.42.254] F=<pansiesyd75@setupper.com> rejected RCPT <inline@trout.me.uk>: rejected because 218.108.42.254 is in a black list at zen.spamhaus.org
2010-03-21 16:28:51 unexpected disconnection while reading SMTP command from (ZTZUWWCRQY) [218.108.42.254] (error: Connection reset by peer)
2010-03-21 16:35:57 no host name found for IP address 123.122.231.66
2010-03-21 16:35:59 H=(LFMTSDM) [123.122.231.66] F=<belladonnai6@buybuildanichestore.com> rejected RCPT <tal@fyrestorm.co.uk>: rejected because 123.122.231.66 is in a black list at zen.spamhaus.org
END

sub input_fh {
  open my $in, '<', \$source;
  return $in;
}

my $out;

my $pipe = input_fh
  | pmap { [ /^(\S+) (\S+) (.*)$/ ] }
  | pgrep { $_->[2] =~ /rejected|Completed/ }
  | pmap { [ @{$_}[0, 1], $_->[2] =~ /rejected/ ? 'Rejected' : 'Completed' ] }
  | pmap { join(' ', @$_)."\n" }
  | psink { $out .= $_ };

is($out, <<'END', 'Output ok');
2010-03-21 16:15:30 Completed
2010-03-21 16:17:29 Completed
2010-03-21 16:20:37 Completed
2010-03-21 16:28:51 Rejected
2010-03-21 16:35:59 Rejected
END
