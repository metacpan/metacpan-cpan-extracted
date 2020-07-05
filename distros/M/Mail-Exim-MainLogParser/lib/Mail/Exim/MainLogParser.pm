package Mail::Exim::MainLogParser;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.02';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(&EximMainLoglineParse EximMainLoglineCompose);
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
  if ($line !~ m/^\d{4}\-\d{2}-\d{2}\s\d{2}\:\d{2}\:\d{2}( [\-\+]\d{4})?/o) {
    warn __PACKAGE__,": Exim log line not in expected format.";
    return undef;
  }
  # Split the line by spaces, and examine each element
  my @line = split(/\s/,$line);
  # To pass this simple filter the string must have a minimum of three elements
  # <date> <time> [ <timezone> | <processid> | <eximid> | <reject or panic message> ]
  return undef unless scalar @line >= 3;
  my $l = {
    'date' => shift @line,
    'time' => shift @line
  };
  # detect if a time zone is provided # Exim: log_timezone=true
  # 2003-04-25 11:17:07 +0100 Start queue run: pid=12762
  if ($line[0] =~ /\+\d{4}/) {
    $l->{'timezone'} = shift @line;
  }

  # detect is the Exim process Id is provided # Exim: log_selector = +pid
  # The parser should not be modifying data, only understanding and separating it
  # For this reason: 'pid': "[<pid>]" , as given in the log line
  if ($line[0] =~ /\[\d+\]/) {
    $l->{'pid'} = shift @line;
  }

  # Exim ID Format: 1dIyz2-0002mc-5x
  if ($line[0] =~ /[a-zA-Z0-9]{6}\-[a-zA-Z0-9]{6}\-[a-zA-Z0-9]{2}/) {
    $l->{'eximid'} = shift @line;
  } else {
    # $l->{'eximid'} = undef;
  }

  # Exim log line flag
  if ($line[0] =~ /\<\=|\(\=|\=\>|\-\>|\>\>|\*\>|\*\*|\=\=/) {
    $l->{'flag'} = shift @line;
  } else {
    # mail rejected or completed
    # $l->{'flag'} = undef;
  }

  return $l if ! scalar @line >= 1;

  # If the flag is undefined or delivery failure, then detect either the message or the field identifiers
  # 2020-06-07 18:10:24 1ji4Qp-0002jY-UD Completed
  # 2020-06-07 18:12:18 1ji4Sf-0002jl-Vk H=ugso.tenet.odessa.ua (ugso.odessa.ua) [195.138.65.238] F=<test@giftvoucherkiosk.com> rejected after DATA: Your message scored 17.4 SpamAssassin point. Report follows:
  if ( ((!exists $l->{'flag'}) || (!defined $l->{'flag'})) || ($l->{'flag'} eq "**") ) {

    if ( ($line[0] !~ /^[A-Zid]{1,4}\=.*/) || (($line[0] =~ /^([A-Zid]{1,4})\=.*/) && (!exists $EXIM_FIELD_IDENFIERS{$1})) ) {
      # If the element does not start with a known field identifier, we assume the whole line is a message
      while (scalar @line >= 1) {
        $l->{'message'} .= (" ") if defined $l->{'message'};
        $l->{'message'} .= shift @line;
      }
    }

  # If the flag is defined and not a delivery failure, then we expect a mail destination (e.g. email, system pipe, system file, etc)
  } else {

    # Exim Address could be email address, pipe, file, and a string combination of several of these elements
    # 2020-06-07 23:44:57 1ji9ea-0003oh-Tt => :blackhole: <realperson@realdomain> R=pipe_to_useraddress
    # 2020-06-07 21:49:23 1ji7qj-0003Ud-Ss => |/usr/bin/listmgr-queue listmgr <listmgr@realdomain> R=pipe_to_listmgr T=address_pipe
    # Skip email detection if element is AAAA=somevalue or id=somevalue, a simple field identifier matcher (where A is alpha)
    # For deferred deliveries (i.e. == flag) email could be: some-identified-realperson=realdomain@some-domain
    while (   (scalar @line >= 1)
           && (   ($line[0] !~ /^[A-Zid]{1,4}\=.*/)
               || (($line[0] =~ /^([A-Zid]{1,4})\=.*/) && (!exists $EXIM_FIELD_IDENFIERS{$1}))
              )
          ) {
      # The element is appended to address until matching a known field identifier
      $l->{'address'} .= (" ") if defined $l->{'address'};
      $l->{'address'} .= shift @line;
    }
  }

  return $l if ! scalar @line >= 1;

  # Exim field identifiers and identifier messages
  $l->{'args'} = [];
  while (scalar @line >= 1) {
    # Matching anything that looks like a field identifier, rather than looking each up in the $EXIM_FIELD_IDENFIERS hash
    if ( ($line[0] =~ /^([A-Zid]{1,4})\=(.*)/) && (exists $EXIM_FIELD_IDENFIERS{$1}) ) {
      my $this_arg = $1;
      my $this_val = $2;
      shift @line;
      while ( (scalar @line >= 1) && (($line[0] !~ /^([A-Zid]{1,4})\=(.*)/) || (!exists $EXIM_FIELD_IDENFIERS{$1})) ) {
        $this_val .= (" " . shift @line);
      }
      push(@{$l->{'args'}},{$this_arg => $this_val});
    } else {
      # If the field identifier is not detected, fall back to message
      # This should only happen if the text in the element does not match any field identifiers
      $l->{'message'} = shift @line;
      while ( (scalar @line >= 1) && (($line[0] !~ /^([A-Zid]{1,4})\=(.*)/) || (!exists $EXIM_FIELD_IDENFIERS{$1})) ) {
        $l->{'message'} .= (" " . shift @line);
      }
    }
  }

  if (scalar @line >= 1) {
    warn ("Error Parsing Line: $line\n"."Unparsed log line data: ".join("; ",@line)."\n");
  }

  return $l;
}

sub _exim_log_main__compose ($) {
  my $parsed = shift || return undef;
  return undef unless ref $parsed eq "HASH";
  my @s_args;
  foreach my $arg (@{$parsed->{'args'}}) {
      push(@s_args, map{qq{$_=$arg->{$_}}} keys %$arg)
  }
  my @s_line;
  push(@s_line,$parsed->{'date'})     if exists $parsed->{'date'};
  push(@s_line,$parsed->{'time'})     if exists $parsed->{'time'};
  push(@s_line,$parsed->{'timezone'}) if exists $parsed->{'timezone'};
  push(@s_line,$parsed->{'pid'})      if exists $parsed->{'pid'};
  push(@s_line,$parsed->{'eximid'})   if exists $parsed->{'eximid'};
  push(@s_line,$parsed->{'flag'})     if exists $parsed->{'flag'};
  push(@s_line,$parsed->{'address'})  if exists $parsed->{'address'};
  push(@s_line, join(" ", @s_args)) if @s_args >= 1;
  push(@s_line,$parsed->{'message'})  if exists $parsed->{'message'};
  return(join(" ", @s_line));
}

sub EximMainLoglineParse($) {
  return _exim_log_main__parse($_[0]);
}

sub EximMainLoglineCompose($) {
  return _exim_log_main__compose($_[0]);
}

sub parse($) {
  my $self = shift;
  return _exim_log_main__parse($_[0]);
}

sub compose($) {
  my $self = shift;
  return _exim_log_main__compose($_[0]);
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

=item *     C<EximMainLoglineCompose>

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

    $exim_log_line_hash = $exlog->parse($exim_log_line_string);

=over 4

=item * B<exim_log_line_string>

This is a single line from the Exim main log output.
The below example log line is split over several lines in order to fit it on the page.

    2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com
        H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]
        P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com

=back

This method returns a hash structure of the parsed log line.

    print Dumper($exim_log_line_hash);
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


=head2 EximMainLoglineCompose

See C<compose()>.

=head2 compose

Compose a log line from a parsed main log line hash and return as a string.

    $exim_log_line_composed = $exlog->compose($exim_log_line_hash)

=over 4

=item * B<exim_log_line_hash>

This is a single parsed line from the Exim main log output represented as a HASH.

    $exim_parsed_main_log_line = {
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

=back

This method returns a string composition of the parsed log line HASH structure.
It is intended that the composed string matches the original log line that was
parsed, minus trailing white space.

    print "$LoglineComposed";
    2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com
        H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]
        P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com

=head1 EXAMPLES

=head2 Show exim mail transactions for a particular email address

    use Mail::Exim::MainLogParser;
    $exilog = new Mail::Exim::MainLogParser();
    my $emailaddress='me@example.com';
    my $index = {};
    my @mine_queued = ();
    my $line_count = 0;
    # open(EXIMLOG,"tail -f /var/log/exim/main.log |");  # Use `tail -f` to watch logs in real time
    open(EXIMLOG,"cat /var/log/exim/main.log |");
    while (my $line = <EXIMLOG>) {
        $line_count++;
        chomp($line);
        my $parsed = $exilog->parse($line) || (warn "Warn: Could not parse line $line_count.\n" && next);
        # Add each transaction to an eximid index
        if (exists $parsed->{'eximid'}) {
            push(@{$index->{$parsed->{'eximid'}}}, $parsed);
        }
        # Track the exim transactions that send or deliver via my email address
        if ((exists $parsed->{'address'}) && ($parsed->{'address'} =~ /$emailaddress/i)) {
            push(@mine_queued,$parsed->{'eximid'});
        }
        # Once a queued message is completed, print out transactions if mine, delete it
        if ((exists $parsed->{'message'}) && ($parsed->{'message'} =~ /Completed/i)) {
            my $eximid = $parsed->{'eximid'};
            if (grep /$eximid/, @mine_queued) {
                foreach my $eximtransaction (@{$index->{$eximid}}) {
                    print $exilog->compose($eximtransaction),"\n";
                }
                @mine_queued = grep ! /$eximid/, @mine_queued;
            }
            delete $index->{$eximid};
        }
    }
    if (scalar @mine_queued >= 1) {
        # Once we reach the end of the log, there may still be messages that have not completed yet
        print "#"x10," My Uncompleted Messages ","#"x10,"\n";
        foreach my $eximid (@mine_queued) {
            foreach my $eximtransaction (@{$index->{$eximid}}) {
                print $exilog->compose($eximtransaction),"\n";
            }
        }
    }
    close(EXIMLOG);

B<Output>

    2020-05-25 10:25:34 1jdEyr-0003IG-QE <= somelist-users-bounces@example10.com H=lists.example10.com [10.10.12.136] P=esmtp S=2761 id=159999925705.99.3666999992664571474@mailman-web
    2020-05-25 10:25:34 1jdEyr-0003IG-QE => me@example.com R=relay_user_to_gate1 T=remote_smtp H=smtp.example.com [10.100.200.27] X=TLSv1:AES128-SHA:128
    2020-05-25 10:25:34 1jdEyr-0003IG-QE Completed
    2020-05-25 11:19:42 1jdFpE-0003Xt-1L <= mailalias@example20.com H=mail.example20.com [10.20.12.168] P=esmtps X=TLSv1:AES256-SHA:256 S=50040 id=49fd3f1f7cab999999951cba1aab8cdc@example20.com
    2020-05-25 11:19:43 1jdFpE-0003Xt-1L => me@example.com R=relay_user_to_gate1 T=remote_smtp H=smtp.example.com [10.100.200.27] X=TLSv1:AES128-SHA:128
    2020-05-25 11:19:43 1jdFpE-0003Xt-1L Completed


=head1 AUTHOR

Russell Glaue, http://russ.glaue.org

=head1 SEE ALSO

Exim4 log documentation: http://www.exim.org/exim-html-current/doc/html/spec_html/ch-log_files.html

=head1 COPYRIGHT

Copyright (c) 2017-2020 Russell E Glaue,
Center for the Application of Information Technologies,
Western Illinois University
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
