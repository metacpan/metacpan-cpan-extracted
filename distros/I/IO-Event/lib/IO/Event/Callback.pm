
package IO::Event::Callback;

use strict;
use warnings;

use IO::Event;

our @handlers;
BEGIN {
	@handlers = qw(input connection read_ready werror eof output 
		outputdone connected connect_failed died timer exception
		outputoverflow);
}

sub new
{
	my ($pkg, $filehandle, %h) = @_;

	my $ro = $h{read_only};
	my $wo = $h{write_only};
	delete $h{read_only};
	delete $h{write_only};

	my $self = handler($pkg, %h);

	return IO::Event->new($filehandle, $self, read_only => $ro, write_only => $wo);
}

sub ie_input		{ $_[0]->{'ie_input'}->(@_)		};
sub ie_connection	{ $_[0]->{'ie_connection'}->(@_)	};
sub ie_read_ready	{ $_[0]->{'ie_read_ready'}->(@_)	};
sub ie_werror		{ $_[0]->{'ie_werror'}->(@_)		};
sub ie_eof		{ $_[0]->{'ie_eof'}->(@_)		};
sub ie_output		{ $_[0]->{'ie_output'}->(@_)		};
sub ie_outputdone	{ $_[0]->{'ie_outputdone'}->(@_)	};
sub ie_connected	{ $_[0]->{'ie_connected'}->(@_)		};
sub ie_connect_failed	{ $_[0]->{'ie_connect_failed'}->(@_)	};
sub ie_died		{ $_[0]->{'ie_died'}->(@_)		};
sub ie_timer		{ $_[0]->{'ie_timer'}->(@_)		};
sub ie_exception	{ $_[0]->{'ie_exception'}->(@_)		};
sub ie_outputoverflow	{ $_[0]->{'ie_outputoverflow'}->(@_)	};

sub handler
{
	my ($pkg, %h) = @_;

	my $self = bless {}, $pkg;

	for my $h (@handlers) {
		my $key = 
			exists($h{$h})		? $h		: 
			exists($h{"ie_$h"})	? "ie_$h"	: undef;
		if ($key) {
			$self->{"ie_$h"} = $h{$key};
			delete $h{$key};
		} else {
			$self->{"ie_$h"} = sub {};
		}
	}
	my @k = keys %h;
	die "unexpected parameters: @k" if @k;
	return $self;
}

sub sock2handler
{
	my ($pkg, $sref) = @_;
	my %h;
	for my $h (@handlers) {
		next unless exists $sref->{$h};
		my $key = 
			exists($sref->{$h})		? $h		: 
			exists($sref->{"ie_$h"})	? "ie_$h"	: next;
		$h{$h} = $sref->{$key};
		delete $sref->{$key};
	}
	my $handler = handler($pkg,%h);
}

package IO::Event::INET::Callback;

use strict;
use warnings;

sub new
{
	my ($pkg, %sock) = @_;
	my $handler = IO::Event::Callback->sock2handler(\%sock);
	return IO::Event::INET->new(%sock, Handler => $handler);
}

package IO::Event::UNIX::Callback;

use strict;
use warnings;

sub new
{
	my ($pkg, %sock) = @_;
	my $handler = IO::Event::Callback->sock2handler(\%sock);
	return IO::Event::UNIX->new(%sock, Handler => $handler);
}

1;

__END__


=head1 NAME

 IO::Event::Callback - A closure based API for IO::Event

=head1 SYNOPSIS

 use IO::Event::Callback;

 IO::Event::Callback->new($filehanle, %callbacks);

 use IO::Event::INET::Callback;

 IO::Event::INET::Callback->new(%socket_info, %callbacks);

 use IO::Event::UNIX::Callback;

 IO::Event::UNIX::Callback->new(%socket_info, %callbacks);

=head1 DESCRIPTION

IO::Event::Callback is a wrapper around L<IO::Event>.  It 
provides an alternative interface to using L<IO::Event>.

Instead of defining a class with methods like "ie_input", you
provide the callbacks as code references when you create
the object.

The keys for the callbacks are the same as the callbacks 
for L<IO::Event> with the C<ie_> prefix removed.

=head1 EXAMPLE

 use IO::Event::Callback;

 my $remote = IO::Event::Callback::INET->new(
	peeraddr	=> '10.20.10.3',
	peerport	=> '23',
	input		=> sub { 
		# handle input
	},
	werror		=> sub {
		# handdle error
	},
	eof		=> sub {
		# handle end-of-file
	},
 );

=head1 SEE ALSO

See the source for L<RPC::ToWorker> for an exmaple use of IO::Event::Callback.

