package Mail::TempAddress;

use strict;
my $pod = do { local $/; <DATA> };

use base 'Mail::Action';
use Carp 'croak';

use Mail::Mailer;
use Email::Address;

use Mail::TempAddress::Addresses;

use vars '$VERSION';
$VERSION = '0.62';

sub storage_class
{
    'Mail::TempAddress::Addresses'
}

sub process
{
    my $self    = shift;

    return if $self->request()->message()->header( 'X-MTA-Seen' );

    my $command = $self->find_command();
    return $self->$command() if $command;

    my ($address, $key) = $self->fetch_address();

    my $result = eval
    {
        die    "No address found\n"             unless $address;
        return $self->respond( $address, $key ) if     $key;
        return $self->deliver( $address )       if     $address;
    };

    return $result unless $@;
    $self->reject( $@ );
}

sub command_help
{
    my $self = shift;
    $self->SUPER::command_help( $pod, 'USING ADDRESSES', 'DIRECTIVES' );
}

sub deliver
{
    my ($self, $address) = @_;

    my $expires = $address->expires();
    $self->reject() if $expires and $expires < time();

    my $request = $self->request();
    my $from    = $request->header( 'From' )->address();
    my $key     = $address->add_sender( $from );
    my $desc    = $address->description();
    my $to      = $request->recipient();
    my $user    = $to->user();
    my $host    = $to->host();

    my @all_to  =
        map  { $self->build_address( $_, $address, $user, $host  ) }
        grep { $_->address() ne $to->address() }
        $request->header( 'To' );

    my @all_cc  =
        map  { $self->build_address( $_, $address, $user, $host  ) }
        grep { $_->address() ne $to->address() }
        $request->header( 'Cc' );

    my $headers = $request->copy_headers();

    $headers->{From}                = $from;
    $headers->{To}                  = [ $address->owner(), @all_to ];
    $headers->{Cc}                  = \@all_cc if @all_cc;
    $headers->{'Reply-To'}          = "$user+$key\@$host";
    $headers->{'X-MTA-Description'} = $desc if $desc;

    $self->storage->save( $address, $address->name() );

    $self->reply( $headers, $request->message->body_raw() );
}

sub build_address
{
    my ($self, $addy, $address, $user, $host) = @_;

    my $real_addy = $addy->address();
    my $comment   = '(' . $real_addy . ')';
    my $key       = $address->add_sender( $real_addy );
    my $keyed     = '<' . $user . '+' . $key . '@' . $host . '>';

    return $comment . ' ' . $keyed;
}

sub respond
{
    my ($self, $address, $key) = @_;

    my $request      = $self->request();
    my $to           = $address->get_sender( $key )
        or die "No sender for '$key'\n";

    my $message      = $self->message();

    my $addy         = $request->recipient();
    my $host         = $addy->host();
    my $from         = $address->name() . "\@$host";

    my $headers      = $request->copy_headers();
    $headers->{To}   = $to;
    $headers->{From} = $from;
    delete $headers->{Cc};

    $self->reply( $headers, join("\n", @{ $request->remove_sig() } ));
}

sub fetch_address
{
    my $self          = shift;
    my ($alias, $key) = $self->parse_alias( $self->request()->recipient() );
    my $addresses     = $self->storage();

    return unless $addresses->exists( $alias );

    my $addy          = $addresses->fetch( $alias );

    return wantarray ? ( $addy, $key ) : $addy;
}

sub parse_alias
{
    my ($self, $address)  = @_;
    my ($add)             = Email::Address->parse( $address );
    my $user              = $add->user();
    my $expansion_pattern = $self->expansion_pattern();
    my $key               = ( $user =~ s/$expansion_pattern// ? $1 : undef );
    return wantarray ? ( $user, $key ) : $user;
}

sub expansion_pattern
{
    return qr/\+([^+]+)$/;
}

sub command_new
{
    my $self      = shift;
    my $request   = $self->request();
    my $from      = $request->header( 'From' )->address();
    my $to        = $request->recipient();
    my $domain    = $to->host();

    my $addresses = $self->storage();
    my $address   = $addresses->create( $from );
    my $tempaddy  = $addresses->generate_address();

    $self->process_body( $address );
    $addresses->save( $address, $tempaddy );

    $self->reply({
        To      => $from,
        From    => $to->address(),
        Subject => 'Temporary address created' },
    "A new temporary address has been created for $from: $tempaddy\@$domain" );
}

sub reject
{
    my ($self, $error) = @_;
    $error ||= "Invalid address";
    $!       = 100;
    die "$error\n";
}

1;
__DATA__

=head1 NAME

Mail::TempAddress - module for managing simple, temporary mailing addresses

=head1 SYNOPSIS

    use Mail::TempAddress;
    my $mta = Mail::TempAddress->new( 'addresses' );
    $mta->process();

=head1 DESCRIPTION

Sometimes, you just need a really simple mailing address to last for a few
days.  You want it to be easy to create and easy to use, and you want it to be
sufficiently anonymous that your real address isn't ever exposed.

Mail::TempAddress, Mail::TempAddress::Addresses, and Mail::TempAddress::Address
make it easy to create a temporary mailing address system.

=head1 USING ADDRESSES

=head2 INSTALLING

Please see the README file in this distribution for installation and
configuration instructions.  You'll need to configure your mail server and your
DNS, but you only need to do it once.  The rest of these instructions assume
you've installed Mail::TempAddress to handle all mail coming to addresses in
the subdomain C<tempmail.example.com>.

=head2 CREATING AN ADDRESS

To create a new temporary address, send an e-mail to the address
C<new@tempmail.example.com>.  In the subject of the message, include the phrase
C<*new*>.  You will receive a response informing you that the address has been
created.  The message will include the new address.  In this case, it might be
C<3abfeec@tempmail.example.com>.

Simply provide this address when required to register at a web site (for
example).

You can specify additional directives when creating an address.  Please see
L<Directives> for more information.

=head2 RECEIVING MESSAGES FROM A TEMPORARY ADDRESS

Every message sent to your temporary address will be resent to the address you
used to create the address.  The sender will not see your actual address.

=head2 REPLYING TO MESSAGES RECEIVED AT A TEMPORARY ADDRESS

Every message relayed to your actual address will contain a special C<Reply-To>
header keyed to the sender.  Thus, a message from C<news@example.com> may have
a C<Reply-To> header of C<3abfeec+3f974d46@tempmail.example.com>.  Be sure to
send any replies to this address so that the message may be relayed from your
temporary address.

=head1 DIRECTIVES

Temporary addresses have two attributes.  You can specify these attributes by
including directives when you create a new address.

Directives go in the body of the creation message.  They take the form:

    Directive: option

=head2 Expires

This directive governs how long the address will last.  After its expiration
date has passed, no one may send a message to the address.  Everyone will then
receive an error message indicating that the address does not exist.

This attribute is not set by default; addresses do not expire.  To enable it,
use the directive form:

    Expires: 7d2h

This directive will cause the address to expire in seven days and two hours.
Valid time units are:

=over 4

=item * C<m>, for minute.  This is sixty (60) seconds.

=item * C<h>, for hour.  This is sixty (60) minutes.

=item * C<d>, for day.  This is twenty-four (24) hours.

=item * C<w>, for week. This is seven (7) days.

=item * C<M>, for month.  This is thirty (30) days.

=back

This should suffice for most purposes.

=head2 Description

This is a single line that describes the purpose of the address.  If provided,
it will be sent in the C<X-MTA-Description> header in all messages sent to the
address.  By default, it is blank.  To set a description, use the form:

    Description: This address was generated to enter a contest.

=head1 METHODS

=over 4

=item * new( $address_directory,
    [ Filehandle => $fh, Storage => $addys, Message => $mess ] )

C<new()> takes one mandatory argument and three optional arguments.
C<$address_directory> is the path to the directory where address data is
stored.  You can usually get by with just the mandatory argument.

C<$fh> is a filehandle (or a reference to a glob) from which to read an
incoming message.  If not provided, M::TA will read from C<STDIN>, as that is
how mail filters work.

C<$addys> should be an Storage object (which manages the storage of temporary
addresses).  If not provided, M::TA will use L<Mail::TempAddress::Addresses> by
default.

C<$mess> should be a Mail::Message object (representing an incoming e-mail
message) to the constructor.  If not provided, M::TA will use L<Mail::Message>
by default.

=item * process()

Processes one incoming message.

=item * expansion_pattern()

Returns a compiled regex to find expanded e-mail addresses (of the form
C<you+expansion@example.com>).  If you've set your mail server to use a
delimiter other than C<+>, override this method.  For example, Andy Lester uses
addresses of the form C<you-expansion@example.com>.  What a nut.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>.

=head1 BUGS

No known bugs.

=head1 TODO

=over 4

=item * allow nicer name generation

=item * allow new message creation to send an initial message

=item * allow address creation to be restricted to a set of users

=back

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
