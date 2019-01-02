package Magrathea::API;

use strict;
use warnings;
use 5.10.0;

use version 0.77; our $VERSION = qv('v1.6.0');

use Net::Telnet;
use Phone::Number;
use Email::Address;
use Magrathea::API::Status;
use Magrathea::API::Emergency;
use Attribute::Boolean;

use Carp;
use Data::Dumper;

our @CARP_NOT = qw{ Net::Telnet };

=encoding utf8

=head2 NAME

Magrathea::API - Easier access to the Magrathea NTS API

=head2 VERSION

Version 1.6.0

=head2 SYNOPSIS

    use Magrathea::API;
    my $mt = new Magrathea::API;
    my $number = $mt->allocate('01792');
    $mt->deactivate($number);
    my @list = $mt->list('01792');
    my @numbers = $mt->block_allocate('01792', 10);
    $mt->fax2email($numbers[2], 'user@host.com');
    $mt->divert($number[3], '+5716027171');
    $emerg = $mt->emergency_info;

=head2 DESCRIPTION

This module implements most of the
L<Magrathea NTS API|https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Numbering-API-Instructions.pdf>
in a simple format.

=head2 EXPORT

Nothing Exported.

=cut

#################################################################
##
##  Local Prototyped Functions
##
#################################################################

sub catch(;$)
{
    local $_ = $@;
    return undef unless $_;
    chomp;
    my $re = shift;
    return true if ref $re eq 'Regexp' and $_ =~ $re;
    croak $_;
}

#################################################################
##
##  Private Instance Functions
##
#################################################################

sub sendline
{
    my $self = shift;
    my $message = shift // '';
    say ">> $message" if $self->{params}{debug} && $message;
    $self->{telnet}->print($message) if $message;
    my $response = $self->{telnet}->getline;
    croak 'Error in getline' unless defined $response;
    chomp $response;
    my ($val, $msg) = $response =~ /^(\d)\s+(.*)/;
    croak qq(Unknown response: "$response") unless defined $val;
    say "<<$val $msg" if $self->{params}{debug};
    croak "$msg" unless $val == 0;
    return $val, $msg;
}

#################################################################
##
##  Class Functions
##
#################################################################

=head2 MAIN API METHODS

=head2 Constructor

=head3 new

This will create a new Magrathea object and open at telnet
session to the server.  If authorisation fails, it will croak.

    my $mt = new Magrathea::API(
	username    => 'myuser',
	password    => 'mypass',
    );

=head4 Parameters:

=over

=item username

=item password

The username and password allocated by Magrathea.

=item host

Defaults to I<api.magrathea-telecom.co.uk> but could be overridden.

=item port

Defaults to I<777>.

=item timeout

In seconds. Defaults to I<10>.

=item debug

If set to a true value, this will output the conversation between the API
and Magrathea's server.  Be careful as this will also echo the username
and password.

=back

=cut

sub new
{
    my $class = shift;
    my %defaults = (
	host	=> 'api.magrathea-telecom.co.uk',
	port	=> 777,
	timeout	=> 10,
        debug   => false,
    );
    my %params = (%defaults, @_);
    croak "Username & Password Required"
	    unless $params{username} && $params{password};
    my $telnet = new Net::Telnet(
	Host	=> $params{host},
	Port	=> $params{port},
	Timeout => $params{timeout},
	Errmode	=> sub {
	    croak shift;
	},
    );
    my $self = {
	params	=> \%params,
	telnet	=> $telnet,
    };
    bless $self, $class;
    $self->sendline;
    eval {
	$self->auth(@params{qw(username password)});
    };
    catch;
    return $self;
}

#################################################################
##
##  Instance Functions
##
#################################################################

=head2 Allocation Methods 

In all cases where C<$number> is passed, this may be a string
containing a number in National format (I<020 1234 5678>) or
in International format (I<+44 20 1234 5678>).  Spaces are ignored.
Also, L<Phone::Number> objects may be passed.

When a number is returned, it will always be in the for of a
L<Phone::Number> object.

=head3 allocate

Passed a prefix, this will allocate and activate a number.  You do not need
to add the C<_> characters.  If a number can be found, this routine
will return a L<Phone::Number> object.  If no match is found, this
routine will return C<undef>. It will croak on any other error from
Magrathea.

=cut

sub allocate
{
    my $self = shift;
    my $number = shift;
    $number = substr $number . '_' x 11, 0, 11;
    for (my $tries = 0; $tries < 5; $tries++)
    {
	eval {
	    my $result = $self->allo($number);
	    ($number = $result) =~ s/\s.*$//;
	};
	return undef if catch qr/^No number found for allocation/;
	eval {
	    $self->acti($number);
	};
	unless (catch qr/^Number not activated/)    # $@ is ''
	{
	    return new Phone::Number($number);
	}
    }
    return undef;   # Failed after 5 attempts.
}

=head3 activate

Passed a number as a string or a L<Phone::Number>, this will
activate that number.

=cut

sub activate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->acti($number->uk ? $number->packed : $number->number);
}

=head3 deactivate

Passed a number as a string or a L<Phone::Number>, this deactivates
the number.

=cut

sub deactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->deac($number->uk ? $number->packed  : $number->number);
}

=head3 reactivate

Reactivates a number that has previously been deactivated.

=cut

sub reactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->reac($number->uk ? $number->packed  : $number->number);
}

=head3 list

This should be passed a prefix and possibly a quantity (defaulting
to 10.  It will return a sorted random list of available numbers matching
the prefix.  These are returned as an array (or an arrayref) of
L<Phone::Number>.  None  of the numbers is allocated by this method.

If none are available, the method will return an empty array.

=cut

sub list
{
    my $self = shift;
    my $prefix = shift;
    my $qty = shift // 10;
    local $_;
    my @results;
    eval {
        push @results, new Phone::Number($self->alist($prefix, $qty));
    };
    unless (catch qr/^No range found for allocation/) {
        while (true) {
            my $response = $self->{telnet}->getline;
            chomp $response;
            my ($val, $msg) = $response =~ /^(\d)\s+(.*)/;
            say "<<$val $msg" if $self->{params}{debug};
            last if $val != 0;
            push @results, new Phone::Number($msg);
        }
        @results = sort { $a->plain cmp $b->plain } @results;
    }
    return wantarray ? @results : \@results;

}

=head2 Block Methods

=head3 block_allocate

This should be passed a prefix (without any C<_> characters) and an
optional block size (defaulting to 10).  It will attempt to allocate
and activate a block of numbers.

If a block can be found, this routine
should return an array or arrayref of L<Phone::Number> objects. Under odd
circumstances, it is possible that fewer than the requested quantity
of numbers will be returned;

If no range is found is found, this routine will return C<undef> in scalar
context or an empty array in list context. It will croak
on any other error from Magrathea.

=cut

sub block_allocate
{
    my $self = shift;
    my $range = shift;
    my $qty = shift // 10;
    local $_;
    croak "Block size must be a number" unless $qty =~ /^\d+$/;
    my $alloc = eval {
	$self->blkacti($range, $qty);
    };
    if (catch qr/^No range found for allocation/) {
        return wantarray ? () : undef;
    }
    my ($first, $last) = split ' ', $alloc;
    my @numbers;
    while ($first le $last) {
        push @numbers, new Phone::Number($first++);
    }
    return wantarray ? @numbers : \@numbers;
}

=head3 block_info

This should be passed a number (string or L<Phone::Number>)
to check whether that number is part of a block.

If it is, the size of the block will be returned in scalar context;
In list context, the response will be an array of all the numbers
in that block.

If it is not a block, this will return C<undef> or an empty
array.

=cut

sub block_info
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $block = eval {
	$self->blkinfo($number->uk ? $number->packed  : $number->number);
    };
    if (catch qr/^Account not ACTIve/) {
        return wantarray ? () : undef;
    }
    my ($first, $qty) = split ' ', $block;
    return 0 + $qty unless wantarray;
    my @numbers;
    for (; $qty > 0; $qty--) {
        push @numbers, new Phone::Number($first++);
    }
    return @numbers;
}

=head3 block_deactivate

This should be passed the first number in a block.  It will
deactivate and return the block of numbers.

=cut

sub block_deactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->blkdeac($number->uk ? $number->packed  : $number->number);
}

=head3 block_reactivate

This should be passed the first number in a block.  It will
reactivate the block and return the size of the block in scalar
context or an array of the numbers in list context.

If the block is not available, this method will croak.

In testing, this method has never worked correctly.

=cut

sub block_reactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->blkreac($number->uk ? $number->packed  : $number->number);
}

=head2 Service Methods

=head3 fax2email

Sets a number as a fax to email.

    $mt->fax2email($number, $email_address);

=cut

sub fax2email
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $email = shift;
    my @email = parse Email::Address($email);
    croak "One email address required" if @email != 1;
    my $num = $number->uk ? $number->packed  : $number->number;
    $self->set($num, 1, "F:$email[0]");
}

=head3 voice2email

Sets a number as a voice to email.

    $mt->voice2email($number, $email_address);

=cut

sub voice2email
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $email = shift;
    my @email = parse Email::Address($email);
    croak "One email address required" if @email != 1;
    my $num = $number->uk ? $number->packed  : $number->number;
    $self->set($num, 1, "V:$email[0]");
}

=head3 sip

    $mt->sip($number, $host, [$username, [$inband]]);

Passed a number and a host, will set an inbound sip link
to the international number (minus leading +) @ the host.
If username is defined, it will be used instead of the number.
If inband is true, it will force inband DTMF.  The default is
RFC2833 DTMF.

=cut

sub sip
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my ($host, $username, $inband) = @_;
    croak "Domain required" unless $host;
    $username = $number->plain unless $username;
    my $sip = $inband ? "s" : "S";
    my $num = $number->uk ? $number->packed  : $number->number;
    $self->set($num, 1, "$sip:$username\@$host");
}

=head3 divert

    $mt->divert($number, $to_number);

=cut

sub divert
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $to = new Phone::Number(shift);
    my $num = $number->uk ? $number->packed  : $number->number;
    $self->set($num, 1, $to->plain);
}


=head3 status

Returns the status for a given number.  

    my $status = $mt->status($number);
    my @status = $mt->status($number);

In scalar context, returns the first (and usually only) status as
a L<Magrathea::API::Status> object.  In list context, returns up to
three statuses representing the three possible setups created with
ORDE.

If the number is not allocated to us and activated, this routine
returns C<undef> in scalar context and an empty list in list context.

The L<Magrathea::API::Status> object has the following calls:

=over

=item C<< $status->number >>

A L<Phone::Number> object representing the number to which this
status refers.

=item C<< $status->active >>

Boolean.

=item C<< $status->expiry >>

The date this number expires in the form C<YYYY-MM-DD>.

=item C<< $status->type >>

One of sip, fax2email, voice2email, divert or unallocated.

=item C<< $status->target >>

The target email or phone number for this number;

=item C<< $status->entry >>

The entry number (1, 2 or 3) for this status;

=back

In addition, it overloads '""' to provide as tring comprising
the type and the target, separated by a space.

=cut

sub status
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $status = eval {
	$self->stat($number->uk ? $number->packed  : $number->number);
    };
    return wantarray ? () : undef if $@;
    my @statuses = split /\|/, $status;
    my @retval;
    for my $i (0 .. 2)
    {
	my $stat = new Magrathea::API::Status($statuses[$i]);
	return $stat unless wantarray;
	next unless $stat;
	$stat->entry($i + 1);
	push @retval, $stat;
    }
    return @retval;
}

=head2 Emergency Methods

=head3 emergency_info

Passed a phone number, this method returns a
L<Magrathea::API::Emergency> object with the current 999
information.

Optionally it can be passed a second parameter which, if it
is a truthy value, will set the C<ported> flag.

=cut

sub emergency_info
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $ported = shift;
    return new Magrathea::API::Emergency($self, $number, $ported);
}

=head2 Low Level Methods

All the Magrathea low level calls are available.  These are
simply passed an array of strings which are joined to create
the command string.  They return the raw response
on success (minus the leading 0) and die on failure.  C<$@>
will contain the error.

See the L<Magrathea documentation|http://www.magrathea-telecom.co.uk/assets/Client-Downloads/Numbering-API-Instructions.pdf>.

The functions are:

=over

=item auth

This is called by L</new> and should not be called directly.

    $mt->auth('username', 'password');

=item quit

This is called automatically upon the Magrathea::API object
going out of scope and should not be called directly.

=item allo

    $mt->allo('0201235___');

=item acti

    $mt->acti('02012345678');

=item deac

    $mt->deac('02012345678');

=item reac

    $mt->reac('02012345678');

=item stat

    $mt->stat('02012345678');

=item set

    $mt->set('02012345678 1 441189999999');
    $mt->set('02012345678 1 F:fax@mydomain.com');
    $mt->set('02012345678 1 V:voicemail@mydomain.com');
    $mt->set('02012345678 1 S:username@sip.com');
    $mt->set('02012345678 1 I:username:password@iaxhost.com');

=item spin

    $mt->set('02012345678 [pin]');

=item feat

    $mt->feat('02012345678 D');
    $mt->feat('02012345678 J');

=item orde

    $mt->orde('02012345678 1 0000');

=item info

    $mt->info('02012345678 GEN Magrathea, 14 Shute End, RG40 1BJ');

=back

It will not usually be necessary to call these functions directly.

=cut

sub AUTOLOAD
{
    my $self = shift;
    my $commands = qr{^(?:
    AUTH|QUIT|ALLO|ACTI|DEAC|REAC|STAT|SET|SPIN|FEAT|ORDE|INFO|ALIST|
    BLKACTI|BLKINFO|BLKDEAC|BLKREAC
    )$}x;
    (my $name = our $AUTOLOAD) =~ s/.*://;
    my $cmd = uc $name;
    croak "Unknown Command: $name" unless $cmd =~ $commands;
    return $self->sendline("$cmd @_");
}

sub DESTROY
{
    my $self = shift;
    eval {
	$self->quit;
    };
}

1;

__END__

=head2 AUTHOR

Cliff Stanford, E<lt>cliff@may.beE<gt>

=head2 ISSUES

Please open any issues with this code on the
L<Github Issues Page|https://github.com/CliffS/magrathea-api/issues>.

=head2 COPYRIGHT AND LICENCE

Copyright (C) 2012 - 2018 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

