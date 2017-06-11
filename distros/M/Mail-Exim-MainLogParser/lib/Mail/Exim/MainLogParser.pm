package Mail::Exim::MainLogParser;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(&EximMainLoglineParse);
    %EXPORT_TAGS = ();
}

BEGIN {
  use vars      qw(%EXIM_FLAGS %EXIM_FIELD_IDENFIERS);

  # As of 2017-06-08
  # Source: http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html
  %EXIM_FLAGS = (
	'<='	=>	'message arrival',
	'(='	=>	'message fakereject',
	'=>'	=>	'normal message delivery',
	'->'	=>	'additional address in same delivery',
	'>>'	=>	'cutthrough message delivery',
	'*>'	=>	'delivery suppressed by -N',
	'**'	=>	'delivery failed; address bounced',
	'=='	=>	'delivery deferred; temporary problem',
  );
  %EXIM_FIELD_IDENFIERS = (
	A	=>	'authenticator name (and optional id and sender)',
	C	=>	('SMTP confirmation on delivery'.			'; '.
			'command list for "no mail in SMTP session”'),
	CV	=>	'certificate verification status',
	D	=>	'duration of "no mail in SMTP session”',
	DN	=>	'distinguished name from peer certificate',
	DS	=>	'DNSSEC secured lookups',
	DT	=>	'on => lines: time taken for a delivery',
	F	=>	'sender address (on delivery lines)',
	H	=>	'host name and IP address',
	I	=>	'local interface used',
	K	=>	'CHUNKING extension used',
	id	=>	'message id for incoming message',
	P	=>	('on <= lines: protocol used'. 				'; '.
			'on => and ** lines: return path'),
	PRDR	=>	'PRDR extension used',
	PRX	=>	'on <= and => lines: proxy address',
	Q	=>	'alternate queue name',
	QT	=>	('on => lines: time spent on queue so far'. 		'; '.
			'on "Completed” lines: time spent on queue'),
	R	=>	('on <= lines: reference for local bounce'. 		'; '.
			'on =>  >> ** and == lines: router name'),
	S	=>	'size of message in bytes',
	SNI	=>	'server name indication from TLS client hello',
	ST	=>	'shadow transport name',
	T	=>	('on <= lines: message subject (topic)'. 		'; '.
			'on => ** and == lines: transport name'),
	U	=>	'local user or RFC 1413 identity',
	X	=>	'TLS cipher suite'
    );
}


sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}

sub _exim_log_main__parse($) {
  my $line = shift || return undef;
  my @line = split(/\s/,$line);
  return undef unless scalar @line >= 3;
  my $l = {
    date => shift @line,
    time => shift @line
  };

  # Exim ID: 1dIyz2-0002mc-5x
  if ($line[0] =~ /......\-......\-../) {
    $l->{eximid} = shift @line;
  } else {
    $l->{eximid} = undef;
  }

  # Exim log line flag
  if ($line[0] =~ /\<\=|\(\=|\=\>|\-\>|\>\>|\*\>|\*\*|\=\=/) {
    $l->{flag} = shift @line;
  } else {
    # mail rejected or completed!
    $l->{flag} = undef;
  }

  # Exim Mail Address
  if (($line[0] !~ /^[A-Zid]{1,4}\=.+/) && ($line[0] =~ /.+\@.+/)) {
    $l->{address} = shift @line;
    while ((defined $line[0]) && ($line[0] !~ /^[A-Zid]{1,4}\=.+/)) {
      if ( ((!defined $l->{flag}) || ((defined $l->{flag}) && ($l->{flag} eq '**'))) && ($l->{address} =~ /\:$/)) {
        chop $l->{address};
        last;
      }
      $l->{address} .= (" " . shift @line);
    }
  }

  # Exim field identifiers and messages
  $l->{args} = [];
  while (scalar @line >= 1) {
    if ($line[0] =~ /^([A-Zid]{1,4})\=(.+)/) {
      my $this_arg = $1;
      my $this_val = $2;
      shift @line;
      while ( (scalar @line >= 1) && (($line[0] =~ /^\[.+\]/) || ($line[0] =~ /^\(.+\)/)) ) {
        $this_val .= (" " . shift @line);
      }
      push(@{$l->{args}},{$this_arg => $this_val});
    } else {
      $l->{message} = shift @line;
      while ((defined $line[0]) && ($line[0] !~ /^[A-Zid]{1,4}\=.+/)) {
        $l->{message} .= (" " . shift @line);
      }
    }
  }

  if (scalar @line >= 1) {
    die ("Error Parsing Line: $line\n"."Unparsed log line data: ".join("; ",@line)."\n");
  }

  return $l;
}

sub EximMainLoglineParse($) {
  return _exim_log_main__parse($_[0]);
}

sub parse($) {
  my $self = shift;
  return _exim_log_main__parse($_[0]);
}

1;
__END__

=head1 NAME

Mail::Exim::MainLogParser - Parse log lines from the Exim Main Log

=head1 SYNOPSIS

  use Mail::Exim::MainLogParser;
  use Data::Dumper;
  my $exlog = new Mail::Exim::MainLogParser;

  my $logline = "2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101] P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com";
  $logLineHashStructure = $exlog->parse($logline);

  print Dumper($logLineHashStructure);
  $VAR1 = {
          'eximid' => '1dJ08B-0003oP-5i',
          'time' => '11:17:56',
          'date' => '2017-06-08',
          'args' => [
                      {
                        'H' => 'realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]'
                      },
                      {
                        'P' => 'esmtp'
                      },
                      {
                        'S' => '1364'
                      },
                      {
                        'id' => '266785270.3.2385849643852@peerhost.server.example.com'
                      }
                    ],
          'address' => 'do-not-reply@nowhere.com',
          'flag' => '<='
        };

=head1 DESCRIPTION

This module will parse log lines from Exim version 4, according to the source
http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html
as of 2017-06-08

=head1 REQUIREMENTS

This module is pure perl and does not depend on other modules. But does
depend on a log file from Exim version 4 main log output.

=over 4

=item * Exim 4

=back

=head1 IMPORTED METHODS

When the calling application invokes this module in a use clause, the following
method can be imported into its space.

=over 4

=item *     C<EximMainLoglineParse>

=back

=head1 METHODS

=head2 new

Create a new object instances of this module.
It is not necessary to create an object for this module, as the methods can
be called outside of OO style programming.

=over 4

=item * I<returns>

An object instance of this module.

=back

    my $eximlog = new Mail::Exim::MainLogParser();


=head2 EximMainLoglineParse

See C<parse()>.

=head2 parse

Parse a line from the Exim main log file and return a hash structure.

    $logLineHashStructure = $exlog->parse($logline);

=over 4

=item * B<exim_main_log_line>

This is a single line from the Exim main log output.
The below example log line is split over several lines in order to fit it on the page.

    2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com
        H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]
        P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com

=back

This method returns a hash structure of the parsed log line.

    print Dumper($logLineHashStructure);
    $VAR1 = {
          'eximid' => '1dJ08B-0003oP-5i',
          'time' => '11:17:56',
          'date' => '2017-06-08',
          'args' => [
                      {
                        'H' => 'realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]'
                      },
                      {
                        'P' => 'esmtp'
                      },
                      {
                        'S' => '1364'
                      },
                      {
                        'id' => '266785270.3.2385849643852@peerhost.server.example.com'
                      }
                    ],
          'address' => 'do-not-reply@nowhere.com',
          'flag' => '<='
        };

=head1 AUTHOR

Russell Glaue, http://russ.glaue.org

=head1 SEE ALSO

Exim4 log documentation: http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html

=head1 COPYRIGHT

Copyright (c) 2017 Russell E Glaue,
Center for the Application of Information Technologies,
Western Illinois University
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

