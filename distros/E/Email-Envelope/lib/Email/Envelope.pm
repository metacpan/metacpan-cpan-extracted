package Email::Envelope;

use 5.00503;
use strict;
use warnings;
use vars qw($VERSION @ISA);

$VERSION = '0.01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use Email::Simple;
use Email::Address;
use Regexp::Common qw(net number);

=head1 NAME

Email::Envelope - Email with SMTP time information

=head1 SYNOPSIS

 use Email::Envelope;
 my $mailenv = Email::Envelope->new();
 $mailenv->remote_host('mx.example.com');
 ...

OR

 my $mailenv = Email::Envelope->new({
    remote_port => 29,
    secure => 1,
    ...
 });

=head1 DESCRIPTION

This module has been designed as a simple container with a few handy
methods. Currently Email::Simple contains RFC2822 data, however when
dealing with filtering Email, sometimes the information available just
isn't enough. Many people may wish to block certain subnets or run
SBL/XBL checks. This module has been provided for this very reason.

=head1 METHODS

=head2 new

Currently the constructor supports adding data via hash references for the following data:

 remote_host
 remote_port
 local_host
 local_port
 secure
 rcpt_to
 mail_from
 helo
 data
 mta_msg_id
 received_timestamp

And can be used as so:

 my $mailenv = Email::Envelope->new({
   remote_host => '127.0.0.1',
   local_host => 'mx.example.com',
   ...
 });

=cut

sub new {
    my ($class,$args) = @_;
    my $foo = {
	data         => $args,
	simple       => ($args->{data}      ? Email::Simple->new($args->{data})       : ''),
	to_address   => ($args->{rcpt_to}   ? Email::Address->parse($args->{rcpt_to})   : ''),
	from_address => ($args->{mail_from} ? Email::Address->parse($args->{mail_from}) : '')
    };
    
    return bless $foo, $class;
}

=head2 remote_host

Simple accessor. Will only accept either an IP address or a Fully Qualified Domain Name.
Will die upon wrong value being set.

 $mailenv->remote_host('127.0.0.1');
 print $mailenv->remote_host;

 $mailenv->remote_host('mx.example.com');
 print $mailenv->remote_host;

=cut

sub remote_host {
    my ($self,$val) = @_;
    if(defined $val){
	if($val =~ /^$RE{net}{IPv4}$|^$RE{net}{domain}{-nospace}$/){
	    $self->{data}{remote_host} = $val;
	}else{
	    die "Incorrect IP address or FQDN";
	}
    }
    return $self->{data}{remote_host};
}

=head2 remote_port

Simple accessor. Will only accept a positive integer.
Will die upon wrong value being set.

 $mailenv->remote_port(25);
 print $mailenv->remote_port;

=cut

sub remote_port {
    my ($self,$val) = @_;
    if(defined $val){
	if($val =~ /^$RE{num}{int}$/ && (1 <= $val && $val <= 65535)){
	    $self->{data}{remote_port} = $val;
	}else{
	    die "Incorrect port number";
	}
    }
    return $self->{data}{remote_port};
}

=head2 local_host

Simple accessor. Will only accept either an IP address or a Fully Qualified Domain Name.
Will die upon wrong value being set.

 $mailenv->local_host('127.0.0.1');
 print $mailenv->local_host;

 $mailenv->local_host('mx.example.com');
 print $mailenv->local_host;

=cut

sub local_host {
    my ($self,$val) = @_;
    
    if(defined $val){
	if($val =~ /^$RE{net}{IPv4}$|^$RE{net}{domain}{-nospace}$/){
	    $self->{data}{local_host} = $val;
	}else{
	    die "Incorrect IP address or FQDN";
	}
    }
    return $self->{data}{local_host};
}

=head2 local_port 

Simple accessor. Will only accept a positive integer.
Will die upon wrong value being set.

 $mailenv->local_port(25);
 print $mailenv->local_port;

=cut

sub local_port {
    my ($self,$val) = @_;
    if(defined $val){
	if($val =~ /^$RE{num}{int}$/ && (1 <= $val && $val <= 65535)){
	    $self->{data}{local_port} = $val;
	}else{
	    die "Incorrect port number";
	}
    }
    return $self->{data}{local_port};
}

=head2 secure

Simple accessor. Requires either a 'true' or 'false' value.

 $mailenv->secure(1);
 $mailenv->secure(0);
 print "Secured" if $mailenv->secure;

=cut

sub secure {
    my ($self,$val) = @_;
    if(defined $val){
	$self->{data}{secure} = $val ? 1 : 0;
    }
    return $self->{data}{secure};
}

=head2 mta_msg_id

Simple accessor/mutator. Will take an arbitary string representing the message ID that the MTA has assigned.

 $mailenv->mta_msg_id("Exim-2004/22927437493-189282");
 print "MTA reports this message as " . $mailenv->mta_msg_id;

=cut

sub mta_msg_id {
    my ($self,$val) = @_;
    if($val){
	$self->{data}{mta_msg_id} = $val;
    }
    return $self->{data}{mta_msg_id};
}


=head2 recieved_timestamp

Simple accessor/mutator. Will take a unix epoch to represent the time that the message arrived with the MTA.

 $mailenv->recieved_timestamp(103838934);
 my $dt = Date::Time->new($mailenv->recieved_timestamp);

=cut

sub recieved_timestamp {
    my ($self,$val) = @_;
    if(defined $val){
	if($val =~ /^$RE{num}{int}$/){
	    $self->{data}{recieved_timestamp} = $val;
	}else{
	    die "Incorrect timestamp";
	}
    }
    return $self->{data}{recieved_timestamp};
}

=head2 rcpt_to

Simple Accessor.

 $mailenv->rcpt_to("Example User <user\@example.com>");
 print $mailenv->rcpt_to;

 $mailenv->rcpt_to("Example User <user\@example.com>, Another User <another\@example.com>");
 print $mailenv->rcpt_to;

=cut

sub rcpt_to {
    my ($self,$val) = @_;
    if($val){
	$self->{data}{rcpt_to} = $val;
	$self->{to_address} = [ Email::Address->parse($val) ];
    }
    return $self->{data}{rcpt_to};
}

=head2 mail_from

Simple Accessor.

 $mailenv->mail_from("Example User <user\@example.com>");
 print $mailenv->mail_from;

=cut

sub mail_from {
    my ($self,$val) = @_;
    if($val){
	$self->{data}{mail_from} = $val;
	my ($addr) = Email::Address->parse($val);
	$self->{from_address} = $addr;
	$self->{data}{mail_from} = $addr->format;
    }
    return $self->{data}{mail_from};
}

=head2 helo

Simple Accessor.

 $mailenv->helo("HELO mx.example.com");
 print $mailenv->helo;

=cut

sub helo {
    my ($self,$val) = @_;
    $self->{data}{helo} = $val if $val;
    return $self->{data}{helo};
}

=head2 data

Simple accessor. Uses an L<Email::Simple> object internally.

 $mailenv->data($rfc2822);
 print $mailenv->data;

=cut

sub data {
    my ($self,$val) = @_;
    $self->{simple} = Email::Simple->new($val) if $val;
    return $self->{simple}->as_string;
}

=head2 simple

Simple getter. Will return an L<Email::Simple> object based on the DATA that the current object contains.

 my $simple = $mailenv->simple;

=cut

sub simple {
    my ($self) = @_;
    return $self->{simple};
}

=head2 to_address

Simple getter. Will return an L<Email::Address> object based on the RCPT_TO address that the current object contains.

 my $address   = $mailenv->to_address;
 my @addresses = $mailenv->to_address;

NB: in scalar context to_address() will return the first address in the list.

=cut

sub to_address {
    my ($self) = @_;
    return wantarray ? @{$self->{to_address}} : @{$self->{to_address}}[0];
}

=head2 from_address

Simple getter. Will return an L<Email::Address> object based on the MAIL_FROM address that the current object contains.

 my $address = $mailenv->from_address;

NB: Since RFC 2821 states that there can only be one MAIL_FROM address per smtp session, if you supply more than one MAIL_FROM format to mail_from() then you will only recieve back the first address in the list.

=cut

sub from_address {
    my ($self) = @_;
    return $self->{from_address};
}


1;

=head1 COVERAGE

This module has been written using test-first development. Below are the 
Devel::Cover details.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/Email/Envelope.pm    100.0   90.5  100.0  100.0  100.0  100.0   97.8
 Total                         100.0   90.5  100.0  100.0  100.0  100.0   97.8
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 HISTORY

=over

=item 0.01

Initial release to CPAN.

=item 0.00_02

Fixes to how Email::Address is used. Added mta_msg_id and received_timestamp.

=item 0.00_01

Initial implementation.

=back

=head1 TODO

=over

=item IPv6 support

=back

=head1 SEE ALSO

L<Email::Simple> L<Email::Address>

=head1 AUTHOR

Scott McWhirter E<lt>kungfuftr@cpan.orgE<gt>

=head1 SUPPORT

This module is part of the Perl Email Project - http://pep.kwiki.org/

There is a mailing list at pep@perl.org (subscribe at pep-subscribe@perl.org) 
and an archive available at http://nntp.perl.org/group/pep.php

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Scott McWhirter

This library is released under a BSD licence, please see 
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

