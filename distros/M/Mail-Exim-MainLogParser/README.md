# NAME

Mail::Exim::MainLogParser - Parse log lines from the Exim Main Log

# SYNOPSIS

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

# DESCRIPTION

This module will parse log lines from Exim version 4, according to the source
http://www.exim.org/exim-html-current/doc/html/spec\_html/ch-log\_files.html
as of 2017-06-08

# REQUIREMENTS

This module is pure perl and does not depend on other modules. But does
depend on a log file from Exim version 4 main log output.

- Exim 4

# IMPORTED METHODS

When the calling application invokes this module in a use clause, the following
method can be imported into its space.

- `EximMainLoglineParse`
- `EximMainLoglineCompose`

# METHODS

## new

Create a new object instances of this module.
It is not necessary to create an object for this module, as the methods can
be called outside of OO style programming.

- _returns_

    An object instance of this module.

    my $eximlog = new Mail::Exim::MainLogParser();

## EximMainLoglineParse

See `parse()`.

## parse

Parse a line from the Exim main log file and return a hash structure.

    $exim_log_line_hash = $exlog->parse($exim_log_line_string);

- **exim\_log\_line\_string**

    This is a single line from the Exim main log output.
    The below example log line is split over several lines in order to fit it on the page.

        2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com
            H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]
            P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com

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

## EximMainLoglineCompose

See `compose()`.

## compose

Compose a log line from a parsed main log line hash and return as a string.

    $exim_log_line_composed = $exlog->compose($exim_log_line_hash)

- **exim\_log\_line\_hash**

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

This method returns a string composition of the parsed log line HASH structure.
It is intended that the composed string matches the original log line that was
parsed, minus trailing white space.

    print "$LoglineComposed";
    2017-06-08 11:17:56 1dJ08B-0003oP-5i <= do-not-reply@nowhere.com
        H=realmail.server.example.com (ehlo-name.example.com) [192.168.250.101]
        P=esmtp S=1364 id=266785270.3.2385849643852@peerhost.server.example.com

# EXAMPLES

## Show exim mail transactions for a particular email address

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

**Output**

    2020-05-25 10:25:34 1jdEyr-0003IG-QE <= somelist-users-bounces@example10.com H=lists.example10.com [10.10.12.136] P=esmtp S=2761 id=159999925705.99.3666999992664571474@mailman-web
    2020-05-25 10:25:34 1jdEyr-0003IG-QE => me@example.com R=relay_user_to_gate1 T=remote_smtp H=smtp.example.com [10.100.200.27] X=TLSv1:AES128-SHA:128
    2020-05-25 10:25:34 1jdEyr-0003IG-QE Completed
    2020-05-25 11:19:42 1jdFpE-0003Xt-1L <= mailalias@example20.com H=mail.example20.com [10.20.12.168] P=esmtps X=TLSv1:AES256-SHA:256 S=50040 id=49fd3f1f7cab999999951cba1aab8cdc@example20.com
    2020-05-25 11:19:43 1jdFpE-0003Xt-1L => me@example.com R=relay_user_to_gate1 T=remote_smtp H=smtp.example.com [10.100.200.27] X=TLSv1:AES128-SHA:128
    2020-05-25 11:19:43 1jdFpE-0003Xt-1L Completed

# AUTHOR

Russell Glaue, http://russ.glaue.org

# SEE ALSO

Exim4 log documentation: http://www.exim.org/exim-html-current/doc/html/spec\_html/ch-log\_files.html

# COPYRIGHT

Copyright (c) 2017-2020 Russell E Glaue,
Center for the Application of Information Technologies,
Western Illinois University
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
