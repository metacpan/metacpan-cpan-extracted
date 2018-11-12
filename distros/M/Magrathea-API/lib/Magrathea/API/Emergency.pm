package Magrathea::API::Emergency;

use strict;
use warnings;
use 5.10.0;
use utf8;

use Scalar::Util qw{ dualvar };
use Attribute::Boolean;
use Carp;
use Data::Dumper;

use Magrathea::API::Abbreviation qw{abbreviate};

use constant POSTCODE_RE => qr/^([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9]?[A-Za-z])))) [0-9][A-Za-z]{2})$/;

=encoding utf8

=head2 NAME

Magrathea::API::Emergency - Access to the Magrathea 999 Interface

=head2 EXAMPLE

    use Magrathea::API;
    my $mt = new Magrathea::API($username, $password);
    my $emerg = $mt->emergency_info($phone_number);
    # Get the status, print it and check it
    my $status = $emerg->status;
    say "Status is: $status" if $status != 0;
    # Print the thoroughfare, update it and print it again
    say "Thoroughfare is currently: ", $emerg->thoroughfare;
    $emerg->thoroughfare("He is a justice of the peace and in accommodation.");
    say "Thoroughfare is now ", $emerg->thoroughfare;
    # prints: He is a J.P. & in Accom.
    # Update the changes
    $emerge->update

=cut

=head2 DESCRIPTION

This module represents the
L<Magrathea 999 API Appendix|https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Magrathea-NTSAPI-999-Appendix.pdf>.

It should not be constructed by user code; it is only avalible through
the main L<Magrathea::API> code as follows:

    my $mt = new Magrathea::API($username, $password);
    my $emerg = $mt->emergency_info($phone_number, $is_ported);

=cut

#################################################################
##
##  Local Prototyped Functions
##
#################################################################


#################################################################
##
##  Private Instance Functions
##
#################################################################

sub sendline
{
    my $self = shift;
    my $message = shift // '';
    say ">> $message" if $self->{debug} && $message;
    $self->{telnet}->print($message) if $message;
    my $response = $self->{telnet}->getline;
    chomp $response;
    my ($val, $msg) = $response =~ /^(\d)\s+(.*)/;
    croak qq(Unknown response: "$response") unless defined $val;
    say "<<$val $msg" if $self->{debug};
    return dualvar $val, $msg;
}

#################################################################
##
##  Class Functions
##
#################################################################

=head2 METHODS

=cut

sub new
{
    my $class = shift;
    my $api = shift;
    my $number = shift;
    my $ported : Boolean = shift;
    local $_;
    croak "This package must not be called directly" unless ref $api eq 'Magrathea::API';
    my $self = {
        telnet  => $api->{telnet},
        debug   => $api->{params}{debug},
        number  => $number,
        ported  => $ported,
    };
    bless $self, $class;
    my %info;
    my $response = $self->DATA;
    while ($response == 0) {
        chomp $response;
        my ($key, $value) = split / /, $response, 2;
        $info{lc $key} = $value;
        $response = $self->sendline;
    }
    $self->{info} = \%info;
    my $exists : Boolean = keys(%info) > 0;
    $self->{exists} = $exists;
    $self;
}

=head2 create

This is used the first time a number is put onto the database and
then only if the owner changes.  It needs to be followed by an
L</update> after entering all the data.

=cut

sub create
{
    my $self = shift;
    my $result = $self->CREATE;
    croak "$result" unless $result == 0;
    $self->{exists} = true;
}

=head3 number

This returns the number currently being worked on as a L<Phone::Number>.

=cut

sub number
{
    my $self = shift;
    return $self->{number};
}

=head3 exists

This is a boolean which can be tested to find out if the number
already exists on the Magrathea database.  It is set during
the call to L<Magrathea::API/emergency_info> and updated after
a successful call to L</create>.

=cut

sub exists
{
    my $self = shift;
    return $self->{exists};
}

=head3 info

This returns all the fields in a hash or as a pointer to a hash
depending on list or scalar context.  The fields are as documented for
methods below.

=cut

sub info
{
    my $self = shift;
    my %info = %{$self->{info}};  # Copy it so it can't be changed
    return wantarray ? %info : \%info;
}

=head3 status

This returns a single value for status.  The valuse returned can be
used as a string and returns the message or as a number which returns
the status code.  The possible statuses are curently as below but they
are returned from Magrathea so the
L<999 Appendix|https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Magrathea-NTSAPI-999-Appendix.pdf>
should be treated as authoritive.

=over

=item 0 Accepted

=item 1 Info received

=item 2 Info awaiting further validation

=item 3 Info submitted

=item 6 Submitted – Awaiting manual processing

=item 8 Rejected

=item 9 No record found

=back

=cut

sub status
{
    my $self = shift;
    my $status = eval {
        $self->STATUS;
    };
    return $status;
}


=head3 title

=head3 forename

=head3 name

=head3 honours

=head3 bussuffix

=head3 premises

=head3 thoroughfare

=head3 locality

=head3 postcode

The above methods will get or set a field in the 999 record.

Abbreviations are substituted and they are then checked for
maximum length.  These routines will croak if an invalid length
(or invalid postcode) is passed

To get the data, simply call the method, to change the data, pass
it as a parameter.

Nothing is sent to Magrathea until L</update> is called.

=cut

sub postcode
{
    my $self = shift;
    my $postcode = shift;
    if ($postcode) {
        if ($postcode ne "") {
            croak "Invalid postcode" unless $postcode =~ POSTCODE_RE;
        }
        $self->{info}{postcode} = $postcode;
        $self->POSTCODE($postcode);
    }
    return $self->{info}{postcode};
}

=head3 ported

This is a boolean value showing whether or not the number has been
ported in from another provider.  It will always evaluate to C<false>
though unless set by this method as there is no way to store the
information on the Magrathea database.


        $emerge->ported(true);      # Assuming true is set to 1
        my $ported = $emerg->ported;

=cut

sub ported
{
    my $self = shift;
    my $val = shift;
    my $value : Boolean = $val;
    $self->{ported} = $value if defined $val;
    $value = $self->{ported};
    return $value;
}

=head3 update

This will take the current data and send it to Magrathea.  The possible
valid responses are C<Information Valid> (0 in numeric context) or
C<Parsed OK. Check later for status.> (1 in numeric context).

If Magrathea's validation fails, the update will croak.

=cut

sub update
{
    my $self = shift;
    my $info = $self->info;
    unless ($self->postcode and $self->name) {
        croak "Name and postcode are mandatory";
    }
    my $response = $self->VALIDATE;
    croak "Update failed: $response" if  $response >= 2;
    return $response;
}

sub AUTOLOAD
{
    my $self = shift;
    my $commands = qr{^(?:
    CREATE|VALIDATE|STATUS|DATA|
    TITLE|FORENAME|NAME|HONOURS|BUSSUFFIX|
    PREMISES|THOROUGHFARE|LOCALITY|POSTCODE
    )$}x;
    my %fields = (
        title => 20,
        forename => 20,
        name => 50,
        honours => 30,
        bussuffix => 50,
        premises => 60,
        thoroughfare => 55, 
        locality => 30
    );
    (my $name = our $AUTOLOAD) =~ s/.*://;
    if ($name =~ /^[A-Z]+$/) {
        croak "Unknown Command: $name" unless $name =~ $commands;
        my $number = $self->number->packed;
        $number =~ s/^0/P/ if $self->ported;
        my @cmd = ('INFO', $number, 999, $name, @_);
        return $self->sendline("@cmd");
    }
    else {
        my $value = shift;
        croak "Unknown method: $name" unless exists $fields{$name};
        if (defined $value) {
            my $abbr = abbreviate $value;
            my $len = length $abbr;
            my $max = $fields{$name};
            croak "$abbr ($len charancters abbreviated)\n" .
            "is longer than the max. length of $max" .
            "for field $name" if $len > $max;
            $self->{info}{$name} = $abbr;
            my $cmd = uc $name;
            $self->$cmd($abbr);
        }
        return $self->{info}{$name};
    }
}

sub DESTROY {
    # Avoid AUTOLOAD
}

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

1;
