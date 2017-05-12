package Mail::IMAP2SMS;

use strict;
use Carp;
use Net::IMAP::Simple;
use Net::IMAP::Simple::SSL;
use Email::Simple;
use Mail::Sendmail;

use vars qw[$VERSION];
$VERSION = $1 if('$Id: IMAP2SMS.pm,v 1.2 2009/05/21 14:49:36 rcrowder Exp $' =~ /,v ([\d_.]+) /);

=head1 NAME

Mail::IMAP2SMS - Perl extension for IMAP to SMS.

=head1 SYNOPSIS

    # Import Module
    use Mail::IMAP2SMS;

    # Instantiate the IMAP2SMS object.
    my $sms = Mail::IMAP2SMS->new('imap.example.com', 'test@example.com', 'p4$$w0rd', 1);

    # Get unseen mail from inbox.
    my $unseen = $sms->get_unseen('INBOX');

    # Chunk each message into specified size (160) SMSs.
    foreach (@$unseen) {
        my ($id) = $_;
        $sms->chunk($id, 160);
    } # foreach

    # Send chunked messages.
    if ($sms->send('7895551234@vtext.com')) {
        print 'All sent successfully';
    } else {
        print 'Send failed...';
    } # if/else

    # Close connection
    $sms->disconnect;

=head1 DESCRIPTION

This module is a quick and easy way to SMS your IMAP email.

=head1 OBJECT CREATION METHOD

=over 4

=item new

 my $sms = Mail::IMAP2SMS->new( $server [ :port ], $username, $password, $ssl );

This class method constructs a C<Mail::IMAP2SMS> object. It takes four required parameters. The server parameter may specify just the

server, or both the server and the port. To specify an alternate port, seperate it from the server with a colon (C<:>), C<example.com:9876>.

The ssl (BOOLEAN) parameter may specify whether to use or not use SSL to connect to the specified IMAP server.

=back

=cut

sub new {
    my $class = shift;

    my $self = {
        server  => shift,
        user    => shift,
        pass    => shift,
        ssl     => shift
    };

    $self->{sms} = [];

    bless $self, $class;

    $self->_connect;

    return $self;
} # new

sub _connect {
    my ($self) = @_;

    if ($self->{ssl} == 1) {
        $self->{imap} = Net::IMAP::Simple::SSL->new($self->{server}) ||
            croak "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
    } else {
        $self->{imap} = Net::IMAP::Simple->new($self->{server}) ||
            croak "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
    }

    # Log on
    if(!$self->{imap}->login($self->{user}, $self->{pass})) {
        croak "Login failed: " . $self->{imap}->errstr . "\n";
    }

    return 1;
} # connect

=pod

=head1 METHODS

=over 4

=item get_seen

 my $seen = $sms->get_seen('INBOX');

This method takes one required parameter, an IMAP folder. The number of seen
messages is returned on success. On failure, nothing is returned.

=cut

sub get_seen {
    my ($self, $folder) = @_;

    my $nm = $self->{imap}->select($folder);

    my @seen;

    for (my $i = 1; $i <= $nm; $i++){
        if ($self->{imap}->seen($i)){
            push @seen, $i;
        }
    }

    return \@seen;
} # get_seen

=pod

=item get_unseen

 my $unseen = $sms->get_unseen('INBOX');

This method takes one required parameter, an IMAP folder. The number of seen
messages is returned on success. On failure, nothing is returned.

=cut

sub get_unseen {
    my ($self, $folder) = @_;

    my $nm = $self->{imap}->select($folder);

    my @unseen;

    for (my $i = 1; $i <= $nm; $i++){
        if (!$self->{imap}->seen($i)) {
            push @unseen, $i;
        }
    }

    return \@unseen;
} # get_unseen

=pod

=item chunk

 print 'Successfully chunked!' if $sms->chunk($id, 160);

This method takes two require parameters, a message ID and a chunking size.
The message ID is used to get the message from the IMAP server. Upon getting
the message it is determined whether the subject and body can fit in one SMS
or if the message must be broken into segments of the proper SMS size. Carriers
differ on SMS size thus a size must be specified. On success, boolean true is
returned. On failure, nothing is returned.

=cut

sub chunk {
    my ($self, $id, $size) = @_;

    my $es = Email::Simple->new(join '', @{ $self->{imap}->get($id) } );

    my $sub = $es->header('Subject');

    my $subl = length($sub);

    my $bodyl = length($es->body);

    if (($bodyl + $subl) < $size) {
        push @{ $self->{sms} }, $es;
    } else {
        my $msg_size = $subl;

        my @body = split(/ /, $es->body);

        my $str = "";

        foreach (@body) {
            my $wordl = length($_);

            if (($wordl + $msg_size + 1) > $size) {
                my $msg = Email::Simple->new(join '', @{ $self->{imap}->get($id) } );
                $msg->body_set("$str");

                push @{ $self->{sms} }, $msg;

                $msg_size = $subl;
                $str = "$_ ";
            } else {
                $msg_size += ($wordl + 1);
                $str .= "$_ ";
            } # if/else
        } # foreach
    } # if/else

    return 1;
} # chunk

=pod

=item send

 print 'Send successful...' if $sms->send('7895551234@vtext.com');

This method requires one parameter, a wireless carrier phone number email address.
This method will send all SMS created to the specified email address. If more than
three SMS are readied to send, a sending sleep time between each SMS will be applied
to reduce the chance of the wireless carrier dropping any messages. On success, a
boolean true is returned. On failure, nothing is returned.

=cut

sub send {
    my ($self, $email) = @_;

    my $count = 1;

    foreach (@{ $self->{sms} }) {
        my %mail = ( To => $email, From => $_->header('From'),
            'Content-Type' => 'text/plain; charset=us-ascii',
            'Content-Transfer-Encoding' => '7bit',
            Subject => "$count " . $_->header('Subject'), Message => $_->body);

        if (scalar @{ $self->{sms} } > 3) {
            sleep(3);
        }

        sendmail(%mail) || croak "Unable to send email: $!";

        $count++;
    } # foreach

    return 1;
} # send

=pod

=item disconnect

 print 'Disconnected from IMAP...' if $sms->quit;

This method requires no parameters. It simply closes the connection
to the IMAP server. On success, a boolean true is returned. On failure,
nothing is returned.

=cut

sub disconnect {
    my ($self) = @_;

    $self->{imap}->quit;

    return 1;
} # quit

=pod

=back

=cut

1;

__END__

=head1 AUTHOR

Roy Crowder, <F<roy.crowder@gmail.com>>.

=head1 SEE ALSO

L<Net::IMAP::Simple>,
L<Net::IMAP::Simple::SSL>,
L<Email::Simple>,
L<Mail::Sendmail>,
L<perl>,
L<Changes>

=head1 COPYRIGHT

Copyright (c) 2009 Roy Crowder.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=cut
