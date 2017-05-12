package Mail::Action::Request;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.46';

use Email::MIME;
use Email::Address;
use Email::MIME::Modifier;

sub new
{
    my ($class, $message_text, @args) = @_;
    my $message                       = Email::MIME->new( $message_text );
    my $self                          = bless
    {
        Message   => $message,
        headers   => {},
        recipient => '',
        @args,
    }, $class;

    $self->init();

    return $self;
}

sub init
{
    my $self = shift;
    $self->add_headers();
    $self->add_recipient();
    $self->remove_recipient( $self->recipient_header(), $self->recipient() );
    $self->find_key();
}

sub message
{
    my $self = shift;
       $self->{Message};
}

sub headers
{
    my $self = shift;
       $self->{headers};
}

BEGIN
{
    no strict 'refs';

    for my $attribute (qw( key recipient recipient_header ))
    {
        *{ $attribute } = sub
        {
            my $self = shift;
               $self->{$attribute} = shift if @_;
               $self->{$attribute};
        };
    }
}

sub store_header
{
    my ($self, $header, $value) = @_;
    my $headers                 = $self->headers();
    $headers->{$header}         = $value;
}

sub recipient_headers
{
    return qw( Delivered-To To Cc );
}

sub header
{
    my ($self, $name) = @_;
    my $headers       = $self->headers();

    return $self->message->header( $name ) unless exists $headers->{$name};
    return wantarray ? @{ $headers->{$name} } : $headers->{$name}[0];
}

sub add_headers
{
    my $self = shift;
    $self->find_headers(qw( Subject ));
    $self->find_address_headers();
}

sub find_headers
{
    my ($self, @headers) = @_;
    my $message          = $self->message();

    for my $header (map { ucfirst( lc( $_ ) ) } @headers)
    {
        $self->store_header( $header, [ $message->header( $header ) ] );
    }
}

sub find_address_headers
{
    my $self    = shift;
    my $message = $self->message();

    for my $header (map { ucfirst(lc($_)) } $self->recipient_headers(), 'From')
    {
        my @value = map { Email::Address->parse( $_ ) }
            $message->header( $header );
        $self->store_header( $header, \@value );
    }
}

sub add_recipient
{
    my $self      = shift;
    my $message   = $self->message();
    my $recipient = $self->recipient();

    if ($recipient)
    {
        $self->recipient_header( '' );
    }
    else
    {
        for my $header (map { ucfirst( lc( $_ ) ) } $self->recipient_headers())
        {
            next unless $recipient = $self->header( $header );
            $self->recipient_header( $header );
            last;
        }
    }

    $self->recipient( ( Email::Address->parse( $recipient ) )[0] );
}

sub remove_recipient
{
    my ($self, $header, $recipient) = @_;
    use Carp;
    Carp::cluck( 'no' ) unless $recipient;
    my $recip_addy                  = $recipient->address();

    for my $remove_header ( 'To', 'Cc' )
    {
        my ($found, @cleaned);

        my @addresses       = $self->header( $remove_header );

        while ( my $address = shift @addresses )
        {
            if ( not( $found ) and $address->address() eq $recip_addy )
            {
                push @cleaned, @addresses;
                $found = 1;
                last;
            }
            else
            {
                push @cleaned, $address;
            }
        }

        next unless $found;
        $self->store_header( $remove_header, \@cleaned );
        return;
    }
}

sub find_key
{
    my $self      = shift;

    # be paranoid; explicitly copy captured match variables
    $self->key( "$1" ) if $self->recipient() =~ /\+(\w+)/;
}

sub process_body
{
    my ($self, $address) = @_;
    my $attributes       = $address->attributes();
    my $body             = $self->remove_sig();

    while (@$body and $body->[0] =~ /^(\w+):\s*(.*)$/)
    {
        my ($directive, $value) = (lc( $1 ), $2);
        $address->$directive( $value ) if exists $attributes->{ $directive };
        shift @$body;
    }

    return $body;
}

sub remove_sig
{
    my $self    = shift;
    my $message = $self->message();
    my $body    = ( $message->parts() )[0]->body();

    my @lines;

    for my $line (split(/\n/, $body))
    {
        last if $line eq '-- ';
        push @lines, $line;
    }

    return \@lines;
}

sub copy_headers
{
    my $self    = shift;
    my $message = $self->message();
    my $headers = $self->headers();

    my %copy;

    for my $header ( $message->headers() )
    {
        next if $header eq 'From ';

        my @value = exists $headers->{$header} ?
                           $self->header( $header ) :
                           $message->header( $header );

        next unless @value;
        $copy{ ucfirst( lc( $header ) ) } = join(', ', @value);
    }

    return \%copy;
}

1;
__END__

=head1 NAME

Mail::Action::Request - base for building modules that represent incoming mail

=head1 SYNOPSIS

    use base 'Mail::Action::Request';

=head1 DESCRIPTION

=head1 METHODS

Mail::Action::Request objects have the following methods in several categories:

=head2 Creation and Initialization

=over 4

=item C<new()>

=item C<init()>

=back

=head2 Accessors

=over 4

=item C<message()>

Returns the raw L<Email::Simple> object representing the incoming message.

=item C<headers()>

Returns a hash reference of known message headers and their values.  This can
be dangerous, so use it cautiously.

=item C<header( $name )>

If the invocant has a header of the given C<$name>, returns the first or all of
the values associated with that header, depending on the context of the call.
This will return nothing if the named header does not exist.

=item C<key( [ $new_key ] )>

Returns the key associated with this request, if it exists.  (The key of a
request is usually, but not always, the extension of an extended e-mail
address:  C<extension> in E<lt>you+extension@example.comE<lt>, for example.)

You can use this to store a key, if you must.

=item C<recipient( [ $new_recipient ] )>

Returns the e-mail address for which this request exists.  It is difficult to
determine this reliably and generically across a whole swath of mail servers,
but this makes its best guess.  Note that this I<will> contain the key, if it
exists.

You can use this to store a recipient, if you must.

=item C<recipient_header( [ $new_recipient_header ] )>

Returns the name of the header from which the recipient address came.  You'll
almost never need this, but when you do need it, you'll really need it.

You can use this to store a recipient header, if absolutely necessary.

=item C<recipient_headers()>

Depending on your mail server, you may need to override this in your own
applications to provide a list of headers to check for the e-mail address to
which the server delivered a message.  With Postfix, at least, it appears that
the C<Delivered-To> header is always correct.  This will fall back to C<To> and
C<Cc> as next-best guesses.

Ideally, there will be roles to apply for your mail server of choice that
handle this for you automatically.

=item C<store_header( $name, $value )>

Given the C<$name> of a header and an array reference in C<$value>,
representing the value of that header, stores both in the invocant's headers
structure.

=back

=head2 Other Methods

If you want to subclass this, you might care about the methods:

=over 4

=item C<add_headers()>

Adds the C<Subject> and address headers to the object.

=item C<find_headers( [ @list_of_headers ] )>

Attempts to find every header in the argument list in the message.  Adds every
header found to the list of known headers in the object.

=item C<find_address_headers()>

Adds all recipient headers (see C<recipient_headers()>) and the C<From> header
to the object.

=item C<add_recipient()>

Attempts to set the recipient for this request, if there's not one set already.
Otherwise, it checks all of the headers from C<recipient_headers()>, in order,
trying to find a likely recipient.

=item C<remove_recipient( $recipient_header, $recipient )>

Removes the C<$recipient> from the C<$recipient_header>, leaving the rest of
the message headers undisturbed.  The idea here is to figure out which address
I<received> this message, avoid sending the mail to that address again, and
pass it on appropriately otherwise.

=item C<find_key()>

Attempts to find and set the key for this request.  The key is the portion of
the recipient address immediately following the C<+> sign before the domain
name.  That is, for C<tempmail+fun_list@example.com> the key is C<fun_list>.
Override this if you have a different way to mark keys.

=item C<process_body( $address )>

Given the equivalent of an C<Mail::Action::Address> object, removes the
signature of the message, removes and processes all of the directives from the
body(using the C<$address>), and returns a reference to an array containing the
remaining lines of the body.

=item C<remove_sig()>

Attempts to remove the signature from the message by removing everything
following a line containing C<-- >.  This returns a reference to an array
containing the remaining lines.

It I<tries> to do the right thing with multipart messages, but it looks only in
the first part for the signature.  This may or may not be correct, depending on
how broken the sending MUA was.

=item C<copy_headers()>

Copies all headers from the incoming message to a hash reference where the key
is the name of the header and the value is a comma-separated list of values for
the header.  This explicitly I<removes> the C<From > header that sometimes
C<procmail> seems to add in some cases.

=back

=head1 SEE ALSO

L<Mail::SimpleList> and L<Mail::TempAddress> for example uses.

See L<Mail::Action::Storage>, L<Mail::Action::Address>, and
L<Mail::Action::PodToHelp> for related modules.

=head1 AUTHOR

chromatic, C<chromatic at wgz dot org>.

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
