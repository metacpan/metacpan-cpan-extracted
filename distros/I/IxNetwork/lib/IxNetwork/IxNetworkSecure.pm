#!/usr/bin/perl
#
# Copyright 1997 - 2019 by IXIA Keysight
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict;
use File::Basename;
use File::stat;
use File::Spec;
use File::Path;
use IO::Socket::INET;
use Scalar::Util qw( blessed );
our $SSL_ERROR;
my $dependenciespath;
my $libraryFilePath;
BEGIN {
    my ($volume, $directory, $file) = File::Spec->splitpath(__FILE__);
    $libraryFilePath = File::Spec->rel2abs($directory);
    $directory = File::Spec->catdir( (File::Spec->rel2abs($directory), 'dependencies') );
    $dependenciespath = $directory;
}
use lib $dependenciespath;
use IO::Socket::SSL;
use LWP::UserAgent;
use Protocol::WebSocket::Client;
use JSON::PP;
use URI::Escape;
use constant NL => "\r\n";

package IxNetworkSecure;

=head1 new
=cut
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_setDefaults();
    $self->{_debug} = undef;
    return $self;
}

sub _setDefaults {
    my $self = shift;

    $self->{_websocket} = undef;
    $self->{_evalError} = '1';
    $self->{_evalSuccess} = '0';
    $self->{_evalResult} = '0';
    $self->{_addContentSeparator} = 0;
    $self->{_firstItem} = undef;
    $self->{_sendContent} = '';
    $self->{_buffer} = undef;                       
    $self->{_sendBuffer} = '';
    $self->{_decoratedResult} = '';                 
    $self->{_async} = undef;                        
    $self->{_timeout} = undef;
    $self->{_serverPayloadSize}= 65535;
    $self->{_transportType} = 'WebSocket';     
    $self->{_OK} = '::ixNet::OK';
    $self->{_ERROR} = '::ixNet::ERROR';
    $self->{_version} = '9.00.1915.16';
    $self->{_noApiKey} = '00000000000000000000000000000000';
    $self->{_connectionInfo} = {
        port => undef,
        verb => undef,
        wsVerb => undef,
        hostname => undef,
        url => undef,
        sessionUrl => undef,
        restUrl => undef,
        wsUrl => undef,
        sessionId => undef,
        backendType => undef,
        applicationType => undef,
        closeServerOnDisconnect => undef,
        serverUsername => undef
    };
    $self->{_initialPort} = undef;
    $self->{_initialHostname} = undef;
}

sub setDebug {
    my($self, $debug) = @_;
    if ($debug) {
        $self->{_debug} = 1;
    } else {
        $self->{_debug} = undef;
    }
}

sub getRoot {
    my($self) = @_;
    return '::ixNet::OBJ-/';
}

sub getNull {
    my($self) = @_;
    return '::ixNet::OBJ-null';
}

sub setAsync {
    my($self) = @_;
    $self->{_async} = '1';
    return $self;
}

sub setTimeout {
    my($self, $timeout) = @_;
    if (defined $timeout) {
        $self->{_timeout} = $timeout;
    } else {
        die "A timeout value must be provided.\n";
    }
    return $self;
}

sub getApiKey {
    my ($self) = shift;
    my ($hostname) = shift;

    my %defaultArgs = (
        -apiKeyFile => 'api.key',
        -port => 443
    );

    my $sessionArgs = $self->_get_arg_map(\%defaultArgs, @_);
    my $port = $sessionArgs->{-port};
    my $apiKeyFile = $sessionArgs->{-apiKeyFile};

    if (!$self->_isConnected()) {
        $self->_createHeaders();
    }

    my $username = '';
    my $password = '';
    if ((!exists $sessionArgs->{-username}) or (!exists $sessionArgs->{-password})) {
        if (scalar(@_) >= 2) {
            $username = @_[0];
            $password = @_[1];
        }
    } else {
        $username = $sessionArgs->{-username};
        $password = $sessionArgs->{-password};
    }
    my $auth = '';
    my $ret = eval {
        $auth = $self->_restSend('POST', 'https://'.$hostname.':'.$port.'/api/v1/auth/session', {'username' => $username, 'password' => $password}, 180);
        1;
    };

    if (!$ret and $@ or !$auth) {
        if ($@ =~ /IxNetAuthenticationError/) {
            my $msg = 'Unable to get API key from '.$hostname.':'.$port.'. Error: '.$@."\n";
            $msg .= "Please check the getApiKey command arguments.\n";
            $msg .= "An example of a correct method call is:\n\t";
            $msg .= '$ixNet->getApiKey(<hostname>, "-username", <username>, "-password", <password> [,"-port", <443>] [, "-apiKeyFile", <api.key>])';
            die $msg."\n";        
        } else {
            die 'Unable to get API key from '.$hostname.':'.$port."\n";
        }
     }

    my $apiKeyPath = '';
    if (!File::Spec->file_name_is_absolute($apiKeyFile)) {
        my $cwdFilePath = File::Spec->rel2abs($apiKeyFile);
        $apiKeyPath = $self->_tryWriteAPIKey($cwdFilePath, $auth->{apiKey}); 
        if (not defined $apiKeyPath) { 
            $apiKeyPath = $self->_tryWriteAPIKey(File::Spec->rel2abs($apiKeyFile, $libraryFilePath), $auth->{apiKey});
        }
    } else {
        $apiKeyPath = $self->_tryWriteAPIKey($apiKeyFile, $auth->{apiKey});
    }

    if ($apiKeyPath) {
        $self->_log("The API key was saved at: $apiKeyPath\n");
    } else {
        $self->_log("Could not save API key to disk.\n");
    }

    return $auth->{apiKey};
}

sub getSessions {
    my($self) = shift;
    my ($hostname) = shift;

    my $baseURL = '';
    my $port = undef;
    if (!$self->_isConnected()) {
        if (!$self->{_connectionInfo}->{url}) {
            my %defaultArgs = (
                -apiKey => '',
                -apiKeyFile => 'api.key',
                -port => 443
            );
            my $sessionArgs = $self->_get_arg_map(\%defaultArgs, @_);
            $self->_createHeaders($sessionArgs->{-apiKey}, $sessionArgs->{-apiKeyFile});
            $baseURL = $self->_getBaseURL($hostname, $sessionArgs);
            $port = $sessionArgs->{-port};
        } else {
            $baseURL = $self->{_connectionInfo}->{url};
            $port = $self->{_connectionInfo}->{port}
        }
    } else {
        my %defaultArgs = (
            -port => 443
        );
        my $sessionArgs = $self->_get_arg_map(\%defaultArgs, @_);
        $port = $sessionArgs->{-port};
        $baseURL = $self->{_connectionInfo}->{url};

        if (($hostname ne $self->{_initialHostname} and $hostname ne $self->{_connectionInfo}->{hostname}) or
            ($port ne $self->{_initialPort} and $port ne $self->{_connectionInfo}->{port})) {
            die "A connection has already been established to ".$self->{_connectionInfo}->{hostname}.":".$self->{_connectionInfo}->{port}.". In order to query ".$hostname.":".$port." you must first disconnect.\n";
        }
    }

    my @response = ();
    my $response_ref = $self->_restSend('GET', $baseURL);
    if (ref($response_ref) ne 'ARRAY') {
        @response = ($response_ref);
    } else {
        @response = @$response_ref;
    }

    my @sessions = ();
    foreach my $session (@response) {
        if ((lc $session->{applicationType} eq 'ixnrest') or (lc $self->_tryGetAttr($session, 'backendType', 'LinuxAPIServer' eq 'ixnetwork'))) {
            push(@sessions, $self->_getDetailedSessionInfo($session, $baseURL, $port))
        }
    }
    
    return @sessions;
}

sub getSessionInfo {
    my($self) = shift;
    $self->_isConnected(1);
    my $session = $self->_restSend('GET', $self->{_connectionInfo}->{sessionUrl});
    return $self->_getDetailedSessionInfo($session);
}

sub clearSessions {
    my ($self) = shift;
    my ($hostname) = shift;

    my @deleted_sessions = ();
    my @sessions = $self->getSessions($hostname, @_);
    foreach my $session (@sessions) {
        if (($session->{backendType} ne 'ixnetwork') and ($session->{state} eq 'active') and !$self->_parseAsBool($session->{inUse})) {
            $self->_cleanUpSession($session->{sessionUrl});
            push(@deleted_sessions, $session->{sessionUrl});
        }
    }
    return @deleted_sessions;
}

sub clearSession {
    my ($self) = shift;
    my ($hostname) = shift;

    my %defaultArgs = (
        -sessionId => '',
        -force => 0
    );
    my $operationArgs = $self->_get_arg_map(\%defaultArgs, @_);
    my $id = $operationArgs->{-sessionId};
    if (!$id) {
        die "IxNetError: A session ID must be provided in order to clear a specific session.\n";
    }

    my @sessions = $self->getSessions($hostname, @_);
    my $sessions = {};
    my $session = {};
    for my $s (@sessions) {
          $sessions->{$s->{id}} = $s;
    }

    if (!exists $sessions->{$id}) {
        my $enumeratedSessions = join(', ', keys(%{ $sessions }));
        die 'Session '.$id.' cannot be found in the list of sessions IDs: '.$enumeratedSessions;
    } else {
        $session = $sessions->{$id};
    }
    if ($operationArgs->{-force} and ($session->{state} eq 'initial')) {
        $self->_restSend('POST', $session->{sessionUrl}.'/operations/start');
        $self->_waitForState('active', $session->{sessionUrl});
        $self->_cleanUpSession($session->{sessionUrl});
        return $self->_OK;
    } elsif (($session->{state} eq 'active') and ($operationArgs->{-force} or !$self->_parseAsBool($session->{inUse}))) {
        if ($session->{backendType} eq 'ixnetwork') {
            return "Clearing IxNetwork standalone sessions is not supported.";
        } elsif ($self->_isConnected() and ($self->{_connectionInfo}->{sessionId} == $id)) {
            $self->{_connectionInfo}->{closeServerOnDisconnect} = 1;
            return $self->disconnect();
        } else {
            $self->_cleanUpSession($session->{sessionUrl});
            return $self->{_OK};
        }
    } elsif ($operationArgs->{-force} and ($session->{state} eq 'stopped')) {
        $self->_deleteSession($session->{sessionUrl});
        return $self->{_OK};
    }

    die 'Session '.$id.' cannot be cleared as it is currently in '.$session->{state}.' state. Please specify -force true if you want to forcefully clear in use sessions.';
}

sub _isConnected {
    my ($self, $raiseError) = @_;
    if (not defined $raiseError) {
        $raiseError = 0;
    }

    if (!defined($self->{_websocket})) {
        if ($raiseError) {
            die "not connected\n";
        } else {
            return 0; 
        } 
    } else {
        return 1;
    }
}

sub _get_arg_map {
    my $self = shift;
    my $default_args = shift;
    my $name = undef;
    foreach my $arg (@_) {
        if (index($arg, '-') == 0 && not defined $name) {
            $name = $arg;
        } elsif (defined $name) {
            $default_args->{$name} = $arg;
            $name = undef;
        }
    }

    return $default_args;
}

sub _restSend {
    my($self) = shift;
    my $method = shift;
    my $url = shift;
    my $payload = shift;
    my $timeout = do { my $arg = shift; defined($arg) ? $arg : 0 };
    my $json = JSON::PP->new->utf8;

    $self->_log("$method $url\n");

    my $response = undef;
    my $returnJson = 1;
    if (ref($payload) && defined $payload->{file_transfer}) {
        $returnJson = 0;
        if ($method eq 'GET') {
            $response = $self->{_user_agent}->mirror($url, $payload->{filename});
        } else {
            my $content = '';
            my $content_length = 0;
            if (defined $payload->{filename}) {
                open(my $fid, "<:raw", $payload->{filename});
                $content_length = File::stat::stat($payload->{filename})->size();
                read($fid, $content, $content_length);
                close $fid;
            } elsif (defined $payload->{file_content}) {
                $content = $json->encode($payload->{file_content});
                $content_length = length($content);
            }
            $response = $self->{_user_agent}->post($url,
                Content_Length => $content_length,
                Content_Type => 'application/octet-stream',
                Content => $content);
        }
    } else {
        my $request = new HTTP::Request($method => $url, ['Content_Type' => 'application/json']);

        if (defined $payload) {
            $request->content($json->encode($payload));
        }
        if ($timeout) {
            $self->{_user_agent}->timeout($timeout);
        }
        $response = $self->{_user_agent}->request($request);
    }

    $self->_log($response->code." ".$response->message."\n");
    
    if ($response->code == 204) {
        return undef;
    }

    if ($response->is_success) {
        if($returnJson) {
            # The opposite of encode: expects a JSON text and tries to parse it,
            # returning the resulting simple scalar or reference. Croaks on error.
            # JSON numbers and strings become simple Perl scalars. JSON arrays become
            # Perl arrayrefs and JSON objects become Perl hashrefs. true becomes 1 (JSON::true),
            # false becomes 0 (JSON::false) and null becomes undef.
            my $ret = eval {
                $response = $json->decode($response->decoded_content);
                1;
            };   
            if (!$ret and $@) {
                die "Connection handshake failed - invalid JSON response.\n";
            }
            return $response;
        } else {
            return $response->code;
        }
    } elsif ($response->code == 307) {
        if (($url =~ qr/(?<baseUrl>https?:\/\/[^\/]+:\d+)/) || ($url =~ qr/(?<baseUrl>https?:\/\/[^\/]+)/)) {
            $url = $+{baseUrl}.$response->header('Location');
        }
        return $self->_restSend($method, $url, $payload);
    } else {
        my $errorsText = '';
        my $ret = eval {
            my $errorsContent = $json->decode($response->decoded_content);
            if (exists $errorsContent->{error}) {
                $errorsText = $errorsContent->{error};
            } elsif (exists $errorsContent->{errors}) {
                $errorsText = join(', ', @{ $errorsContent->{errors} });
            }
            1;
        };
        if (!$ret and $@) {
            $errorsText = $response->message;
        }
        if (($response->code == 401) or ($response->code == 403)) {
            die 'IxNetAuthenticationError: '.$errorsText."\n";    
        } else {
            die $response->code." ".$errorsText."\n";    
        }        
    }
}

sub _createHeaders {
    my $self = shift;
    my $apiKey = do { my $arg = shift; defined($arg) ? $arg : '' };
    my $apiKeyFile = do { my $arg = shift; defined($arg) ? $arg : '' };

    my $apiKeyValue = $self->{_noApiKey};

    if ($apiKey) {
        $apiKeyValue = $apiKey;
    } elsif ($apiKeyFile) {
        my $apiKeyFile = $apiKeyFile;
        if (!File::Spec->file_name_is_absolute($apiKeyFile)) {
            my $cwdFilePath = File::Spec->rel2abs($apiKeyFile);
            $apiKeyValue = $self->_tryReadAPIKey($cwdFilePath);
            if (not defined $apiKeyValue) {
            $apiKeyValue = $self->_tryReadAPIKey(File::Spec->rel2abs($apiKeyFile, $libraryFilePath));
            }
        } else {
            $apiKeyValue = $self->_tryReadAPIKey($apiKeyFile);
        }
    }
    $self->{_user_agent} = new LWP::UserAgent();
    $self->{_user_agent}->protocols_allowed(['https', 'http']);
    $self->{_user_agent}->ssl_opts(verify_hostname => 0);
    $self->{_user_agent}->default_header('X-Api-Key' => $apiKeyValue);
    $self->{_user_agent}->default_header('IxNetwork-Lib' => 'IxNetwork perl client v.'.$self->{_version});
}

sub connect {
    my ($self) = shift;
    my ($hostname) = shift;

    my %defaultArgs = (
        -sessionId => 0,
        -clientId => 'perl',
        -version => '5.30',
        -connectTimeout => 450,
        -allowOnlyOneConnection => 0,
        -apiKey => '',
        -apiKeyFile => 'api.key',
        -product => 'ixnrest',
        -clientusername => getlogin(),
        -serverusername => ''
    );

    my $connectArgs = $self->_get_arg_map(\%defaultArgs, @_);
    $connectArgs->{-allowOnlyOneConnection} = $self->_parseAsBool($connectArgs->{-allowOnlyOneConnection});
    
    if ($self->_isConnected()) {
        my $port = 443;
        if (exists $connectArgs->{-port}) {
            $port = $connectArgs->{-port};
        }
        if (($hostname ne $self->{_initialHostname} and $hostname ne $self->{_connectionInfo}->{hostname}) or
            ($port ne $self->{_initialPort} and $port ne $self->{_connectionInfo}->{port})) {
            return "Cannot connect to ".$hostname.':'.$port." as a connection is already established to ".$self->{_connectionInfo}->{hostname}.':'.$self->{_connectionInfo}->{port}.". Please execute disconnect before trying this command again.";
        } elsif ($connectArgs->{-sessionId} and $connectArgs->{-sessionId} != $self->{_connectionInfo}->{sessionId}) {
            return "Cannot connect to session ".$connectArgs->{-sessionId}." as a connection is already established to session ".$self->{_connectionInfo}->{sessionId}.". Please execute disconnect before trying this command again.";
        } elsif ($connectArgs->{-serverusername} and $self->{_connectionInfo}->{backendType} ne 'ixnetwork' and $connectArgs->{-serverusername} ne $self->{_connectionInfo}->{serverUsername}) {
            return "Cannot connect to a session associated with ".$connectArgs->{-serverusername}." as a connection is already established to a session associated with ".$self->{_connectionInfo}->{serverUsername}.". Please execute disconnect before trying this command again.";
        } else {
            return $self->{_OK};
        }
    }

    $self->_createHeaders($connectArgs->{-apiKey}, $connectArgs->{-apiKeyFile});

    $self->_getBaseURL($hostname, $connectArgs, 1);
    my $result = undef;
    my $ret = eval {
        my $session = {};
        if (($connectArgs->{-sessionId}) < 1 and !$connectArgs->{-serverusername}) {
            $session = $self->_restSend('POST', $self->{_connectionInfo}->{url}, {applicationType => $connectArgs->{-product}}, $connectArgs->{-connectTimeout});
        } else {
            my @sessions = $self->getSessions($self->{_initialHostname}, @_);
            my $sessions = {};
            for my $s (@sessions) {
                $sessions->{$s->{id}} = $s;
            }
            if ($connectArgs->{-serverusername}) {
                my $matchedSessions = {};
                while(my($k, $v) = each %{ $sessions }) {
                    if ((lc $v->{userName}) eq (lc $connectArgs->{-serverusername})) {
                        $matchedSessions->{$k} = $v;
                    }
                }
                $sessions = $matchedSessions;
                if (keys %{ $sessions } == 0) {
                    die 'There are no sessions available with the serverusername '.$connectArgs->{-serverusername}."\n";
                }
                if ($connectArgs->{-sessionId} < 1) {
                    if (keys %{ $sessions } > 1) {
                        die 'There are multiple sessions available with the serverusername '.$connectArgs->{-serverusername}.'. Please specify -sessionId also.'."\n";
                    } else {
                        my @keys = keys %{ $sessions };
                        $connectArgs->{-sessionId} = @keys[0];
                    }
                }
            }
            if (!exists $sessions->{$connectArgs->{-sessionId}}) {
                die "Invalid sessionId value ($connectArgs->{-sessionId}).\n";
            }
            $session = $sessions->{$connectArgs->{-sessionId}};
            if ($session->{inUse} and (index($connectArgs->{-clientId}, 'HLAPI') == -1)) {
                if ((lc $self->_tryGetAttr($session, 'backendType', 'LinuxAPIServer') eq 'connectionmanager') or $connectArgs->{-allowOnlyOneConnection}) {
                    $self->{_connectionInfo}->{closeServerOnDisconnect} = 0;
                    die "The requested session is currently in use.\n";
                } else {
                    print 'Warning: you are connecting to session '.$session->{id}." which is in use.\n";
                }
            }
        }

        $self->{_connectionInfo}->{applicationType} = $session->{applicationType};
        if (!exists $connectArgs->{-closeServerOnDisconnect}) {
            if ($self->{_connectionInfo}->{applicationType} eq 'ixnrest') {
                $connectArgs->{-closeServerOnDisconnect} = 'true';
            } else {
                $connectArgs->{-closeServerOnDisconnect} = 'false';
            }
        } else {
            if ($self->_parseAsBool($connectArgs->{-closeServerOnDisconnect})) {
                $connectArgs->{-closeServerOnDisconnect} = 'true';
                } else {
                    $connectArgs->{-closeServerOnDisconnect} = 'false';
                }
        }
        $self->{_connectionInfo}->{closeServerOnDisconnect} = $self->_parseAsBool($connectArgs->{-closeServerOnDisconnect});
        $self->{_connectionInfo}->{sessionId} = $session->{id};
        $self->{_connectionInfo}->{sessionUrl} = $self->{_connectionInfo}->{url}.'/'.$self->{_connectionInfo}->{sessionId};
        $self->{_connectionInfo}->{backendType} = $self->_tryGetAttr($session, 'backendType', 'LinuxAPIServer');
        $self->{_connectionInfo}->{wsUrl} = $self->{_connectionInfo}->{wsVerb}.'://'.$self->{_connectionInfo}->{hostname}.':'.$self->{_connectionInfo}->{port}.'/ixnetworkweb/ixnrest/ws/api/v1/sessions/'.$self->{_connectionInfo}->{sessionId}.'/ixnetwork/globals/ixnet?closeServerOnDisconnect='.$self->{_connectionInfo}->{closeServerOnDisconnect}.'&clientType='.$connectArgs->{-clientId}.'&clientUsername='.$connectArgs->{'-clientusername'};
        $self->{_connectionInfo}->{restUrl} = $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork';
        $self->{_connectionInfo}->{serverUsername} = $session->{userName};

        if ((lc($session->{state}) eq 'initial') or (lc($session->{state}) eq 'stopped')) {
            $self->_restSend('POST', $self->{_connectionInfo}->{sessionUrl}.'/operations/start', {applicationType => $connectArgs->{-product}}, $connectArgs->{-connectTimeout});
        }
        $self->_waitForState('active', $self->{_connectionInfo}->{sessionUrl}, $connectArgs->{-connectTimeout});

        if ($self->_parseAsBool($connectArgs->{-allowOnlyOneConnection})) {
            $self->_isSessionAvailable($session, 1);
        }

        if ($self->{_connectionInfo}->{wsVerb} eq 'wss') {
            $self->{_websocket} = new IO::Socket::SSL(
            PeerHost => $self->{_connectionInfo}->{hostname}.':'.$self->{_connectionInfo}->{port},
            PeerPort => $self->{_connectionInfo}->{verb},
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE
            ) or die "IO::Socket::SSL reported: $! (ssl_error=$SSL_ERROR)";  
        } else {
            $self->{_websocket} = new IO::Socket::INET(
            PeerAddr => $self->{_connectionInfo}->{hostname}.':'.$self->{_connectionInfo}->{port},
            PeerPort => $self->{_connectionInfo}->{verb},
            ) or die "IO::Socket::INET reported: $!";  
        }
        
        $self->{_ws_client} = new Protocol::WebSocket::Client(url => $self->{_connectionInfo}->{wsUrl},  max_fragments_amount=> 10240, max_payload_size=> $self->{_serverPayloadSize});
        $self->{_ws_client}->on(write => sub {
            my ($ws) = shift;
            my $buffer = shift;
            $self->ws_write($ws, $buffer);
        });
        $self->{_ws_client}->on(read => sub {
            my ($ws) = shift;
            my $buffer = shift;
            $self->ws_read($ws, $buffer);
        });
        $self->{_ws_client}->connect;

        $result = $self->_send_recv('ixNet', 'connect',
            '-version', $connectArgs->{'-version'},
            '-clientType', 'perl',
            '-clientId', $connectArgs->{-clientId},
            '-clientUsername', $connectArgs->{'-clientusername'},
            '-closeServerOnDisconnect', $connectArgs->{-closeServerOnDisconnect} ,
            '-apiKey', $self->{_user_agent}{def_headers}{"x-api-key"});
        $self->_check_client_version();
        1;
    };
    if (!$ret and $@) {
        if ($self->{_connectionInfo}->{sessionUrl} and $self->{_connectionInfo}->{closeServerOnDisconnect}) {
            $self->_cleanUpSession($self->{_connectionInfo}->{sessionUrl});
        }
        $self->_close();
        $self->_deleteSession($self->{_connectionInfo}->{sessionUrl});
        my $failedConnectionPort;
        if (exists $connectArgs->{-port}) {
            $failedConnectionPort = $connectArgs->{-port};
        } else {
            $failedConnectionPort = 443;
        }
        $self->_setDefaults();
        die 'Unable to connect to '.$hostname.':'.$failedConnectionPort.'. Error: '.$self->{_ERROR}.': '.$@."\n";
    } else {
        return $result;
    }
}

sub ws_write {
    my ($self) = shift;
    my $ws = shift;
    my $buffer = shift;
    my $paddingSize = 4;
    $self->{_recvBuffer} = '';
    my $ret = eval {
        $self->{_websocket}->write($buffer);
        my $recv_buffer = '';

        while (1) {
            my $bytes = '';
        sysread($self->{_websocket}, $bytes, $self->{_serverPayloadSize});
            $recv_buffer .= $bytes;
            if (not $self->{_ws_client}->{hs}->is_done) {
                last;
            }
            my $startIndex = index($recv_buffer, '<009');
            my $stopIndex = index($recv_buffer, '>', $startIndex);
            if ($startIndex != -1 && $stopIndex != -1) {
            my $contentLength = int(substr($recv_buffer, $startIndex + $paddingSize, $stopIndex));
            if (length($recv_buffer) >= (($stopIndex + $contentLength +1 - $paddingSize) / $self->{_serverPayloadSize}) * ($self->{_serverPayloadSize} + $paddingSize)) {
                    last;
                }
            }
        }
    $self->{_ws_client}->read($recv_buffer);
 1;
    };
    if (!$ret and $@) {
        $self->_close();
        die 'Connection to the remote IxNetwork instance has been closed: '.$@."\n";
    }
}

sub ws_read {
    my ($self) = shift;
    my $ws = shift;
    $self->{_recvBuffer} = shift;
}

sub disconnect {
    my($self) = @_;

    if ($self->_isConnected()) {
        $self->_close();
        # bye bye $self->_cleanUpSession() forever
        #if ($self->{_connectionInfo}->{closeServerOnDisconnect}) {
        #    $self->_cleanUpSession($self->{_connectionInfo}->{sessionUrl});
        #}
        $self->_setDefaults();
        return $self->{_OK};
    } else {
        return "not connected";
    }
}

sub _cleanUpSession {
    my ($self, $url) = @_;
    
    eval {
        $self->_restSend('POST', $url.'/operations/stop');
        $self->_waitForState('stopped', $url);
    };
    $self->_deleteSession($url);
}

sub _deleteSession {
    my ($self, $url) = @_;

    eval {
        $self->_restSend('DELETE', $url);   
    };
}

sub _waitForState {
    my ($self, $state, $url, $timeout) = @_;

    if (not defined $timeout) {
        $timeout = 450;
    }

    my $startTime = time;
    my $sessionState = '';
    my $resp = {};

    while ((time - $startTime) < $timeout) {
        my $ret = eval {
            $resp = $self->_restSend('GET', $url);
            $sessionState = lc($resp->{state});
            1;
        };
        if (!$ret and $@) {
            $self->_log($@);
            die;
        }
        if (($sessionState eq $state) or ($state eq 'stopped' and ($sessionState eq 'initial' or $sessionState eq 'abnormallystopped'))) {
            return;
        } elsif (($state eq 'active' and ($sessionState eq 'stopped' or $sessionState eq 'stopping' or $sessionState eq 'abnormallystopped')) or 
            ($state eq 'stopped' and ($sessionState eq 'starting' or $sessionState eq 'active'))) {
            die 'Session '.$self->{_connectionInfo}->{id}.' was expected to reach state '.$state.'. It reached the invalid state '.$sessionState.".\n";
        }
        sleep(1.5);
    }

}

sub help {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'help', @args);
}

sub setSessionParameter {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    if (scalar(@args) % 2 == 0) {
        return $self->_send_recv('ixNet', 'setSessionParameter', @args);
    } else {
        die "setSessionParameter requires an even number of name/value pairs\n";
    }
}

sub getVersion {
    my($self) = shift;

    if ($self->_isConnected()) {
        return $self->_send_recv('ixNet', 'getVersion');
    } else {
        return $self->{_version};
    }
}

sub getParent {
    my($self) = @_;

    return $self->_send_recv('ixNet', 'getParent', $_[1]);
}

sub exists {
    my($self) = @_;

    return $self->_send_recv('ixNet', 'exists', $_[1]);
}

sub commit {
    my($self) = @_;

    return $self->_send_recv('ixNet', 'commit');
}

sub rollback {
    my($self) = @_;

    return $self->_send_recv('ixNet', 'rollback');
}

sub execute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'exec', @args);
}

sub add {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'add', @args);
}

sub remove {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'remove', @args);
}

sub setAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    $self->{_buffer} = 1;

    return$self->_send_recv('ixNet', 'setAttribute', @args);
}

sub setMultiAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];
    $self->{_buffer} = 1;

    return $self->_send_recv('ixNet', 'setMultiAttribute', @args);
}

sub getAttribute {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'getAttribute', @args)
}

sub getList {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'getList', @args);
}

sub getFilteredList {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'getFilteredList', @args);
}

sub adjustIndexes {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'adjustIndexes', @args);
}

sub remapIds {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'remapIds', @args);
}

sub getResult {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'getResult', @args);
}

sub wait {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'wait', @args);
}

sub isDone {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'isDone', @args);
}

sub isSuccess {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'isSuccess', @args);
}

sub xpath {
    my($self) = @_;
    my @args = @_[1..scalar(@_) - 1];

    return $self->_send_recv('ixNet', 'xpath', @args);
}

sub writeTo {
    my($self) = shift;
    my $filename = shift;
    my @args = @_;

    my $relativeFile = 0;
    for (@args) {
        if ($_ eq '-ixNetRelative') {
            $relativeFile = 1;
            last;
        }
    }
    if ($relativeFile) {
        return $self->_send_recv('ixNet', 'writeTo', $filename, @args);
    } else {
        return $self->_create_file_on_server($filename);
    }
}

sub readFrom {
    my($self) = shift;
    my $filename = shift;
    my @args = @_;

    my $relativeFile = 0;
    for (@args) {
        if ($_ eq '-ixNetRelative') {
            $relativeFile = 1;
            last;
        }
    }
    if ($relativeFile) {
        return $self->_send_recv('ixNet', 'readFrom', $filename, @args);
    } else {
        return $self->_put_file_on_server($filename);
    }
}

sub _isSessionAvailable {
    my ($self, $session, $raiseError) = @_;

    my $sessionInformation = $self->_getDetailedSessionInfo($session);
    if ($sessionInformation->{inUse}) {
        if ($raiseError) {
            die "The requested session is currently in use.\n";
        }
        return 0;
    }
    return 1;
}

sub _getDetailedSessionInfo {
    my ($self, $session, $baseURL, $port) = @_;
    if (not defined $baseURL) {
        $baseURL = $self->{_connectionInfo}->{url};
        $port = $self->{_connectionInfo}->{port};
    }

    my $sessionURL = $baseURL."/".$session->{id};
    my $sessionIxNetworkURL = $sessionURL."/ixnetwork";
    my $ixnet = undef;

    if (lc $session->{state} eq 'active'){
        eval {
            my $payload = undef;
            $ixnet = $self->_restSend('GET', $sessionIxNetworkURL."/globals/ixnet", $payload, 180);
        };
    }
    if (!$ixnet) {
        $ixnet->{isActive} = 'false';
        $ixnet->{connectedClients} = [];
    }
    my $inUse = $self->_parseAsBool($ixnet->{isActive} or ($session->{subState} and (substr(lc $session->{subState}, 0, length('in use')) eq 'in use')));
    return {
        id => $session->{id},
        port => $port,
        url => $sessionIxNetworkURL,
        sessionUrl => $sessionURL,
        applicationType => $session->{applicationType},
        backendType => $self->_tryGetAttr($session, 'backendType', 'LinuxAPIServer'),
        state => lc $session->{state},
        subState => $session->{subState},
        inUse => $inUse,
        userName => $session->{userName},
        connectedClients => $ixnet->{connectedClients},
        createdOn => $session->{createdOn},
        startedOn => $self->_tryGetAttr($session, 'startedOn', ''),
        currentTime => $self->_tryGetAttr($session, 'currentTime', ''),
        stoppedOn => $self->_tryGetAttr($session, 'stoppedOn', '')
    };
}

sub _normalizeFilePaths {
    my ($self) = shift;
    my $path = shift;
    while (index($path, '\\') != -1) {
        my $i = index($path, '\\');
        substr($path, $i, 1) = '/';
    }   

    return $path;
}

sub _put_file_on_server {
    my($self) = shift;
    my $fileName = shift;
    my ($baseName, $dirs, $suffix) = File::Basename::fileparse($self->_normalizeFilePaths($fileName));
    my $files = $self->_restSend('GET', $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork/files');
    my $absoluteFileName = $self->_normalizeFilePaths($files->{'absolute'});
    my $remoteFilename = $absoluteFileName.'/'.$baseName;
    $self->_restSend('POST', $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork/files?filename='.URI::Escape::uri_escape($baseName), {file_transfer => '1', filename => $fileName});
    return $self->_send_recv('ixNet', 'readFrom', $remoteFilename, '-ixNetRelative');
}

sub _create_file_on_server {
    my($self) = shift;
    my $fileName = shift;
    my ($baseName, $dirs, $suffix) = File::Basename::fileparse($self->_normalizeFilePaths($fileName));
    my $files = $self->_restSend('GET', $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork/files');
    my $absoluteFileName = $self->_normalizeFilePaths($files->{'absolute'});
    my $remoteFilename = $absoluteFileName.'/'.$baseName;
    $self->_restSend('POST', $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork/files?filename='.URI::Escape::uri_escape($baseName), {file_transfer => '1', file_content => {}});
    return $self->_send_recv('ixNet', 'writeTo', $remoteFilename, '-ixNetRelative', '-overwrite', '-remote', $fileName);
}

sub _close {
    my($self) = shift;
    if ($self->{_websocket}) {
        close($self->{_websocket}); 
    }
    $self->{_websocket} = undef;
}

sub _join {
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
                    $self->_join(@$item);
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

sub _send_recv {
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
        $self->_join($arg);
    }

    $self->{_sendBuffer} .= $self->{_sendContent}.chr(0x03);
    if (not defined $self->{_buffer}) {
        $self->_log('Sending: '.$self->{_sendBuffer}."\n");
        my $ret = eval {
            $self->{_ws_client}->write(sprintf("<001><002><009%d>%s", length($self->{_sendBuffer}), $self->{_sendBuffer}));
            1;
        };
        if (!$ret and $@) {
            $self->_close();
            die 'Connection to the remote IxNetwork instance has been closed: '.$@."\n";
        }
        $self->{_sendBuffer} = '';
    }

    $self->{_async} = undef;
    $self->{_timeout} = undef;
    $self->{_buffer} = undef;
    $self->{_sendContent} = '';

    if (length($self->{_sendBuffer}) > 0) {
        return $self->{_OK};
    } else {
        return $self->_recv();
    }
}

sub _recv {
    my($self) = shift;

    my $ret = eval {
        while(1) {
            my $commandId = undef;
            my $contentLength = int(0);

            my $startIndex = index($self->{_recvBuffer}, '<');
            my $stopIndex = index($self->{_recvBuffer}, '>');
            if ($startIndex != -1 && $stopIndex != -1) {
                $commandId = substr($self->{_recvBuffer}, $startIndex + 1, $startIndex + 3);
                if ($startIndex + 4 < $stopIndex) {
                    $contentLength = int(substr($self->{_recvBuffer}, $startIndex + 4, $stopIndex));
                }
            }
            if ($commandId == 1) {
                $self->{_evalResult} = $self->{_evalError};
            } elsif ($commandId == 4) {
                $self->{_evalResult} = substr($self->{_recvBuffer}, $stopIndex + 1, $contentLength);
            } elsif ($commandId == 7) {
                my $filename = substr($self->{_recvBuffer}, $stopIndex + 1, $contentLength);
                my ($remoteFilename, $dirs, $suffix) = File::Basename::fileparse($self->_normalizeFilePaths($filename));
                if (!(-d $dirs)) {
                    File::Path::make_path($dirs);
                }
                $self->_restSend('GET', $self->{_connectionInfo}->{sessionUrl}.'/ixnetwork/files?filename='.URI::Escape::uri_escape($remoteFilename), {file_transfer => '1', filename => $filename});
            } elsif ($commandId == 9) {
                $self->{_decoratedResult} = substr($self->{_recvBuffer}, $stopIndex + 1, $contentLength);
                last;
            }

            $self->{_recvBuffer} = substr($self->{_recvBuffer}, $stopIndex + 1 + $contentLength);
        }
        1;
    };
    if (!$ret and $@) {
        die $@."\n";
    }

    if ($self->{_evalResult} eq $self->{_evalError}) {
        die $self->{_decoratedResult}."\n";
    }

    $self->_log('Received: '.$self->{_decoratedResult}."\n");

    if (index($self->{_decoratedResult}, '(') == 0) {
        #return $self->_parseStringArray($self->{_decoratedResult});
        my @array;
        eval '@array = '.$self->{_decoratedResult};
        return @array;
    } else {
        return $self->{_decoratedResult};
    }
}

sub _parseStringArray {
        my $self= shift;
        my $string= shift;
        my $offset = shift;
        my @array;
        my $start = -1;
        my $buffer = '';
        my $ignoreNextChar = 0;
        my $endTag = '';
        my $startIndex = 0;
        if (defined($offset)) {
            $startIndex = $$offset;
        }
        for my $i ($startIndex..length($string)-1) {
            my $char = substr($string, $i, 1);
            if ($start>=0) {
                if ($endTag eq ",") {
                    if ($char =~ /^\d/) {
                         $buffer += $char;
                    } else {
                        push (@array,$buffer);
                        $buffer = '';
                        $start = -1;
                        $endTag = '';
                    }
                } elsif ($ignoreNextChar eq 0 && $char eq $endTag) {
                    push (@array,$buffer);
                    $buffer = '';
                    $start = -1;
                    $endTag = '';
                } else {
                    if ($ignoreNextChar) {
                        $ignoreNextChar = 0;
                    } else {
                        if ($char eq "\\") {
                            $ignoreNextChar = 1;
                        }    
                    }
                    $buffer += $char;
            }
            } elsif ($char eq "'" || $char eq '"') {
                $start = $i;
                $endTag = $char;
                $buffer = '';
            } elsif ($char eq " ") {
                # do nothing (spaces between elements)
            } elsif ($char eq ",") {
                if ($endTag eq ",") {
                     push (@array,'');
                     $endTag = '';
                } else {
                    $endTag = ",";
            } 
            }   elsif ($char eq ")") {
                if (defined $offset) {
                    $$offset = $i;
        }
        return @array;
            } elsif ($char eq "(") {
                $i = $i + 1;
                push (@array, $self->_parseDecoratedResult2($buffer, \$i));
            } elsif ($char =~ /^\d/) {
                $start = $i;
                $endTag = ",";
                $buffer = $char;
            }
    }
        return @array;
}

sub _check_client_version {
    my($self) = @_;
    my $version = $self->getVersion();
    if ($self->{_version} ne $version) {
        print("WARNING: IxNetwork Perl library version ".$self->{_version}." does not match the IxNetwork server version ".$version."\n");
    }
}

sub _tryWriteAPIKey {
    my($self, $dstFile, $key) = @_;

    open(my $fid, '>', $dstFile);
    print $fid $key or return undef;
    close($fid);

    return $dstFile;
}

sub _tryReadAPIKey {
    my($self, $dstFile) = @_;
    my $key = '';
    local $/ = undef;
    open(my $fid, '<', $dstFile) or return undef;
    $key = <$fid>;
    close($fid);
    return $key;
}

sub _log {
    my $self = shift;
    my $msg = shift;

    if ($self->{_debug}) {
        my $now = localtime(time);
        if (length($msg) > 1024) {
            $msg = substr($msg, 0, 1024)."...\n";
        }
        print '['.$now.'] [IxNet] [debug] '.$msg;
    }
}

sub _parseAsBool {
    my $self = shift;
    my $value = shift;

    if (! defined $value || ! $value || lc $value eq "false") {
        return 0;
    }

    return 1;
}

sub _getBaseURL {
    my ($self, $hostname, $connectionArgs, $store) = @_;

    if (not defined $store) {
        $store = 0;
    }

    my $url = '';
    my @params = ();
    my $attempts = 0;
    if (exists $connectionArgs->{'-port'}) {
        @params = (
            [('https', $connectionArgs->{'-port'})],
            [('http', $connectionArgs->{'-port'})]
        );
    } else {
        @params = (
            ['https', 443]
        );
    }

    foreach my $connectionParam (@params) {
        $url = $self->_createUrl($connectionParam->[0], $hostname, $connectionParam->[1]);

        my $ret = eval {
            $url = $self->_restGetRedirect($url, 30);
            my $port = '';
            my $host = '';
            my $verb = '';
            if ($store) {
                if ($url =~ qr/(?<verb>https?):\/\/(?<hostname>[^\/]+):(?<port>\d+)/) {
                    $port = $+{port};
                    $host = $+{hostname};
                    $verb = $+{verb};
                } elsif ($url =~ qr/(?<verb>https?):\/\/(?<hostname>[^\/:]+)/) {
                    if ($+{verb} eq "http") {
                        $port = 80;
                    } else {
                        $port = 443;
                    }
                    $host = $+{hostname};
                    $verb = $+{verb};
                }
                $self->_setConnectionInfo($verb, $host, $port, $url);
                $self->{_initialHostname} = $hostname;
                if (exists $connectionArgs->{'-port'}) {
                        $self->{_initialPort} = $connectionArgs->{'-port'};
                } else {
                    $self->{_initialPort} = 443;
                }
            }
            1;
        };

        if (!$ret and $@) {
            if ($@ =~ /IxNetAuthenticationError/) {
                die "The API key is either missing or incorrect.\n";
            }
            $attempts++;
        } else {
            last;
        }

    }
    my $paramSize = @params;
    if ($attempts == $paramSize) {
        if (exists $connectionArgs->{'-port'}) {
            die 'Unable to connect to '.$hostname.':'.$connectionArgs->{'-port'}.". Error: Host is unreachable\n";
        } else {
             die "Unable to connect to ".$hostname." using default ports (8009 or 443). Error: Host is unreachable.\n";     
        }
    }

    return $url;
}

sub _createUrl {
    my ($self, $verb, $hostname, $port) = @_;

    return $verb.'://'.$hostname.':'.$port.'/api/v1/sessions';
}

sub _setConnectionInfo {
    my ($self, $verb, $hostname, $port, $url) = @_;

    $self->{_connectionInfo}->{verb} = $verb;
    if ($verb eq "http") {
        $self->{_connectionInfo}->{wsVerb} = 'ws';
    } else {
        $self->{_connectionInfo}->{wsVerb} = 'wss';
    }
    $self->{_connectionInfo}->{hostname} = $hostname;
    $self->{_connectionInfo}->{port} = $port;
    $self->{_connectionInfo}->{url} = $url;
}

sub _restGetRedirect {
    my ($self, $url, $timeout) = @_;

    $self->_log("HEAD ".$url."\n");

    my $response = undef;
    my $request = undef;
    my $request = new HTTP::Request('HEAD' => $url);
    
    $self->{_user_agent}->timeout($timeout);
    $response = $self->{_user_agent}->request($request);
    $self->_log($response->code.' '.$response->message."\n");

    my $responseUrl = '';
    if ($response->is_redirect and defined $response->header('location')) {
        $responseUrl = $response->header('location');
        return $self->_restGetRedirect($responseUrl, $timeout);
    }  elsif (defined $response->previous and $response->previous->is_redirect and defined $response->previous->header('location')) {
        $responseUrl = $response->previous->header('location');
    } else {
        $responseUrl = $response->request->uri;
    }

     if ($response->code == 401 || $response->code == 403) {
            die 'IxNetAuthenticationError: '.$response->code.' '.$response->message."\n";
    } elsif ($response->header('client-warning') =~ /Internal/) {
            die "Server Error\n";
    }

    my @a = split(/\?/, $responseUrl);
    $responseUrl = $a[0];
    @a = split(/\#/, $responseUrl);
    $responseUrl = $a[0];

    return $responseUrl;
}

sub _tryGetAttr {
    my ($self, $obj, $attr, $default) = @_;
    my $ret = '';
    if (exists $obj->{$attr}) {
        $ret = $obj->{$attr};   
    } else {
        $ret = $default;
    }

    return $ret;
}

1;
