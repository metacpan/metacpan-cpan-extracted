package Mail::Bulkmail::DummyServer;

# Copyright and (c) 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
# Mail::Bulkmail::DummyServer is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Mail::Bulkmail::DummyServer - dummy class for dummy server objects

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

Mail::Bulkmail::DummyServer is a drop in replacement for Mail::Bulkmail::Server.

Sometimes you just want to test things on your end - make sure your list iterates properly, make
sure your mail merge is functioning fine, make sure your logging functions are correct, whatever.
And in those cases, you probably don't want to worry about futzing around with your SMTP relay and
sending junk messages through it that you don't care about. Not to mention the fact that those
probably will need to be inspected and deleted later. A hassle for debugging.

Enter DummyServer. This is a subclass of Mail::Bulkmail::Server that behaves exactly the same
except for the fact that it doesn't actually connect to a server. Instead, it sends all data
that would be going to the server to a file instead. This file should be specified in the conf file.

 #in your conf file
 define package Mail::Bulkmail::DummyServer
 dummy_file	= ./my.dummy.file

Now, instead of sending commands to your SMTP relay, they'll get sent to ./my.dummy.file for easy
inspection at a later date.

=cut

use Mail::Bulkmail::Server;
@ISA = qw(Mail::Bulkmail::Server);

$VERSION = '3.12';

use strict;
use warnings;

=pod

=head1 CLASS ATTRIBUTES

=over 11

=item dummy_file

Stores the dummy_file that you want to output your data to.

=back

=cut

__PACKAGE__->add_attr('dummy_file');

# this is used for tied filehandles to internally hold the dummy socket
__PACKAGE__->add_attr('_socket');

=pod

=head1 METHODS

=over 11

=item connect

"connects" to your DummyServer. Actually, internally it ties a filehandle onto this package.
Yes, this thing has a (minimal) implementation of a tied handle class to accomplish this feat.

This method is known to return

 MBDu001 - server won't say EHLO

=cut

sub connect {
	my $self = shift;

	local $\ = "\015\012";
	local $/ = "\015\012";

	my $h = $self->gen_handle();
	tie *$h, "Mail::Bulkmail::DummyServer", $self;

	$self->socket($h);

	#We're either given a domain, or we'll build it based on who the message is from
	my $domain = $self->Domain;

	print $h "EHLO $domain";

	my $response = <$h> || "";
	return $self->error("Server won't say EHLO: $response", "MBDu001") if ! $response || $response =~ /^[45]/;

	$self->connected(1);
	return $self;
};

# TIEHANDLE, as usual, ties a filehandle onto this class. It reads the file that is defined
# _in_the_conf_file at Mail::Bulkmail::DummyServer->dummy_file, tries to open it (dies with an
# error if it can't), and then ties our filehandle to the just opened file.
sub TIEHANDLE {

	my $class	= shift;
	my $self	= shift;

	my $file = $self->dummy_file();

	my $handle = Mail::Bulkmail::Object->gen_handle();

	open ($handle, ">>$file") || die $!;

	return $class->new('_socket' => $handle);
};

# in case our filehandle is fetched, just display some minimal information, namely the fact
# that we're in DummyServer, and the name of the dummy file
sub FETCH {
	return "DummyServer at file : " . shift->_socket;
};

# prints to our dummy file. Uses sendmail crlfs, and tacks on a note that we're starting
# a new message if we get a RSET command
sub PRINT {

	my $f = shift->_socket;

	local $\ = "\015\012";
	local $/ = "\015\012";

	if ($_[0] eq 'RSET'){
		print $f "--------NEW MESSAGE (connection reset)-------" if $f;
	};

	print $f @_ if $f;

	return 1;
};

sub FILENO {
	my $f = shift->_socket;
	my $n = fileno($f);
};

# We can't read from this file, it's output only. However, we need to return something since
# talk_and_respond is expecting to read information from its SMTP socket

sub READLINE {
	return "250 bullshit all happy-happy" . scalar localtime() . "\015\012";
};

# closes our filehandle

sub CLOSE {
	my $f = shift->_socket;
	close $f if $f;
	return 1;
};

=pod

=item disconnect

overloaded disconnect method. Wipes out the internal socket as usual, but doesn't try
to say RSET or QUIT to the server.

disconnect can also disconnect quietly, i.e., it won't try to issue a RSET and then quit before closing the socket.

 $server->disconnect(); 			#issues RSET and quit
 $server->disconnect('quietly');	#issues nothing

=back

=cut

sub disconnect {
	my $self	= shift;
	my $quietly	= shift;

	return $self unless $self->connected();

	$self->talk_and_respond('RSET') unless $quietly;	#just to be polite
	$self->talk_and_respond('quit') unless $quietly;

	if (my $socket = $self->socket) {
		close $socket;
		$socket = undef;
	};
	$self->socket(undef);
	$self->connected(0);
	return $self;
};

1;

__END__

=pod

=head1 SEE ALSO

Mail::Bulkmail::Server

=head1 COPYRIGHT (again)

Copyright and (c) 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Mail::Bulkmail::DummyServer is distributed under the terms of the Perl Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut
