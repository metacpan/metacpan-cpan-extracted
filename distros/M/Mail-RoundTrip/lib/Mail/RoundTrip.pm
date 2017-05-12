package Mail::RoundTrip;

use 5.006;
use strict;
use warnings;
use Moo;
use JSON;
use UUID::Tiny qw(:std);
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use File::Slurp;
use Carp;

=head1 NAME

Mail::RoundTrip - Management routines for round trip validation of users' emails

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

To send validation email:

  my $validator = Mail::RoundTrip->new(
                      spool_dir => '/var/spool/myapp/contacts',
                        address => 'test@example.org',
                           data => $data,
                           from => 'me@example.com',
                       reply_to => 'not_me@example.com',
  );
  my $code = $validator->code;
  $validator->send_confirmation(template => $template);

To retrieve based on validation code:

  my $data = Mail::RoundTrip->get_data( code => $code, spool_dir => $dir );

=head1 DESCRIPTION

Many web applicatins rely on some sort of round-trip validation of user emails.
This verifies that the email address, for example, is actually owned by the
user.  This module provides a minimalist set of routines for managing this
process.

The module is curently minimalistic because it is assumed it will provide the
common back-ends for a number of related verification routines.  Extensions and
feature requests are welcome.  The module exposes a fully object-oriented 
interface.

The module basically provides a minimalist spooling service for holding data for
later processing once the code has been provided.

=head1 PROPERTIES

=head2 address

The email address to be confirmed.

=head2 code

This is the random code used to authenticate the request.  Currently this is
generated as an sha2 256-bit hash of a pseudo-random value. 

=head2 from

The address in the from header.

=head2 reply_to 

The address in the reply to header.

=head2 return_path

The return path fo the email.

=head2 data

The data to be queued.

=head2 spool_dir

The spool directory to be used.

=cut

has address => (is =>'ro', required => 0);

has code => (is => 'lazy');

has data => (is => 'ro', required => 0);

has from => (is => 'ro', required => 0);

has reply_to => (is => 'ro', required => 0);

has return_path => (is => 'ro', requird => 0);

has spool_dir => (is => 'ro', required => 1);

sub _build_code {
    my ($self) = @_;
    my $uuid = create_uuid_as_string();
    return $uuid unless -f $self->spool_dir . '/' . $uuid;
    return $self->to_build_code; # If file exists, try again
}

=head1 METHODS

=head2 send_confirmation(subject_prefix = $subpfx, template => $template)

This process the text in template $template, replacing __CODE__ with 
$self->code, setting the subject to "$subpfx $self->code" and sending out the
email to the address provided.

=cut

sub send_confirmation {
    my $self = shift @_;
    my %args = @_;
    my $template = $args{template};
    croak 'No template defined for email' unless $template;
    my $code = $self->code;
    $template =~ s/__CODE__/$code/g;
    my $return_path = $self->return_path || $self->from;
    my $reply_to = $self->reply_to || $self->from;
    my $email = Email::Simple->create(
       header => [
            To => $self->address,
          From => $self->from,
    "Reply-To" => $reply_to,
 'Return-path' => $return_path
       ],
       body => $template,
    );
    _spool($self);
    return sendmail($email);   
}

sub _spool {
    my ($self) = @_;
    my $spooldir = $self->spool_dir;
    $spooldir =~ s|/+$||; # Get rid of trailing slashes
    my $filename = $self->code;
    my $json = encode_json($self->data);
    write_file("$spooldir/$filename", {no_clobber => 1}, $json);
}
    

=head2 get_data(code => $code, spool_dir => $directory)

This gets the data from spool_dir/directory and unlinks the file.

=cut

sub get_data{
    my ($self) = shift @_;
    my %args = @_;
    my $spooldir = $args{spool_dir};
    croak 'No Spool Dir provided' unless defined $spooldir;
    $spooldir =~ s|/+$||; # Get rid of trailing slashes
    my $filename = $args{code};
    my $json = read_file("$spooldir/$filename");
    unlink("$spooldir/$filename");
    return decode_json($json);
}   


=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-roundtrip at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-RoundTrip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::RoundTrip


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-RoundTrip>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-RoundTrip>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-RoundTrip>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-RoundTrip/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Chris Travers.

This program is released under the following license: BSD


=cut

1; # End of Mail::RoundTrip
