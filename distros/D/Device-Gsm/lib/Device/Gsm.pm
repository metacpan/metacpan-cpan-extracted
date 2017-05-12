# Device::Gsm - a Perl class to interface GSM devices as AT modems
# Copyright (C) 2002-2016 Cosimo Streppone, cosimo@cpan.org
# Copyright (C) 2006-2015 Grzegorz Wozniak, wozniakg@gmail.com
# Copyright (C) 2016 Joel Maslak, jmaslak@antelope.net

# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for more details.

package Device::Gsm;

$Device::Gsm::VERSION = '1.61';

use strict;
use Device::Modem 1.47;
use Device::Gsm::Sms;
use Device::Gsm::Pdu;
use Device::Gsm::Charset;
use Device::Gsm::Sms::Token;
use Time::HiRes qw(sleep);
use constant USSD_DCS => 15;

@Device::Gsm::ISA = ('Device::Modem');

%Device::Gsm::USSD_RESPONSE_CODES = (
    0 =>
        'No further user action required (network initiated USSD-Notify, or no further information needed after mobile Initiated operation)',
    1 =>
        'Further user action required (network initiated USSD-Request, or  further information needed after mobile initiated operation)',
    2 =>
        'USSD terminated by network. the reason for the termination is indicated  by the index stored in %Device::Gsm::USSD_TERMINATION_CODES',
    3 => 'Other local client has responded',
    4 => 'Operation not supported',
    5 => 'Network time out'
);
%Device::Gsm::USSD_TERMINATION_CODES = (
    0  => 'NO_CAUSE',
    1  => 'CC_BUSY',
    2  => 'PARAMETER_ERROR',
    3  => 'INVALID_NUMBER',
    4  => 'OUTGOING_CALL_BARRED',
    5  => 'TOO_MANY_CALLS_ON_HOLD',
    6  => 'NORMAL',
    10 => 'DROPPED',
    12 => 'NETWORK',
    13 => 'INVALID_CALL_ID',
    14 => 'NORMAL_CLEARING',
    16 => 'TOO_MANY_ACTIVE_CALLS',
    17 => 'UNASSIGNED_NUMBER',
    18 => 'NO_ROUTE_TO_DEST',
    19 => 'RESOURCE_UNAVAILABLE',
    20 => 'CALL_BARRED',
    21 => 'USER_BUSY',
    22 => 'NO_ANSWER',
    23 => 'CALL_REJECTED',
    24 => 'NUMBER_CHANGED',
    25 => 'DEST_OUT_OF_ORDER',
    26 => 'SIGNALING_ERROR',
    27 => 'NETWORK_ERROR',
    28 => 'NETWORK_BUSY',
    29 => 'NOT_SUBSCRIBED',
    31 => 'SERVICE_UNAVAILABLE',
    32 => 'SERVICE_NOT_SUPPORTED',
    33 => 'PREPAY_LIMIT_REACHED',
    35 => 'INCOMPATIBLE_DEST',
    43 => 'ACCESS_DENIED',
    45 => 'FEATURE_NOT_AVAILABLE',
    46 => 'WRONG_CALL_STATE',
    47 => 'SIGNALING_TIMEOUT',
    48 => 'MAX_MPTY_PARTICIPANTS_EXCEEDED',
    49 => 'SYSTEM_FAILURE',
    50 => 'DATA_MISSING',
    51 => 'BASIC_SERVICE_NOT_PROVISIONED',
    52 => 'ILLEGAL_SS_OPERATION',
    53 => 'SS_INCOMPATIBILITY',
    54 => 'SS_NOT_AVAILABLE',
    55 => 'SS_SUBSCRIPTION_VIOLATION',
    56 => 'INCORRECT_PASSWORD',
    57 => 'TOO_MANY_PASSWORD_ATTEMPTS',
    58 => 'PASSWORD_REGISTRATION_FAILURE',
    59 => 'ILLEGAL_EQUIPMENT',
    60 => 'UNKNOWN_SUBSCRIBER',
    61 => 'ILLEGAL_SUBSCRIBER',
    62 => 'ABSENT_SUBSCRIBER',
    63 => 'USSD_BUSY',
    65 => 'CANNOT_TRANSFER_MPTY_CALL',
    66 => 'BUSY_WITH_UNANSWERED_CALL',
    68 => 'UNANSWERED_CALL_PENDING',
    69 => 'USSD_CANCELED',
    70 => 'PRE_EMPTION',
    71 => 'OPERATION_NOT_ALLOWED',
    72 => 'NO_FREE_BEARER_AVAILABLE',
    73 => 'NBR_SN_EXCEEDED',
    74 => 'NBR_USER_EXCEEDED',
    75 => 'NOT_ALLOWED_BY_CC',
    76 => 'MODIFIED_TO_SS_BY_CC',
    77 => 'MODIFIED_TO_CALL_BY_CC',
    78 => 'CALL_MODIFIED_BY_CC',
    90 => 'FDN_FAILURE'
);

# Connection defaults to 19200 baud. This seems to be the optimal
# rate for serial links to new gsm phones.
$Device::Gsm::BAUDRATE = 19200;

# Time to wait after network register command (secs)
$Device::Gsm::REGISTER_DELAY = 2;

# Connect on serial port to gsm device
# see parameters on Device::Modem::connect()
sub connect {
    my $me = shift;
    my %aOpt;
    %aOpt = @_ if (@_);

    #
    # If you have problems with bad characters being trasmitted across serial link,
    # try different baud rates, as below...
    #
    # .---------------------------------.
    # | Model (phone/modem) |  Baudrate |
    # |---------------------+-----------|
    # | Falcom Swing (A2D)  |      9600 |
    # | Siemens C35/C45     |     19200 |
    # | Nokia phones        |     19200 |
    # | Nokia Communicator  |      9600 |
    # | Digicom             |      9600 |
    # `---------------------------------'
    #
    # GSM class defaults to 19200 baud
    #
    $aOpt{'baudrate'} ||= $Device::Gsm::BAUDRATE;

    $me->{_test_cache} = {}; # We clear the list of commands supported,
                             # in case the user disconnects one phone
                             # and connects a different kind of phone

    $me->SUPER::connect(%aOpt);
}

sub disconnect {
    my $me = shift;
    $me->{_test_cache} = {}; # Not strictly needed, but this is safety code
    $me->SUPER::disconnect();
    sleep 0.05;
}

#
# Get/set phone date and time
#
sub datetime {
    my $self     = shift;
    my $ok       = undef;    # ok/err flag
    my $datetime = undef;    # datetime string
    my @time     = ();       # array in "localtime" format

    # Test support for clock function
    if ($self->test_command('+CCLK')) {

        if (@_) {

            # If called with "$self->datetime(time())" format
            if (@_ == 1) {

                # $_[0] must be result of `time()' func
                @time = localtime($_[0]);
            }
            else {

                # If called with "$self->datetime(localtime())" format
                # @_ here is the result of `localtime()' func
                @time = @_;
            }

            $datetime = sprintf(
                '%02d/%02d/%02d,%02d:%02d:%02d',
                $time[5] - 100,    # year
                1 + $time[4],      # month
                $time[3],          # day
                @time[ 2, 1, 0 ],  # hr,min,secs
            );

            # Set time of phone
            $self->atsend(qq{AT+CCLK="$datetime"} . Device::Modem::CR);
            $ok = $self->parse_answer($Device::Modem::STD_RESPONSE);

            $self->log->write(
                'info',
                "write datetime ($datetime) to phone => ("
                    . ($ok ? 'OK' : 'FAILED') . ")"
            );

        }
        else {

            $self->atsend('AT+CCLK?' . Device::Modem::CR);
            ($ok, $datetime)
                = $self->parse_answer($Device::Modem::STD_RESPONSE);

            #warn('datetime='.$datetime);
            if (   $ok
                && $datetime
                =~ m|\+CCLK:\s*"?(\d\d)/(\d\d)/(\d\d)\,(\d\d):(\d\d):(\d\d)"?|
                )
            {
                $datetime = "$1/$2/$3 $4:$5:$6";
                $self->log->write(
                    'info',
                    "read datetime from phone ($datetime)"
                );
            }
            else {
                $self->log->write(
                    'warn',
                    "datetime format ($datetime) not recognized"
                );
                $datetime = undef;
            }

        }

    }

    return $datetime;

}

#
# Delete a message from sim card
#
sub delete_sms {
    my $self      = shift;
    my $msg_index = shift;
    my $storage   = shift;
    my $ok;

    if (!defined $msg_index || $msg_index eq '') {
        $self->log->write(
            'warn',
            'undefined message number. cannot delete sms message'
        );
        return 0;
    }

    # Set default SMS storage if supported
    $self->storage($storage);

    $self->atsend(qq{AT+CMGD=$msg_index} . Device::Modem::CR);

    my $ans = $self->parse_answer($Device::Modem::STD_RESPONSE);
    if (index($ans, 'OK') > -1 || $ans =~ /\+CMGD/) {
        $ok = 1;
    }

    $self->log->write(
        'info',
        "deleting sms n.$msg_index from storage "
            . ($storage || "default")
            . " (result: `$ans') => "
            . ($ok ? 'ok' : '*FAILED*')
    );

    return $ok;
}

#
# Call forwarding
#
sub forward {
    my ($self, $reason, $mode, $number) = @_;

    $reason = lc $reason || 'unconditional';
    $mode   = lc $mode   || 'register';
    $number ||= '';

    my %reasons = (
        'unconditional' => 0,
        'busy'          => 1,
        'no reply'      => 2,
        'unreachable'   => 3
    );

    my %modes = (
        'disable'  => 0,
        'enable'   => 1,
        'query'    => 2,
        'register' => 3,
        'erase'    => 4
    );

    my $reasoncode = $reasons{$reason};
    my $modecode   = $modes{$mode};

    $self->log->write(
        'info',
        qq{setting $reason call forwarding to [$number]}
    );
    $self->atsend(
        qq{AT+CCFC=$reasoncode,$modecode,"$number"} . Device::Modem::CR);

    return $self->parse_answer($Device::Modem::STD_RESPONSE, 15000);
}

#
# Hangup and terminate active call(s)
# this overrides the `Device::Modem::hangup()' method
#
sub hangup {
    my $self = shift;
    $self->log->write('info', 'hanging up...');
    $self->attention();
    $self->atsend('AT+CHUP' . Device::Modem::CR);
    $self->flag('OFFHOOK', 0);
    $self->answer(undef, 5000);
}

#
# Who is the manufacturer of this device?
#
sub manufacturer {
    my $self = shift;
    my ($ok, $man);

    # We can't test for command support, because some phones, mainly Motorola
    # will spit out an error, instead of telling if CGMI is supported.
    $self->atsend('AT+CGMI' . Device::Modem::CR);
    ($ok, $man) = $self->parse_answer($Device::Modem::STD_RESPONSE);

    if ($ok ne 'OK') {
        $self->log->write(
            'warn',
            'manufacturer command ended with error [' . $ok . $man . ']'
        );
        return undef;
    }

    # Again, seems that Motorola phones will re-echo
    # the CGMI command header, instead of giving us the
    # manufacturer info we want. Thanks to Niolay Shaplov
    # for reporting (RT #31540)
    if ($man =~ /\+CGMI:\ \"(.*)\"/s) {
        $man = $1;
    }

    $self->log->write(
        'info',
        'manufacturer of this device appears to be [' . $man . ']'
    );

    return $man || $ok;
}

#
# Set text or pdu mode for gsm devices. If no parameter passed, returns current mode
#
sub mode {
    my $self = shift;

    if (@_) {
        my $mode = lc $_[0];
        if ($mode eq 'text') {
            $mode = 1;
        }
        else {
            $mode = 0;
        }
        $self->{'_mode'} = $mode ? 'text' : 'pdu';
        $self->log->write(
            'info',
            'setting mode to [' . $self->{'_mode'} . ']'
        );
        $self->atsend(qq{AT+CMGF=$mode} . Device::Modem::CR);

        return $self->parse_answer($Device::Modem::STD_RESPONSE);
    }

    return ($self->{'_mode'} || '');

}

#
# What is the model of this device?
#
sub model {
    my $self = shift;
    my ($code, $model);

    # Test if manufacturer code command is supported
    if ($self->test_command('+CGMM')) {

        $self->atsend('AT+CGMM' . Device::Modem::CR);
        ($code, $model) = $self->parse_answer($Device::Modem::STD_RESPONSE);

        $self->log->write(
            'info',
            'model of this device is [' . ($model || '') . ']'
        );

    }

    return $model || $code;
}

#
# Get handphone serial number (IMEI number)
#
sub imei {
    my $self = shift;
    my ($code, $imei);

    # Test if manufacturer code command is supported
    if ($self->test_command('+CGSN')) {

        $self->atsend('AT+CGSN' . Device::Modem::CR);
        ($code, $imei) = $self->parse_answer($Device::Modem::STD_RESPONSE);

        $self->log->write('info', 'IMEI code is [' . $imei . ']');

    }
    return $imei || $code;
}

# Alias for `imei()' is `serial_number()'
*serial_number = *imei;

#
# Get mobile phone signal quality (expressed in dBm)
#
sub signal_quality {
    my $self = shift;

    # Error code, dBm (signal power), bit error rate
    my ($code, @dBm, $dBm, $ber);

    # Test if signal quality command is implemented
    if ($self->test_command('+CSQ')) {

        $self->atsend('AT+CSQ' . Device::Modem::CR);
        ($code, @dBm)
            = $self->parse_answer($Device::Modem::STD_RESPONSE, 15000);

        # Vodafone data cards send out response to commands with
        # many empty lines in between, so +CSQ response is not the very
        # first line of answer.
        for (@dBm) {
            if (/\+CSQ:/) {
                $dBm = $_;
                last;
            }
        }

        # Some gsm software send CSQ command result as "+CSQ: xx,yy"
        if ($dBm =~ /\+CSQ:\s*(\d+),(\d+)/) {

            ($dBm, $ber) = ($1, $2);

            # Further process dBm number to obtain real dB power
            if ($dBm > 30) {
                $dBm = -51;
            }
            else {
                $dBm = -113 + ($dBm << 1);
            }

            $self->log->write(
                'info',
                'signal dBm power is [' 
                    . $dBm
                    . '], bit error rate ['
                    . $ber . ']'
            );

            # Other versions put out "+CSQ: xx" only...
        }
        elsif ($dBm =~ /\+CSQ:\s*(\d+)/) {

            $dBm = $1;

            $self->log->write('info', 'signal is [' . $dBm . '] "bars"');

        }
        else {

            $self->log->write('warn', 'cannot obtain signal dBm power');

        }

    }
    else {

        $self->log->write('warn', 'signal quality command not supported!');

    }

    return $dBm;

}

#
# Get the GSM software version on this device
#
sub software_version {
    my $self = shift;
    my ($code, $ver);

    # Test if manufacturer code command is supported
    if ($self->test_command('+CGMR')) {

        $self->atsend('AT+CGMR' . Device::Modem::CR);
        ($code, $ver) = $self->parse_answer($Device::Modem::STD_RESPONSE);

        $self->log->write('info', 'GSM version is [' . $ver . ']');

    }

    return $ver || $code;
}

#
# Test support for a specific command
#
sub test_command {
    my ($self, $command) = @_;

    if (!exists($self->{_test_cache})) { $self->{_test_cache} = {} }
    if (exists($self->{_test_cache}{$command})) {
        return $self->{_test_cache}{$command};
    }

    # Support old code adding a `+' if not specified
    # TODO to be removed in 1.30 ?
    if ($command =~ /^[a-zA-Z]/) {
        $command = '+' . $command;
    }

    # Standard test procedure for every command
    $self->log->write(
        'info',
        'testing support for command [' . $command . ']'
    );
    $self->atsend("AT$command=?" . Device::Modem::CR);

    # If answer is ok, command is supported
    my $ok = ($self->answer($Device::Modem::STD_RESPONSE) || '') =~ /OK/o;
    $self->log->write(
        'info',
        'command [' . $command . '] is ' . ($ok ? '' : 'not ') . 'supported'
    );

    $self->{_test_cache}{$command} = $ok;
    return $ok;
}

#
# Read all messages on SIM card (XXX must be registered on network)
#
sub messages {
    my ($self, $storage) = @_;
    my @messages;

    # By default (old behaviour) messages are read from sim card
    $storage ||= 'SM';

    $self->log->write('info', 'Reading messages on '
            . ($storage eq 'SM' ? 'Sim card' : 'phone memory'));

    # Register on network (give your PIN number for this!)
    #return undef unless $self->register();
    $self->register();

    #
    # Read messages (TODO need to check if device supports CMGL with `stat'=4)
    #
    if ($self->mode() eq 'text') {
        warn 'Read messages in text mode is not implemented yet.';

        #@messages = $self->_read_messages_text();
    }
    else {

        # Set default storage if supported
        $self->storage($storage);

        push @messages, $self->_read_messages_pdu();
    }

    return @messages;
}

sub storage {
    my $self = shift;
    my $ok   = 0;

    # Set default SMS storage if supported by phone
    if (@_ && (my $storage = uc $_[0])) {
        return unless $self->test_command('+CPMS');
        $self->atsend(qq{AT+CPMS="$storage"} . Device::Modem::CR);

        # Read and discard the answer
        $self->answer($Device::Modem::STD_RESPONSE, 5000);
        $self->{_storage} = $storage;
    }

    return $self->{_storage};
}

#
# Register to GSM service provider network
#
sub register {
    my $me  = shift;
    my $lOk = 0;

    # Check for connection
    if (!$me->{'CONNECTED'}) {
        $me->log->write('info', 'Not yet connected. Doing it now...');
        if (!$me->connect()) {
            $me->log->write('warning', 'No connection!');
            return $lOk;
        }
    }

    # On some phones, registration doesn't work, so you can skip it entirely
    # by passing 'assume_registered => 1' to the new() constructor
    if (exists $me->{'assume_registered'} && $me->{'assume_registered'}) {
        return $me->{'REGISTERED'} = 1;
    }

    # Send PIN status query
    $me->log->write('info', 'PIN status query');
    $me->atsend('AT+CPIN?' . Device::Modem::CR);

    # Get answer
    my $cReply = $me->answer($Device::Modem::STD_RESPONSE, 10000);

    if (!defined $cReply || $cReply eq "") {
        $me->log->write('warn',
            'Could not get a reply for the AT+CPIN command');
        return;
    }

    if ($cReply =~ /(READY|SIM PIN2)/) {

        # Iridium satellite phones rest saying "SIM PIN2" when they are registered...

        $me->log->write(
            'info',
            'Already registered on network. Ready to send.'
        );
        $lOk = 1;

    }
    elsif ($cReply =~ /SIM PIN/) {

        # Pin request, sending PIN code
        $me->log->write('info', 'PIN requested: sending...');
        $me->atsend(qq[AT+CPIN="$$me{'pin'}"] . Device::Modem::CR);

        # Get reply
        $cReply = $me->answer($Device::Modem::STD_RESPONSE, 10000);

        # Test reply
        if ($cReply !~ /ERROR/) {
            $me->log->write('info', 'PIN accepted. Ready to send.');
            $lOk = 1;
        }
        else {
            $me->log->write('warning', 'PIN rejected');
            $lOk = 0;
        }

    }

    # Store status in object and return
    $me->{'REGISTERED'} = $lOk;

    return $lOk;
}

# send_sms( %options )
#
#   recipient => '+39338101010'
#   class     => 'flash' | 'normal'
#   validity  => [ default = 24 hours ]
#   content   => 'text-only for now'
#   mode      => 'text' | 'pdu'        (default = 'pdu')
#
sub send_sms {

    my ($me, %opt) = @_;

    my $lOk = 0;
    my $mr;
    return unless $opt{'recipient'} and $opt{'content'};

    # Check if registered to network
    if (!$me->{'REGISTERED'}) {
        $me->log->write('info', 'Not yet registered, doing now...');
        $me->register();

        # Wait some time to allow SIM registering to network
        $me->wait($Device::Gsm::REGISTER_DELAY << 10);
    }

    # Again check if now registered
    if (!$me->{'REGISTERED'}) {

        $me->log->write('warning', 'ERROR in registering to network');
        return $lOk;

    }

    # Ok, registered. Select mode to send SMS
    $opt{'mode'} ||= 'PDU';
    if (uc $opt{'mode'} ne 'TEXT') {

        ($lOk, $mr) = $me->_send_sms_pdu(%opt);

    }
    else {

        ($lOk, $mr) = $me->_send_sms_text(%opt);
    }

    # Return result of sending
    return wantarray ? ($lOk, $mr) : $lOk;
}

# send_csms( %options )
#
#   recipient => '+39338101010'
#   class     => 'flash' | 'normal'
#   validity  => [ default = 24 hours ]
#   content   => 'text-only above 160 chars'
#
sub send_csms {

    my ($me, %opt) = @_;

    my $lOk = 0;
    my @mrs;
    return unless $opt{'recipient'} and $opt{'content'};

    # Check if registered to network
    if (!$me->{'REGISTERED'}) {
        $me->log->write('info', 'Not yet registered, doing now...');
        $me->register();

        # Wait some time to allow SIM registering to network
        $me->wait($Device::Gsm::REGISTER_DELAY << 10);
    }

    # Again check if now registered
    if (!$me->{'REGISTERED'}) {

        $me->log->write('warning', 'ERROR in registering to network');
        return 0;

    }

    # Ok, registered. Select mode to send SMS
    $opt{'mode'} ||= 'PDU';

    if (uc $opt{'mode'} eq 'TEXT') {
        $me->log->write('warning', 'CSMS only in PDU mode, switching');
        until (uc($me->{'_mode'}) ne 'PDU') {
            $me->mode('pdu') or sleep 0.05;
        }
    }
    my @text_parts;

    #ensure we have to send CSMS
    if (Device::Gsm::Charset::gsm0338_length($opt{'content'}) <= 160) {
        my @send_return = $me->_send_sms_pdu(%opt);
        if ($send_return[0]) {
            $lOk++;
            push(@mrs, $send_return[1]);
        }
        else {
            $lOk  = 0;
            $#mrs = -1;
        }
    }
    else {
        my $udh        = new Sms::Token("UDH");
        my $ref_num    = sprintf("%02X", (int(rand(255))));
        my @text_parts = Device::Gsm::Charset::gsm0338_split($opt{'content'});
        my $parts      = scalar(@text_parts);
        $parts = sprintf("%02X", $parts);
        my $padding
            = Sms::Token::UDH::calculate_padding(Sms::Token::UDH::IEI_T_8_L);
        my $part_count = 1;
        foreach my $text_part (@text_parts) {
            my $part = sprintf("%02X", $part_count);
            my ($len_hex, $encoded_text)
                = Device::Gsm::Pdu::encode_text7_udh($text_part, $padding);
            $part_count++;
            $opt{'content'} = $text_part;
            $opt{'pdu_msg'}
                = sprintf("%02X",
                hex($len_hex) + Sms::Token::UDH::IEI_T_8_L + 2)
                . $udh->encode(
                Sms::Token::UDH::IEI_T_8 => $ref_num . $parts . $part)
                . $encoded_text;
            my @send_return = $me->send_sms_pdu_long(%opt);
            if ($send_return[0]) {
                $lOk++;
                push(@mrs, $send_return[1]);

            }
            else {
                $lOk  = 0;
                $#mrs = -1;
                last;
            }
            sleep 0.05;
        }
    }

    # Return result of sending
    return wantarray ? ($lOk, @mrs) : $lOk;
}

#
#
# read messages in pdu mode
#
#
sub _read_messages_pdu {
    my $self = shift;

    $self->mode('pdu');

    $self->atsend(q{AT+CMGL=4} . Device::Modem::CR);
    my ($messages) = $self->answer($Device::Modem::STD_RESPONSE, 5000);

    # Catch the case that the msgs are returned with gaps between them
    while (my $more = $self->answer($Device::Modem::STD_RESPONSE, 200)) {

        #-- $self->answer will chomp trailing newline, add it back
        $messages .= "\n";
        $messages .= $more;
    }

    # Ok, messages read, now convert from PDU and store in object
    $self->log->write('debug', 'Messages=' . $messages);

    my @data = split /[\r\n]+/m, $messages;

    # Check for errors on SMS reading
    my $code;
    if (($code = pop @data) =~ /ERROR/) {
        $self->log->write(
            'error',
            'cannot read SMS messages on SIM: [' . $code . ']'
        );
        return ();
    }

    my @message = ();
    my $current;

    # Current sms storage memory (ME or SM)
    my $storage = $self->storage();

    #
    # Parse received data (result of +CMGL command)
    #
    while (@data) {

        $self->log->write('debug', 'data[] = ', $data[0]);
        my $header = shift @data;
        my $pdu    = shift @data;

        # Instance new message object
        my $msg = new Device::Gsm::Sms(
            header => $header,
            pdu    => $pdu,

            # XXX mode   => $self->mode(),
            storage => $storage,
            parent  => $self       # Ref to parent Device::Gsm class
        );

        # Check if message has been instanced correctly
        if (ref $msg) {
            push @message, $msg;
        }
        else {
            $self->log->write(
                'info',
                "could not instance message $header $pdu!"
            );
        }

    }

    $self->log->write(
        'info',
        'found ' . (scalar @message) . ' messages on SIM. Reading.'
    );

    return @message;

}

#
# _send_sms_text( %options ) : sends message in text mode
#
sub _send_sms_text {
    my ($me, %opt) = @_;

    my $num  = $opt{'recipient'};
    my $text = $opt{'content'};

    return 0 unless $num and $text;

    my $lOk = 0;
    my $mr;
    my $cReply;

    # Select text format for messages
    $me->mode('text');
    $me->log->write('info', 'Selected text format for message sending');

    # Send sms in text mode
    $me->atsend(qq[AT+CMGS="$num"] . Device::Modem::CR);

    # Wait a bit before sending the text. Some GSM software needs it.
    $me->wait($Device::Modem::WAITCMD);

    # Complete message sending
    $text = Device::Gsm::Charset::iso8859_to_gsm0338($text);
    $me->atsend($text . Device::Modem::CTRL_Z);

    # Get reply and check for errors
    $cReply = $me->answer('+CMGS', 2000);
    if ($cReply =~ /OK$/i) {
        $cReply =~ /\+CMGS:\s*(\d+)/i;
        $me->log->write('info', "Sent SMS (text mode) to $num!");
        $lOk = 1;
        $mr  = $1;
    }
    else {
        $me->log->write('warning', "ERROR in sending SMS");
    }

    return wantarray ? ($lOk, $mr) : $lOk;
}

#
# _send_sms_pdu( %options )  : sends message in PDU mode
#
sub _send_sms_pdu {
    my ($me, %opt, $is_gsm0338) = @_;

    # Get options
    my $num  = $opt{'recipient'};
    my $text = $opt{'content'};

    return 0 unless $num and $text;

    $me->atsend(q[ATE1] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);

    # Select class of sms (normal or *flash sms*)
    my $class = $opt{'class'} || 'normal';
    $class = $class eq 'normal' ? '00' : 'F0';

    #Validity period value
    #0 to 143	(TP-VP + 1) * 5 minutes (i.e. 5 minutes intervals up to 12 hours)
    #144 to 167	12 hours + ((TP-VP - 143) * 30 minutes)
    #168 to 196	(TP-VP - 166) * 1 day
    #197 to 255	(TP-VP - 192) * 1 week
    #default 24h
    my $vp = 'A7';
    if (defined $opt{'validity_period'}) {
        $vp = sprintf("%02X", $opt{'validity_period'});
    }

    # Status report requested?
    my $status_report = 0;
    if (exists $opt{'status_report'} && $opt{'status_report'}) {
        $status_report = 1;
    }

    my $lOk = 0;
    my $mr  = undef;
    my $cReply;

    # Send sms in PDU mode

    #
    # Example of sms send in PDU mode
    #
    #AT+CMGS=22
    #> 0011000A8123988277190000AA0AE8329BFD4697D9EC37
    #+CMGS: 111
    #
    #OK

    # Encode DA
    my $enc_da = Device::Gsm::Pdu::encode_address($num);
    $me->log->write('info', 'encoded dest. address is [' . $enc_da . ']');

    # Encode text
    $is_gsm0338 or $text = Device::Gsm::Charset::iso8859_to_gsm0338($text);
    my $enc_msg = Device::Gsm::Pdu::encode_text7($text);
    $me->log->write(
        'info',
        'encoded 7bit text (w/length) is [' . $enc_msg . ']'
    );

    # Build PDU data
    my $pdu = uc join(
        '',
        '00',
        ($status_report ? '31' : '11'),
        '00',
        $enc_da,
        '00',
        $class,
        $vp,
        $enc_msg
    );

    $me->log->write('info', 'due to send PDU [' . $pdu . ']');

    # Sending main SMS command ( with length )
    my $len = ((length $pdu) >> 1) - 1;

    #$me->log->write('info', 'AT+CMGS='.$len.' string sent');

    # Select PDU format for messages
    $me->atsend(q[AT+CMGF=0] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);
    $me->log->write('info', 'Selected PDU format for msg sending');

    # Send SMS length
    $me->atsend(qq[AT+CMGS=$len] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);

    # Sending SMS content encoded as PDU
    $me->log->write('info', 'PDU sent [' . $pdu . ' + CTRLZ]');
    $me->atsend($pdu . Device::Modem::CTRL_Z);

    # Get reply and check for errors
    $cReply = $me->answer($Device::Modem::STD_RESPONSE, 30000);
    $me->log->write('debug', "SMS reply: $cReply\r\n");

    if ($cReply =~ /OK$/i) {
        $cReply =~ /\+CMGS:\s*(\d+)/i;
        $me->log->write('info', "Sent SMS (pdu mode) to $num!");
        $lOk = 1;
        $mr  = $1;

    }
    else {
        $cReply =~ /(\+CMGS:.*)/;
        $me->log->write('warning', "ERROR in sending SMS: $1");
    }

    return wantarray ? ($lOk, $mr) : $lOk;
}

sub send_sms_pdu_long {
    my ($me, %opt) = @_;

    # Get options
    my $num     = $opt{'recipient'};
    my $text    = $opt{'content'};
    my $pdu_msg = $opt{'pdu_msg'};

    return 0 unless $num and $text and $pdu_msg;

    $me->atsend(q[ATE1] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);

    # Select class of sms (normal or *flash sms*)
    my $class = $opt{'class'} || 'normal';
    $class = $class eq 'normal' ? '00' : 'F0';

    #Validity period value
    #0 to 143	(TP-VP + 1) * 5 minutes (i.e. 5 minutes intervals up to 12 hours)
    #144 to 167	12 hours + ((TP-VP - 143) * 30 minutes)
    #168 to 196	(TP-VP - 166) * 1 day
    #197 to 255	(TP-VP - 192) * 1 week
    #default 24h
    my $vp = 'A7';
    if (defined $opt{'validity_period'}) {
        $vp = sprintf("%02X", $opt{'validity_period'});
    }

    # Status report requested?
    my $status_report = 0;
    if (exists $opt{'status_report'} && $opt{'status_report'}) {
        $status_report = 1;
    }

    my $lOk = 0;
    my $mr  = undef;
    my $cReply;

    # Send sms in PDU mode

    #
    # Example of sms send in PDU mode
    #
    #AT+CMGS=22
    #> 0011000A8123988277190000AA0AE8329BFD4697D9EC37
    #+CMGS: 111
    #
    #OK

    # Encode DA
    my $enc_da = Device::Gsm::Pdu::encode_address($num);
    $me->log->write('info', 'encoded dest. address is [' . $enc_da . ']');

    # Encode text
    #$text = Device::Gsm::Charset::iso8859_to_gsm0338($text);
    #my $enc_msg = Device::Gsm::Pdu::encode_text7($text);
    $me->log->write(
        'info',
        'encoded 7bit text (w/length) is [' . $pdu_msg . ']'
    );

    # Build PDU data
    my $pdu = uc join(
        '',

        #we use default SMSC address(don supply one)
        '00',

        #as you can see when UDH is present we set 6 bit of of first octet, you can recognize CSM that way, I prefer regex :) (se UD.pm)
        ($status_report ? '71' : '51'),

        #message reference, my G24 returns own MR after successful sending, setting this value did nothing in that case, but other modems may behave differently
        '00',
        $enc_da,

        #protocol identifier (0x00 use default)
        '00',

        # data coding scheme (flash sms or normal, coding etc. more about
	# http://en.wikipedia.org/wiki/Data_Coding_Scheme)
        $class,
        $vp,
        $pdu_msg
    );

    $me->log->write('info', 'due to send PDU [' . $pdu . ']');

    # Sending main SMS command ( with length )
    my $len = ((length $pdu) >> 1) - 1;

    #$me->log->write('info', 'AT+CMGS='.$len.' string sent');

    # Select PDU format for messages
    $me->atsend(q[AT+CMGF=0] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);
    $me->log->write('info', 'Selected PDU format for msg sending');

    # Send SMS length
    $me->atsend(qq[AT+CMGS=$len] . Device::Modem::CR);
    $me->answer($Device::Modem::STD_RESPONSE);

    # Sending SMS content encoded as PDU
    $me->log->write('info', 'PDU sent [' . $pdu . ' + CTRLZ]');
    $me->atsend($pdu . Device::Modem::CTRL_Z);

    # Get reply and check for errors
    $cReply = $me->answer($Device::Modem::STD_RESPONSE, 30000);
    $me->log->write('debug', "SMS reply: $cReply\r\n");

    if ($cReply =~ /OK$/i) {
        $cReply =~ /\+CMGS:\s*(\d+)/i;
        $me->log->write('info', "Sent SMS (pdu mode) to $num!");
        $lOk = 1;
        $mr  = $1;
    }
    else {
        $cReply =~ /(\+CMGS:.*)/;
        $me->log->write('warning', "ERROR in sending SMS: $1");
    }

    return wantarray ? ($lOk, $mr) : $lOk;
}

#
# Set or request service center number
#
sub service_center {

    my $self = shift;
    my $nCenter;
    my $lOk = 1;
    my $code;

    # If additional parameter is supplied, store new message center number
    if (@_) {
        $nCenter = shift();

        # Remove all non numbers or `+' sign
        $nCenter =~ s/[^0-9+]//g;

        # Send AT command
        $self->atsend(qq[AT+CSCA="$nCenter"] . Device::Modem::CR);

        # Check for modem answer
        $lOk = ($self->answer($Device::Modem::STD_RESPONSE) =~ /OK/);

        if ($lOk) {
            $self->log->write(
                'info',
                'service center number [' . $nCenter . '] stored'
            );
        }
        else {
            $self->log->write(
                'warning',
                'unexpected response for "service_center" command'
            );
        }

    }
    else {

        $self->log->write('info', 'requesting service center number');
        $self->atsend('AT+CSCA?' . Device::Modem::CR);

        # Get answer and check for errors
        ($code, $nCenter) = $self->parse_answer($Device::Modem::STD_RESPONSE);

        if ($code =~ /ERROR/) {
            $self->log->write(
                'warning',
                'error status for "service_center" command'
            );
            $lOk = 0;
        }
        else {

            # $nCenter =~ tr/\r\nA-Z//s;
            $self->log->write(
                'info',
                'service center number is [' . $nCenter . ']'
            );

            # Return service center number
            $lOk = $nCenter;
        }

    }

    # Status flag or service center number
    return $lOk;

}

sub network {
    my $self = $_[0];
    my $network;

    #if( ! $self->test_command('COPS') )
    #{
    #    print 'NO COMMAND';
    #    return undef;
    #}

    $self->atsend('AT+COPS?' . Device::Modem::CR);

    # Parse COPS answer, the 3rd string is the network name
    my $ans = $self->answer();
    if ($ans =~ /"([^"]*)"/) {
        $network = $1;
        $self->log->write('info', 'Received network name [' . $network . ']');
    }
    else {
        $self->log->write('info', 'Received no network name');
    }

    # Try to decode the network name
    require Device::Gsm::Networks;
    my $netname = Device::Gsm::Networks::name($network);
    if (!defined $netname || $netname eq 'unknown') {
        $netname = undef;
    }
    return wantarray
        ? ($netname, $network)
        : $netname;

}

#
#returns simcard MSISDN
#
sub selfnum {
    my $self = shift;
    my @selfnum;
    my $selfnum;
    if ($self->test_command('CNUM')) {
        $self->atsend('AT+CNUM' . Device::Modem::CR);
        my $ans = $self->answer($Device::Modem::STD_RESPONSE);
        my @answer = split /[\r\n]+/m, $ans;
        foreach (@answer) {
            if ($_ =~ /^\+CNUM: /) {
                my @temp = split /,/, $';
                $temp[1] =~ s/"//g;
                if ($temp[1] =~ /\d{9,}/) {
                    !$selfnum and $selfnum = $temp[1];
                    push(@selfnum, $temp[1]);
                }
            }
        }
        if ($selfnum) {
            $self->log->write('info', 'Received number [' . "@selfnum" . ']');
            return wantarray
                ? @selfnum
                : $selfnum;
        }
        else {
            $self->log->write('info', 'Received no numbers');
            return "";
        }

    }

    #
    #On my motorola G24 for messages with alphanumeric sender sender() returns malformed characters
    #on globetrotter option 505 everything is all right. I wrote this at beggining of playng with you module,
    #and almost forgot about it. I'll investigate this bug in future.
    #
}

sub get_literal_header {
    my ($self, $index) = @_;
    my $header = '';

    #set text mode
    $self->atsend('AT+CMGF=1' . Device::Modem::CR);
    sleep 0.05;
    if ($self->answer($Device::Modem::STD_RESPONSE) =~ /OK/) {
        $self->log->write('warning', 'Text mode set');
    }
    else {
        $self->log->write('warning', 'Text mode not set');
        $self->log->write('warning', 'Trying restore PDU mode');
        $self->atsend('AT+CMGF=0' . Device::Modem::CR);
        sleep 0.05;
        $self->answer($Device::Modem::STD_RESPONSE) =~ /OK/
            and $self->log->write('warning', 'PDU mode restored');
        return;
    }
    $self->atsend('AT+MMGR=' . $index . Device::Modem::CR);
    my $ans = $self->answer();
    if ($ans =~ /\+MMGR:/) {
        my @temp = split(/,/, $');
        $header = $temp[1];
        $header =~ s/\"|\'//g;
    }
    $self->atsend('AT+CMGF=0' . Device::Modem::CR);
    sleep 0.05;
    $self->answer($Device::Modem::STD_RESPONSE) =~ /OK/
        and $self->log->write('warning', 'PDU mode Set')
        or return;
    return $header;
}

sub send_ussd {
    my ($self, $message) = @_;
    my $answer  = '';
    my $encoded = Device::Gsm::Pdu::encode_text7_ussd($message);
    if ($self->test_command("CUSD")) {
        my $at_command
            = 'AT+CUSD=1,"' . $encoded . '",' . USSD_DCS . Device::Modem::CR;
        $self->atsend($at_command);
        my $expect     = qr/ERROR|OK|\+CUSD:/;
        my $cReadChars = $Device::Modem::READCHARS;
        $Device::Modem::READCHARS = 300;
        my $response = '';
        $response = $self->answer($expect, 1000);

        # Catch the case that the msgs are returned with gaps between them
        $response =~ m/OK/
            and $response .= "\n" . $self->answer($expect, 15000);
        $Device::Modem::READCHARS = $cReadChars;
        if ($response =~ m/OK/) {
            $self->log->write('warning',
                      'send_ussd command: "' 
                    . $message
                    . '" OK, AT: '
                    . $at_command . " "
                    . 'response: '
                    . $response);
            if ($response =~ m/\+CUSD:\s*(\d+)\s*,/) {
                my $response_code = $1;
                $self->log->write('warning',
                    "Have a ussd_response code: $response_code=>"
                        . $Device::Gsm::USSD_RESPONSE_CODES{$1});
                $response = $';
                if ($response_code < 2) {
                    if ($response =~ m/\s*\"?([0-9A-F]+)\"?\s*,\s*(\d*)\s*/) {
                        my $ussd_response = $1;
                        my $ussd_dcs = length($2) ? $2 : USSD_DCS;
                        $self->log->write('warning',
                            "Have a ussd_response message: $ussd_response, dcs: $ussd_dcs"
                        );
                        ($ussd_dcs == 15 or $ussd_dcs == 0)
                            and $answer
                            = Device::Gsm::Pdu::decode_text7_ussd(
                            $ussd_response)
                            and $ussd_dcs = -1;
                        $ussd_dcs == 72
                            and $answer
                            = Device::Gsm::Pdu::decode_text_UCS2(
                            $ussd_response)
                            and $ussd_dcs = -1;
                        $ussd_dcs == 68
                            and $answer
                            = Device::Gsm::Pdu::decode_text8($ussd_response)
                            and $ussd_dcs = -1;
                        $ussd_dcs != -1
                            and $self->log->write('warning',
                            "Cant decode ussd_response message with dcs: $ussd_dcs"
                            );

                    }

                }
                elsif ($response_code == 2) {
                    $response =~ m/\s*(\d+)\s*/
                        and $self->log->write('warning',
                        "Have a ussd_termintion code: $1=>"
                            . $Device::Gsm::USSD_TERMINATION_CODES{$1});
                }
            }
        }
        else {
            $self->log->write('warning',
                      'Error send_ussd command: '
                    . $at_command
                    . ", returned: "
                    . $response);
            return '';

        }
    }
    else {
        $self->log->write('warning',
            'Error send_ussd AT+CUSD command not supported');
        return '';
    }
    return $answer;
}
1;

__END__

=head1 NAME

Device::Gsm - Perl extension to interface GSM phones / modems

=head1 SYNOPSIS

  use Device::Gsm;

  my $gsm = new Device::Gsm( port => '/dev/ttyS1', pin => 'xxxx' );

  if( $gsm->connect() ) {
      print "connected!\n";
  } else {
      print "sorry, no connection with gsm phone on serial port!\n";
  }

  # Register to GSM network (you must supply PIN number in above new() call)
  # See 'assume_registered' in the new() method documentation
  $gsm->register();

  # Send quickly a short text message
  $gsm->send_sms(
      recipient => '+3934910203040',
      content   => 'Hello world! from Device::Gsm'
  );

  # Get list of Device::Gsm::Sms message objects
  # see `examples/read_messages.pl' for all the details
  my @messages = $gsm->messages();

=head1 DESCRIPTION

C<Device::Gsm> class implements basic GSM functions, network registration
and SMS sending.

This class supports also C<PDU> mode to send C<SMS> messages, and should be
fairly usable. In the past, I have developed and tested it under Linux RedHat
7.1 with a 16550 serial port and Siemens C35i/C45 GSM phones attached with
a Siemens-compatible serial cable. After some years, I have developed and
tested it with Linux Slackware 10.2 and a B<Cambridge Silicon Radio> (CSR) USB
bluetooth dongle, connecting to a Nokia 6600 phone.

Currently I don't use this software anymore. It should probably still work,
but it's unlikely I will ever be able to test it with a real gsm module.

Feel free to contact me if you have any trouble or you are interested in
improving this software.

If you need a way to test your gsm module or phone, and you don't mind spending
an SMS, use the C<examples/send_to_cosimo.pl> script to notify me that
C<Device::Gsm> still works and works well with your device (thanks!).

Over the years, I have collected hundreds of messages from all over the
world :-)

=head1 WHY?

Why would you want to use this?

When I started writing this software, around year 2000, I needed a practical
way to automatically send tens of SMS messages through my phone.

Fast forward to 2016, I barely use SMS messages anymore, and you can find
plenty of TCP/IP based services to send SMS messages, maybe even for free.

The only motivation left would be to learn how AT commands work for GSM
modules. I had lots of fun learning this, but it was so many years ago, and
YMMV, as they say.

=head1 METHODS

The following documents all supported methods with simple examples of usage.

=head2 new()

Inherited from L<Device::Modem>. See L<Device::Modem> documentation
for more details.

The only mandatory argument is the C<port> you want to use to connect
to the GSM device:

    my $gsm = Device::Gsm->new(
        port => '/dev/ttyS0',
    );

On some phones, you may experience problems in the GSM network registration
step. For this reasons, you can pass a special C<assume_registered> option
to have L<Device::Gsm> ignore the registration step and assume the device
is already registered on the GSM network. Example:

    my $gsm = Device::Gsm->new(
        port => '/dev/ttyS0',
        assume_registered => 1,
    );

If you want to send debugging information to your own log file instead of
the default setting, you can:

    my $gsm = Device::Gsm->new(
        port => '/dev/ttyS1',
        log => 'file,/tmp/myfile.log',
        loglevel => 'debug',  # default is 'warning'
    );

=head2 connect()

This is the main call that connects to the appropriate device. After the
connection has been established, you can start issuing commands.
The list of accepted parameters (to be specified as hash keys and values) is
the same of C<Device::SerialPort> (or C<Win32::SerialPort> on Windows platform),
as all parameters are passed to those classes' connect() method.

The default value for C<baudrate> parameter is C<19200>.

Example:

    my $gsm = Device::Gsm->new( port=>'/dev/ttyS0', log=>'syslog' );
    # ...
    if( $gsm->connect(baudrate => 19200) ) {
        print "Connected!";
    } else {
        print "Could not connect, sorry!";
    }
    # ...

=head2 datetime()

Used to get or set your phone/gsm modem date and time.

If called without parameters, it gets the current phone/gsm date and time in
"gsm" format, "YY/MM/DD,HH:MN:SS". For example C<03/12/15,22:48:59> means
December the 15th, at 10:48:59 PM. Example:

    $datestr = $gsm->datetime();

If called with parameters, sets the current phone/gsm date and time to that
of supplied value. Example:

    $newdate = $gsm->datetime( time() );

where C<time()> is the perl's builtin C<time()> function (see
C<perldoc -f time> for details). Another variant allows one to pass a
C<localtime> array to set the correspondent datetime. Example:
 
    $newdate = $gsm->datetime( localtime() );

(Note the list context). Again you can read the details for C<localtime>
function with C<perldoc -f localtime>.

If your device does not support this command, an B<undefined> value will be
returned in either case.


=head2 delete_sms()

This method deletes a message from your SIM card, given the message index
number.  Example:

    $gsm->delete_sms(3);

An optional second parameter specifies the "storage". It allows one to delete
messages from gsm phone memory or sim card memory. Example:

    # Deletes first message from gsm phone memory
    $gsm->delete_sms(1, 'ME');

    # Deletes 3rd message from sim card
    $gsm->delete_sms(3, 'SM');

By default, it uses the currently set storage, via the C<storage()> method.

=head2 forward()

Sets call forwarding. Accepts three arguments: reason, mode and number.
Reason can be the string C<unconditional>, C<busy>, C<no reply> and
C<unreachable>.  Mode can be the string C<disable>, C<enable>, C<query>,
C<register>, C<erase>.  

Example:

    # Set unconditional call forwarding to +47 123456789
    $gsm->forward('unconditional','register','+47123456789');

    # Erase unconditional call forwarding
    $gsm->forward('unconditional','erase');


=head2 hangup()

Hangs up the phone, terminating the active calls, if any.
This method has been never tested on real "live" conditions, but it needs to be
specialized for GSM phones, because it relies on C<+HUP> GSM command.
Example:

    $gsm->hangup();


=head2 imei()

Returns the device own IMEI number
(B<International Mobile Station Equipment Identity>).

This identifier is numeric and is supposed to be unique among all GSM mobile
devices and phones. Example:

    my $imei = $gsm->imei();


=head2 manufacturer()

Returns the device manufacturer, usually only the first word (example: C<Nokia>,
C<Siemens>, C<Falcom>, ...). Example:

    my $man_name = $gsm->manufacturer();
    if( $man_name eq 'Nokia' ) {
        print "We have a nokia phone...";
    } else {
        print "We have a $man_name phone...";
    }


=head2 messages()

This method is a somewhat unstable and subject to change, but for now it seems
to work. It is meant to extract all text SMS messages stored on your SIM card
or gsm phone.  In list context, it returns a list of messages (or undefined
value if no message or errors), every message being a C<Device::Gsm::Sms>
object.

The only parameter specifies the C<storage> where you want to read the
messages, and can assume some of the following values (but check your
phone/modem manual for special manufacturer values):

=over 4

=item C<ME>

Means gsm phone B<ME>mory

=item C<MT>

Means gsm phone B<ME>mory on Nokia phones?

=item C<SM>

Means B<S>im card B<M>emory (default value)

=back

Example:

    my $gsm = Device::Gsm->new();
    $gsm->connect(port=>'/dev/ttyS0') or die "Can't connect!";

    for( $gsm->messages('SM') )
    {
        print $_->sender(), ': ', $_->content(), "\n";
    }

=head2 mode()

Sets the device GSM command mode. Accepts one parameter to set the new mode
that can be the string C<text> or C<pdu>. Example:

    # Set text mode
    $gsm->mode('text');
    
    # Set pdu mode
    $gsm->mode('pdu');


=head2 model()

Returns phone/device model name or number. Example:

    my $model = $gsm->model();

For example, for Siemens C45, C<$model> holds C<C45>; for Nokia 6600, C<$model>
holds C<6600>.


=head2 network()

Returns the current registered or preferred GSM network operator. Example:

    my $net_name = $gsm->network();
    # Returns 'Wind Telecom Spa'

    my($net_name, $net_code) = $gsm->network();
    # Returns ('Wind Telecom Spa', '222 88')

This obviously varies depending on country and network operator. For me now,
it holds "Wind Telecomunicazioni SpA". It is not guaranteed that the mobile
phone returns the decoded network name. It can also return a gsm network code,
like C<222 88>. In this case, an attempt to decode the network name is made.

Be sure to call the C<network()> method when already registered to gsm
network. See C<register()> method.


=head2 signal_quality()

Returns the measure of signal quality expressed in dBm units, where near to
zero is better.  An example value is -91 dBm, and reported value is C<-91>.
Values should range from -113 to -51 dBm, where -113 is the minimum signal
quality and -51 is the theoretical maximum quality.

    my $level = $gsm->signal_quality();

If signal quality can't be read or your device does not support this command,
an B<undefined> value will be returned.

=head2 software_version()

Returns the device firmware version, as stored by the manufacturer. Example:

    my $rev = $gsm->software_revision();

For example, for my Siemens C45, C<$rev> holds C<06>.

=head2 storage()

Allows to get/set the current sms storage, that is where the sms messages are
saved, either the sim card or gsm phone memory. Phones/modems that do not
support this feature (implemented by C<+CPMS> AT command won't be affected by
this method.

    my @msg;
    my $storage = $gsm->storage();
    print "Current storage is $storage\n";

    # Read all messages on sim card
    $gsm->storage('SM');
    @msg = $gsm->messages();

    # Read messages from gsm phone memory
    $gsm->storage('ME');
    push @msg, $gsm->messages();

=head2 test_command()

This method queries the device to know if a specific AT GSM command is
supported.  This is used only with GSM commands (those with C<AT+> prefix).
For example, if I want to know if my device supports the C<AT+GXXX> command:

    my $gsm = Device::Gsm->new( port => '/dev/myport' );

    ...

    if( $gsm->test_command('GXXX') ) {
        # Ok, command is supported
    } else {
        # Nope, no GXXX command
    }

Note that if you omit the starting C<+> character, it is automatically added.
You can also test commands like C<^SNBR> or the like, without C<+> char being
added.

This method caches the results of the test to use in future tests (at least
until the next C<connect()> or C<disconnect()> is executed).

=for html
<I>Must be explained better, uh?</I>

=for comment
// must be explainer better, uh? //

=head2 register()

"Registering" on the GSM network is what happens when you turn on your mobile
phone or GSM equipment and the device tries to reach the GSM operator network.
If your device requires a B<PIN> number, it is used here (but remember to
supply the C<pin> parameter in new() object constructor for this to work.

Registration can take some seconds, don't worry for the wait.
After that, you are ready to send your SMS messages or do some voice calls.
Normally you don't need to call register() explicitly because it is done
automatically for you when/if needed.

If return value is true, registration was successful, otherwise there is
something wrong; probably you supplied the wrong PIN code or network
unreachable.

=head2 send_sms()

Obviously, this sends out SMS text messages. I should warn you that
B<you cannot send> (for now) MMS, ringtone, smart, ota messages of any kind
with this method.

Send out an SMS message quickly:

    my $sent = $gsm->send_sms(
        content   => 'Hello, world!',   # SMS text
        recipient => '+99000123456',    # recipient phone number
    );

    if( $sent ) {
        print "OK!";
    } else {
        print "Troubles...";
    }

The allowed parameters to send_sms() are:

=over

=item C<class>

Class parameter can assume two values: C<normal> and C<flash>. Flash (or class
zero) messages are particular because they are immediately displayed (without
user confirm) and never stored on phone memory, while C<normal> is the default.

=item C<content>

This is the text you want to send, consisting of max 160 chars if you use B<PDU> mode
and 140 (?) if in B<text> mode (more on this later).

=item C<mode>

Can assume two values (case insensitive): C<pdu> and C<text>.
C<PDU> means B<Protocol Data Unit> and it is a sort of B<binary> encoding of
commands, to save time/space, while C<text> is the normal GSM commands text
mode.

Recent mobile phones and GSM equipment surely have support for C<PDU> mode.
Older OEM modules (like Falcom Swing, for example) don't have PDU mode, but
only text mode. It is just a matter of trying.

=item C<recipient>

Phone number of message recipient

=item C<status_report>

If present with a true value, it enables sending of SMS messages (only for PDU
mode, text mode SMS won't be influenced by this parameter) with the status
report, also known as delivery report, that is a short message that reports the
status of your sent message.
Usually this is only available if your mobile company supports this feature,
and probably you will be charged a small amount for this service.

More information on this would be welcome.

=back

=head2 service_center()

If called without parameters, returns the actual SMS Service Center phone
number. This is the number your phone automatically calls when receiving and
sending SMS text messages, and your network operator should tell you what this
number is.

Example:

    my $gsm = Device::Gsm->new( port => 'COM1' );
    $gsm->connect() or die "Can't connect";
    $srv_cnt = $gsm->service_center();
    print "My service center number is: $srv_cnt\n";

If you want to set or change this number (if used improperly this can disable
sending of SMS messages, so be warned!), you can try something like:

    my $ok = $gsm->service_center('+99001234567');
    print "Service center changed!\n" if $ok;

=head1 REQUIRES

=over 4

=item *

Device::Modem, which in turn requires

=item *

Device::SerialPort (or Win32::SerialPort on Windows machines)

=back

=head1 EXPORT

None

=head1 TROUBLESHOOTING

If you experience problems, please double check:

=over 4

=item Device permissions

Maybe you don't have necessary permissions to access your serial,
irda or bluetooth port device. Try executing your script as root, or
try, if you don't mind, C<chmod a+rw /dev/ttyS1> (or whatever device
you use instead of C</dev/ttyS1>).

=item Connection speed

Try switching C<baudrate> parameter from 19200 (the default value)
to 9600 or viceversa. This one is the responsible of 80% of the problems,
because there is no baudrate auto-detection.

=item Device autoscan

If all else fails, please use the B<autoscan> utility in the C<bin/> folder
of the C<Device::Gsm> distribution. Try running this autoscan utility and
examine the log file produced in the current directory.

If you lose any hope, send me this log file so I can eventually
have any clue about the problem / failure.

Also this is a profiling tool, to know which commands are supported
by your device, so please send me profiles of your devices, so
I can add better support for all devices in the future!

=back

=head1 TO-DO

=over 4

=item Spooler

Build a simple spooler program that sends all SMS stored in a special
queue (that could be a simple filesystem folder).

=item Validity Period

Support C<validity> period option on SMS sending. Tells how much time the SMS
Service Center must hold the SMS for delivery when not received.

=back


=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 SEE ALSO

L<Device::Modem>, L<Device::SerialPort>, L<Win32::SerialPort>, perl(1)

=cut


