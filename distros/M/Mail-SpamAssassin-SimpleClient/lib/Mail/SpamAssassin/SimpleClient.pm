use strict;
use warnings;
use 5.006;
package Mail::SpamAssassin::SimpleClient;
{
  $Mail::SpamAssassin::SimpleClient::VERSION = '0.102';
}
# ABSTRACT: easy client to SpamAssassin's spamd

use Carp ();
use Email::MIME;
use Mail::SpamAssassin::Client;
use Mail::SpamAssassin::SimpleClient::Result;


sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  $arg->{host} = 'localhost' unless defined $arg->{host};
  $arg->{port} = 783 unless defined $arg->{port};
  $arg->{timeout} = 120 unless defined $arg->{timeout};

  bless $arg => $class;
}


sub check {
  my ($self, $message) = @_;

  local $SIG{ALRM} = sub {
    Carp::croak "SpamAssassin failed to respond within $self->{timeout}s";
  };

  alarm $self->{timeout};

  # Maybe we should keep one spamc and ping each check.  Whatever, I'll deal
  # with that when it turns out to matter. -- rjbs, 2007-03-21
  my $spamc = Mail::SpamAssassin::Client->new({
    host => $self->{host},
    port => $self->{port},
    ($self->{username} ? (username => $self->{username}) : ()),
  });

  my $response = $spamc->process($message->as_string);

  alarm 0;
# X-Spam-Flag: YES
# X-Spam-Checker-Version: SpamAssassin 3.1.0 (2005-09-13) on emerald.pobox.com
# X-Spam-Status: Yes, score=1000.8 required=5.0 tests=ENGLISH_UCE_SUBJECT,GTUBE,
#   NO_REAL_NAME,NO_RECEIVED,NO_RELAYS autolearn=no version=3.1.0
# X-Spam-Level: **************************************************
# X-Spam-Report: *  1.4 NO_DNS_FOR_FROM DNS: Envelope sender has no MX or A DNS records *  0.0 MISSING_MID Missing Message-Id: header * -0.0 NO_RELAYS Informational: message was not relayed via SMTP

  # use Data::Dumper;
  # warn Dumper($response);

  my $response_email = Email::MIME->new($response->{message});

  # We can't just look for tests=\S because when the tests wrap and are
  # unfolded, a space is introduced betwen tests.
  my $status = $response_email->header('X-Spam-Status');

  $status =~ s/,\s([A-Z])/,$1/g;
  my ($tests) = $status =~ /tests=(.+?)(?:\s[a-z]|$)/;
  my ($version) = $status =~ /version=(\S+)/;

  my @tests = split /,/, $tests;

  # isspam will be True or False
  # score
  # threshold

  my (%test_score, %test_desc);

  if ($response->{isspam} eq 'True') {
    # prefer the X-Spam-Report header before checking the body
    my $report = $response_email->header('X-Spam-Report');
    if( $report ) {
        foreach my $report_part (split(/\s*\*\s*/, $report)) {
            next unless $report_part;
            my ($score, $name, $desc) = $report_part =~ /^(-?[\d.]+)\s+(\S+)\s+(.*)$/;
            $test_score{ $name } = $score;
            $test_desc{ $name } = $desc;
        }
    } else {
      ($report) = ($response_email->parts)[0];

      my $past_header;
      LINE: for my $line (split /\n/, $report->body) {
        next if not($past_header) and not($line =~ /^\s*---- -/);
        $past_header = 1, next if not $past_header;
  
        my ($score, $name) = $line =~ /\s*(-?[\d.]+)\s+(\S+)/;
        next LINE unless defined $name;
        $test_score{ $name } = $score;
      }
    }
  }

  return Mail::SpamAssassin::SimpleClient::Result->new({
    is_spam    => $response->{score} > $response->{threshold},
    score      => $response->{score},
    threshold  => $response->{threshold},
    version    => $version,
    email      => $response_email,

    tests      => %test_score
                ? \%test_score
                : { map { $_ => undef } @tests },
    test_desc  => %test_desc
                ? \%test_desc
                : { map { $_ => undef } @tests },
  });
}



1;

__END__

=pod

=head1 NAME

Mail::SpamAssassin::SimpleClient - easy client to SpamAssassin's spamd

=head1 VERSION

version 0.102

=head1 WARNING

B<Achtung!>

This module is still in its infancy.  Its interface will probably change
somewhat, especially if some changes are made to the spamd protocol to make
this module awesomer.  Please don't rely on it.  Just play with it and try to
help figure out how to make it great.

=head1 SYNOPSIS

  my $spamc = Mail::SpamAssassin::Simpleclient->new;

  die "It's horrible, horrible spam!" if $spamc->check($message)->is_spam;

=head1 DESCRIPTION

Mail::SpamAssassin is a great, free tool for identifying spam messages.  It is
generally accessed via the F<spamc> or F<spamassassin> programs.  Despite the
fact that SpamAssassin in implemented in Perl, it is often difficult to check a
message against SpamAssassin from within a Perl program.

This module provides a very simple (but also limited) interface to check mail
against SpamAssassin.

=head1 METHODS

=head2 new

  my $client = Mail::SpamAssassin::SimpleClient->new(\%arg);

This method returns a new SimpleClient object.

Valid arguments are:

  host     - the host on which to look for spamd (default: localhost)
  port     - the port on which to look for spamd (default: 783)
  username - username to pass to spamd
  timeout  - how long (in seconds) to allow SpamAssassin to consider the
             message before an exception is raised; default 120;  set to 0 to
             wait forever

=head2 check

  my $result = $spamc->check($message);

This method passes a message to SpamAssassin to be spam-checked.  It returns a
L<Mail::SpamAssassin::SimpleClient::Result> object.  If SpamAssassin does not
respond within the SimpleClient's timeout period, an exception is raised.

=head1 TODO

Support spamd-less operation.

Get the protocol to support "always rewrite" or another way to always get
scores.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
