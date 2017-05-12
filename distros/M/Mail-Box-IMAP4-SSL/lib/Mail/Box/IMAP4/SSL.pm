use 5.006;
use strict;
use warnings;

package Mail::Box::IMAP4::SSL;
# ABSTRACT: handle IMAP4 folders with SSL
our $VERSION = '0.03'; # VERSION

use superclass 'Mail::Box::IMAP4' => 2.079;
use IO::Socket::SSL 1.12;
use Mail::Reporter 2.079 qw();
use Mail::Transport::IMAP4 2.079 qw();
use Mail::IMAPClient 3.02;

my $imaps_port = 993; # standard port for IMAP over SSL

#--------------------------------------------------------------------------#
# init
#--------------------------------------------------------------------------#

sub init {
    my ( $self, $args ) = @_;

    # until we're connected, mark as closed in case we exit early
    # (otherwise, Mail::Box::DESTROY will try to close/unlock, which dies)
    $self->{MB_is_closed}++;

    # if no port is provided, use the default
    $args->{server_port} ||= $imaps_port;

    # Mail::Box::IMAP4 wants a folder or it throws warnings
    $args->{folder} ||= '/';

    # Use messages classes from our superclass type
    $args->{message_type} ||= 'Mail::Box::IMAP4::Message';

    # giving us a transport argument is an error since our only purpose
    # is to create the right kind of transport object
    if ( $args->{transporter} ) {
        Mail::Reporter->log(
            ERROR => "The 'transporter' option is not valid for " . __PACKAGE__ );
        return;
    }

    # some arguments are required to connect to a server
    for my $req (qw/ server_name username password/) {
        if ( not defined $args->{$req} ) {
            Mail::Reporter->log( ERROR => "The '$req' option is required for " . __PACKAGE__ );
            return;
        }
    }

    # trying to create the transport object

    my $verify_mode =
      $ENV{MAIL_BOX_IMAP4_SSL_NOVERIFY} ? SSL_VERIFY_NONE() : SSL_VERIFY_PEER();

    my $ssl_socket = IO::Socket::SSL->new(
        Proto           => 'tcp',
        PeerAddr        => $args->{server_name},
        PeerPort        => $args->{server_port},
        SSL_verify_mode => $verify_mode,
    );

    unless ($ssl_socket) {
        Mail::Reporter->log( ERROR => "Couldn't connect to '$args->{server_name}': "
              . IO::Socket::SSL::errstr() );
        return;
    }

    my $imap = Mail::IMAPClient->new(
        User     => $args->{username},
        Password => $args->{password},
        Socket   => $ssl_socket,
        Uid      => 1,                # Mail::Transport::IMAP4 does this
        Peek     => 1,                # Mail::Transport::IMAP4 does this
    );
    my $imap_err = $@;

    unless ( $imap && $imap->IsAuthenticated ) {
        Mail::Reporter->log( ERROR => "Login rejected for user '$args->{username}'"
              . " on server '$args->{server_name}': $imap_err" );
        return;
    }

    $args->{transporter} = Mail::Transport::IMAP4->new( imap_client => $imap, );

    unless ( $args->{transporter} ) {
        Mail::Reporter->log(
            ERROR => "Error creating Mail::Transport::IMAP4 from the SSL connection." );
        return;
    }

    # now that we have a valid transporter, mark ourselves open
    # and let the superclass initialize
    delete $self->{MB_is_closed};
    $self->SUPER::init($args);

}

sub type { 'imaps' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Box::IMAP4::SSL - handle IMAP4 folders with SSL

=head1 VERSION

version 0.03

=head1 SYNOPSIS

     # standalone
     use Mail::Box::IMAP4::SSL;
 
     my $folder = new Mail::Box::IMAP4::SSL(
         username => 'johndoe',
         password => 'wbuaqbr',
         server_name => 'imap.example.com',
     );
 
     # with Mail::Box::Manager
     use Mail::Box::Manager;
 
     my $mbm = Mail::Box::Manager->new;
     $mbm->registerType( imaps => 'Mail::Box::IMAP4::SSL' );
 
     my $inbox = $mbm->open(
         folder => 'imaps://johndoe:wbuaqbr@imap.example.com/INBOX',
     );

=head1 DESCRIPTION

This is a thin subclass of L<Mail::Box::IMAP4> to provide IMAP over SSL (aka
IMAPS).  It hides the complexity of setting up Mail::Box::IMAP4 with
L<IO::Socket::SSL>, L<Mail::IMAPClient> and L<Mail::Transport::IMAP4>.

In all other respects, it resembles L<Mail::Box::IMAP4>.  See that module
for documentation.

=for Pod::Coverage init

=head1 INHERITANCE

     Mail::Box::IMAP4::SSL
       is a Mail::Box::IMAP4
       is a Mail::Box::Net
       is a Mail::Box
       is a Mail::Reporter

=head1 METHODS

=head2 C<<< Mail::Box::IMAP4::SSL->new( %options ) >>>

     my $folder = new Mail::Box::IMAP4::SSL(
         username => 'johndoe',
         password => 'wbuaqbr',
         server_name => 'imap.example.com',
         %other_options
     );

The C<<< username >>>, C<<< password >>> and C<<< server_name >>> options arguments are required.
The C<<< server_port >>> option is automatically set to the standard IMAPS port 993,
but can be changed if needed. See L<Mail::Box::IMAP4> for additional options.

Note: It is an error to provide a C<<< transporter >>> options, as this class exists
only to create an SSL-secured C<<< transporter >>> for C<<< Mail::Box::IMAP4 >>>.

=head1 SEE ALSO

=over

=item *

L<Mail::Box>

=item *

L<Mail::Box::IMAP4>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Mail-Box-IMAP4-SSL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Mail-Box-IMAP4-SSL>

  git clone https://github.com/dagolden/Mail-Box-IMAP4-SSL.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
