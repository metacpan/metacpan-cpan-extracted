###########################################
package Gaim::Log::Parser;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use DateTime;
use Gaim::Log::Message;
use Text::Wrap qw(fill);

our $VERSION = "0.14";

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my $self = {
        time_zone => DateTime::TimeZone->new(name => 'local'),
        @options,
    };

    LOGDIE "Cannot open $self->{file}" unless -f $self->{file};

    open my $fh, "$self->{file}" or 
        LOGDIE "Cannot open $self->{file}";

    $self->{fh} = $fh;

    bless $self, $class;
    $self->reset();

    DEBUG "Parsing logfile $self->{file}";

        # ./proto/from/to/2005-10-29.230219.txt
    if($self->{file} =~ m#([^/]+)/([^/]+)/([^/]+)/([^/]+)$#) {
        $self->{protocol} = $1;
        $self->{from}     = $2;
        $self->{to}       = $3;
        if($4 =~ /(\d{4})-(\d{2})-(\d{2})\.(\d{2})(\d{2})(\d{2})/) {
          my $dt = DateTime->new(year => $1, month  => $2, day    => $3,
                                 hour => $4, minute => $5, second => $6,
                                 time_zone => $self->{time_zone},
                                );
          $self->{dt}         = $dt;
        }
    } else {
        LOGDIE "Please use full path information (something like ",
               "\".../proto/from/to/2005-10-29.230219.txt\")",
               " since ", __PACKAGE__, " uses it to generate meta data ",
               "from it.";
    }

    if($self->{offset}) {
            # If an offset has been specified, leap ahead message
            # by message (therefore accounting for roll-overs) until
            # the requested offset has been reached.
        my $offset = $self->{offset};
        $self->{offset} = tell $self->{fh};
        while($offset > $self->{offset}) {
            $self->next_message() or last;
        }
    } else {
        $self->{offset} = tell $self->{fh};
    }

    return bless $self, $class;
}

###########################################
sub as_string {
###########################################
    my($self, $opts) = @_;

    my $string;

    my $fh     = $self->{fh};
    my $old_offset = $self->{offset};

    $self->reset();

    local $Text::Wrap::columns = ($opts->{columns} || 70);

    while(my $m = $self->next_message()) {
      my $content = $m->content();
      $content =~ s/\n+/ /g;
      $string .= fill("", "  ",
                      nice_time($m->date()) . " " .
                      $m->from() . ": " . $content) . "\n\n";
    }

      # reset fh
    $self->{offset} = $old_offset;
    seek $fh, $self->{offset}, 0;

    return $string;
}

###########################################
sub next_message {
###########################################
    my($self) = @_;

    my $fh = $self->{fh};
    my $time_match      = qr(\d{2}:\d{2}:\d{2}(?: [AP]M)?);
    my $date_match      = qr(\d{2}/\d{2}/\d{2,4});
    my $euro_date_match = qr(\d{2}\.\d{2}\.\d{2,4});
    my $iso_date_match  = qr(\d{4}-\d{2}-\d{2});


    my $line_match_with_time = qr/^\(($time_match)\) (.*)/;
    my $line_match_with_date_and_time = 
                               qr/^\(($date_match) ($time_match)\) (.*)/;
    my $line_match_with_euro_date_and_time = 
                               qr/^\(($euro_date_match) ($time_match)\) (.*)/;
    my $line_match_with_iso_date_and_time =
                               qr/^\(($iso_date_match) ($time_match)\) (.*)/;
    my $line_match = qr($line_match_with_time|
                        $line_match_with_date_and_time|
                        $line_match_with_euro_date_and_time|
                        $line_match_with_iso_date_and_time)x;

        # Read next line
    my $line = <$fh>;

        # End of file?
    if(! defined $line) {
        DEBUG "End of file $self->{file}";
        $self->{fh} = $fh;
        return undef;
    }

    my($time, $date, $msg, $day, $month, $year);

        # Valid line?
    if($line =~ /$line_match_with_time/) {
        $time = $1;
        $msg  = $2;
    } elsif($line =~ /$line_match_with_date_and_time/) {
        $date = $1;
        ($month, $day, $year) = split m#/#, $date;
        $time = $2;
        $msg  = $3;
    } elsif($line =~ /$line_match_with_euro_date_and_time/) {
        $date = $1;
        ($day, $month, $year) = split m#\.#, $date;
        $time = $2;
        $msg  = $3;
    } elsif($line =~ /$line_match_with_iso_date_and_time/) {
        $date = $1;
        ($year, $month, $day) = split m#-#, $date;
        $time = $2;
        $msg  = $3;
    } else {
        while(defined $line and $line !~ /$line_match/) {
            chomp $line;
            LOGWARN "Format error in $self->{file}: ",
                    "Line '$line' doesn't match $line_match";
            $line = <$fh>;
        }
    }

      # We accepted either 2 or 4 digit years. Hopefully there's no
      # gaim logs from < 2000 :).
    if($year) {
        $year += 2000 unless length $year == 4;
    }

    $self->{offset} = tell $fh;

        # We've got a message, let's see if there's continuation lines
    while(defined($_ = <$fh>)) {
        if(/$line_match/) {
                # Next line doesn't look like a continuation line,
            last;
        }
            # We have a continuation line.
        chomp; 
        $msg .= "\n$_"; 
        $self->{offset} = tell $fh; 
    }

        # Go back to the previous offset, before we tried searching
        # for continuation lines
    seek $fh, $self->{offset}, 0;

    $self->{fh} = $fh;

        # Check if we have a roll-over
    my $dtclone = $self->{dt}->clone();

    if($date) {
      $dtclone = DateTime->new(year      => $year, 
                               month     => $month, 
                               day       => $day,
                               time_zone => $self->{time_zone}
                              );
      $self->{dt} = $dtclone;
    }

    my $pm = 0;
    if($time =~ / PM/) {
        $pm = 1;
    }
    $time =~ s/ .*//;

    my($hour, $minute, $second) = split /:/, $time;
    $dtclone->set_hour($hour);
    $dtclone->set_minute($minute);
    $dtclone->set_second($second);

    if($pm) {
        $dtclone->add(hours => 12);
    }

    if(!$date and $dtclone->epoch() < $self->{dt}->epoch()) {
        # Rollover detected. Adjust datetime instance variable
        $self->{dt}->add(days => 1);
        $dtclone->add(days => 1);
    }

    my $sender   = $self->{from};
    my $receiver = $self->{to};

        # strip "from_user: " from beginning of message
    if($msg =~ /^(.*?): /) {
        if($1 eq $receiver) {
                # The other party sent
            ($sender, $receiver) = ($receiver, $sender);
        } elsif($1 ne $sender) {
                # A different chat user sent
            $sender = $1;
        }
        $msg =~ s/^(.*?): //;
    } else {
            # No sender specified. This could be a message like
            # "foo logged out.". Leave sender/receiver as is.
    }

    DEBUG "Creating new message (date=",  $dtclone->epoch(), ") msg=",
          $msg;

    return Gaim::Log::Message->new(
            from     => $sender,
            to       => $receiver,
            protocol => $self->{protocol},
            content  => $msg,
            date     => $dtclone->epoch(),
    );
}

###########################################
sub offset {
###########################################
    my($self) = @_;

    return $self->{offset};
}

###########################################
sub datetime {
###########################################
    my($self) = @_;

    return $self->{dt};
}

###########################################
sub reset {
###########################################
    my($self) = @_;

    my $fh = $self->{fh};
    seek $fh, 0, 0;

        # "Conversation with foo at 2005-10-29 23:02:19 
        #  on bar (protocol)"
    my $first_line = <$fh>;

    $self->{offset} = tell $fh;

    1;
}

###########################################
sub nice_time {
###########################################
    my($time) = @_;

    $time = time() unless defined $time;

    my ($sec,$min,$hour,$mday,$mon,$year,
     $wday,$yday,$isdst) = localtime($time);

    return sprintf("%d/%02d/%02d %02d:%02d:%02d",
     $year+1900, $mon+1, $mday,
     $hour, $min, $sec);
}

1;

__END__

=head1 NAME

Gaim::Log::Parser - Parse Gaim's Log Files

=head1 SYNOPSIS

    use Gaim::Log::Parser;

    my $parser = Gaim::Log::Parser->new(file => $filename);

    while(my $msg = $parser->next_message()) {
        print $msg->as_string();
    }

=head1 DESCRIPTION

Gaim::Log::Parser parses Gaim/Pidgin's log files. In the 1.4+ series, they are 
organized in the following way:

    .gaim/logs/protocol/local_user/comm_partner/2005-10-29.230219.txt

Make sure that your Gaim/Pidgin client has logging turned on and that
the logging format is set to 'text' (not html). If you have log files in
html format already, run the utility eg/gaimlog-html2text to make
text format copies of existing html logs.

=head2 Methods

=over 4

=item C<my $parser = Gaim::Log::Parser->new(file =E<gt> $filename)>

Create a new log parser. 

The parser will interpret the message time stamps according to a selected
time zone.

By default, the time zone is assumed to be 'local' which will try all
kinds of tricks to determine the local time zone. If this is not what you
want, a time zone for DateTime::TimeZone can be provided, e.g.
"America/Los_Angeles".

=item C<my $msg = $parser-E<gt>next_message()>

Return the next message in the log. Returns an object of type
C<Gaim::Log::Message>. Check its documentation for details.

=item C<my $dt = $parser-E<gt>datetime()>

Retrieve the DateTime object used internally by
C<Gaim::Log::Parser>. Can be used to obtain the 
the start date of the parsed log file or the time zone used.

=item C<$parser-E<gt>reset()>

Position the parser back to the beginning of the conversation. After
this has been completed, the next next_message() will return the 
first message in the log file.

=item C<my $str = $parser-E<gt>as_string()>

Return the entire conversation as a nicely formatted text string.
By default, Text::Wrap's column with lines will be set to 70, if you
prefer a different width, specify it explicitely

    my $str = $parser->as_string( {columns => 30} );

=head1 SEE ALSO

L<Gaim::Log::Finder>, L<Gaim::Log::Message> in this distribution

=back

=head1 LEGALESE

Copyright 2005-2008 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>
