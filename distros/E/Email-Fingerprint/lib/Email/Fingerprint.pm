package Email::Fingerprint;

use warnings;
use strict;

use Class::Std;

use Carp qw( croak );
use overload;
use Mail::Header;
use Scalar::Util qw( blessed reftype );
use List::MoreUtils qw( apply );

=head1 NAME

Email::Fingerprint - Calculate a digest for recognizing duplicate emails

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';

=head1 SYNOPSIS

Email::Fingerprint calculates a checksum that uniquely identifies an email,
for use in spotting duplicate messages. The checksum is based on: the
Message-ID: header; or if it doesn't exist, on the Date:, From:,
To: and Cc: headers together; or if those don't exist, on the body of the
message.

    use Email::Fingerprint;

    my $foo = Email::Fingerprint->new();
    ...

=head1 ATTRIBUTES

=cut

my %header          : ATTR( :get<header> );         # Header and body are
my %body            : ATTR( :get<body> );           # read-only fields
my %input           : ATTR( :init_arg<input> :get<input> :default(0) );
my %strict_checking : ATTR( :name<strict_checking>  :default(0) );
my %checksum        : ATTR( :get<checksum> :default('unpack') );

=head1 FUNCTIONS

=head2 new

    $fp = new Email::Fingerprint({
        input           => \*INPUT,         # Or $string, \@lines, etc.
        checksum        => "Digest::SHA",   # Or "Digest::MD5", etc.
        strict_checking => 1,               # If true, use message bodies
        %mail_header_opts,
    });

Create a new fingerprinting object. If the C<input> option is used,
C<Email::Fingerprint> attempts to intelligently read the email message
given by that option, whether it's a string, an array of lines or a
filehandle.

If C<$opts{checksum}> is not supplied, then C<Email::Fingerprint> will use
the first checksum module that it finds. If it finds no modules, it will
use C<unpack> in a ghastly manner you don't want to think about.

Any C<%opts> are also passed along to C<Mail::Header->new>; see the
perldoc for C<Mail::Header> options.

=cut

sub BUILD {
    my ( $self, $ident, $args ) = @_;

    $self->set_checksum( $args->{checksum} || 'unpack' );

    # Try to be "smart" and input the message by hook or by crook.
    # Here we do something slightly nasty, and let Mail::Header see our
    # args.
    $self->read( $args->{input}, $args ) if exists $args->{input};
}

=head2 checksum

    # Uses original/default settings to take checksum
    $checksum = $fp->checksum;

    # Can use any options accepted by constructor
    $options  = {
        input           => \*INPUT,         # Or $string, \@lines, etc.
        checksum        => "Digest::SHA",   # Or "Digest::MD5", etc.
        strict_checking => 1,               # If true, use message bodies
        %mail_header_opts,
    };

    # Overrides one or more original/default settings
    $checksum = $fp->checksum($options);

Calculates the actual email fingerprint. The optional hashref
argument will permanently override the object's previous settings.

=cut

sub checksum {
    my $self = shift;
    my %opts = %{ shift || {} };

    # Optionally override strict checking
    $self->set_strict_checking($opts{strict_checking})
        if exists $opts{strict_checking};

    # Optionally override the checksum to use
    $self->set_checksum($opts{checksum}) if exists $opts{checksum};

    # Optionally read a new email message
    $self->read( $opts{input}, \%opts ) if exists $opts{input};

    # It's an error to call checksum without first loading a message.
    croak "No mesage loaded for checksum" unless $self->message_loaded;

    my $module = $self->get_checksum;
    my $header = $self->_extract_headers;
    my $body   = $self->get_strict_checking ? $self->_extract_body : "";

    # Only here for backward compatibility!
    if ( not $module or $module eq 'unpack' ) {
        return unpack("%32C*", $header . $body);
    }

    my $digest = $module->new;

    $digest->add( $header . $body );

    return $digest->hexdigest;
}

=head2 read

  $fingerprint->read_string( $email );
  $fingerprint->read_string( $email, \%mh_args );

Accepts the email message C<$email> and attempts to read it
intelligently, distinguishing strings, array references and file
handles.  If supplied, the optional hash reference is passed on to
Mail::Header.

=cut

sub read {
    my ( $self, $input, $mh_args ) = @_;

    if ( not ref $input ) {

        # Simple case: scalars are treated as strings.
        return $self->read_string( $input );
    }
    elsif ( ref $input eq 'ARRAY' ) {

        # Another simple case: array references
        return $self->read_arrayref( $input, $mh_args );
    }
    elsif ( reftype $input eq 'GLOB' ) {

        # Also simple: filehandle. Using Scalar::Util::reftype()
        # instead of ref() quietly does the right thing, e.g., for
        # FileHandle objects, which are blessed GLOB references.
        return $self->read_filehandle( $input, $mh_args );
    }

    # If execution gets this far, $input had better be an object.
    # None of Perl's other types are supported.
    if ( not blessed $input ) {
        croak "Unknown input type: ", ref $input;
    }

    if ( overload::Method( $input, '""' ) ) {

        # Treat it as a string
        return $self->read_string( $input, $mh_args );
    }
    elsif ( overload::Method( $input, '<>' ) ) {

        # Treat it as a filehandle
        return $self->read_filehandle( $input, $mh_args );
    }

    # OK, I give up.
    croak "Unknown input type: ", ref $input;
}

=head2 read_string

  $fingerprint->read_string( $email_string );
  $fingerprint->read_string( $email_string, \%mh_args );

Accepts the email message C<$email_string> and prepares it for
checksum computation. If supplied, the optional hashref is passed
on to Mail::Header.

=cut

sub read_string {
    my ( $self, $message, $mh_args ) = @_;

    # Split the stringified message into an array of lines.  We can't use
    # split(/\n/,$input); that would discard trailing blank lines.
    $message = [ "$message" =~ m{ ( ^ [^\n]* \n? ) }xmg ];

    # Now delegate
    return $self->read_arrayref( $message, $mh_args );
}

=head2 read_filehandle

  $fingerprint->read_filehandle( $email_fh );
  $fingerprint->read_filehandle( $email_fh, \%mh_args );

Accepts the email message C<$email_fh> and prepares it for checksum
computation. If supplied, the optional hashref is passed on to
Mail::Header.

=cut

sub read_filehandle {
    my ( $self, $message, $mh_args ) = @_;

    # Slurp everything into an arrayref
    $message = [ <$message> ];

    # Now delegate
    return $self->read_arrayref( $message, $mh_args );
}

=head2 read_arrayref

  $fingerprint->read_arrayref( \@email_lines );
  $fingerprint->read_arrayref( \@email_lines, \%mh_args );

Accepts the email message C<\@email_lines> and prepares it for
checksum computation. If supplied, the optional hashref is passed
on to Mail::Header.

=cut

sub read_arrayref {
    my ( $self, $message, $mh_args ) = @_;
    $mh_args ||= {};

    # Prepare args to pass on to Mail::Header constructor. The ordering
    # below causes $mh_args to override the default settings in this
    # hashref.
    $mh_args = {
        Modify   => 0,          # Don't mess with the header.
        MailFrom => 'IGNORE',   # Accept message in mbox format.
        %$mh_args,
    };

    # Initializations. This is the ONLY method that sets the
    # "input" and "header" fields.
    $header{ ident $self } = Mail::Header->new( $message, %$mh_args );
    $input{ ident $self }  = $message;
    delete $body{ ident $self };
}

=head2 message_loaded

Returns true if an email message has been loaded and is ready for checksum,
or false if no message has been loaded or an error has occurred.

=cut

sub message_loaded {
    my $self = shift;

    return defined $self->get_header ? 1 : 0;
}

=head2 set_checksum

Specifies the checksum method to be used.

=cut

sub set_checksum {
    my ( $self, $checksum )  = @_;
    $checksum{ ident $self } = $checksum;

    return if not $checksum or $checksum eq 'unpack';

    eval "use $checksum";   ## no critic
    croak "Invalid checksum: $checksum\n" if $@;
}

=head1 INTERNAL METHODS

=head2 BUILD

A constructor helper method called from the C<Class::Std> framework. To
execute C<BUILD>, use C<new()>.

=head2 _extract_headers

Extract the Message-ID: header. If that does not exist, extract
the Date:, From:, To: and Cc: headers. If those do not exist, then
force strict checking so that the message body will be
fingerprinted.

=cut

sub _extract_headers :RESTRICTED {
    my $self = shift;

    my $raw  = $self->get_header->header_hashref;

    my %headers;

    my $extracted_headers = "";

    map { my $key = lc( $_ ); $headers{$key} = $raw->{$_} } keys %$raw;

    if (defined $headers{'message-id'}) {
        $extracted_headers .= $self->_concat( $headers{'message-id'} );
    }
    else {
        foreach my $h ('date', 'from', 'to', 'cc') {
            next unless exists $headers{$h};

            $extracted_headers .= $self->_concat( $headers{$h}, "$h:" );
        }
    }

    $self->set_strict_checking(1) unless $extracted_headers;
    return $extracted_headers;
}

=head2 _extract_body

    $body = $fp->_extract_body;

Gets the body of the message, as a string. Line-endings are preserved, so
the body can, e.g., be printed.

This method must only be called after a message has been read. No
validation is done in the method itself, so this is the user's
responsibility.

=cut

sub _extract_body :RESTRICTED {

    my $self = shift;

    # Use the cached body, if any
    my $body = $self->get_body;
    return $body if defined $body;

    my $input = $self->get_input;

    # Copy the message. We don't want to munge the original!
    my @message = @$input;

    my $line;

    # Discard the RFC822 header. Perhaps not as bullet-proof
    # as it could be...
    do { $line = shift @message } while ( $line and $line !~ m{ ^$ }xmsg );

    $body .= join "", @message;

    # Cache the body for reuse. This is the ONLY method that sets the
    # "body" field.
    $body{ident $self} = $body;

    return $body;
}

=head2 _concat

  @headers = qw( foo@example.com bar@example.com );
  $delim   = 'To:';
  $string  = $fp->_concat( \@headers, $delim );

  # $string is now 'To:foo@example.comTo:bar@example.com'

Returns the concatenation of C<\@headers>, with C<$delim> prepended
to each element of C<\@headers>. If C<$delim> is omitted, the empty
string is used. C<\@headers> elements are all chomped before
concatenation.

=cut

sub _concat :PRIVATE {
    my $self  = shift;
    my $data  = shift;
    my $delim = shift || "";

    return $delim . join($delim, apply {chomp } @$data);
}

=head1 AUTHOR

Len Budney, C<< <lbudney at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-fingerprint at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Fingerprint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Fingerprint

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Fingerprint>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Fingerprint>

=back

=head1 SEE ALSO

See B<Mail::Header> for options governing the parsing of email headers.

=head1 ACKNOWLEDGEMENTS

Email::Fingerprint is based on the C<eliminate_dups> script by Peter Samuel
and available at L<http://www.qmail.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2011 Len Budney, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Email::Fingerprint
