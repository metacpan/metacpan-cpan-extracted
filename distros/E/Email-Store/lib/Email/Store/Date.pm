package Email::Store::Date;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.1';

use Email::Store::DBI;
use base 'Email::Store::DBI';
use Email::Store::Mail;

use Time::Piece;
use Date::Parse;

Email::Store::Date->table("mail_date");
Email::Store::Date->columns(All => qw/mail date year month day/);
Email::Store::Date->columns(Primary => qw/mail/);
Email::Store::Date->has_a( date => 'Time::Piece' );
Email::Store::Date->has_a( mail => "Email::Store::Mail" );
Email::Store::Mail->might_have( mail_date => "Email::Store::Date" => qw(date year month day));



sub on_store_order { 80 }

sub on_store {
    my ($self, $mail) = @_;
    my $simple = $mail->simple;

    my $date   = $simple->header('date')
                 || _get_date_in_received_header($simple)
                 || $simple->header('resent-date');

    my $time   = str2time($date);
    my $tp     = Time::Piece->new($time);
    Email::Store::Date->create( { mail => $mail->id, date => $time, year => $tp->year, month => $tp->mon, day => $tp->mday } );

}

sub _get_date_in_received_header {
    my @received = shift->header("Received");
    return unless @received;
    my $date = $received[-1];
    $date =~ s/.*;// and return $date;
}


sub on_gather_plucene_fields_order { 80 }
sub on_gather_plucene_fields {
    my ($self, $mail, $hash) = @_;
    if ($mail->date) {
        $hash->{'date'} = $mail->date->ymd;
    }
}

=head1 NAME

Email::Store::Date - Provides a Time::Piece object representing a date for the mail

=head1 SYNOPSIS

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    print $mail->date->ymd,"\n";

or

    $mail->year;
    $mail->month;
    $mail->day;

You can also search for all mails between two unix epochs

    # get all mails in the last day
    my $time = time();
    my $day  = 24*60*60;
    Email::Store::Mail->search_between($time, $time-$day);

=head1 SEE ALSO

L<Email::Store::Mail>, L<Time::Piece>.

=head1 AUTHOR

Simon Wistow, C<simon@thegestalt.org>

This module is distributed under the same terms as Perl itself.

=cut


Email::Store::Mail->set_sql(between => qq{
    SELECT mail.message_id
    FROM mail_date, mail
    WHERE mail.message_id = mail_date.mail AND
    mail_date.date >= ? AND
    mail_date.date <=  ?
    ORDER BY mail_date.date DESC
});


1;
__DATA__
CREATE TABLE IF NOT EXISTS mail_date (
    mail varchar(255) NOT NULL PRIMARY KEY,                                                 
    date  int,
    year  int,
    month int,
    day   int
);
