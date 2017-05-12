# Device::Gsm::Sms - SMS message simple class that represents a text SMS message
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
# Copyright (C) 2006-2015 Grzegorz Wozniak, wozniakg@gmail.com
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# Commercial support is available. Write me if you are
# interested in new features or software support.

package Device::Gsm::Sms;

use strict;
use integer;

use constant SMS_DELIVER => 0x00;
use constant SMS_SUBMIT  => 0x01;
use constant SMS_STATUS  => 0x02;

use Device::Gsm::Pdu;
use Device::Gsm::Sms::Structure;
use Device::Gsm::Sms::Token;

sub _log { print @_, "\n"; }
sub _parent { $_[0]->{_parent} }

#
# new(
#     header  => '+CMGL: .....',
#     pdu     => '[encoded pdu string]',
# )
#
# creates message object
#
sub new {
    my ($proto, %opt) = @_;
    my $class = ref $proto || $proto;

    # Create new message object
    my $self = {};

    # Store gsm parent object reference
    if (exists $opt{'parent'}) {
        $self->{'_parent'} = $opt{'parent'};

        # Assume default storage for sms message
        $opt{'storage'} ||= $self->{'_parent'}->storage();
    }

    # Store options into main object
    $self->{'options'} = \%opt;

    # Hash to contain token objects after decoding (must be accessible by name)
    $self->{'tokens'} = {};

    return undef unless (exists $opt{'header'} && exists $opt{'pdu'});

    #_log("NEW SMS OBJECT");
    #_log("Header [$opt{header}]");
    #_log("PDU    [$opt{pdu}]");

    # Check for valid msg header (thanks to Pierre Hilson for his patch
    # to make this regex work also for Alcatel gsm software)
    if ($opt{'header'} =~ /\+CMGL:\s*(\d+),\s*(\d+),\s*(\w*),\s*(\d+)/o) {

        $self->{'index'} = $1;    # Position of message in SIM card
        $self->{'status'}
            = $2;    # Status of message (REC READ/UNREAD, STO, ...);
        $self->{'alpha'}  = $3;    # Alphanumeric representation of sender
        $self->{'length'} = $4;    # Final length of message
        $self->{'pdu'}     = $opt{'pdu'};        # PDU content
        $self->{'storage'} = $opt{'storage'};    # Storage (SM or ME)

        bless $self, $class;

        if ($self->decode(Device::Gsm::Sms::SMS_DELIVER)) {

            #			_log('OK, message decoded correctly!');
        }
        elsif ($self->decode(Device::Gsm::Sms::SMS_STATUS)) {

        }
        else {

            #			_log('CASINO!');
            undef $self;
        }

    }
    elsif ($opt{'header'} =~ /\+CDS:\s*(\d+)/o) {

        $self->{'mr'} = $1;    # Message number
        $self->{'pdu'}     = $opt{'pdu'};        # PDU content

        bless $self, $class;

        if ($self->decode(Device::Gsm::Sms::SMS_STATUS)) {
            #			_log('OK, message decoded correctly!');

        }
        else {

            #			_log('CASINO!');
            undef $self;
        }

    }
    else {

        # Warning: could not parse message header
        undef $self;

    }

    return $self;
}

#
# time(): returns message time in ascii format
#
sub time {
    my $self = shift;
    if (my $t = $self->token('SCTS')) {
        return $t->toString();
    }
    return '';
}

#
# time_dt (): returns status message discharge time in ascii format
#
sub time_dt {
    my $self = shift;
    if (my $t = $self->token('DT')) {
        return $t->toString();
    }
    return '';
}

#
# message_ref(): returns message reference of status message
#
sub message_ref {
    my $self = shift;
    if (my $t = $self->token('MR')) {
        return $t->toString();
    }
    return '';
}

#
# type(): returns message type in ascii readable format
#
{

    # List of allowed status strings
    my @status
        = ('UNKNOWN', 'REC UNREAD', 'REC READ', 'SENT UNREAD', 'SENT READ');

    sub status () {
        my $self = shift;
        return $status[ defined $self->{'status'} ? $self->{'status'} : 0 ];
    }

}

#
# decode( CMGL_header, pdu_string )
#
# creates a new Device::Gsm::Sms object from
# PDU encoded message string returned by +CMGL commands
#
# If some error occurs, returns undef.
#
#
sub _old_decode {
    my ($header, $pdu) = @_;
    my %msg    = ();
    my $errors = 0;

    # Copy original header/pdu strings
    $msg{'_HEADER'} = $header;
    $msg{'_PDU'}    = $pdu;

    #
    # Decode header string
    #
    if ($header =~ /\+CMGL:\s*(\d+),(\d+),(\d*),(\d+)/) {
        $msg{'index'}  = $1;
        $msg{'type'}   = $2;
        $msg{'xxx'}    = $3;    # XXX
        $msg{'length'} = $4;
    }

    #
    # Decode all parts of PDU message
    #

    # ----------------------------------- SCA (service center address)
    my $sca_length = hex(substr $pdu, 0, 2);
    if ($sca_length == 0) {

        # No SCA provided, take default
        $msg{'SCA'} = undef;
    }
    else {

        # Parse SCA address
        #print STDERR "SCA length = ", $sca_length, "; ";
        #print STDERR "Parsing address ", substr( $pdu, 0, ($sca_length+1) << 1 );
        $msg{'SCA'} = Device::Gsm::Pdu::decode_address(
            substr($pdu, 0, ($sca_length + 1) << 1));

        #print STDERR ' = `', $msg{'SCA'}, "'\n";
    }

    # ----------------------------------- PDU type
    $pdu = substr $pdu => (($sca_length + 1) << 1);
    $msg{'PDU_TYPE'} = substr $pdu, 0, 2;
    undef $sca_length;

    # ----------------------------------- OA (originating address)
    $pdu = substr $pdu => 2;
    my $oa_length = hex(substr $pdu, 0, 2);

    $msg{'OA'} = Device::Gsm::Pdu::decode_address(
        substr($pdu, 0, ($oa_length + 1) << 1));
    undef $oa_length;

    # PID      (protocol identifier)
    # DCS      (data coding scheme)
    # SCTS     (service center time stamp)
    # UDL + UD (user data)
    @msg{qw/PID DCS SCTS UDL UD/} = unpack 'A2 A2 A14 A2 A*', $pdu;

    #map { $msg{$_} = hex $msg{$_} } qw/PID DCS UDL/;
    #
    # Decode USER DATA in 7/8 bit encoding
    #
    if ($msg{'DCS'} eq '00') {    # DCS_7BIT
        Device::Gsm::Pdu::decode_text7($msg{'UD'});
    }
    elsif ($msg{'DCS'} eq 'F6') {    # DCS_8BIT
        Device::Gsm::Pdu::decode_text8($msg{'UD'});
    }

    # XXX DEBUG
    #foreach( sort keys %msg ) {
    #	print STDERR 'MSG[', $_, '] = `'.$msg{$_}.'\'', "\n";
    #}

    bless \%msg, 'Device::Gsm::Sms';
}

sub decode {
    my ($self, $type) = @_;
    $self->{'type'} = $type;

    # Get list of tokens for this message (from ::Sms::Structure)
    my $cPdu = $self->{'pdu'};

    # Check that PDU is not empty
    return 0 unless $cPdu;

    # Backup copy for "backtracking"
    my $cPduCopy = $cPdu;

    my @token_names = $self->structure();
    my $decoded     = 1;

    #is udh in pdu?
    my $udh_parsed = 0;
    while (@token_names) {

        # Create new token object
        my $token = new Sms::Token(shift @token_names,
            { messageTokens => $self->{'tokens'} });
        if (!defined $token) {
            $decoded = 0;
            last;
        }

        # If decoding is completed successfully, add token object to message
        #_log('PDU BEFORE ['.$cPdu.']', length($cPdu) );

        if ($token->decode(\$cPdu)) {

            # Store token object into SMS message
            $self->{'tokens'}->{ $token->name() } = $token;

            # Catch message type indicator (MTI) and re-load structure
            # We must also skip message types 0x02 and 0x03 because we don't handle them currently
            if ($token->name() eq 'PDUTYPE') {

                my $mti  = $token->MTI();
                my $udhi = $token->UDHI();

                #               # If MTI has bit 1 on, this could be a SMS-STATUS message (0x02), or (0x03???)
                #               if( $mti >= SMS_STATUS ) {
                #                   _log('skipping unhandled message type ['.$mti.']');
                #                   return undef;
                #               }

                if ($mti != $type) {

                    #_log('token PDUTYPE, data='.$token->data().' MTI='.$token->get('MTI').' ->MTI()='.$token->MTI());
                    #
                    # This is a SMS-SUBMIT message, so:
                    #
                    # 1) change type
                    # 2) restore original PDU message
                    # 3) reload token structure
                    # 4) restart decoding
                    #
                    $self->type($type = $mti);

                    $cPdu        = $cPduCopy;
                    @token_names = $self->structure();

                    #_log('RESTARTING DECODING AFTER MTI DETECTION'); #<STDIN>;
                    redo;
                }

                if ($udh_parsed == 0 and $udhi == 1) {
                    $cPdu        = $cPduCopy;
                    @token_names = $self->structure();
                    $udh_parsed  = 1;
                    redo;
                }

                #_log('       ', $token->name(), ' DATA = ', $token->toString() );

            }

        }

        #_log('PDU AFTER  ['.$cPdu.']', length($cPdu) );

    }

    #_log("\n", 'PRESS ENTER TO CONTINUE'); <STDIN>;

    return $decoded;

}

#
# Delete an sms message
#
sub delete {
    my $self = $_[0];
    my $gsm  = $self->_parent();
    my $ok;

    # Try to delete message
    my $msg_index = $self->index();
    my $storage   = $self->storage();

    # Issue delete command
    if (ref $gsm && $storage && $msg_index >= 0) {
        $ok = $gsm->delete_sms($msg_index, $storage);
        $gsm->log->write('info',
                  'Delete sms n.'
                . $msg_index
                . ' in storage '
                . $storage . ' => '
                . ($ok ? 'OK' : '*ERROR'));
    }
    else {
        $gsm->log->write('warn',
                  'Could not delete sms n.'
                . $msg_index
                . ' in storage '
                . $storage
                . '. Internal error.');
        $ok = undef;
    }

    return $ok;
}

#
# Returns message own index number (position)
#
sub index {
    my $self = $_[0];
    return $self->{'index'};
}

#
# Returns message storage (SM - SIM card or ME - phone memory)
#
sub storage {
    my $self = $_[0];
    return $self->{'storage'};
}

#
# Only valid for SMS_SUBMIT and SMS_STATUS messages
#
sub recipient {
    my $self = shift;
    if ($self->type() == SMS_SUBMIT or $self->type() == SMS_STATUS) {
        my $t = $self->token('DA');
        return $t->toString() if $t;
    }
}

#
# Only valid for SMS_STATUS messages?
#
sub message_reference {
    my $self = shift;
    if ( $self->type() == SMS_STATUS) {
        my $t = $self->token('MR');
        return $t->toString() if $t;
    }
}


#
#Only valid for SMS_STATUS messages returns status code(in hex) extracted from status message
#Codes are explained in ST.pm
#
sub delivery_status {
    my $self = shift;
    if ($self->type() == SMS_STATUS) {
        my $t = $self->token('ST');
        return $t->toString() if $t;
    }
}

#
# Only valid for SMS_DELIVER messages (?)
#
sub sender {
    my $self = shift;
    if ($self->type() == SMS_DELIVER) {
        my $t = $self->token('OA');
        return $t->toString() if $t;
    }
}

# Alias for text()
sub content {
    return $_[0]->text();
}

sub text {
    my $self = shift;
    my $t    = $self->token('UD');
    return $t->toString() if $t;
}

#
#only valid for SMS_DELIVER messages, retuns presence of UDH
#
sub is_udh {
    my $self = shift;
    if ($self->type() == SMS_DELIVER) {
        return $self->{'tokens'}->{'PDUTYPE'}->{'_UDHI'};
    }
}

#
#only valid for SMS_DELIVER messages with UDH, returns if sms is csms
#
sub is_csms {
    my $self = shift;
    if ($self->is_udh()) {
        return $self->{'tokens'}->{'UDH'}->{'_IS_CSMS'};
    }
}

#
#only valid for SMS_DELIVER messages with UDH, retuns CSM reference number
#
sub csms_ref_num {
    my $self = shift;
    if ($self->is_csms()) {
        return $self->{'tokens'}->{'UDH'}->{'_REF_NUM'};
    }
}

#
#only valid for SMS_DELIVER messages with UDH, retuns CSM reference number
#
sub csms_ref_hex {
    my $self = shift;
    if ($self->is_csms()) {
        return $self->{'tokens'}->{'UDH'}->{'_REF_HEX'};
    }
}

#
#only valid for SMS_DELIVER messages with UDH, retuns CSM parts count
#
sub csms_parts {
    my $self = shift;
    if ($self->is_csms()) {
        return $self->{'tokens'}->{'UDH'}->{'_PARTS'};
    }
}

#
#only valid for SMS_DELIVER messages with UDH, retuns CSM current part number
#
sub csms_part_num {
    my $self = shift;
    if ($self->is_csms()) {
        return $self->{'tokens'}->{'UDH'}->{'_PART_NUM'};
    }
}

sub token ($) {
    my ($self, $token_name) = @_;
    return undef unless $token_name;

    if (exists $self->{'tokens'}->{$token_name}) {
        return $self->{'tokens'}->{$token_name};
    }
    else {
        warn('undefined token ' . $token_name . ' for this sms');
        return undef;
    }
}

#
# Returns type of sms (SMS_DELIVER || SMS_SUBMIT)
#
sub type {
    my $self = shift;
    if (@_) {
        $self->{'type'} = shift;
    }
    $self->{'type'};
}

=pod

=head1 NAME

Device::Gsm::Sms - SMS message internal class that represents a single text SMS message

=head1 SYNOPSIS

    # A list of Device::Gsm::Sms messages is returned by
    # Device::Gsm messages() method.

    use Device::Gsm;
    ...
    @sms = $gsm->messages();

    if( @sms ) {
        foreach( @sms ) {
            print $msg->storage()   , "\n";
            print $msg->recipient() , "\n";
            print $msg->sender()    , "\n";
            print $msg->content()   , "\n";
            print $msg->time()      , "\n";
            print $msg->type()      , "\n";
        }
    }

    # Or you can instance a sms message from raw PDU data
    my $msg = new Device::Gsm::Sms(
        header => '+CMGL: ...',
        pdu    => `[encoded pdu data]',
        storage=> 'ME', # or 'SC'
    );

    if( defined $msg ) {
        print $msg->recipient() , "\n";
        print $msg->sender()    , "\n";
        print $msg->content()   , "\n";  # or $msg->text()
        print $msg->time()      , "\n";
        print $msg->type()      , "\n";
    }

	$msg->delete();

=head1 DESCRIPTION

C<Device::Gsm::Sms> class implements very basic SMS message object,
that can be used to decode C<+CMGL> GSM command response to build a more
friendly high-level object.

=head1 METHODS

The following is a list of methods applicable to C<Device::Gsm::Sms> objects.

=head2 content()

See text() method.

=head2 decode()

Starts the decoding process of pdu binary data. If decoding process 
ends in success, return value is true and sms object is filled with
all proper values.

If decoding process has errors or pdu data is not provided, return
value is 0 (zero).


=head2 delete()

Delete the current SMS message from sim card.
Example:

    $gsm = Device::Gsm->new();
    ...
    my @msg = $gsm->messages();
    $msg[0] && $msg[0]->delete();

=head2 new()

Basic constructor. You can build a new C<Device::Gsm::Sms> object from the
raw B<+CMGL> header and B<PDU> data. Those data is then decoded and a new
sms object is instanced and all information filled, to be available
for subsequent method calls.

The allowed parameters to new() method are:

=over 4

=item header

This is the raw B<+CMGL> header string as modem outputs when you
issue a B<+CMGL> command

=item pdu

Binary encoded sms data

=item storage

Tells which storage to delete the message from. Check the documentation of your
phone to know valid storage values. Default values are:

=over 4

=item C<ME>

Deletes messages from gsm phone memory.

=item C<SC>

Deletes messages from sim card.

=back

=back

=head2 index()

Returns the sms message index number, that is the position of message in the
internal device memory or sim card.
This number is used for example to delete the message.

    my $gsm = Device::Gsm->new(port=>'/dev/ttyS0');
    ...
    my @messages = $gsm->messages();
    ...
    # Delete the first returned message
    my $msg = shift @messages;
    $gsm->delete_sms( $msg->index() );

=head2 recipient()

Returns the sms recipient number (destination address = DA)
as string (ex.: C<+39012345678>).

=head2 sender()

Returns the sms sender number (originating address = OA) as string.

=head2 status()

Status of the message can be one value from the following list:

=for html
<FORM><SELECT><OPTION>UNKNOWN<OPTION>REC UNREAD<OPTION>REC READ<OPTION>SENT UNREAD<OPTION>SENT READ</SELECT></FORM>

=for pod
'UNKNOWN', 'REC UNREAD', 'REC READ', 'SENT UNREAD', 'SENT READ'

=head2 storage()

Returns the storage where SMS has been read from.

=head2 text()

Returns the textual content of sms message.

=head2 token()

Returns the given PDU token of the decoded message (internal usage).

=head2 type()

SMS messages can be of two types: SMS_SUBMIT and SMS_DELIVER, that are defined by
two constants with those names. type() method returns one of these two values.

Example:

	if( $sms->type() == Device::Gsm::Sms::SMS_DELIVER ) {
		# ...
	}
	elsif( $sms->type() == Device::Gsm::Sms::SMS_SUBMIT ) {
		# ...
	}

=head1 REQUIRES

=over 4

=item *

Device::Gsm

=back

=head1 EXPORTS

None

=head1 TODO

=over 4

=item *

Complete and proof-read documentation and examples

=back

=head1 COPYRIGHT

Device::Gsm::Sms - SMS message simple class that represents a text SMS message

Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org

This program is free software; you can redistribute it and/or modify
it only under the terms of Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Perl licensing terms for details.

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

L<Device::Gsm>, perl(1)

=cut
