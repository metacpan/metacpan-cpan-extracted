package Mail::Action;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.46';

use Carp 'croak';

use Mail::Mailer;

use Mail::Action::Request;
use Mail::Action::PodToHelp;

sub new
{
    my ($class, $address_dir, @options, %options, $fh) = @_;
    croak "No address directory provided\n" unless $address_dir;

    if (@options == 1)
    {
        $fh      = $options[0];
    }
    else
    {
        %options = @options if @options;
        $fh      = $options{Filehandle} if exists $options{Filehandle};
    }

    my $storage  = $class->storage_class();

    unless ($options{Request})
    {
        $fh             ||= \*STDIN;
        $fh               = do { local $/; <$fh> } if defined( fileno( $fh ) );
        $options{Request} = Mail::Action::Request->new( $fh );
    }

    $options{Storage} ||= $options{Addresses};
    $options{Storage}   = $storage->new($address_dir) unless $options{Storage};

    bless \%options, $class;
}

sub storage
{
    my $self = shift;
       $self->{Storage};
}

sub request
{
    my $self = shift;
       $self->{Request};
}

# try to avoid this one from now on
sub message
{
    my $self    = shift;
    my $request = $self->request();
       $request->message();
}

sub fetch_address
{
    my $self      = shift;
    my $alias     = $self->parse_alias( $self->request->recipient() );
    my $addresses = $self->storage();

    return unless $addresses->exists( $alias );

    my $addy      = $addresses->fetch( $alias );

    return wantarray ? ( $addy, $alias ) : $addy;
}

sub command_help
{
    my ($self, $pod, @headings) = @_;
    my $request                 = $self->request();

    my $from   = $request->header( 'From' )->address();
    my $parser = Mail::Action::PodToHelp->new();

    $parser->show_headings( @headings );
    $parser->output_string( \( my $output ));
    $parser->parse_string_document( $pod );

    $output =~ s/(\A\s+|\s+\Z)//g;

    $self->reply({
        To      => $from,
        Subject => ref( $self ) . ' Help'
    }, $output );
}

sub process_body
{
    my ($self, $address) = @_;
    my $attributes       = $address->attributes();
    my $body             = $self->request->remove_sig();

    while (@$body and $body->[0] =~ /^(\w+):\s*(.*)$/)
    {
        my ($directive, $value) = (lc( $1 ), $2);
        $address->$directive( $value ) if exists $attributes->{ $directive };
        shift @$body;
    }

    return $body;
}

sub reply
{
    my ($self, $headers, @body) = @_;

    my $mailer = Mail::Mailer->new();
    $mailer->open( $headers );
    $mailer->print( @body );
    $mailer->close();
}

sub find_command
{
    my $self      = shift;
    my ($subject) = $self->request()->header( 'Subject' ) =~ /^\*(\w+)\*/;

    return unless $subject;

    my $command   = 'command_' . lc $subject;
    return $self->can( $command ) ? $command : '';
}

sub copy_headers
{
    my $self    = shift;
    my $headers = $self->request()->headers();

    my %copy;

    while (my ($header, $value) = each %$headers)
    {
        next if $header eq 'From ';
        $copy{ $header } = join(', ', @$value );
    }

    return \%copy;
}

1;
__END__

=head1 NAME

Mail::Action - base for building modules that act on incoming mail

=head1 SYNOPSIS

    use base 'Mail::Action';

=head1 DESCRIPTION

E-mail doesn't have to be boring.  If you have server-side filters, a bit of
disk space, some cleverness, and access to an outgoing SMTP server, you can do
some very clever things.  Want a temporary mailing list?  Try
L<Mail::SimpleList>.  Want a temporary, mostly-anonymous mailing address?  Try
L<Mail::TempAddress>.  Want to build your own similar program?  Read on.

Mail::Action, Mail::Action::Address, Mail::Action::Request, and
Mail::Action::Storage make it easy to create a other modules that receive,
filter, and respond to incoming e-mails.

=head1 METHODS

=over 4

=item * new( $address_directory,
    [ Filehandle => $fh, Storage => $storage, Request => $request ] )

C<new()> takes one mandatory argument and three optional arguments.
C<$address_directory> is the path to the directory where address data is
stored.  You can usually get by with just the mandatory argument.

C<$fh> is a filehandle (or a reference to a glob) from which to read an
incoming message.  If not provided, M::TA will read from C<STDIN>, as that is
how mail filters work.

C<$storage> should be a L<Mail::Action::Storage> object (or workalike), which
manages the storage of action data.  If not provided, Mail::Action will use
L<Mail::Action::Storage> by default.

C<$request> should be a Mail::Action::Request object (representing and
encapsulating an incoming e-mail message) to the constructor.  If not provided,
M::TA will use L<Mail::Action::Request> by default.

=item * process()

Processes one incoming message.

=item * find_command()

Looks in the C<Subject> header of the incoming message for a command (a word
contained within asterisks, such as C<*help*>.  If it finds this, it checks to
see if the current object can perform a method named C<command_I<command>>,
where I<command> is the command found.  If so, it returns the name of that
method.

If not, it returns an empty string.

=item * copy_headers()

Copies, cleans, and returns a hash reference of headers from the incoming
message.

=item * command_help( $pod, @headings )

Given C<$pod>, POD documentation, and C<@headings>, and list of headings within
the POD, extracts the POD within those headings, turns it into plain text, and
e-mails that text to the C<From> address of the incoming message.

=item * process_body( $address )

Looks for lines of the form:

    Directive: arguments

at the I<start> of the body of the incoming message.  If the C<$address> object
(likely L<Mail::Action::Address> or equivalent) understands the directive, this
method calls the method with the name of the directive on the address object,
passing the arguments.

This stops looking for directives when it encounters a blank line.

=item * reply( $headers, @body )

Given a hash reference of e-mail C<$headers> and a list of lines of C<@body>
text, sends a message via L<Mail::Mailer>.  Be sure you've configured that
correctly.

=back

=head1 SUBCLASSING

In addition to the methods described earlier, you may want to override any of
the other methods:

=over 4

=item C<fetch_address()>

Attempts to retrieve the address for the associated alias, if it exists.  In
scalar context, returns just the address.  In list context, returns the address
and the alias.  If the address does not exist, returns nothing.

=item C<message()>

Returns the C<Email::MIME> object associated with this request.

=item C<request()>

Returns the request object for this object.

=item C<storage()>

Returns the storage object for this object.

=back

=head1 SEE ALSO

L<Mail::SimpleList> and L<Mail::TempAddress> for example uses.

See L<Mail::Action::Address>, L<Mail::Action::Request>,
L<Mail::Action::Storage>, and L<Mail::Action::PodToHelp> for related modules.

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<lt>.

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
