package ICal::QuickAdd;
use Params::Validate ':all';
use strict;
use warnings;
use Fcntl qw(SEEK_END O_RDONLY);
use Carp;
use vars '$VERSION';
$VERSION = '1.00';

=head1 DESCRIPTION

This is the guts of ICal::QuickAdd, of interest to developers.  Most users
probably want the docs of L<iqa> instead, which is a script which uses this
module.

=head2 new()

  $iqa = ICal::QuickAdd->new('tomorrow at noon. Lunch with Bob') ;

  # Default to expecting a email message with the SMS in body, On STDIN
  $iqa = ICal::QuickAdd->new();

=cut

sub new {
    my $class = shift;
    my $str = shift;

    my $self  = {};
    unless ($str) {
        require Mail::Audit;
        my $m = Mail::Audit->new(
                emergency=>"~/mail_audit_emergency_mbox",
                #   log =>'~/mail_audit_log',
                #  loglevel => 3,
                            );
        # Look on the first line of the message.
        $str = $m->body->[0];
        $self->{from_email} = $m->from;
        $self->{from_email_obj} = $m;
    }
    bless($self,$class);

    die "no quick-add message found in arg or email" unless $str;

    ($self->{dt},$self->{msg}) = $self->parse_date_and_summary($str);

    return $self;

}

=begin private

=head2 _is_ical_file

    my ($is_ical,$line_ending) = _is_ical_file($filename);

Returns whether or not we think this file is a iCalendar file by checking
that it ends with "END:VCALENDAR" as the standard mandates. We also return
the last line break of the file to see whether it is "\n" which Evolution
and Korganizer use (among others), or if it "\r\n" (CRLF), which is what
the iCalendar standard prescribes.

=end private

=cut

sub _is_ical_file {
    my $filename = shift;
    my $handle;
    sysopen( $handle, $filename, O_RDONLY ) || croak "failed to open $filename: $!";
    binmode $handle ;

   my $file_length = (stat($filename))[7];

   # "END:VCALENDAR" + \n or CRLF == 15 chars/bytes
   my $end_vcal_len = 15;

   # A valid ics file would be much bigger
   croak "not valid ICS file" unless ($file_length > $end_vcal_len);

    # seek to the end of the file and get its size
    my $seek_pos = seek( $handle, -$end_vcal_len, SEEK_END ) or croak "failed to seek: $!";
    my $last_chars;
    read($handle, $last_chars, $end_vcal_len);
    # The spec says we must end in CRLF, not just unix "\n"
    my $is_ical_file = ($last_chars =~ m/END:VCALENDAR(\r?\n)$/s) ;
    my $line_ending = $1;
    # $is_ical_file || warn "last chars were: $last_chars";
    return ($is_ical_file, $line_ending);
}

=head2 parse_date_and_summary()

   $iqa->parse_date_and_summary($msg);

Takes a string, such as short SMS text, and parses out a date
and event summary from it.

Right now it's sort of dumb. It expects the event description
to come first, followed by a period, and then a summary. Example:

 tomorrow at noon. Lunch with Bob

The dot was chosen as the delimiter because my cell phone allows
me to type it directly, using the "1" key.

Limitations: A future version should also return an "$is_date" flag, to note if
the date found was a date or a date and time.

=cut

sub parse_date_and_summary {
    my $self = shift;
    my $in = shift;

    require DateTime::Format::Natural;
    my ($date,$msg) = split '\.',  $in;
    $date ||= '';
    $msg ||= '';
    chomp $date;
    chomp $msg;

    # trim leading and trailing whitespace
    $msg =~ s/^\s+|\s+$//g;

    my $dt;
    eval { $dt = DateTime::Format::Natural->new->parse_datetime(string => $date) };
    croak "error parsing date ($date). error was: $@" if $@;

    return ($dt, $msg);
}

=head2 inject_into_ics()

    $iqa->inject_into_ics($filename);

Injects a valid ical event block into the env entry into the end of $filename,
which is assumed to be a valid iCalendar file. If that assumption is wrong, the
file could be corrupted. Use the is_ical_file() to check first!

Bugs: Currently always injects a Unix newline. This could corrupt an
ICS file with with CRLF line entries.

=cut

sub inject_into_ics {
    my $self     = shift;
    my $filename = shift;

    my ($is_ical,$line_ending) = _is_ical_file($filename);
    croak "$filename doesn't look like a valid ICS file" unless $is_ical;

    my $entry =  $self->as_vevent->as_string;

    open( my $fh, "+<$filename") || croak "couldn't open $filename: $!";

    # END:VCALENDAR has 13 chars
    my $perfect_length = 13 + length $line_ending;

    # seek to exactly the right spot to inject our file.
    my $seek_pos = seek( $fh, -$perfect_length, SEEK_END ) or croak "failed to seek: $!";

    print $fh $entry || croak "couldn't print to fh: $!";

    print $fh "END:VCALENDAR".$line_ending;

    close ($fh) || croak "couldn't close fh: $!";

    return 1;

}

=head2 parsed_string()

 my $desc = $iqa->parsed_string;

Return a short description. Useful for confirming to the user how the Quick Add string was
parsed.

Limitations: the description returned currently always includes hours/minute compontent
and is in 24 hour time.

=cut

sub parsed_string {
    my $self = shift;
    my $dt = $self->get_dt;
    return sprintf("Event: %s on %s %d, %d at %02d:%02d",
            $self->get_msg, $dt->month_abbr, $dt->day, $dt->year, $dt->hour, $dt->minute);

}

=head2 as_vevent()

 my $vevent = $iqa->as_vevent;

Return a L<Data::ICal::Entry::Event> object representing the event.

For now, hard-code a one hour duration

=cut

sub as_vevent {
    my $self = shift;

    # XXX Could add caching here.

    require Data::ICal::Entry::Event;
    require DateTime::Format::ICal;
    my $vevent = Data::ICal::Entry::Event->new;
       $vevent->add_properties(
           summary => $self->get_msg,
           dtstart => DateTime::Format::ICal->format_datetime($self->get_dt),
           dtend   => DateTime::Format::ICal->format_datetime( $self->get_dt->add( hours => 1 ) ),
       );
    return $vevent;

}

=head2 as_ical()

 my $data_ical = $iqa->as_ical;

Returns a L<Data::ICal> object with the "PUBLISH" method set.

The PUBLISH method is used when mailing iCalendar events.

=cut

sub as_ical {
    my $self = shift;

    require Data::ICal;

     my $calendar = Data::ICal->new;
     $calendar->add_entry( $self->as_vevent );
     $calendar->add_properties( method => 'PUBLISH');

     return $calendar;
}

=head2 as_ical_email()

 my $email_simple_obj = $iqa->as_ical_email(
        To    => $your_regular_email,
        From  => $from_email, # Defaults to $iqa->from_email
  );

Returns a ready-to-mail L<Email::Simple> object with an iCalendar body.
Extra headers  can be passed in.

=cut

sub as_ical_email {
    my $self = shift;
    my %in = validate(@_, {
        To    => { type => SCALAR },
        From  => { type => SCALAR, default => $self->from_email },
    });

     require Email::Simple;
     my $email = Email::Simple->new('');
     $email->header_set("Content-Type", "text/calendar; name=calendar.ics; charset=utf-8; METHOD=PUBLISH");
     $email->header_set(From => $in{From} );
     $email->header_set(To => $in{To} );

     $email->header_set("Subject", $self->parsed_string );
     $email->body_set( $self->as_ical->as_string );

     use Email::Date;
     $email->header_set( Date => format_date );

     return $email;
}



=head2 from_email()

Returns the 'from' email address. It can also be used as a check
to see if the SMS came from an email at all, since will only be set in that case.

=cut

sub from_email {
    my $self = shift;
    return $self->{from_email};
}

=head2 from_email_obj()

If the input was an email, returns the object representing
the incoming message. Currently a L<Mail::Audit> object.

=cut

sub from_email_obj {
    my $self = shift;
    return $self->{from_email_obj}

}

=head2 get_msg()

 Return the event name found in the SMS message.

=cut

sub get_msg {
    my $self = shift;
    return $self->{msg};
}

=head2 get_dt()

Returns DateTime object found in SMS.

=cut

sub get_dt {
    my $self = shift;
    return $self->{dt};
}

=head1 CONTRIBUTING

This project is managed using the darcs source control system
( http://www.darcs.net/ ). My darcs archive is here:
http://mark.stosberg.com/darcs_hive/ICal-QuickAdd

Contributing a patch can be as easy as:

 darcs get http://mark.stosberg.com/darcs_hive/ICal-QuickAdd
 cd ICal-QuickAdd
 # hack...
 darcs record
 darcs send


=head1 AUTHOR

Mark Stosberg  C<< mark@summersault.com >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Mark Stosberg C<< mark@summersault.com >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.



1;

# vim: nospell
