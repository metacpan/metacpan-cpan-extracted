package Memcached::Server;

use warnings;
use strict;

=head1 NAME

Memcached::Server - A pure perl Memcached server helper, that help you create a server speaking Memcached protocol

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

use AnyEvent::Socket;
use AnyEvent::Handle;
use Hash::Identity qw(e);
use callee;

=head1 SYNOPSIS

    # running as a stand alone server
    use Memcached::Server;
    my $server = Memcached::Server->new(
	no_extra => 0 / 1, # if set to true, then the server will skip cas, expire, flag;
			   #  thus, cas always success, never expire, flag remains 0 forever.
			   # with this option on, one can get a entry that hasn't been set,
			   #  as long as your 'get' and '_find' say yes.
	open => [[0, 8888], ['127.0.0.1', 8889], ['10.0.0.5', 8889], [$host, $port], ...],
	cmd => { # customizable handlers
	    _find => sub {
		my($cb, $key, $client) = @_;
		...
		$cb->(0); # not found
		... or ...
		$cb->(1); # found
	    },
	    get => sub {
		my($cb, $key, $client) = @_;
		...
		$cb->(0); # not found
		... or ...
		$cb->(1, $data); # found
	    },
	    set => sub {
		my($cb, $key, $flag, $expire, $value, $client) = @_;
		...
		$cb->(1); # success
		... or ...
		$cb->(-1, $error_message); # error occured, but keep the connection to accept next commands.
		... or ...
		$cb->(-2, $error_message); # error occured, and close the connection immediately.
	    },
	    delete => sub {
		my($cb, $key, $client) = @_;
		...
		$cb->(0); # not found
		... or ...
		$cb->(1); # success
	    },
	    flush_all => sub {
		my($cb, $client) = @_;
		...
		$cb->();
	    },
	    _begin => sub { # called when a client is accepted or assigned by 'serve' method (optional)
		my($cb, $client) = @_;
		...
		$cb->();
	    },
	    _end => sub { # called when a client disconnects (optional)
		my($cb, $client) = @_;
		...
		$cb->();
	    },
	    # NOTE: the $client, a AnyEvent::Handle object, is presented for keeping per connection information by using it as a hash key.
	    #  it's not recommended to read or write to this object directly, that might break the protocol consistency.
	}
    );
    ...
    $server->open($host, $port); # open one more listening address
    $server->close($host, $port); # close a listening address
    $server->close_all; # close all the listening addresses
    $server->serve($file_handle); # assign an accepted client socket to the server manually

=head1 DESCRIPTION

This module help us to create a pure perl Memcached server.
It take care some protocol stuff, so that we can only focus on primary functions.

Take a look on the source of L<Memcached::Server::Default>, a compelete example that
works as a standard Memcached server, except it's pure perl implemented.

=head1 SUBROUTINES/METHODS

=head2 $server = Memcached::Server->new( cmd => ..., open => ... );

Create a Memcached::Server with parameters 'cmd' (required) and 'open' (optional).

The parameter 'cmd' is provided to control the behaviors, that should be prepared
and assigned at the initial time.

The parameter 'open' is provided to assign a list of listening hosts/ports.
Each of the list is passed to L<AnyEvent::Socket::tcp_server> directly,
so you can use IPv4, IPv6, and also unix sockets.

If you don't provide 'open' here, you can provide it later by member method 'open'.

=cut

sub new {
    my $self = bless {
	open => [],
	cas => 0,
	extra_data => {},
    }, shift;
    while( @_ ) {
	my $key = shift;
	if( $key eq 'cmd' ) {
	    $self->{cmd} = shift;
	}
	elsif( $key eq 'open' ) {
	    $self->open(@$_) for @{shift()};
	}
	elsif( $key eq 'no_extra' ) {
	    $self->{no_extra} = shift;
	}
    }
    return $self;
}

=head2 $server->serve($fh)

Assign an accepted client socket to the server.
Instead of accepting and serving clients on centain listening port automatically,
you can also serve clients manually by this method.

=cut

sub serve {
    my($self, $fh) = @_;

    my $client;
    $client = AnyEvent::Handle->new(
	fh => $fh,
	on_error => sub {
	    $self->_end( sub {
		undef $client;
	    } );
	},
    );
    $self->_begin( sub {
	$client->push_read( line => sub {
	    #$client->push_write("line: $_[1]\n");
	    if( my($cmd, $key, $flag, $expire, $size, $cas, $noreply) = $_[1] =~ /^ *(set|add|replace|append|prepend|cas) +([^ ]+) +(\d+) +(\d+) +(\d+)(?: +(\d+))?( +noreply)? *$/ ) {
		$client->unshift_read( chunk => $size, sub {
		    my $data_ref = \$_[1];
		    $client->unshift_read( line => sub {
			if( $_[1] eq '' ) {
			    if( $cmd eq 'set' ) {
				$self->_set($client, $noreply, $key, $flag, $expire, $$data_ref);
			    }
			    elsif( $cmd eq 'add' ) {
				$self->_find( sub {
				    if( $_[0] ) {
					$client->push_write("NOT_STORED\r\n") unless $noreply;
				    }
				    else {
					$self->_set($client, $noreply, $key, $flag, $expire, $$data_ref);
				    }
				}, $key, $client );
			    }
			    elsif( $cmd eq 'replace' ) {
				$self->_find( sub {
				    if( $_[0] ) {
					$self->_set($client, $noreply, $key, $flag, $expire, $$data_ref);
				    }
				    else {
					$client->push_write("NOT_STORED\r\n") unless $noreply;
				    }
				}, $key, $client );
			    }
			    elsif( $cmd eq 'cas' ) {
				$self->_find( sub {
				    if( $_[0] ) {
					if( $self->{no_extra} || $self->{extra_data}{$key}[2]==$cas ) {
					    $self->_set($client, $noreply, $key, $flag, $expire, $$data_ref);
					}
					else {
					    $client->push_write("EXISTS\r\n") unless $noreply;
					}
				    }
				    else {
					$client->push_write("NOT_FOUND\r\n") unless $noreply;
				    }
				}, $key, $client );
			    }
			    elsif( $cmd eq 'prepend' ) {
				$self->_get( sub {
				    if( $_[0] ) {
					$self->_set($client, $noreply, $key, -1, -1, "$$data_ref$_[1]");
				    }
				    else {
					$client->push_write("NOT_STORED\r\n") unless $noreply;
				    }
				}, $key, $client );
			    }
			    elsif( $cmd eq 'append' ) {
				$self->_get( sub {
				    if( $_[0] ) {
					$self->_set($client, $noreply, $key, -1, -1, "$_[1]$$data_ref");
				    }
				    else {
					$client->push_write("NOT_STORED\r\n") unless $noreply;
				    }
				}, $key, $client );
			    }
			}
			else {
			    $client->push_write("CLIENT_ERROR bad data chunk\r\n") unless $noreply;
			    $client->push_write("ERROR\r\n");
			}
		    } );
		} );
	    }
	    elsif( $_[1] =~ /^ *(gets?) +([^ ].*) *$/ ) {
		my($cmd, $keys) = ($1, $2);
		my $n = 0;
		my $curr = 0;
		my @status;
		my @data;
		my $end;
		while( $keys =~ /([^ ]+)/g ) {
		    my $key = $1;
		    my $i = $n++;
		    $self->_get( sub {
			$status[$i-$curr] = $_[0];
			$data[$i-$curr] = $_[1];
			while( $curr<$n && defined $status[0] ) {
			    if( shift @status ) {
				$client->push_write("VALUE $key $e{ $self->{no_extra} ? 0 : $self->{extra_data}{$key}[1] } $e{length $data[0]}");
				$client->push_write(" $e{ $self->{no_extra} ? 0 : $self->{extra_data}{$key}[2] }") if( $cmd eq 'gets' );
				$client->push_write("\r\n");
				$client->push_write($data[0]);
				$client->push_write("\r\n");
				shift @data;
			    }
			    ++$curr;
			}
			$client->push_write("END\r\n") if( $end && $curr==$n );
		    }, $key, $client );
		}
		if( $curr==$n ) {
		    $client->push_write("END\r\n");
		}
		else {
		    $end = 1;
		}
	    }
	    elsif( ($key, $noreply) = $_[1] =~ /^ *delete +([^ ]+)( +noreply)? *$/ ) {
		$self->_delete( sub {
		    if( !$noreply ) {
			if( $_[0] ) {
			    $client->push_write("DELETED\r\n");
			}
			else {
			    $client->push_write("NOT_FOUND\r\n");
			}
		    }
		}, $key, $client );
	    }
	    elsif( ($cmd, $key, my $val, $noreply) = $_[1] =~ /^ *(incr|decr) +([^ ]+) +(\d+)( +noreply)? *$/ ) {
		$self->_get( sub {
		    if( $_[0] ) {
			if( $cmd eq 'incr' ) {
			    no warnings 'numeric';
			    $val = $_[1] + $val;
			}
			else {
			    no warnings 'numeric';
			    $val = $_[1] - $val;
			    $val = 0 if $val<0;
			}
			$self->_set($client, sub { $client->push_write("$val\r\n") unless $noreply }, $key, -1, -1, $val);
		    }
		    else {
			$client->push_write("NOT_FOUND\r\n") unless $noreply;
		    }
		}, $key, $client );
	    }
	    elsif( $_[1] =~ /^ *stats *$/ ) {
		$client->push_write("END\r\n");
	    }
	    elsif( ($noreply) = $_[1] =~ /^ *flush_all( +noreply)? *$/ ) {
		$self->_flush_all( sub {
		    $client->push_write("OK\r\n") unless $noreply;
		} );
	    }
	    elsif( $_[1] =~ /^ *verbosity( +noreply)? *$/ ) {
		$client->push_write("OK\r\n") if !$1;
	    }
	    elsif( $_[1] =~ /^ *version *$/ ) {
		$client->push_write("VERSION 1.4.4\r\n");
	    }
	    elsif( $_[1] =~ /^ *quit *$/ ) {
		$client->push_shutdown;
	    }
	    else {
		$client->push_write("ERROR\r\n");
	    }
	    $client->push_read( line => callee );
	} );
    }, $client );
}

=head2 $server->open( host, port )

Functions like the 'open' parameter of the 'new' method.
The 'new' method will put each element of the 'open' parameter to this method indeed.

=cut

sub open {
    my $self = shift;
    push @{$self->{open}}, [ $_[0], $_[1], tcp_server( $_[0], $_[1], sub { $self->serve($_[0]) } ) ];
}

=head2 $server->close( host, port )

Close and stop listening to certain host-port.

=cut

sub close {
    my $self = shift;
    $self->{open} = [ grep { $_->[0] ne $_[0] or $_->[1] != $_[1] } @{$self->{open}} ];
}

=head2 $server->close_all

Close all the listening host-port.

=cut

sub close_all {
    my $self = shift;
    $self->{open} = [];
}

=head2 $server->_set, $server->_find, $server->_get, $server->_delete, $server->_flush_all, $server->_begin, $server->_end

These methods are the main function methods used by the server.
They should be used or overrided when you implementing your own server and you want
to do something SPECIAL. Please read the source for better understanding.

=cut

sub _set {
    my($self, $client, $noreply, $key, $flag, $expire) = @_;
    $self->{cmd}{set}( sub {
	my($status, $msg) = @_;
	if( $status==1 ) {
	    $expire += time if $expire>0 && $expire<=2592000;
	    if( !$self->{no_extra} ) {
		if( $expire<0 ) {
		    $self->{extra_data}{$key}[2] = ++$self->{cas};
		}
		else {
		    $self->{extra_data}{$key} = [$expire, $flag, ++$self->{cas}];
		}
	    }
	    $client->push_write("STORED\r\n") unless $noreply;
	    $noreply->() if ref($noreply) eq 'CODE';
	}
	elsif( $status==-1 ) {
	    $client->push_write("SERVER_ERROR $msg\r\n");
	}
	elsif( $status==-2 ) {
	    $client->push_write("SERVER_ERROR $msg\r\n", 1);
	    $client->push_shutdown;
	}
	else {
	    warn "Unknown 'set' callback status: $status";
	    $client->push_write("SERVER_ERROR $msg\r\n");
	}
    }, $key, $flag, $expire, $_[6], $client);
}

sub _find {
    my($self, $cb, $key, $client) = @_;
    if( $self->{no_extra} || exists $self->{extra_data}{$key} ) {
	if( $self->{no_extra} || !$self->{extra_data}{$key}[0] || $self->{extra_data}{$key}[0]>time ) {
	    $self->{cmd}{_find}($cb, $key, $client);
	}
	else {
	    $self->_delete( sub { $cb->(0) }, $key, $client ); 
	}
    }
    else {
	$cb->(0);
    }
}

sub _get {
    my($self, $cb, $key, $client) = @_;
    if( $self->{no_extra} || exists $self->{extra_data}{$key} ) {
	if( $self->{no_extra} || !$self->{extra_data}{$key}[0] || $self->{extra_data}{$key}[0]>time ) {
	    $self->{cmd}{get}->($cb, $key, $client);
	}
	else {
	    $self->_delete( sub { $cb->(0) }, $key, $client ); 
	}
    }
    else {
	$cb->(0);
    }
}

sub _delete {
    my($self, $cb, $key, $client) = @_;
    if( $self->{no_extra} || exists $self->{extra_data}{$key} ) {
	my $extra_data = delete $self->{extra_data}{$key};
	$self->{cmd}{delete}->( !$extra_data->[0] || $extra_data->[0]>time ? $cb : sub { $cb->(0) }, $key, $client );
    }
    else {
	$cb->(0);
    }
}

sub _flush_all {
    my($self, $cb, $client) = @_;
    $self->{cmd}{flush_all}->( sub {
	$self->{extra_data} = {};
	$cb->();
    }, $client );
}

sub _begin {
    my($self, $cb, $client) = @_;
    if( exists $self->{cmd}{_begin} ) {
	$self->{cmd}{_begin}->($cb, $client);
    }
    else {
	$cb->();
    }
}

sub _end {
    my($self, $cb, $client) = @_;
    if( exists $self->{cmd}{_end} ) {
	$self->{cmd}{_end}->($cb, $client);
    }
    else {
	$cb->();
    }
}

=head1 SEE ALSO

L<Memcached::Server::Default>, L<AnyEvent>, L<AnyEvent::Socket>

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-memcached-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memcached-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memcached::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memcached-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Memcached-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Memcached-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Memcached-Server/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Memcached::Server
