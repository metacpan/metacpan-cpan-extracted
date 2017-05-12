package Mail::POP3;

use strict;
use IO::Socket;
use IO::File;
use POSIX;

use Mail::POP3::Daemon; # needs to handle signals!
use Mail::POP3::Server;
use Mail::POP3::Folder::maildir;
use Mail::POP3::Folder::mbox;
use Mail::POP3::Folder::mbox::parse_to_disk;
use Mail::POP3::Security::Connection;
# use Mail::POP3::Security::User;
# use Mail::POP3::Security::User::system;
# use Mail::POP3::Security::User::vdomain;

# UIDL is the Message-ID

use vars qw($VERSION);
$VERSION = "3.08";

sub read_config {
    my ($class, $config_text) = @_;
    my $config = eval $config_text;
    # mpopd config files have a version number of their own which must
    # be the same as the Mail::POP3 version. As mpopd develops, new features
    # may require new config items or syntax so the version number of
    # the config file must be checked first.
    die <<EOF if $config->{mpopd_conf_version} ne $VERSION;
Sorry, Mail::POP3 v$VERSION requires an mpopd config file conforming
to config version '$VERSION'.
Your config file is version '$config->{mpopd_conf_version}'
EOF
    $config;
}

sub make_sane {
    my ($class, $config_hash) = @_;
    # Create a sane environment if not configured in mpop.conf
    $config_hash->{port} = 110 if $config_hash->{port} !~ /^\d+$/;
    $config_hash->{message_start} = "^From "
        if $config_hash->{message_start} !~ /^\S+$/;
    $config_hash->{message_end} = "^\\s*\$"
        if $config_hash->{message_end} !~ /^\S+$/;
    $config_hash->{timeout} = 10
        if $config_hash->{timeout} !~ /^\d+$/;
    # Make disk-based parsing the default
    $config_hash->{parse_to_disk} = 1
        unless defined $config_hash->{parse_to_disk};
    $config_hash->{greeting} =~ s/([\w\.-_:\)\(]{50}).*/$1/;
}

sub from_file {
    my ($class, $file) = @_;
    local (*FH, $/);
    open FH, $file or die "$file: $!\n";
    <FH>;
}

1;

__END__

=head1 NAME

Mail::POP3 -- a module implementing a full POP3 server

=head1 SYNOPSIS

    use Mail::POP3;
    my $config_text = Mail::POP3->from_file($config_file);
    my $config = Mail::POP3->read_config($config_text);
    Mail::POP3->make_sane($config);
    while (my $sock = $server_sock->accept) {
        my $server = Mail::POP3::Server->new(
            $config,
        );
        $server->start(
            $sock,
            $sock,
            $sock->peerhost,
        );
    }

=head1 DESCRIPTION

C<Mail::POP3> and its associated classes work together as follows:

L<Mail::POP3::Daemon> does the socket-accepting.
L<Mail::POP3::Server> does (most of) the network POP3 stuff.
L<Mail::POP3::Security::User> and L<Mail::POP3::Security::Connection>
do the checks on users and connections.
C<Mail::POP3::Folder::*> classes handles the mail folders.

This last characteristic means that diverse sources of information
can be served up as though they are a POP3 mailbox by implementing
a C<Mail::POP3::Folder> subclass. An example is provided in
L<Mail::POP3::Folder::webscrape>, and included is a working configuration
file that makes the server connect to Jobserve (as of Jan 2014) and
provide a view of jobs as email messages in accordance with the username
which provides a colon-separated set of terms: keywords (encoding spaces
as C<+>), location radius in miles, location (e.g. Berlin). E.g. the
username C<perl:5:Berlin> would search for jobs relating to Perl within
5 miles of Berlin.

=head2 COPYRIGHT

Copyright (c) Mark Tiramani 1998-2001 - up to version 2.21.
Copyright (c) Ed J 2001+ - version 3+.
All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head2 DISCLAIMER

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Artistic License for more details.

=cut
