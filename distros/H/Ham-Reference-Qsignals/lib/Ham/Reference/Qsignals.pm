package Ham::Reference::Qsignals;

# --------------------------------------------------------------------------
# Ham::Reference::Qsignals - A quick reference for Q Signals
# 
# Copyright (c) 2008 Brad McConahay N8QQ.
# Cincinnat, Ohio USA
#
# This module is free software; you can redistribute it and/or
# modify it under the terms of the Artistic License 2.0. For
# details, see the full text of the license in the file LICENSE.
# 
# This program is distributed in the hope that it will be
# useful, but it is provided "as is" and without any express
# or implied warranties. For details, see the full text of
# the license in the file LICENSE.
# --------------------------------------------------------------------------

use warnings;
use strict;

use vars qw($VERSION);
 
our $VERSION = '0.02';

my $qsignals = {};
$qsignals->{arrl} =
{
	'qna' => 'Answer in prearranged order.',
	'qnc' => 'All net stations copy.',
	'qnd' => 'Net is directed.',
	'qne' => 'Entire net stand by.',
	'qnf' => 'Net is free.',
	'qng' => 'Take over as net control station.',
	'qni' => 'Net stations report in.',
	'qnm' => 'You are QRMing the net.',
	'qnn' => 'Net control station is [call sign].',
	'qno' => 'Station is leaving the net.',
	'qnp' => 'Unable to copy you.',
	'qns' => 'Following stations are in the net.',
	'qnt' => 'I request permission to leave the net.',
	'qnu' => 'The net has traffic for you.',
	'qnx' => 'You are excused from the net',
	'qny' => 'Shift to another frequency.',
	'qnz' => 'Zero beat your signal with mine.',
	'qrg' => 'Will you tell me my exact frequency?',
	'qrh' => 'Does my frequency vary?',
	'qrj' => 'Are you receiving me badly?',
	'qrk' => 'What is the intelligibility of my signals?',
	'qrl' => 'Are you busy?',
	'qrm' => 'Is my transmission being interfered with?',
	'qrn' => 'Are you troubled by static?',
	'qro' => 'Shall I increase power?',
	'qrp' => 'Shall I decrease power?',
	'qrq' => 'Shall I send faster?',
	'qrs' => 'Shall I send more slowly?',
	'qrt' => 'Shall I stop sending?',
	'qru' => 'Have you anything for me?',
	'qrv' => 'Are you ready?',
	'qrx' => 'When will you call me again?',
	'qry' => 'What is my turn?',
	'qrz' => 'Who is calling me?',
	'qsa' => 'What is the strength of my signals?',
	'qsb' => 'Are my signals fading?',
	'qsd' => 'Is my keying defective?',
	'qsg' => 'Shall I send messages?',
	'qsk' => 'Can you hear between your signals?',
	'qsl' => 'Can you acknowledge receipt?',
	'qsm' => 'Shall I repeat the last message?',
	'qsn' => 'Did you hear me?',
	'qso' => 'Can you communicate with me?',
	'qsp' => 'Will you relay?',
	'qst' => 'General call preceding a message.',
	'qsu' => 'Shall I send or reply on this frequency?',
	'qsw' => 'Will you send on this frequency?',
	'qsx' => 'Will you listen?',
	'qsy' => 'Shall I change frequency?',
	'qsz' => 'Shall I send each word more than once?',
	'qta' => 'Shall I cancel message?',
	'qtb' => 'Do you agree with my counting of words?',
	'qtc' => 'How many messages have you to send?',
	'qth' => 'What is your location?',
	'qtr' => 'What is the correct time?'
};

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;
	$self->{signal_set} = lc($args{signal_set}) || 'arrl';
    return $self;
}

sub get
{
	my $self = shift;
	my $signal = shift;
	return $qsignals->{$self->{signal_set}}->{lc($signal)} || undef;
}

sub get_hashref
{
	my $self = shift;
	return $qsignals->{$self->{signal_set}};
}

1;

=head1 NAME

Ham::Reference::Qsignals - A quick reference for Q Signals.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 my $q = new Ham::Reference::Qsignals;

 # use the get() function to get a single meaning for a particular Q signal

 print $q->get('qrp');
 print "\n";

 # use a hash reference to get all Q signals at once
 # the following will display all signals and meanings

 my $hashref = $q->get_hashref();
 foreach (sort keys %$hashref)
 {
 	print "$_ = $hashref->{$_}\n";
 }

=head1 DESCRIPTION

The C<Ham::Reference::Qsignals> module is a quick reference to the ARRL suggested Q signal set.
Other Q signal sets may be added in the future, but the primary mission of this module is
for Amateur Radio applications.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $q = Ham::Reference::Qsignals->new();
 Function : creates a new Ham::Reference::Qsignals object
 Returns  : A Ham::Reference::Qsignals object
 Args     : an anonymous hash:
            key         required?   value
            -------     ---------   -----
            signal_set  no          select the set of Q signals
                                    the only set for now, and the default set
                                    is arrl


=head1 METHODS

=head2 get()

 Usage    : my $description = $q->get( 'qrp' );
 Function : gets a single meaning for a given Q signal
 Returns  : a string
 Args     : you can get a full list of Q signals by accessing the keys of
            of the hashref returned by get_hashref() function
            (see the synopsis for example)

=head2 get_hashref()

 Usage    : my $hashref = $q->get_hashref();
 Function : get all q signals
 Returns  : a hash reference
 Args     : n/a

=head1 ACKNOWLEDGEMENTS

The arrl Q signal set is from http://www.arrl.org/files/bbs/general/q-sigs,
courtesy of the American Radio Relay League.

=head1 AUTHOR

Brad McConahay N8QQ, C<< <brad at n8qq.com> >>

=head1 COPYRIGHT & LICENSE

C<Ham::Reference::Qsignals> is Copyright (C) 2008-2010 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.


