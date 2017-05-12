package IO::Socket::Socks::Wrapper;

use strict;
no warnings 'prototype';
no warnings 'redefine';
use Socket qw(:DEFAULT inet_ntop);
use Errno;
use base 'Exporter';

our $VERSION = '0.17';
our @EXPORT_OK = ('connect', 'wrap_connection');

# cache
# pkg -> ref to pkg::sub || undef(if pkg has no connect)
my %PKGS;

# reference to &IO::Socket::connect
my $io_socket_connect;
sub _io_socket_connect_ref {
	return $io_socket_connect if $io_socket_connect;
	$io_socket_connect = \&IO::Socket::connect;
}

# fake handle to put under event loop while making socks handshake
sub _get_blocking_handles {
	pipe(my $blocking_reader, my $blocking_writer)
		or die 'pipe(): ', $!;
	
	$blocking_writer->blocking(0);
	$blocking_reader->blocking(0);
	my $garbage = '\0' x 1024;
	
	my ($writed, $total_writed);
	while ($writed = syswrite($blocking_writer, $garbage)) {
		$total_writed += $writed;
		
		if ($total_writed > 2097152) {
			# socket with buffer more than 2 mb
			# are u kidding me?
			die "Can't create blocking handle";
		}
	}
	
	return ($blocking_reader, $blocking_writer);
}

sub _unblock_handles {
	my ($blocking_reader, $blocking_writer) = @_;
	
	while (sysread($blocking_reader, my $buf, 4096)) {
		vec(my $win, fileno($blocking_writer), 1) = 1;
		last if select(undef, $win, undef, 0);
	}
}

sub import {
	my $mypkg = shift;
	
	if (@_ == 1 && !ref($_[0]) && $_[0] eq 'wrap_connection') {
		return __PACKAGE__->export_to_level(1, $mypkg, 'wrap_connection');
	}
	
	while (my ($pkg, $cfg) = splice @_, 0, 2) {
		unless (defined $cfg) {
			$cfg = $pkg;
			$pkg = undef;
		}
		
		if ($pkg) {
			no strict 'refs';
			
			my $sub;
			if ($pkg =~ /^(.+)::([^:]+)\(\)$/) {
				$pkg = $1;
				$sub = $2;
			}
			
			# override in the package
			
			# try to load if not already available
			# and if not requested to do not load
			unless(delete $cfg->{_norequire} || %{$pkg.'::'}) {
				eval "require $pkg" # make @ISA available
					or die $@;
			}
			
			if ($sub) {
			# localize IO::Socket::connect overriding
			# in the sub where IO::Socket::connect called
				my $symbol = $pkg.'::'.$sub;
				my $pkg_sub = exists $PKGS{$symbol} ?
				                     $PKGS{$symbol} :
				                     ($PKGS{$symbol} = \&$symbol);
				
				_io_socket_connect_ref();
				
				*$symbol = sub {
					local *IO::Socket::IP::connect = local *IO::Socket::connect = sub {
						_connect(@_, $cfg, 1);
					};
					
					$pkg_sub->(@_);
				};
				next;
			}
			elsif ($pkg->isa('IO::Socket')) {
			# replace IO::Socket::connect
			# if package inherits from IO::Socket
				# save replaceable package version of the connect
				# if it has own
				# will call it from the our new connect
				my $symbol = $pkg.'::connect';
				my $pkg_connect = exists $PKGS{$pkg} ?
				                         $PKGS{$pkg} :
				                         ($PKGS{$pkg} = eval{ *{$symbol}{CODE} } ? \&$symbol : undef);
				
				*connect = sub {
					_io_socket_connect_ref();
					
					local *IO::Socket::IP::connect = local *IO::Socket::connect = sub {
						_connect(@_, $cfg, 1);
					};
					
					my $self = shift;
					
					if ($pkg_connect) {
					# package has its own connect
						$pkg_connect->($self, @_);
					}
					else {
					# get first parent which has connect sub
					# and call it
						my $ref = ref($self);
						
						foreach my $parent (@{$pkg.'::ISA'}) {
							if($parent->isa('IO::Socket')) {
								bless $self, $parent;
								my $connected = $self->connect(@_);
								bless $self, $ref;
								return $connected ? $self : undef;
							}
						}
					}
				}
			}
			else {
				# replace package version of connect
				*connect = sub {
					_connect(@_, $cfg);
				}
			}
			
			$mypkg->export($pkg, 'connect');
		}
		else {
			# override connect() globally
			*connect = sub(*$) {
				my $socket = shift;
				unless (ref $socket) {
					# old-style bareword used
					no strict 'refs';
					my $caller = caller;
					$socket = $caller . '::' . $socket;
					$socket = \*{$socket};
				}
				
				_connect($socket, @_, $cfg);
			};
			
			$mypkg->export('CORE::GLOBAL', 'connect');
		}
	}
}

sub wrap_connection {
	require IO::Socket::Socks::Wrapped;
	return  IO::Socket::Socks::Wrapped->new(@_);
}

sub _connect {
	my ($socket, $name, $cfg, $io_socket) = @_;
	
	my $ref = ref($socket);
	my $connected;
	
	if ($socket->isa('IO::Socket::Socks') || !$cfg || ( $connected = defined getpeername($socket) )) {
		unless (!$connected && $io_socket and ${*$socket}{'io_socket_timeout'}) {
			return CORE::connect( $socket, $name );
		}
		
		# use IO::Socket::connect for timeout support
		local *connect = sub { CORE::connect($_[0], $_[1]) };
		return _io_socket_connect_ref->( $socket, $name );
	}
	
	my ($port, $host);
	if (($port, $host) = eval { unpack_sockaddr_in($name) }) {
		$host = inet_ntoa($host);
	}
	else {
		($port, $host) = unpack_sockaddr_in6($name);
		$host = inet_ntop(AF_INET6, $host);
	}
	
	# global overriding will not work with `use'
	require IO::Socket::Socks;
	my $io_handler = $cfg->{_io_handler};
	
	unless ($io_handler || exists $cfg->{Timeout}) {
		$cfg->{Timeout} = $ref && $socket->isa('IO::Socket') && ${*$socket}{'io_socket_timeout'} || 180;
	}
	
	my $need_nb;
	
	if ($io_handler) {
		$io_handler = $io_handler->();
		require POSIX;
		
		
		my $fd = fileno($socket);
		my $tmp_fd = POSIX::dup($fd) // die 'dup(): ', $!;
		open my $tmp_socket, '+<&=' . $tmp_fd or die 'open(): ', $!;
		
		my ($blocking_reader, $blocking_writer) = _get_blocking_handles();
		POSIX::dup2(fileno($blocking_writer), $fd) // die 'dup2(): ', $!;
		
		$io_handler->{blocking_reader} = $blocking_reader;
		$io_handler->{blocking_writer} = $blocking_writer;
		$io_handler->{orig_socket} = $socket;
		Scalar::Util::weaken($io_handler->{orig_socket});
		$socket = $tmp_socket;
	}
	elsif (!$socket->blocking) {
		# without io handler non-blocking connection will not be success
		# so set socket to blocking mode while making socks handshake
		$socket->blocking(1);
		$need_nb = 1;
	}
	
	my $ok;
	{
		# safe cleanup even if interrupted by SIGALRM
		my $cleaner = IO::Socket::Socks::Wrapper::Cleaner->new(sub {
			bless $socket, $ref if $ref && !$io_handler; # XXX: should we unbless for GLOB?
		});
		
		$ok = IO::Socket::Socks->new_from_socket(
			$socket,
			ConnectAddr  => $host,
			ConnectPort  => $port,
			%$cfg
		);
		
		if ($need_nb) {
			$socket->blocking(0);
		}
	};
	
	return unless $ok;
	
	if ($io_handler) {
		my ($r_cb, $w_cb); 
		my $done;
		
		tie *{$io_handler->{orig_socket}}, 'IO::Socket::Socks::Wrapper::Handle', $io_handler->{orig_socket}, sub {
			unless ($done) {
				$io_handler->{unset_read_watcher}->($socket);
				$io_handler->{unset_write_watcher}->($socket);
				
				if ($io_handler->{destroy_io_watcher}) {
					$io_handler->{destroy_io_watcher}->($socket);
				}
				
				close $socket;
			}
			
			# clean circular references
			undef $r_cb;
			undef $w_cb;
		};
		
		my $on_finish = sub {
			tied(*{$io_handler->{orig_socket}})->handshake_done($done = 1);
			POSIX::dup2(fileno($socket), fileno($io_handler->{orig_socket})) // die 'dup2(): ', $!;
			close $socket;
			_unblock_handles($io_handler->{blocking_reader}, $io_handler->{blocking_writer});
		};
		
		my $on_error = sub {
			tied(*{$io_handler->{orig_socket}})->handshake_done($done = 1);
			shutdown($socket, 0);
			POSIX::dup2(fileno($socket), fileno($io_handler->{orig_socket}))  // die 'dup2(): ', $!;
			close $socket;
		};
		
		$r_cb = sub {
			if ($socket->ready) {
				$io_handler->{unset_read_watcher}->($socket);
				
				if ($io_handler->{destroy_io_watcher}) {
					$io_handler->{destroy_io_watcher}->($socket);
				}
				
				$on_finish->();
			}
			elsif ($IO::Socket::Socks::SOCKS_ERROR == &IO::Socket::Socks::SOCKS_WANT_WRITE) {
				$io_handler->{unset_read_watcher}->($socket);
				$io_handler->{set_write_watcher}->($socket, $w_cb);
			}
			elsif ($IO::Socket::Socks::SOCKS_ERROR != &IO::Socket::Socks::SOCKS_WANT_READ) {
				$io_handler->{unset_read_watcher}->($socket);
				
				if ($io_handler->{destroy_io_watcher}) {
					$io_handler->{destroy_io_watcher}->($socket);
				}
				
				$on_error->();
			}
		};
		
		$w_cb = sub {
			if ($socket->ready) {
				$io_handler->{unset_write_watcher}->($socket);
				
				if ($io_handler->{destroy_io_watcher}) {
					$io_handler->{destroy_io_watcher}->($socket);
				}
				
				$on_finish->();
			}
			elsif ($IO::Socket::Socks::SOCKS_ERROR == &IO::Socket::Socks::SOCKS_WANT_READ) {
				$io_handler->{unset_write_watcher}->($socket);
				$io_handler->{set_read_watcher}->($socket, $r_cb);
			}
			elsif ($IO::Socket::Socks::SOCKS_ERROR != &IO::Socket::Socks::SOCKS_WANT_WRITE) {
				$io_handler->{unset_write_watcher}->($socket);
				
				if ($io_handler->{destroy_io_watcher}) {
					$io_handler->{destroy_io_watcher}->($socket);
				}
				
				$on_error->();
			}
		};
		
		if ($io_handler->{init_io_watcher}) {
			$io_handler->{init_io_watcher}->($socket, $r_cb, $w_cb);
		}
		
		$io_handler->{set_write_watcher}->($socket, $w_cb);
		
		$! = Errno::EINPROGRESS;
		return 0;
	}
	
	return 1;
}

package IO::Socket::Socks::Wrapper::Handle;

use strict;

sub TIEHANDLE {
	my ($class, $orig_handle, $cleanup_cb) = @_;
	
	open my $self, '+<&=' . fileno($orig_handle)
		or die 'open: ', $!;
	
	${*$self}{handshake_done} = 0;
	${*$self}{cleanup_cb} = $cleanup_cb;
	
	bless $self, $class;
}

sub handshake_done {
	my $self = shift;
	
	if (@_) {
		${*$self}{handshake_done} = $_[0];
	}
	
	return ${*$self}{handshake_done};
}

sub READ {
	my $self = shift;
	sysread($self, $_[0], $_[1], @_ > 2 ? $_[2] : ());
}

sub WRITE {
	my $self = shift;
	syswrite($self, $_[0], $_[1], @_ > 2 ? $_[2] : ());
}

sub FILENO {
	my $self = shift;
	fileno($self);
}

sub CLOSE {
	my $self = shift;
	
	unless ($self->handshake_done) {
		$self->handshake_done(1);
		${*$self}{cleanup_cb}->();
	}
	
	close $self;
}

sub DESTROY {
	my $self = shift;
	${*$self}{cleanup_cb}->();
}

package IO::Socket::Socks::Wrapper::Cleaner;

use strict;

sub new {
	my ($class, $on_destroy) = @_;
	bless [ $on_destroy ], $class;
}

sub DESTROY {
	shift->[0]->();
}

1;

__END__

=head1 NAME

IO::Socket::Socks::Wrapper - Add SOCKS support for any perl object / package / program

=head1 SYNOPSIS

	use IO::Socket::Socks::Wrapper {
		ProxyAddr => 'localhost',
		ProxyPort => 1080
	};
	
	connect($socket, $name); # will make connection through a socks proxy

=head1 DESCRIPTION

C<IO::Socket::Socks::Wrapper> allows to wrap up the network connections into socks proxy. It can wrap up any network connection,
connection from separate packages or even connection from separate object. It can also play well with your preferred event loop
and do not block it.

=head1 METHODS

=head2 import( CFG )

import() is invoked when C<IO::Socket::Socks::Wrapper> loaded by `use' command. Later it can be invoked manually
to change proxy. Global overriding will not work in the packages that was loaded before calling 
IO::Socket::Socks::Wrapper->import(). So, for this purposes `use IO::Socket::Socks::Wrapper' with $hashref argument
should be before any other `use' statements.

=head3 CFG syntax

=head4 Global wrapping

Only $hashref should be specified. $hashref is a reference to a hash with key/value pairs same as L<IO::Socket::Socks>
constructor options, but without (Connect|Bind|Udp)Addr and (Connect|Bind|Udp)Port. To disable wrapping $hashref could
be scalar with false value.

	# we can wrap all connections
	use IO::Socket::Socks::Wrapper { # should be before any other `use'
		ProxyAddr => 'localhost',
		ProxyPort => 1080,
		SocksDebug => 1,
		Timeout => 10
	};
	
	# except Net::FTP
	IO::Socket::Socks::Wrapper->import(Net::FTP:: => 0); # direct network access

=head4 Wrapping package that inherits from IO::Socket

Examples are: Net::FTP, Net::POP3, Net::HTTP

	'pkg' => $hashref

Where pkg is a package name that is responsible for connections. For example if you want to wrap LWP http connections, then module
name should be Net::HTTP, for https connections it should be Net::HTTPS or even LWP::Protocol::http::Socket and
LWP::Protocol::https::Socket respectively (see examples below). You really need to look at the source code of the package
which you want to wrap to determine the name for wrapping. Or use global wrapping which will wrap all that can. Use `SocksDebug' to
verify that wrapping works. For $hashref description see above.

=over

	# we can wrap connection for separate packages
	# if package inherited from IO::Socket
	# let's wrap Net::FTP and Net::HTTP
	
	use IO::Socket::Socks::Wrapper (
		Net::FTP => {
			ProxyAddr => '10.0.0.1',
			ProxyPort => 1080,
			SocksDebug => 1,
			Timeout => 15
		},
		Net::FTP::dataconn => {
			ProxyAddr => '10.0.0.1',
			ProxyPort => 1080,
			SocksDebug => 1,
			Timeout => 15
		},
		Net::HTTP => {
			ProxyAddr => '10.0.0.2',
			ProxyPort => 1080,
			SocksVersion => 4,
			SocksDebug => 1,
			Timeout => 15
		}
	);
	use Net::FTP;
	use Net::POP3;
	use LWP; # it uses Net::HTTP for http connections
	use strict;
	
	my $ftp = Net::FTP->new();       # via socks5://10.0.0.1:1080
	my $lwp = LWP::UserAgent->new(); # via socks4://10.0.0.2:1080
	my $pop = Net::POP3->new();      # direct network access
	
	...
	
	# change proxy for Net::HTTP
	IO::Socket::Socks::Wrapper->import(Net::HTTP:: => {ProxyAddr => '10.0.0.3', ProxyPort => 1080});

=back

And if package has no separate module you should load module with this package manually

=over

	# we can wrap connection for packages that hasn't separate modules
	# let's make more direct LWP::UserAgent wrapping
	
	# we need to associate LWP::Protocol::http::Socket and LWP::Protocol::https::Socket packages
	# with socks proxy
	# this packages do not have separate modules
	# LWP::Protocol::http and LWP::Protocol::https modules includes this packages respectively
	# IO::Socket::Socks::Wrapper should has access to @ISA of each package which want to be wrapped
	# when package == module it can load packages automatically and do its magic
	# but in the case like this loading will fail
	# so, we should load this modules manually
	
	use LWP::Protocol::http;
	use LWP::Protocol::https;
	use IO::Socket::Socks::Wrapper (
		LWP::Protocol::http::Socket => {
			ProxyAddr => 'localhost',
			ProxyPort => 1080,
			SocksDebug => 1,
			Timeout => 15
		},
		LWP::Protocol::https::Socket => {
			ProxyAddr => 'localhost',
			ProxyPort => 1080,
			SocksDebug => 1,
			Timeout => 15
		}
	);
	use LWP;
	
	# then use lwp as usual
	my $ua = LWP::UserAgent->new();
	
	# in this case Net::HTTP and Net::HTTPS objects will use direct network access
	# but LWP::UserAgent objects will use socks proxy

=back

=head4 Wrapping package that uses built-in connect()

Examples are: Net::Telnet

	'pkg' => $hashref

Syntax is the same as for wrapping package that inherits from IO::Socket except for one point.
Replacing of built-in connect() should be performed before package being actually loaded. For this purposes you should specify
C<_norequire> key with true value for $hashref CFG. This will prevent package loading, so you need to require this package manually
after.

	# we can wrap packages that uses bult-in connect()
	# Net::Telnet for example
	
	use IO::Socket::Socks::Wrapper (
		Net::Telnet => {
			_norequire => 1, # should tell do not load it
			                 # because buil-in connect should be overrided
			                 # before package being compiled
			ProxyAddr => 'localhost',
			ProxyPort => 1080,
			SocksDebug => 1
		}
	);
	use Net::Telnet; # and load it after manually

=head4 Wrapping package that uses IO::Socket object or class object inherited from IO::Socket as internal socket handle

Examples are: HTTP::Tiny (HTTP::Tiny::Handle::connect)

	'pkg::sub()' => $hashref

Where sub is a name of subroutine contains IO::Socket object creation/connection.
Parentheses required. For pkg and $hashref description see above.

	# we can wrap packages that is not inherited from IO::Socket
	# but uses IO::Socket object as internal socket handle
	
	use HTTP::Tiny; # HTTP::Tiny::Handle package is in HTTP::Tiny module
	use IO::Socket::Socks::Wrapper (
		# HTTP::Tiny::Handle::connect sub invokes IO::Socket::INET->new
		# see HTTP::Tiny sourse code
		'HTTP::Tiny::Handle::connect()' => { # parentheses required
			ProxyAddr => 'localhost',
			ProxyPort => 1080,
			SocksVersion => 4,
			Timeout => 15
		}
	);
	
	# via socks
	my $page = HTTP::Tiny->new->get('http://www.google.com/')->{content};
	
	# disable wrapping for HTTP::Tiny
	IO::Socket::Socks::Wrapper->import('HTTP::Tiny::Handle::connect()' => 0);
	# and get page without socks
	$page = HTTP::Tiny->new->get('http://www.google.com/')->{content};

=head4 Wrapping objects

To wrap object connection you should use wrap_connection($obj, $hashref) subroutine, which may be imported manually. $obj may be any object
that uses IO::Socket for tcp connections creation. This subroutine will return new object which you should use. Returned object
is object of IO::Socket::Socks::Wrapped class and it has all methods that original object has. You can also use original object as before,
but it will create direct connections without proxy. For more details see L<IO::Socket::Socks::Wrapped> documentation. For $hashref
description see above.

	# we can wrap connection for separate object
	# if package internally uses IO::Socket for connections (for most this is true)
	
	use IO::Socket::Socks::Wrapper 'wrap_connection';
	use Net::SMTP;
	
	my $smtp = wrap_connection(Net::SMTP->new('mailhost'), {
		ProxyAddr => 'localhost',
		ProxyPort => 1080,
		SocksDebug => 1
	});
	
	# $smtp now uses socks5 proxy for connections
	$smtp->to('postmaster');
	$smtp->data();
	$smtp->datasend("To: postmaster\n");
	$smtp->datasend("\n");
	$smtp->datasend("A simple test message\n");
	$smtp->dataend();

=head4 Integration with event loops

B<Note:> integration with C<kqueue> based event loops known to be broken

When you are using some event loop like AnyEvent or POE it is important to prevent any long blocking operations.
By default IO::Socket::Socks::Wrapper blocks your program while it making connection and SOCKS handshake with a proxy.
If you are using fast proxy on localhost this is not big problem, because connection to proxy and making SOCKS
handshake will not get some significant time. But usually SOCKS proxy located somewhere in the other part of the Earth and
is not so fast. So your event loop will suffer from this delays and even may misbehaves.

Since version 0.11 IO::Socket::Socks::Wrapper introduces several hooks, so you can integrate it with any event loop and make
event loop happy. In the CFG you should specify additional parameter with name C<_io_handler> and value is a reference to subroutine,
which should return reference to a hash. Possible keys in this hash are:

=over

=item init_io_watcher => sub { my ($handle, $r_cb, $w_cb) = @_ }

Value should be a reference to subroutine in which you'll make some IO watcher initialization for your event loop if needed.
When it will be time to call this sub IO::Socket::Socks::Wrapper will pass to it 3 arguments: $handle - this is IO::Socket object,
$r_cb - read callback that should be called when $handle will become ready for reading, $w_cb - write callback that should be called
when $handle will become ready for writing.

This parameter is optional.

Let's start example to make it clear. For our example we will use some fictional IO loop called C<Some::IOLoop>, which has same methods
and behavior as L<Mojo::IOLoop>

Beginning looks like

=over

	use IO::Socket::Socks::Wrapper {
		ProxyAddr   => $s_host,
		ProxyPort   => $s_port,
		_io_handler => sub {
		# ...

=back

Here in the sub you can define some variable which you will use in the closures below

=over

			# ...
			my $reactor = Some::IOLoop->singleton->reactor;
			
			return {
				init_io_watcher => sub {
					my ($hdl, $r_cb, $w_cb) = @_;
					
					# initialize IO watcher
					$reactor->io($hdl => sub {
						my $writable = pop;
						
						if ($writable) {
							$w_cb->();
						}
						else {
							$r_cb->();
						}
					});
				},
				# ...

=back

=item set_read_watcher => sub { my ($handle, $r_cb) = @_ }

Value should be a reference to subroutine in which you'll start read watcher for passed $handle. When $handle will be ready
for read $r_cb should be called.

This parameter is not optional. Let's continue our example.

Watcher already created above and all we need to do is to start watching for reading and stop watching for writing

=over

				# ...
				set_read_watcher => sub {
					my ($hdl, $cb) = @_;
					$reactor->watch($hdl, 1, 0);
				},
				# ...

=back

=item unset_read_watcher => sub { my ($handle) = @_ }

Value should be  a reference to subroutine in which you'll stop read watcher for passed $handle.

This parameter is not optional

=over

				# ...
				unset_read_watcher => sub {
					my $hdl = shift;
					$reactor->watch($hdl, 0, 0);
				},
				# ...

=back

=item set_write_watcher => sub { my ($handle, $w_cb) = @_ }

Value should be a reference to subroutine in which you'll start write watcher for passed $handle. When handle will be ready
for write $w_cb should be called.

This parameter is not optional

=over

				# ...
				set_write_watcher => sub {
					my ($hdl, $cb) = @_;
					$reactor->watch($hdl, 0, 1);
				},
				# ...

=back

=item unset_write_watcher => sub { my ($handle) = @_ }

Value should be a reference to subroutine in which you'll stop write watcher for passed $handle.

This parameter is not optional

=over

				# ...
				unset_write_watcher => sub {
					my $hdl = shift;
					$reactor->watch($hdl, 0, 0);
				},
				# ...

=back

=item destroy_io_watcher => sub { my ($handle) = @_  } 

Value should be a reference to subroutine in which you'll destroy watcher for passed $handle if needed.

This parameter is optional

=over

				# ...
				destroy_io_watcher => sub {
					my $hdl = shift;
					$reactor->remove($hdl);
				}
				# ...

=back

And we are done

=over

			# ...
			}
		}
	};

=back

=back

And here is how it may be implemented with AnyEvent

=over

	use IO::Socket::Socks::Wrapper {
		ProxyAddr   => $s_host,
		ProxyPort   => $s_port,
		_io_handler => sub {
			# watcher variable for closures
			my $w;
			
			return {
				# we don't need init_io_watcher
				# and destroy_io_watcher for AnyEvent

				set_read_watcher => sub {
					# because all initialization done here
					my ($hdl, $cb) = @_;
					
					$w = AnyEvent->io(
						poll => 'r',
						fh   => $hdl,
						cb   => $cb
					)
				},
				unset_read_watcher => sub {
					# and destroying here
					undef $w;
				},
				set_write_watcher => sub {
					# and here
					my ($hdl, $cb) = @_;
					
					$w = AnyEvent->io(
						poll => 'w',
						fh   => $hdl,
						cb   => $cb
					)
				},
				unset_write_watcher => sub {
					# and here
					undef $w;
				}
			}
		}
	};

=back

=head1 NOTICE

Default timeout for wrapped connect is timeout value for socket on which we trying to connect. This timeout value checked only
for sockets inherited from IO::Socket. For example C<LWP::UserAgent-E<gt>new(timeout =E<gt> 5)> creates socket with timeout 5 sec, so no 
need to additionally specify timeout for C<IO::Socket::Socks::Wrapper>. If socket timeout not specified or socket not inherited
from IO::Socket then default timeout will be 180 sec. You can specify your own value using C<Timeout> option. Set it to zero if you
don't want to limit connection attempt time.

=head1 BUGS

Wrapping doesn't work with XS based modules, where connection done inside C part. WWW::Curl for example.

Since C<IO::Socket::IP> version 0.08 till version 0.35 it used C<CORE::connect> internally, which can't be wrapped by global wrapping.
And many modules nowadays uses IO::Socket::IP as socket class. So if you have problems with global wrapping make sure you have
C<IO::Socket::IP> 0.35+

=head1 SEE ALSO

L<IO::Socket::Socks>, L<IO::Socket::Socks::Wrapped>

=head1 COPYRIGHT

Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
