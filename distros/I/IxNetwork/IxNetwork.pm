#!/usr/bin/perl 
use strict;
use Fcntl;
use Socket;
use File::stat;
use File::Basename;
use IO::Socket;

package IxNetwork;

our $VERSION = '8.40';

=head1 SYNOPSIS
IxNetwork is the Perl package for the IxNetwork Low Level API that allows you to configure and run IxNetwork tests.

=head1 IMPORTANT LINKS

=over 4

=item * L<https://github.com/ixiacom/ixnetwork-api-pl>

=cut

sub new
{
    my $class = shift;
    my $self = {
        _root => '::ixNet::OBJ-/',
        _null => '::ixNet::OBJ-null',
        _socket => undef,
        _proxySocket => undef,
        _connectTokens => undef,
        _evalError => '1',
        _evalSuccess => '0',
        _evalResult => '0',
        _addContentSeparator => 0,
        _firstItem => undef,
        _sendContent => '',
        _buffer => undef,
        _sendBuffer => '',
        _decoratedResult => '',
        _filename => '',
        _debug => undef,
        _async => undef,
        _timeout => undef,
        _OK => '::ixNet::OK',
        _version => '8.40.1123.47'
    };
    bless $self, $class;
    return $self;
}

sub setDebug
{
    my($self, $debug) = @_;
    if ($_[1]) {
        $self->{_debug} = 1;
    } else {
        $self->{_debug} = undef;
    }
}

sub getRoot
{
    my($self) = @_;
    return $self->{_root};
}

sub getNull
{
    my($self) = @_;
    return $self->{_null};
}

sub setAsync
{
    my($self) = @_;
    $self->{_async} = '1';
    return $self;
}

sub setTimeout
{
    my($self, $timeout) = @_;
    if (defined $timeout)
    {
        $self->{_timeout} = $timeout;
    }
    else
    {
        die "A timeout value must be provided\n";
    }
    return $self;
}

sub connect {
    my($self) = @_;
    my $address = $_[1];
    my @args = @_[1..scalar(@_) - 1];
    
    if (defined $self->{_socket}) {
        eval {
            $self->_SendRecv('ixNet', 'help');
        };
        if ($@) {
            $self->_Close();
        }
    }
    
    my %nameValuePairs = (
        '-port' => '8009',
        '-closeServerOnDisconnect' => 'true',
        '-clientType' => 'perl',
        '-clientusername' => getlogin()
    );
    my $name = undef;
    foreach my $arg (@args) {
        if (index($arg, '-', 0) == 0 and not defined $name) {
            $name = $arg;
        } elsif (defined $name) {
            $nameValuePairs{$name} = $arg;
            $name = undef;
        }
    }

    my $options = '';
    foreach my $name (keys(%nameValuePairs)) {
        if ($name ne '-port') {
            $options .= $name.' '.$nameValuePairs{$name}.' ';
        }
    }

    if (not defined $self->{_socket}) {
        eval {
            $self->_InitialConnect($address, $nameValuePairs{'-port'}, $options);
        };
        if($@) {
            die "Unable to connect to host:$address port:$nameValuePairs{'-port'} $@\n";
        } else {
        	my $conRes = $self->_SendRecv('ixNet', 'connect', $address, split(/ /, $options));
        	$self->_CheckClientVersion();
            return $conRes;
        }
    } else {
        my $sockInfo = getpeername($self->{_socket});
        (my $peerPort, my $peerAddress) = Socket::sockaddr_in($sockInfo);
        $peerAddress = Socket::inet_ntoa($peerAddress);
        return 'Cannot connect to '.$address.':'.$nameValuePairs{'-port'}.' as a connection is already established to '.$peerAddress.':'.$peerPort.'. Please execute disconnect before trying this command again.';
    }
}

sub disconnect {
    my($self) = @_;
    $self->_Close();
}

sub help {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'help', @args);
}

sub setSessionParameter {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    
    if (scalar(@args) % 2 == 0) {
        return $self->_SendRecv('ixNet', 'setSessionParameter', @args);
    } else {
        die "setSessionParameter requires an even number of name/value pairs\n";
    }
}

sub getVersion {
    my($self) = @_;

    if (not defined $self->{_socket}) {
        return $self->{_version};
    } else {
        return $self->_SendRecv('ixNet', 'getVersion');
    }
}

sub getParent {
    my($self) = @_;

    return $self->_SendRecv('ixNet', 'getParent', $_[1]);
}

sub exists {
    my($self) = @_;

    return $self->_SendRecv('ixNet', 'exists', $_[1]);
}

sub commit {
    my($self) = @_;

    return $self->_SendRecv('ixNet', 'commit');
}

sub rollback {
    my($self) = @_;

    return $self->_SendRecv('ixNet', 'rollback');
}

sub execute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'exec', @args);
}

sub add {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'add', @args);
}

sub remove {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'remove', @args);
}

sub setAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    $self->{_buffer} = 1;
    
    return$self->_SendRecv('ixNet', 'setAttribute', @args);
}

sub setMultiAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    $self->{_buffer} = 1;

    return $self->_SendRecv('ixNet', 'setMultiAttribute', @args);
}

sub getAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'getAttribute', @args)
}

sub getList {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'getList', @args);
}

sub getFilteredList {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'getFilteredList', @args);
}

sub adjustIndexes {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'adjustIndexes', @args);
}

sub remapIds {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'remapIds', @args);
}

sub getResult {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'getResult', @args);
}

sub wait {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'wait', @args);
}

sub isDone
{
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'isDone', @args);
}

sub isSuccess {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'isSuccess', @args);
}

sub xpath {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_SendRecv('ixNet', 'xpath', @args);
}

sub writeTo {
    my($self) = @_;
    my $filename = $_[1];
    my @args = @_[2..scalar(@_) - 1];

    my $relativeFile = 0;
    for (@args) {
        if ($_ eq '-ixNetRelative') {
            $relativeFile = 1;
            last;
        }
    }
    if ($relativeFile) {
        return $self->_SendRecv('ixNet', 'writeTo', $filename, @args);
    } else {
        return $self->_CreateFileOnServer($filename);
    }
}

sub readFrom {
    my($self) = @_;
    my $filename = $_[1];
    my @args = @_[2..scalar(@_) - 1];

    my $relativeFile = 0;
    for (@args) {
        if ($_ eq '-ixNetRelative') {
            $relativeFile = 1;
            last;
        }
    }
    if ($relativeFile) {
        return $self->_SendRecv('ixNet', 'readFrom', $filename, @args);
    } else {
        return $self->_PutFileOnServer($filename);
    }
}

sub _PutFileOnServer {
    my($self) = @_;
    my $filename = $_[1];
    my $fid = undef;
    
    my $truncatedFilename = File::Basename::fileparse($filename);
    my $fileStat = File::stat::stat($filename);
    open($fid, '<:raw', $filename) or die "Unable to open file $filename; please check that the file exists\n";
    my $fileSize = $fileStat->size();
    $self->_Send(sprintf("<001><005><007%d>%s<009%d>", length($truncatedFilename), $truncatedFilename, $fileSize));
    my $fileContents = '';
    my $readSize = read($fid, $fileContents, $fileSize);
    $self->_SendBinary($fileContents);
    close($fid);
    my $remoteFilename = $self->_Recv();

    return $self->_SendRecv('ixNet', 'readFrom', $remoteFilename, '-ixNetRelative');
}

sub _CreateFileOnServer {
    my($self) = @_;
    my $filename = $_[1];

    $self->_Send(sprintf("<001><006><007%d>%s<009>", length($filename), $filename));
    my $remoteFilename = $self->_Recv();

    return $self->_SendRecv('ixNet', 'writeTo', $remoteFilename, '-ixNetRelative', '-overwrite')
}

sub _InitialConnect {
    my($self) = @_;
    my $address = $_[1];
    my $port = $_[2];
    my $options = $_[3];
    
    # make an initial socket connection
    # this will keep trying as it could be connecting to the proxy
    # which may not have an available application instance at that time
    my $attempts = 0;
    while(1)
    {
        eval {
            my $protocol = getprotobyname('tcp');
            socket($self->{_socket}, Socket::AF_INET, Socket::SOCK_STREAM, $protocol);

            my $inetAddress = gethostbyname($address);
            my $sockAddress = Socket::sockaddr_in($port, $inetAddress);
            CORE::connect($self->{_socket}, $sockAddress);

            last;
        };
        if ($@) {
            if ((defined $self->{_proxySocket}) && $attempts < 120) {
                sleep(2);
                $attempts++;
            } else {
                $self->_Close();
                die "$@\n";
            }
        };
    }
    
    ## a socket connection has been made now read the type of connection
    ## setup to timeout if the remote endpoint is not valid
    my $sock = $self->{_socket};
    $self->{_socket}->blocking(0);
    my $rin = '';
    vec($rin, fileno($sock), 1) = 1;
    my $timeout = 30;
    my $nfound = select(my $rout = $rin, undef, undef, $timeout);
    if ($nfound == 0)
    {
        $self->_Close();
        die "Connection handshake timed out after $timeout seconds\n";
    }
    $sock->blocking(1);

    my $connectString = $self->_Recv();
    if($connectString eq 'proxy') {
        $self->{_socket}->write($options);
        $self->{_socket}->flush();
        $self->{_connectTokens} = $self->_Recv();
        my %connectTokens = split(/ /, $self->{_connectTokens});
        $self->{_proxySocket} = $self->{_socket};
        $self->{_socket} = undef;
        $self->_InitialConnect($address, $connectTokens{-port}, '');
    }
}

sub _Close {
    my($self) = @_;
    
    eval {
        if (defined $self->{_socket}) {
            close($self->{_socket});
            $self->{_socket} = undef;
        }
        if (defined $self->{_proxySocket}) {
            close($self->{_proxySocket});
            $self->{_proxySocket} = undef;
        }
    }
}

sub _Join {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    
    foreach my $arg (@args) {
        if (ref($arg) eq 'ARRAY') {
            if ($self->{_addContentSeparator} == 0) {
                $self->{_sendContent} .= chr(0x02);
            }
            if ($self->{_addContentSeparator} > 0) {
                $self->{_sendContent} .= '{';
            }
            $self->{_addContentSeparator} += 1;
            $self->{_firstItem} = 1;
            if (scalar(@$arg) == 0) {
                $self->{_sendContent} .= '{}';
            } else {
                foreach my $item ($arg) {
                    $self->_Join(@$item);
                }
            }
            if ($self->{_addContentSeparator} > 1) {
                $self->{_sendContent} .= '}';
            }
            $self->{_addContentSeparator} -= 1;
        } else {
            if ($self->{_addContentSeparator} == 0 and length($self->{_sendContent}) > 0) {
                $self->{_sendContent} .= chr(0x02);
            } elsif ($self->{_addContentSeparator} > 0) {
                if (not defined $self->{_firstItem}) {
                    $self->{_sendContent} .= ' ';
                } else {
                    $self->{_firstItem} = undef;
                }
            }
            if (not defined $arg) {
                $arg = '';
            }
            if (length($arg) == 0 and length($self->{_sendContent}) > 0) {
                $self->{_sendContent} .= '{}';
            } elsif (index($arg, ' ') != -1 and $self->{_addContentSeparator} > 0) {
                $self->{_sendContent} .= "{$arg}";
            } else {
                $self->{_sendContent} .= $arg;
            }
        }
    }
}

sub _SendRecv {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    $self->{_addContentSeparator} = undef;
    $self->{_firstItem} = 1;

    my @argList = @args;

    if (defined $self->{_async}) {
        splice(@argList, 1, 0, '-async');
    }
    
    if (defined $self->{_timeout}) {
        splice(@argList, 1, 0, $self->{_timeout});
        splice(@argList, 1, 0, '-timeout');
    }
    
    foreach my $arg (@argList) {
        $self->_Join($arg);
    }
    
    $self->{_sendBuffer} .= $self->{_sendContent}.chr(0x03);
    if (not defined $self->{_buffer}) {
        if (defined $self->{_debug}) {
            print 'Sending: '.$self->{_sendBuffer}.chr(0x0a);
        }
        $self->_Send(sprintf("<001><002><009%d>%s", length($self->{_sendBuffer}), $self->{_sendBuffer}));
        $self->{_sendBuffer} = '';
    }
    
    $self->{_async} = undef;
    $self->{_timeout} = undef;
    $self->{_buffer} = undef;
    $self->{_sendContent} = '';

    if (length($self->{_sendBuffer}) > 0) {
        return $self->{_OK};
    } else {
        return $self->_Recv();
    }
}

sub _Send {
    my($self) = @_;
    my $content = $_[1];
    
    if (not defined $self->{_socket}) {
        die "not connected\n";
    } else {
        eval {
            binmode($self->{_socket}, ":raw"); 
            $self->{_socket}->write($content);
            $self->{_socket}->flush();
        };
        if($@) {
            die "$@\n";
        }
    }
}

sub _SendBinary {
    my($self) = @_;
    my $content = $_[1];

    if (not defined $self->{_socket}) {
        die "not connected\n";
    } else {
        eval {
            binmode($self->{_socket}, ":raw"); 
            $self->{_socket}->write($content);
            $self->{_socket}->flush();
            #binmode($self->{_socket}, ":crlf"); 
        };
        if($@) {
            die "$@\n";
        }
    }
}

sub _Recv {
    my($self) = @_;
    $self->{_decoratedResult} = '';
    my $responseBuffer = '';
    eval {
        while(1) {
            $responseBuffer = '';
            my $commandId = undef;
            my $contentLength = int(0);

            while(1) {
                my $buffer = '';
                $self->{_socket}->read($buffer, 1);
                if (length($buffer) == 0) {
                    die "Socket connection is closed\n";
                }
                $responseBuffer .= $buffer;
                my $startIndex = index($responseBuffer, '<');
                my $stopIndex = index($responseBuffer, '>');
                if ($startIndex != -1 && $stopIndex != -1) {
                    $commandId = substr($responseBuffer, $startIndex + 1, $startIndex + 3);
                    if ($startIndex + 4 < $stopIndex) {
                        $contentLength = int(substr($responseBuffer, $startIndex + 4, $stopIndex));
                    }
                    last;
                }
            }

            if ($commandId == 1) {
                my $buffer = '';
                $self->{_evalResult} = $self->{_evalError};
                $self->{_socket}->read($buffer, $contentLength);
            } elsif ($commandId == 3) {
                my $buffer = '';
                $self->{_socket}->read($buffer, $contentLength);
            } elsif ($commandId == 4) {
                $self->{_socket}->read($self->{_evalResult}, $contentLength);
            } elsif ($commandId == 7) {
                $self->{_socket}->read($self->{_filename}, $contentLength);
            } elsif ($commandId == 8) {
                open(my $binaryFile, '>:raw', $self->{_filename});
                my $chunk = '';
                my $bytesToRead = 32767;
                while ($contentLength > 0) {
                    if ($contentLength < $bytesToRead) {
                        $bytesToRead = $contentLength;
                    }
                    $self->{_socket}->read($chunk, $bytesToRead);
                    $binaryFile->write($chunk);
                    $contentLength -= length($chunk);
                }
                $binaryFile->close();
            } elsif ($commandId == 9) {
                $self->{_decoratedResult} = '';
                my $chunk = '';
                my $bytesToRead = 32767;
                while($contentLength > 0) {
                    if ($contentLength < $bytesToRead) {
                        $bytesToRead = $contentLength;
                    }
                    $self->{_socket}->read($chunk, $bytesToRead);
                    $self->{_decoratedResult} .= $chunk;
                    $contentLength -= length($chunk);
                }
                last;
            }
        }
    };
    if ($@) {
        $self->_Close();
        die "$@\n";
    }
    
    if (defined $self->{_debug}) {
        print 'Received: '.$self->{_decoratedResult}.chr(0x0a);
    }
    
    if ($self->{_evalResult} eq $self->{_evalError}) {
        die "$self->{_decoratedResult}\n";
    }
    
    if (index($self->{_decoratedResult}, '(') == 0) {
        my @array;
        eval '@array = '.$self->{_decoratedResult};
        return @array;
    } else {
        return $self->{_decoratedResult};
    }
}

sub _CheckClientVersion {
	my($self) = @_;
    if ($self->{_version} ne $self->getVersion()) {
        print("WARNING: IxNetwork Perl library version ".$self->{_version}." is not matching the IxNetwork client version ".$self->getVersion()."\n");
    }
}

1;