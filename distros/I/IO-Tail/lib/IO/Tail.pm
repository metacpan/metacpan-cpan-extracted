## ----------------------------------------------------------------------------
#  IO::Tail
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package IO::Tail;
use strict;
use warnings;

use IO::Poll qw(POLLIN POLLERR POLLHUP POLLNVAL);
our $SEEK_SET = 0;
our $SEEK_END = 2;
our $POLL_FLAGS = POLLIN | POLLERR | POLLHUP | POLLNVAL;

our $VERSION = '0.01';

1;


=begin COMMENT

format for an item of IO::Tail.

$type is one of "handle", "file", "timeout", "interval".

common case:

	my $item = {
		type     => $type,
		name     => $name, # e.g. "$type:$obj".
		callback => $callback,
		buffer   => '',
		_read    => \&_read_handle,
	};

when type is "handle":

	my $item = {
		type     => 'handle',
		name     => "handle:$handle",
		handle   => $handle,
		callback => $callback,
		buffer   => '',
		_read => \&_read_handle,
	};

when type is "file":

	my $item = {
		type     => 'file',
		name     => $file,
		handle   => $fh,
		pos      => $pos,
		callback => $callback,
		buffer   => '',
		_read => \&_read_file,
	};

when type is "timeout":

	my $item = {
		type     => 'timeout',
		name     => "timeout:$callback",
		interval => $timeout_secs,
		timeout  => $next_timeout,
		callback => $callback,
	};

when type is "interval":

	my $item = {
		type   => 'interval',
		name   => "interval:$callback",
		interval => $interval_secs,
		timeout  => $next_timeout,
		callback => $callback,
	};

=end COMMENT

=cut

# -----------------------------------------------------------------------------
# $pkg->new();
#
sub new
{
	my $pkg = shift;
	my $this = bless {}, $pkg;
	$this->{poll}    = undef;
	$this->{handles} = {};
	$this->{files}   = [];
	$this->{timeout} = {};
	
	$this;
}

# -----------------------------------------------------------------------------
# $tail->add($obj, $callback, $opts);
#
sub add
{
	my $this = shift;
	$this->_do('add', @_);
}

# -----------------------------------------------------------------------------
# $tail->remove($obj);
#
sub remove
{
	my $this = shift;
	$this->_do('remove', @_);
}

# -----------------------------------------------------------------------------
# $tail->_do($cmd, $obj, $callback, $opts);
#
sub _do
{
	my $this = shift;
	my $cmd  = shift;
	my $obj  = shift;
	
	$cmd =~ /^(?:add|remove)\z/ or die "_do: $cmd";
	my $type;
	if( UNIVERSAL::isa($obj, 'GLOB') )
	{
		$type = 'handle';
	}elsif( UNIVERSAL::isa($obj, 'HASH') )
	{
		$type = $obj->{type};
		unshift @_, $obj;
		$obj = $type =~ /^(file|handle)$/ ? $obj->{$type} : $obj->{callback};
	}else
	{
		$type = 'file';
	}
	my $subname = "${cmd}_${type}";
	my $sub = $this->can($subname) or die "_do: $subname";
	$this->$sub($obj, @_);
}

# -----------------------------------------------------------------------------
# $tail->add_handle($handle, $callback, $opts);
#
sub add_handle
{
	my $this     = shift;
	my $handle   = shift;
	my $callback = shift;
	my $opts     = shift;
	
	my $poll = $this->{poll} ||= IO::Poll->new();
	$handle->blocking(0);
	$poll->mask($handle, POLLIN);
	
	my $item = {
		type     => 'handle',
		name     => "handle:$handle",
		handle   => $handle,
		callback => $callback,
		buffer   => '',
		_read => \&_read_handle,
	};
	$this->{handles}{$handle} = $item;
	
	$this;
}

# -----------------------------------------------------------------------------
# $tail->remove_handle($handle);
#
sub remove_handle
{
	my $this   = shift;
	my $handle = shift;
	if( my $item = delete $this->{handles}{$handle} )
	{
		my $poll = $this->{poll};
		$poll->remove($handle);
		delete $this->{handles}{$handle};
		
		if( keys %{$this->{handles}}==0 )
		{
			$this->{poll} = undef;
		}
	}
	$this;
}

# -----------------------------------------------------------------------------
# $tail->_read_handle($item);
#
sub _read_handle
{
	my $this = shift;
	my $item = shift;
	my $handle = $item->{handle};
	READ:{
		my $len = sysread($handle, $item->{buffer}, 1024, length $item->{buffer});
		if( $len )
		{
			my $ret = $this->_callback_read($item);
			$ret or return; # quit.
			redo READ;
		}
		if( defined($len) )
		{
			# eof.
			return;
		}
		$!{EAGAIN} and last READ;
		die "sysread: $item->{name}: $!";
	}
	1;
}

# -----------------------------------------------------------------------------
# $tail->add_file($file, $callback, $opts);
#
sub add_file
{
	my $this = shift;
	my $file = shift;
	my $callback = shift;
	my $opts     = shift;
	
	if( $file eq '-' )
	{
		return $this->add_handle(\*STDIN, $callback, @_);
	}
	
	open(my $fh, '<', $file) or die "$file: $!";
	my $pos = sysseek($fh, 0, $SEEK_END) || 0;
	my $item = {
		type     => 'file',
		name     => $file,
		handle   => $fh,
		pos      => $pos,
		callback => $callback,
		buffer   => '',
		_read => \&_read_file,
	};
	push(@{$this->{files}}, $item);
	
	$this;
}

# -----------------------------------------------------------------------------
# $tail->remove_file($file);
#
sub remove_file
{
	my $this   = shift;
	my $file = shift;
	
	if( $file eq '-' )
	{
		return $this->remove_handle(\*STDIN, @_);
	}
	
	my $files = $this->{files};
	foreach my $item (@$files)
	{
		$item->{name} eq $file or next;
		$item = undef;
	}
	@$files = grep {$_} @$files;
	$this;
}

# -----------------------------------------------------------------------------
# $tail->_read_file($item);
#
sub _read_file
{
	my $this = shift;
	my $item = shift;
	
	my $pos = sysseek($item->{handle}, 0, $SEEK_END);
	defined($pos) or die "sysseek: $item->{name}: $!";
	if( $pos==$item->{pos} )
	{
		return 1;
	}
	sysseek($item->{handle}, $item->{pos}, $SEEK_SET);
	
	my $len = sysread($item->{handle}, $item->{buffer}, $pos-$item->{pos}, length $item->{buffer});
	$item->{pos} = $pos;
	if( $len )
	{
		my $ret = $this->_callback_read($item);
		$ret or return; # quit.
	}elsif( defined($len) )
	{
		# eof.
		return;
	}else
	{
		$!{EAGAIN} and last READ;
		die "sysread: $item->{name}: $!";
	}
	1;
}

# -----------------------------------------------------------------------------
# $tail->add_timeout($callback, $timeout_secs, $opts);
#
sub add_timeout
{
	my $this = shift;
	my $callback = shift;
	my $timeout_secs = shift;
	my $opts = shift;
	
	my $next_timeout = time + $timeout_secs;
	my $item = {
		type     => 'timeout',
		name     => "timeout:$callback",
		interval => $timeout_secs,
		timeout  => $next_timeout,
		callback => $callback,
	};
	$this->{timeout}{$item} = $item;
	$this;
}

# -----------------------------------------------------------------------------
# $tail->remove_timeout($callback);
#
sub remove_timeout
{
	my $this     = shift;
	my $callback = shift;
	my $timeout = $this->{timeout};
	foreach my $item (values %$timeout)
	{
		$item->{callback} eq $callback or next;
		delete $timeout->{$item};
	}
	$this;
}

# -----------------------------------------------------------------------------
# $tail->add_interval($callback, $interval_secs, $opts);
#
sub add_interval
{
	my $this = shift;
	my $callback = shift;
	my $interval_secs = shift;
	my $opts = shift;
	
	my $next_timeout = time + $interval_secs;
	my $item = {
		type   => 'interval',
		name   => "interval:$callback",
		interval => $interval_secs,
		timeout  => $next_timeout,
		callback => $callback,
	};
	$this->{timeout}{$item} = $item;
	$this;
}

# -----------------------------------------------------------------------------
# $tail->remove_interval($callback);
#
sub remove_interval
{
	my $this     = shift;
	my $callback = shift;
	my $timeout = $this->{timeout};
	foreach my $item (values %$timeout)
	{
		$item->{callback} eq $callback or next;
		delete $timeout->{$item};
	}
	$this;
}

# -----------------------------------------------------------------------------
# $tail->_callback_read($item) @ private.
#
sub _callback_read
{
	my $this = shift;
	my $item = shift;
	scalar $item->{callback}->(\$item->{buffer}, undef, $item->{args}, $item);
}

# -----------------------------------------------------------------------------
# $tail->_callback_eof($item) @ private.
#
sub _callback_eof
{
	my $this = shift;
	my $item = shift;
	$item && $item->{callback} or return;
	scalar $item->{callback}->(\$item->{buffer}, 'eof', $item->{args}, $item);
}

# -----------------------------------------------------------------------------
# $tail->check();
#
sub check
{
	my $this = shift;
	
	# check_handles.
	if( my $poll = $this->{poll} )
	{
		my $ev = $poll->poll(0);
		$ev==-1 and die "poll: $!";
		foreach my $handle ($poll->handles($POLL_FLAGS))
		{
			my $item = $this->{handles}{$handle};
			my $ret = $item->{_read}->($this, $item);
			if( !$ret )
			{
				$this->_callback_eof($item);
				$poll->remove($handle);
				delete $this->{handles}{$handle};
			}
		}
		if( keys %{$this->{handles}}==0 )
		{
			$this->{poll} = undef;
		}
	}
	
	# check files.
	if( my $files = $this->{files} )
	{
		foreach my $item (@$files)
		{
			my $ret = $item->{_read}->($this, $item);
			if( !$ret )
			{
				$this->_callback_eof($item);
				$item = undef;
			}
		}
		@$files = grep {$_} @$files;
	}
	
	# check timeouts and intervals.
	if( my $timeout = $this->{timeout} )
	{
		my $now = time;
		foreach my $item (values %$timeout)
		{
			if( $now > $item->{timeout} )
			{
				$item->{callback}->(undef, undef, $item->{args}, $item);
				if( $item->{type} eq 'interval' )
				{
					$item->{timeout} = $now + $item->{interval};
				}else
				{
					delete $timeout->{$item};
				}
			}
		}
	}
	
	($this->{poll} || @{$this->{files}} || keys %{$this->{timeout}}) && 1;
}

# -----------------------------------------------------------------------------
# $tail->loop();
#
sub loop
{
	my $this = shift;
	my $timeout_secs = shift;
	my $enter_at = time;
	
	while( $this->check() )
	{
		if( defined($timeout_secs) && time - $enter_at > $timeout_secs )
		{
			last;
		}
		select(undef,undef,undef,0.1);
	}
}


# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

IO::Tail - follow the tail of files/stream

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 use IO::Tail;
 my $tail = IO::Tail->new();
 $tail->add(\*STDIN, \&callback);
 $tail->add('test.log', \&callback);
 $tail->check();
 $tail->loop();

=head1 EXPORT

No functions are exported.

=head1 METHODS

=head2 $pkg->new()

=head2 $pkg->add($obj, $callback);

=head2 $pkg->remove($obj);

=head2 $pkg->check();

=head2 $pkg->loop();

=head2 $pkg->add_handle($handle, $callback);

=head2 $pkg->remove_handle($handle);

=head2 $pkg->add_file($file, $callback);

=head2 $pkg->remove_file($file);

=head2 $pkg->add_timeout($callback, $timeout_secs);

=head2 $pkg->remove_timeout($callback);

=head2 $pkg->add_interval($callback, $interval_secs);

=head2 $pkg->remove_interval($callback);

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-io-tail at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Tail>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Tail

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Tail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Tail>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Tail>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Tail>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IO::Tail
