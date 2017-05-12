# Grips::Cmd.pm
#
# Copyright (c) 2002 DIMDI <tarek.ahmed@dimdi.de>. All rights reserved.
#
# This module is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself, i.e. under the terms of either the GNU General
# Public License or the Artistic License, as specified in the F<LICENCE> file.
package	Grips::Cmd;

use strict;
use warnings;
use Carp;
use IO::Socket;
use Data::Dumper;
#use Parse::RecDescent;
use Grips::Gripsrc;
    
use vars qw($AUTOLOAD @EXPORT_OK $VERSION);

require Exporter;

our @ISA = qw(Exporter);

$VERSION = "1.11";

@EXPORT_OK = qw(checkGripsResponse);

my $gscGrammar = q (
		    response : assign(s)
		    {
			my $response = {};
			my $key;
			my $value;
			my $str = "";
			
			for my $assign (@{$item[1]}) {
			    
			    $key   = $assign->[0];
			    $value = $assign->[1];
			    
			    if (@$key == 1) {
				if (ref $key->[0] eq 'ARRAY') {
				    $response->{$key->[0]->[0]}->[$key->[0]->[1]] = $value;
				} else {
				    $response->{$key->[0]} = $value;
				}
			    } else {
				$str .= '$response';
				for (my $i = 0; $i < @$key - 1; $i++) {
				    
				    if (ref $key->[$i] eq 'ARRAY') {
					$str .= "->{'$key->[$i]->[0]'}->[$key->[$i]->[1]]";
				    } else {
					$str .= "->{'$key->[$i]'}";
				    }
				}
				
				if (ref $key->[@$key - 1] eq 'ARRAY') {
				    $str .= "->{'" . $key->[@$key - 1]->[0] . "'}->[" . $key->[@$key - 1]->[1] . "] = q($value);\n";
				} else {
				    $str .= "->{'" . $key->[@$key - 1] ."'} = q ($value);\n";
				}
			    }
			}
			
			eval($str);
			$response;
		    }

		    assign : /\x05/ key '=' value data(s?)
		    {
			my $value = $item[4] . join "", @{$item[5]};
			$value ||= "";
			chomp $value;
			[$item[2], $value];
		    }

		    key : /^/ kLevel(s)
		    {
			$item[2];
		    }

		    kLevel : /(\$??\w)+/ '(' /\d+/ ')' dot(?)
		    {
			[$item[1], $item[3] - 1];
		    }
		    | /(\$??\w)+/ dot(?)
		    {
			$item[1];
		    }

		    value : /[^\x04\x05]*/
		    
		    data : /\x04/ /.*/ {
			$item[2]
			}
		    
		    dot : '.'
		    );

#$::RD_TRACE = 1;
my $gscParser; # = Parse::RecDescent->new ($gscGrammar);

sub new
{
    my $pkg =	shift;
    my %params = @_;
    my $port;
    my $host;
    my $sock;
    my $ok = 1;

    $params{sessionID} = _generateSessionID()	unless ($params{sessionID});

    $port	= $params{port}	or $port = 5101;
    $host	= $params{host}	or $host = "app01testgrips.dimdi.de";

    $sock	= IO::Socket::INET->new(PeerAddr =>	$host,
					PeerPort =>	$port,
					Proto	 =>	"tcp",
					Type	 =>	SOCK_STREAM)

	or $ok = 0;
    
    unless ($ok) {
	carp "Couldn't connect to $host:$port. Message $@\n";
	return undef;
    }

    my $self = bless
    {
	_sessionID         => $params{sessionID},
	_sock	           => $sock,
	_port	           => $port,
	_host	           => $host,
	_baseID	           => undef,
	_trID              => 0,
	_newResponseSyntax => $params{newResponseSyntax} || 0,

    }, $pkg;

    return $self;
}

sub login
{
    my $self = shift;
    my %params = @_;
    my $arr =	[];

    push (@$arr, "request=" . $self->getSessionID() . ".Login");

    unless ($params{user}) {
	my $h = Grips::Gripsrc->lookup($self->getHost());
	
	unless ($h) {
	    my $u;
	    
	    if ($ENV{USER}) {
		$u = "user" . $ENV{USER} . "!";
	    } else {
		$u = '[unknown user] (if no user could be found, the .gripsrc-method cannot work - are you using Grips::Cmd in a CGI environment?)';
	    }
	    
	    croak "Couldn't find host " . $self->getHost() . " in .gripsrc file of $u";
	}
	
	(undef,	$params{user}, $params{pwd}) = $h->iup();
    }

    push @$arr, "user=$params{user}";
    push @$arr, "pwd=$params{pwd}" if	($params{pwd});
    push @$arr, "new_response_syntax=CBI_YES" if $self->{_newResponseSyntax};
    push @$arr, "switch_port=CBI_YES" if ($params{switch_port});

    return $self->_sendRequest($arr, $params{debug});
}

sub connectionIsAlive {
    my $self = shift;
    
    my $sock = $self->_getSock();
    my $tmp =	"";
    my @rawResponse = ();
    my $retVal;
    my $debug;
    
    #	falls das dieses Modul nutzende	script $/ kaputt macht,	setze es hier wieder
    #	auf	den	Standard, sonst	gibst Aerger mit der response aus dem socket!!!
    local	$/ = "\n";
    
    eval {
	#	send Request
	print	$sock "\x0A";
	
	#	get	response: die Antwort kommt	zeilenweise	aus	dem	socket
	do
	{
	    $tmp = <$sock>;
	    croak "Something went wrong while getting answer from Socket (possibly a grips timeout occurred). Answer string	not	defined. Session ID: " . $self->getSessionID() . '.' unless (defined($tmp));
	    push @rawResponse, $tmp;
	} while ($tmp !~ m/^\}$/);
	
	$rawResponse[0] =~ s/\{//;
	
	$retVal = $self->_parseWithRegex(\@rawResponse, $debug);
	#  $retVal = _parseRecDecent(\@rawResponse, $debug);
    };
    return 0 if $@;
    return $retVal->{status} eq 'CBI_SYNTAX_ERR' || 0;
}

sub getHost
{
    my $self = shift;
    return $self->{_host};
}

sub getPort
{
    my $self = shift;
    return $self->{_port};
}

sub _checkParams {
    my $p = shift;
    my $m = shift;
    my $goDie = shift;
    
    if (exists $p->{_}) {
        $p->{grips_object_name} = $p->{_} unless exists $p->{grips_object_name};
    }
    
    carp "Parameter name 'request_id' is deprecated, please use 'grips_object_name' instead. Warned" if exists $p->{request_id};
    unless (exists $p->{grips_object_name} || exists $p->{request_id}) {
	if ($goDie) {
	    croak "No method '$m()' or calling '$m()' without parameter 'grips_object_name' or '_' is not possible, died";
	} else {
	    carp "No method '$m()' or calling '$m()' without parameter 'grips_object_name' or '_' is deprecated, warned";
	}
    }
}

sub getAttributes
{
    my $self = shift;
    my %params = @_;
    my $arr =	[];

    push @{$params{attribute}}, $params{attributes} if (exists $params{attributes});
    _checkParams(\%params, "getAttributes");

    my $obj = $params{grips_object_name} || $params{request_id} || $self->getSessionID();
    push (@$arr, "request=" . $obj . ".GetAttributes");

    if (exists $params{attribute}) {
	for (1 ..	@{$params{attributes}})
	{
	    push (@$arr, "attribute($_)=" .	$params{attributes}->[$_ - 1]);
	}
	push (@$arr, "attributes_num=" . scalar(@{$params{attributes}}));
    }

    return $self->_sendRequest($arr, $params{debug});
}

sub setAttribute
{
    my $self = shift;
    my %params = @_;
    my $arr;

    _checkParams(\%params, "setAttribute");

    my $obj = $params{grips_object_name} || $params{request_id} || $self->getSessionID();
    push @$arr, "request=" . $obj . ".SetAttribute";

    for my $key (keys %params) {
	next if $key eq "debug";
	next if $key eq "_";
	next if $key eq "grips_object_name";
	next if $key eq "request_id";
	
	push @$arr, "$key=" . $params{$key};
    }

    return $self->_sendRequest($arr, $params{debug});
}

sub reflect
{
    my $self = shift;
    my %params = @_;

    return $self->_sendRequest(["request=$params{object}.Reflect","$params{id}=$params{value}"], $params{debug});
}

sub defineBase
{
    my $self = shift;
    my %params = @_;
    my $dbs_num =	-1;
    my $dbs =	"";
    my $obj = $params{grips_object_name} || $self->getSessionID();
    my $arr = ["request=" . $obj . ".DefineBase"];

    _checkParams(\%params, "defineBase");

    $params{id} =	_generateBaseID() unless ($params{id});
    $self->_setBaseID($params{id});

    push @$arr, "id=$params{id}";
    push @$arr, "model=$params{model}" if	$params{model};
    push @$arr, "type=$params{type}" if $params{type};
    push @$arr, "access=$params{access}" if $params{access};
    push @$arr, "domain=$params{domain}" if $params{domain};
    push @$arr, "model=$params{model}" if	$params{model};
    push @$arr, "name=$params{name}" if $params{name};

    if (exists($params{db}))
    {
	push @{$params{dbs}}, @{$params{db}};
    }

    croak	"No	list of	databases" if ((!exists($params{dbs})) or (@{$params{dbs}} == 0));

    $dbs_num = @{$params{dbs}};

    push @$arr, "dbs_num=$dbs_num";

    for (0 ..	@{$params{dbs}}	- 1) {
	push @$arr,	"db(" .	($_	+ 1) . ")="	. $params{dbs}->[$_];
    }

    if (exists $params{db_access}) {
	for (0 ..	@{$params{db_access}} - 1) {
	    push @$arr,	"db_access(" . ($_ + 1) . ")=" . $params{db_access}->[$_];
	}
    }

    return $self->_sendRequest($arr, $params{debug});
}

sub storeDocument_deprecated
{
    my $self = shift;
    my %params = @_;
    my $items_num = -1;
    my $dbs =	"";
    my $obj = $params{grips_object_name} || $params{request_id};
    my $arr =	["request=" . $obj . ".StoreDocument"];

    carp "Parameter name 'request_id' is deprecated, please use 'grips_object_name' instead!" if exists $params{request_id};

    push @$arr, "mode=$params{mode}";
    push @$arr, "unlock=$params{unlock}" if $params{unlock};
    push @$arr, "doc.key=$params{'doc.key'}";

    croak	"No	list of	paths" if ((!exists($params{path})) or (@{$params{path}} == 0));
    croak	"No	list of	values" if ((!exists($params{value})) or (@{$params{value}} == 0));
    croak	"Numbers of paths and values differ" if (@{$params{path}} != @{$params{value}});

    if (exists($params{value}))
    {
	push @{$params{values}}, @{$params{value}};
    }

    if (exists($params{path}))
    {
	push @{$params{paths}}, @{$params{path}};
    }

    $items_num = @{$params{values}};

    push @$arr, "items_num=$items_num";

    for (0 ..	@{$params{paths}}	- 1)
    {
	push @$arr,	"path(" .	($_	+ 1) . ")="	. $params{paths}->[$_];
	push @$arr,	"value(" .	($_	+ 1) . ")="	. $params{value}->[$_];
    }

    return $self->_sendRequest($arr, $params{debug});
}

sub open
{
    my $self = shift;
    my %params = @_;
    my $arr = [];

    carp "Parameter name 'base' is deprecated, please use 'grips_object_name' instead!" if exists $params{base};
    _checkParams(\%params, "open");
    
    $params{_} = $params{grips_object_name} || $params{base} || $self->_getBaseID() unless exists $params{_};

    push @$arr, "request=$params{_}.Open";
    fillRequestArr(\%params, $arr);
    return $self->_sendRequest($arr, $params{debug});
}

sub search
{
    my $self = shift;
    my %params = @_;
    my $base = $self->_getBaseID();
    my $resId	= "";
    my $reqParams	= [];
    
    carp "Parameter name 'base' is deprecated, please use 'grips_object_name' instead!" if exists $params{base};
    _checkParams(\%params, "search");
    
    my $obj = $params{grips_object_name} || $params{request_id};
    $base = $obj if $obj;
    
    unless ($params{query} or $params{"query.string"}) {
        carp "No or empty query string!";
        return;
    }

    push @$reqParams, "request=$base.Search";

    if (ref $params{query} eq 'HASH') {
        croak "parameter 'query' must have key 'string'" unless exists $params{query}{string};
        $params{query}{lang} = 'CBI_NATIVE' unless exists $params{query}{lang};

        push @$reqParams, "query.lang=$params{query}{lang}";
        push @$reqParams, "query.string=$params{query}{string}";
        push @$reqParams, "query.mode=$params{query}{mode}" if exists $params{query}{mode};
    } else {
	my $qStr = $params{'query.string'} || $params{query};
	
        $params{"query.lang"} = "CBI_NATIVE" unless $params{"query.lang"};
        
        push @$reqParams, "query.lang=CBI_NATIVE";
        push @$reqParams, "query.string=$qStr";
        push @$reqParams, "query.mode=$params{'query.mode'}" if exists ($params{'query.mode'});
    }

    if ($params{'result.id'}) {
        push @$reqParams, "result.id=$params{'result.id'}";
    }

    return $self->_sendRequest($reqParams, $params{debug});
}

sub getDocs_deprecated
{
    my $self = shift;
    my %params = @_;

    my $arr =	[];

    unless ($params{statementID})
    {
	carp "No statement ID";
	return undef;
    }

    push @$arr, "request=$params{statementID}.GetDocs";

    if ($params{fieldList})
    {
	my $str	= "";

	foreach	(@{$params{fieldList}})
	{
	    $str .= $_ . ';';
	}

	$str =~	s/;$//;
	push @$arr,	"req_modifier=$str";
    }

    push @$arr, "subset=$params{subset}" if ($params{subset});

    return $self->_sendRequest($arr, $params{debug});
}

sub close
{
    my $self = shift;
    my %params = @_;
    
    my $obj = $params{grips_object_name} || $params{base} || $self->_getBaseID();

    carp "Parameter name 'base' is deprecated, please use 'grips_object_name' instead!" if exists $params{base};
    _checkParams(\%params, "close");

    return $self->_sendRequest(["request=$obj.Close"], $params{debug});
}

sub DELETE
{
    my $self = shift;
    $self->_getSock()->close() or	carp "Couldn't close socket: $@\n";
}

sub logout
{
    my $self = shift;
    my %params = @_;

    my $obj = $params{grips_object_name} || $self->getSessionID();
    return $self->_sendRequest(["request=" . $obj . ".Logout"], $params{debug});
}

sub getResults
{
    my $self = shift;
    my %params = @_;

    my $obj = $params{grips_object_name} || $params{base} || $self->_getBaseID();

    carp "Parameter name 'base' is deprecated, please use 'grips_object_name' instead!" if exists $params{base};
    _checkParams(\%params, "getResults");

    return $self->_sendRequest(["request=" . $obj . ".GetResults"], $params{debug});
}

sub deleteResult
{
    my $self = shift;
    my %params = @_;

    my $obj = $params{grips_object_name} || $params{base} || $self->_getBaseID();
    
    $params{'result.id'} = $params{result}{id} if (exists $params{result} and ref ($params{result}) eq 'HASH');

    carp "Parameter name 'base' is deprecated, please use 'grips_object_name' instead!" if exists $params{base};
    _checkParams(\%params, "deleteResult");

    return $self->_sendRequest(["request=" . $obj . ".DeleteResult", "result.id=" . $params{"result.id"}], $params{debug});
}

sub checkGripsResponse {
    my $type     = shift;
    my $response = shift;
    my $status   = shift;
    
    $status ||= 'CBI_OK';
    
    if ($response->{status} and $response->{status} ne $status) {
	my $msg = "grips returned $response->{status} in request $response->{request}. Message was\n  $response->{message}.";
	
	if      ($type eq "HARD") {
	    croak $msg;
	} elsif ($type eq "SOFT") {
	    carp $msg;
	} else {
	    croak "Unknown type $type. Please use 'HARD' or 'SOFT'!";
	}
    }
    
    return $response;
}

sub _generateSessionID
{
#    return time() . $$;
    my ($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime();

    return ($year + 1900 . 
	    sprintf ("%02u", $mon + 1) . 
	    sprintf ("%02u", $mday)    . 
	    sprintf ("%02u", $hour)    .
	    sprintf ("%02u", $min)     . 
	    sprintf ("%02u", $sec)     .
	    "-"                        . 
	    substr(rand(), 2, 5));
}

sub _getTransactionID
{
    my $self	 = shift;
    return sprintf ("%07u", ++$self->{_trID});
}

sub gscDirect {
    my $self  = shift;
    my $data  = shift;
    my $debug = shift; # wenn true, werden debugging-ausgaben erstellt

    return $self->_sendRequest($data, $debug, 1);
}

sub _sendRequest
{
    my $self	    	 = shift;
    my $req	    	 = shift;
    my $debug	    	 = shift;
    my $processGscDirect = shift; # wenn true, wird die unverarbeitete, textbasierte gsc-response als array oder ref. auf array zurückgeliefert

    my $retVal;
    my $sock 	    	 = $self->_getSock();
    my $out  	    	 =	"\{";
    my $respStr       	 =	"";
    my $rawResponse 	 = [];

    #	falls das dieses Modul nutzende	script $/ kaputt macht,	setze es hier wieder
    #	auf den Standard, sonst	gibst Aerger mit der response aus dem socket!!!
    
    #	TODO: geht noch	nicht, wahrscheinlich ist der socket auch nach timeout noch offen
    croak "Session ID " . $self->getSessionID() . " lost connection to socket!" unless ($sock->connected());

    $debug = 0 unless	$debug;

    #	send Request
    $out .= "CBI_REQUEST=" . $self->getSessionID() . "." . $self->_getTransactionID() . "\n";

    foreach (@$req){
	chomp;
	s/\x0D//;
	$out .= "$_\x0A";
    }

    $out .= "\}\x0A";

    print STDERR $out if ($debug > 1);

    print $sock $out;

    #   get response
    local $/ = "\n}\n";

    $respStr = <$sock>;

    $rawResponse = $self->_getRawResponse($respStr);

    if ($processGscDirect) {
	$_ .= "\n" for @$rawResponse;
	print STDERR @$rawResponse if $debug > 1;
	return $rawResponse;
    }

    $rawResponse->[0] =~ s/\{// if @$rawResponse;

    $retVal = $self->_parseWithRegex($rawResponse, $debug);

    print STDERR Dumper $retVal if ($debug > 2);

    return $retVal;
}

sub _getRawResponse {
    my $self = shift;
    my $rStr = shift;
    my $rawResp = [];

    if ($self->{_newResponseSyntax}) {
	@$rawResp = split /\n\.\n/, $rStr;
	s/^\.\././ for @$rawResp;
    } else {
	@$rawResp = split /\n/, $rStr;
    }

    return $rawResp;
}

sub _benchMark {
#    use Benchmark::Timer;
#	
#	my $rawResponse = shift;
#	my $debug       = shift;
#	
#    my $t = Benchmark::Timer->new(skip => 1);
#
#    for(0 .. 20) {
#        $t->start('old');
#        &_parseWithRegex($rawResponse, $debug);
#        $t->stop;
#    }
#    print "\n";
#    $t->report;
#
#    $t = Benchmark::Timer->new(skip => 1);
#
#    for(0 .. 20) {
#        $t->start('new');
#        &_parseRecDecent($rawResponse, $debug);
#        $t->stop;
#    }
#    
#    $t->report;
}

# schnell, aber prinzipiell anfällig (wenn auch lang erprobt)
sub _parseWithRegex {
    my $self = shift;
    my $assigns = shift;
    my $debug   = shift;
    my $retVal = {};
    my $respPar = "";

    if ($self->{_newResponseSyntax}) {
	for (@$assigns) {
	    _gsc2perl(\$_, $retVal) if ($_);
	}
    } else {
	for (@$assigns) {
	    next if (/^\}$/);
	    print STDERR "$_\n" if ($debug);
	
	    unless (/^[\w\.\(\)\$#-]+=/) {
	        $respPar .= $_;
	    } else {
		_gsc2perl(\$respPar, $retVal) if ($respPar);
		$respPar = $_;
	    }
	}
    }

    _gsc2perl(\$respPar, $retVal) if ($respPar);
    return $retVal;
}

# sauber, aber je nach response ca. 10 - 50x langsamer als _parseWithRegex
    sub _parseRecDecent {
	my $assigns = shift;
	my $debug   = shift;
	my $gscResponse;
	
	for (@$assigns) {
	    print "$_" if ($debug);
	    
	    unless (/^[\w\.\(\)\$#]+=/) {
		       $gscResponse .= "\x04" . $_;
		   } else {
		       $gscResponse .= "\x05" . $_;
		   }
		}

#    chomp $gscResponse;
#    $gscResponse =~ s/\}$//;

#    print $$response, "\nis ";
#    print "NOT " unless $gscParser->response($$response);
#    print "a valid gsc-response\n";

	    $gscParser->response($gscResponse);
	}

	sub _gsc2perl
{
    my $respPar = shift;
    my $retVal  = shift;
    my $k;
    my $v;
    
#	print "RESPPAR=", $$respPar, "\n";
    
    # die Antwort des CBI-Demons wird hier in einen	String mit einer
    # verschachtelten Perl-Datenstruktur konvertiert. Grob gesagt werden
    # Zahlen "(1)" und "#1"	zu Array-Indices und Punkte "." zu Referenzen
    # auf Hashkeys.	Das Ganze wird dann per	eval zu	Perl gemacht.
    # Besser waere es, hier	Parse::RecDescent zu benutzen, aber ...
    # never	change a running program :-)
#	print $$respPar, "\n";
    if ($$respPar =~ /^(.*?)=(.*\S*.*)/ms)
    {
	$k = $1;
	$v = $2;
	chomp $v;
#	  print "$k ---> $v\n";

	$k = '{\'' . $k	. '\'}';
	$k =~	s!(\d+)\)\.!($1 - 1) . ']->{\''!eg;
	$k =~	s!(\d+)\)!($1 - 1) . ']'!eg;
	$k =~	s/\#(\d+)/'\'}->[' . ($1 - 1) . ']'/eg;
	$k =~	s/\./'\}\-\>\{'/g;
	$k =~	s/\(/'\}\-\>\[/g;
#	  $k =~	s/\$//g;
	  $k =~	s/\]'\}$/\]/;
#	  $k =~	s/(\w+-\w+)/\'$1\'/g;  # hab ich das mal für "p-group" gemacht???
	
	#	***	falls Anfuehrungszeichen etc. drin sind, gibt es Probleme
	#	***	beim eval, daher alles unpack()en, später pack()en
	# *** q() geht nicht, wenn in $v eine ungerade Anzahl von Klammern vorkommt
#	  print "$k ---> $v\n\n";
	$v = unpack ("H*", $v);
	_cleanRetVal($retVal, $k);
	# sieh nach ob das in $k befindlich Perlgebilde als key schon
	# existiert, wenn nein, schreib es
	eval "unless (\$retVal->$k) {\$retVal->$k = \'$v\'; \$retVal->$k = pack(\"H*\", \$retVal->$k)}";
    }
}

# leider gibt es bei Periodengruppen immer eine Art Überschrift, die genauso
# heisst, wie die danach folgende Liste, also etwas TEIL vs. TEIL(1)... etc.
# diese Überschriften lassen sich, wenn einmal in $retVal abgelegt, nicht mehr
# durch eine Referenz auf einen Array überschreiben. Daher werden solche Keys
# wieder gelöscht
# 
#doc.TEIL= 
#doc.TEIL(1).STFC1= 
#doc.TEIL(1).STFC1(1).STFNR1=00023
#doc.TEIL(1).STFC1_num=1
#doc.TEIL_num=1

sub _cleanRetVal {
    my $retVal = shift;
    my $keyStr = shift;
    
#	print "\nKEYSTR=", $keyStr, "\n";
    
    my @keys = split '->', $keyStr;
    my $chain = '';
    
    for (@keys) {
	$chain .= '->' . $_;
	eval  "delete \$retVal" . $chain . " if (exists \$retVal" . $chain . " and !ref \$retVal" . $chain . " and \$retVal" . $chain . " =~ /^\\s*\$/)";
#		print "delete \$retVal" . $chain . " if (exists \$retVal" . $chain . " and !ref \$retVal" . $chain . " and \$retVal" . $chain . " =~ /^\\s*\$/)\n";
    }
}

sub getSessionID
{
    my $self = shift;

    return $self->{_sessionID};
}

sub _getSock
{
    my $self = shift;

    return $self->{_sock};
}

sub _getBaseID
{
    my $self = shift;

    return $self->{_baseID};
}

sub _setBaseID
{
    my $self = shift;
    my $base = shift;

    $self->{_baseID} = $base;
}

sub _generateBaseID()
{
    my $self = shift;

    return "bas1";
}

sub AUTOLOAD
{
    my $self	   = shift;
    my %params   = @_;
    my $response = {};
    my $sub	   = $AUTOLOAD;
    my $tmp	   = "";

    $sub =~ s/.*:://;
    $sub = ucfirst $sub;

    if ($sub eq "DESTROY"){return;}

    my $arr =	[];
    
    _checkParams(\%params, $sub, 1);
    
    my $obj = $params{grips_object_name} || $params{request_id};

    #*** Spezialbehandlungen um die Benutzung bequemer zu machen:

    #*** GetField()
    $params{path} = uc($params{path}) if (lc($sub) eq "getfield");

    #*** ...

    push @$arr, "request=$obj." . $sub;

    fillRequestArr(\%params, $arr);
    
    return $self->_sendRequest($arr, $params{debug});
}

sub fillRequestArr {
    my $params = shift;
    my $arr    = shift;
    
    while (my ($k, $v) = each %$params) {
        next if	($k	eq "debug");
        next if	($k	eq "request_id");
        next if	($k	eq "grips_object_name");
        next if	($k	eq "_");
	
        _perl2gsc($v, $k, $arr);
    }
}

sub _perl2gsc {
    my $data   = shift;
    my $prefix = shift;
    my $arr    = shift;
    my $tmp;
    my $out;
    my $dot;
    
    $prefix ||= "";

    unless (defined $data) {
	$data = "";
	carp "Value of $prefix is undefined, I convert it to '' (empty string). Warning issued";
    }
    
    if (!defined ref($data) or ref($data) eq "") {
	$out .= $prefix . "=" . $data;
	push @$arr, $out;
	
    } elsif (ref($data) eq "SCALAR") {
	$out .= $prefix . "=" . $$data;
	push @$arr, $out;
	
    }  elsif (ref($data) eq "ARRAY") {
	for (1..@$data) {
	    $dot = "";
#	        $dot = ref $data->[$_ - 1] ? "." : "";
	    $out .= _perl2gsc($data->[$_ - 1], $prefix . "(" . $_ . ")" . $dot, $arr);
	}
	
    } elsif (ref($data) eq "HASH") {
	for (keys %$data) {
	    $out .= _perl2gsc($data->{$_}, $prefix . "." . $_, $arr);
	}
	
    } else {
	croak "Unsupported data structure " .ref $data . "!";
    }
    
    return $out;
}

1;

__END__

=head1 NAME

Grips::Cmd - Perl-Schnittstelle zur grips-open Skriptsprache

=head1 SYNOPSIS

    use Grips::Cmd;
    $grips = new Grips::Cmd(host => 'gripsdb.dimdi.de', port => 5101);
    $grips->login(user => '1234abcd', pwd => "");
    $grips->setAttribute(grips_object_name => $grips->getSessionID, timeout => 600);
    $grips->defineBase(grips_object_name => $grips->getSessionID, id => "bas1", dbs => ["ml66"]);
    $grips->open(grips_object_name => "bas1");
    $searchResponse = $grips->search(grips_object_name => "bas1", 'query.string' => "nix");
    
    $hits = $searchResponse->{result}->{hits};
    
    for (1..$hits) {
    	$gdbResponse = $grips->getDocBody(grips_object_name => 2, subset => $_, layout => "CBI_HTML", req_modifier => "CBI_FULL");
    	$htmlText = $gdbResponse->{doc_body};
    	print $htmlText;
    }
    
    $grips->close(grips_object_name => "bas1");
    $grips->logout(grips_object_name => $grips->getSessionID);

=head1 DESCRIPTION

Dieses Modul implementiert eine Perl-Schnittstelle zur grips-open
Skriptsprache. Dabei ersetzt es die flache Skriptstruktur sowohl beim
Request als auch bei der Response durch Perl-Datenstrukturen.

=head2 Struktur des Requests

Die grips-open-Skriptfunktionen werden als Methoden auf dem
grips::Cmd-Objekt aufgerufen. Dabei fangen sämtliche Methoden mit
einem Kleinbuchstaben an und heissen ansonsten exakt wie die
Skriptfunktionen. Die Parameter für den Request werden den Methoden in
der perlüblichen Hash-Schreibweise übergeben:

    $grips->methodenName(par1 => 'wert1', par2 => 'wert2');

Hat ein Parameter die Form einer Liste, muss diese als Referenz auf
einen Array bzw. als anonymer Array übergeben werden:

    $grips->methodenName(par1 => \@werte);

oder

    $grips->methodenName(par1 => ['wert1', 'wert2']);

Desweiteren muss bei Methoden allgemein der grips-Script-Objektname
als Parameter 'grips_object_name' (oder alternativ '_') übergeben
werden, also etwa

    $grips->getDocBody(_ => 2, subset => 1-10, layout => "CBI_HTML", req_modifier => "CBI_FULL");

wo die Methode C<getDocBody()> auf dem Search-Result-Objekt mit der ID
'2' aufgerufen wird oder

    $grips->close(_ => "bas1");

wenn das base-Objekt mit der ID "bas1" geschlossen werden
soll. Hierbei muss angemerkt werden, dass diese Vorgehensweise nicht
ganz durchgehend implementiert wurde. Bei einigen Methoden müssen
möglicherweise andere Parameter gesetzt werden.

=head2 Struktur der Response

Die grips-Skript-Response wird in eine komplexe Perl-Datenstruktur
nach folgenden Regeln umgesetzt: Sämtliche Methoden liefern eine
Referenz auf einen Hash zurück. Die Parameter der Response bilden
Schlüssel dieses Hashs, die je nach Struktur der Response wieder
unterschiedliche Strukturen annehmen können. Ist der Wert eines
solchen Schlüssels ein schlichter skalarer Wert, wird dies auch in der
Perl-Datenstruktur so abgebildet. Ist der Wert in der grips-Response
eine Liste, so wird er in der Perl-Datenstruktur als Array
abgebildet. Hierbei ist zu beachten, dass in der grips-Response die
Listennumerierung mit 1, in der Perl-Datenstruktur aber natürlich mit
0 beginnt. Kommt ein Schlüssel in der grips-Response mehrfach vor,
wird er in der Perl-Datenstruktur in einen Hash umgesetzt. Ein
Beispiel macht dies vielleicht deutlicher: Eine grips-Response mit der
Struktur

    {CBI_RESPONSE=103960370811963.0000005
    request=bas1.Search  
    status=CBI_OK	  
    message=Base.Search: Search was o.K.
    result.id=2
    result.hits=1
    result.query=ND=381095
    }

wird in folgende Perl-Datenstruktur umgewandelt

    $response = { 
	'result' => {
	    'hits' => '1',
	    'id' => '2',
	    'query' => 'ND=381095'
	    },	  
	 'status' => 'CBI_OK',
	 'message' => 'Base.Search: Search was o.K.',
	 'CBI_RESPONSE' => '103960370811963.0000005',
	 'request' => 'bas1.Search'
    };

Zur Betrachtung der Perl-Datenstruktur ist das C<Data::Dumper>-Modul
sehr hilfreich, mit dem auch die obige Ausgabe produziert wurde
(C<print Dumper $response;>).

Listen in der grips-Response werden folgendermassen umgesetzt:

{CBI_RESPONSE=103960871526624.0000006				  
request=2.GetDocs						  
status=CBI_OK						  
message=SearchResult.GetDocs: end of subset	  
docs_num=2					  
doc(1).id=1				  
doc(1).title=In vitro effects of NIPRISAN (Nix-0699).
doc(1).$DBNAME=MEDLINE		  
doc(1).$DBKEY=ML66		  
doc(1).$COPYR=NLM		  
doc(1).TI=In vitro effects of NIPRISAN (Nix-0699).
doc(2).id=2	  
doc(2).title=Mitochondrial death protein Nix.
doc(2).$DBNAME=MEDLINE
doc(2).$DBKEY=ML66
doc(2).$COPYR=NLM
doc(2).TI=Mitochondrial death protein Nix.
}

wird zu

    $response = {
	'status' => 'CBI_OK',
	'docs_num' => '2',
	'message' => 'SearchResult.GetDocs: end of subset',
	'CBI_RESPONSE' => '103960863726019.0000006',
	'doc' => [
		  {
		      'DBNAME' => 'MEDLINE',
		      'title' => 'In vitro effects of NIPRISAN (Nix-0699).',
		      'COPYR' => 'NLM',
		      'DBKEY' => 'ML66',
		      'id' => '1',
		      'TI' => 'In vitro effects of NIPRISAN (Nix-0699)'
		      },
		  {
		      'DBNAME' => 'MEDLINE',
		      'title' => 'Mitochondrial death protein Nix.',
		      'COPYR' => 'NLM',
		      'DBKEY' => 'ML66',
		      'id' => '2',
		      'TI' => 'Mitochondrial death protein Nix.'
		      }
		  ],
	'request' => '2.GetDocs'
    };

=head1 METHODS

=head2 gsc-Methoden

Das Modul unterstützt einen grossen Teil der Methoden der
grips-open-Skriptsprache. Definitiv funktionieren folgende Methoden:

    login();
    <SESSION|BASE|SEARCH_RESULT|HOST_SERVICES|USER>.getAttributes();
    <SESSION|BASE|SEARCH_RESULT|HOST_SERVICES|USER>.setAttribute();
    <SESSION|BASE|SEARCH_RESULT|HOST_SERVICES|USER>.setAttributePermanent();
    
    <SESSION>.getSubjectList();
    <SESSION>.getBaseList();
    <SESSION>.getIndexedBaseList();
    <SESSION>.getApplicationInfo();
    <SESSION>.defineBase();
    <SESSION>.logout();
    
    <BASE>.open();
    <BASE>.setLimit();
    <BASE>.getFieldsInfo();
    <BASE>.browseIndex();
    <BASE>.search();
    <BASE>.removeDuplicates();
    <BASE>.getResults();
    <BASE>.deleteResult();
    <BASE>.getDocForUpdate();
    <BASE>.getNewDocKey();
    <BASE>.storeDocument();
    <BASE>.lock();
    <BASE>.unlock();
    <BASE>.close();
    
    <SEARCH_RESULT>.sort();
    <SEARCH_RESULT>.getDocBody();
    <SEARCH_RESULT>.getDocs();
    <SEARCH_RESULT>.getField();
    <SEARCH_RESULT>.getFullTextInfo()
    <SEARCH_RESULT>.analyseTerms();
    <SEARCH_RESULT>.analyseTermsStatistic();
    
    <SERVICE>.getSupplList();
    <SERVICE>.getSupplInfo();

Diverse andere Methoden sollten automatisch funktionieren, für einige
Methoden ist allerdings eine Spezialimplementierung erforderlich. Dies
kann bei Bedarf auf Anfrage an den Autor hin geschehen.

Die Parameter der Methoden entprechen den im grips-open Script
verwendeten. Das in spitzen Klammern vorangestellte grips-Objekt
sollte bei allen Methoden über den Parameter 'grips_object_name' (oder
alternativ '_') referenziert werden, also z.B.

    $grips->search(grips_object_name => "bas1", ...)
    
wenn das Base-Object in defineBase() "bas1" genannt wurde,

    $grips->getField(grips_object_name => 2, ...)  

wenn ein Feld des Profiltabelleneitrags mit der ID 2 gefunden werden
soll etc.

Darüber hinaus hat das Modul folgende eigene Methoden:

=head2 new()

Legt ein neues grips::Cmd-Objekt an.

=head3 Parameters

=over 4

=item *

C<host> - Host des Socket-CBI-Dämons, also z.B. gripsdb.dimdi.de. Kann
weggelassen werden, ist dann app01testgrips.dimdi.de.

=item *

C<port> - Port des Socket-CBI-Dämons. Kann weggelassen werden, ist
dann 5101.

=item *

C<sessionID> - Session-ID für die Session. Kann weggelassen werden,
wird dann generiert aus "unix-Epochensekunden.pid"

=item *

C<newResponseSyntax> - wenn dieser Paramter einen Wert hat, der zu
true evaluiert, wird die neue Responsesyntax (die mit den Punkten,
s. GSC-Handbuch, "Login" verwendet.

=back

=head3 croaks if ...

=over

=item *

... keine Verbindung zum CBI-Dämon hergestellt werden kann

=back

=head2 getHost()

Liefert den Host des Script-CBI-Dämons.

=head2 getPort()

Liefert den Port des Script-CBI-Dämons.

=head2 getSessionID()

Liefert die Session ID

=head2 checkGripsResponse()

überprüft, ob der Status der Response CBI_OK bzw. ein anderer erwarteter Status ist.

=head3 Parameters

=over 4

=item *

1. Parameter - (HARD|SOFT) wenn HARD, wird eine Exception geworfen, sonst wird eine Warnung ausgegeben.

=item *

2. Parameter - die Response einer grips-Skriptfunktion

=item *

3. Parameter - der erwartete Status der script-Response. Wenn der
   Parameter nicht übergeben wird, 'CBI_OK'

=back

=head3 croaks if ...

=over

=item *

... s.o.

=item *

... wenn der Wert des ersten Parameter das nicht entweder HARD oder
SOFT ist

=back

=head3 Beispiel
    
    $response = checkGripsResponse("HARD", $grips->defineBase(_ => $grips->getSessionID, id => "bas1", dbs => ["ml66"]), 'CBI_OK');

wirft Exception, wenn defineBase() nicht CBI_OK liefert

=head2 connectionIsAlive()

Liefert 1, wenn noch eine Verbindung zum Socket-CBI-Dämon besteht, sonst 0.

=head2 gscDirect

Hat als Input und Output grips script in Textformat, also genau das,
was der cbi_demon versteht. Auf diese Weise kann ein Perldämon mit
Hilfe eines Grips::Cmd-Objekts sich als cbi_demon tarnen. Liefert
Response als Referenz auf array zurück.

=head3 Parameters

=over 4

=item *

1. Parameter - Referenz auf array mit grips-script-request

=item *

2. Parameter - Debugging: 0 => aus, 1,2,3 ... => an

=back

=head3 croaks if ...

=over

=item *

... s.o.

=item *

... wenn der Wert des ersten Parameter das nicht entweder HARD oder SOFT ist

=back

=head1 EXPORT_OK

    checkGripsResponse();

=head1 .gripsrc-Datei

Im $HOME-Verzeichnis des aufrufenden Users kann eine Datei namens
".gripsrc" mit der Berechtigung 700 angelegt werden, in der Host,
Usercode und Passwort angegeben werden können. In diesem Fall müssen
Usercode und Passwort nicht der Login-Methode mit übergeben
werden. Die gripsrc-Datei kann folgendermassen aussehen:

    host app01grips.dimdi.de
    pwd  blubb
    user abcd1234

    host app01testgrips.dimdi.de
    user wxyz9876

Hier wird für den Host gripsdb.dimdi.de der Usercode abcd1234 mit dem
Passwort blubb und für den Host app01testgrips.dimdi.de der Usercode wxyz9876
ohne Passwort eingetragen.

Die Verwendung einer solchen Datei empfiehlt sich sehr, da es ein
Sicherheitsrisiko ist, in Perlscripten Usercode und Passwort
anzugeben.

ACHTUNG!!! Um böse Fallen gleich zu vermeiden: eine solche
.gripsrc-Lösung funktioniert natürlich nicht in CGI-Kontexten. Hier
müssen Usercode und Passwort der login()-Methode direkt übergeben
werden. Wie sie dort hinkommen, ohne grosse Sicherheitslöcher zu
reissen, ist eine Frage, die unabhängig von diesem Modul gelöst werden
muss.

=head1 VERIONS

    0.01

    - Rudimentäre und wenig systematisierte Funktionalität

    0.80

    - Dokumentation hinzugefägt

    - Methodenschnittstellen vereinheitlicht

    - alle Methoden mit Parameter grips_object_name versehen, der den
      Namen des grips-open-Objekts bezeichnet, auf dem der
      Scriptrequest ausgeführt wird

    - Parameter request_id vorhanden, aber deprecated

    - Fehler mit Session-ID korrigiert

    - hochzählende Transaction-ID hinzugefügt

    - auch login()-Methode liefert jetzt Response-Objekt zurück

    - Bei getDocs() kommen jetzt auch die '$'-Felder (DBKEY, COPYRIGHT etc.), allerdings ohne '$' davor

    0.81

    - Dokumentation erweitert

    - 3. Parameter (erwarteten Status) zu checkGripsResponse() hinzugefügt

    1.00

    - Perl-Datenstrukturen werden jetzt automatisch in beliebiger
      Tiefe in gsc-requests umgesetzt. Damit sollte theoretisch jeder
      grips-Request, der sich an die gsc-eigenen Regeln hält,
      funktionieren.

    - Alle Funktionen ausser login() und logout() geben jetzt eine
      Warnung aus, wenn sie ohne den Parameter "grips_object_name"
      aufgerufen werden.

    - Damit man nicht so viel tippen muss, kann statt des
      Parameternamens "grips_object_name" jetzt auch "_" eingegeben
      werden.

    1.01

    - Fehler bei getCost() und analogen response-Strukturen beseitigt,
      wo Reponsezeile die Struktur key(n)=value (im Ggs. zu
      keyA(n).keyB=value) hat

    - Open kann jetzt auch 'rd_from' und 'rd_to'

    - Search kann jetzt auch 'query.mode'

    1.02

    - Abwärtskompatibilität bei search() hergestellt: Request versteht
      jetzt auch wieder skalaren Parameter "query", der query.string
      enthält.

    1.03

    - Funktion connectionIsAlive() hinzugefügt. Liefert 1, wenn noch
      eine Verbindung zum Socket-CBI-Dämon besteht, sonst 0.

    1.04

    - Problem beim Parsen der Response von GetFields() behoben, wenn
      Periodengruppen zurückkommen. Gelöst über Funktion
      _cleanRetVal()

    - Fehler beim Parsen von #1 in Response von GetFields() behoben

    1.05

    - Fehler beim Parsen von Periodengruppen namens "P-Group" behoben

    1.06

    - Konstruktor stirbt nicht mehr, wenn kein Socket da, sondern
      warnt und liefert undef

    1.07

    - Nur Quelltextlayoutverschönerungen

    1.08

    - Session-ID jetzt nicht mehr Epochensekunden + pid sondern lesbare
      Zeitangabe yyyymmddhhmmss-<5-stellige Zufallszahl>
    - neue Methode gscDirect(), die grips script als input und output hat

    1.09

    - new response syntax implementiert

    1.10

    - Fix package declaration
    
    1.11

    - Fix Makefile.PL
    
=head1 AUTHOR

Tarek Ahmed, E<lt>ahmed@dimdi.deE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Tarek Ahmed. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

Grips::Gripsrc für die Entwicklung eigener grips-perl-Schnittstellen
(Das Modul ist inklusive Dokumentation von Net::Netrc
abgekupfert. Daher ist die Dokumentation in englisch und
möglicherweise zu umfangreich und nicht ganz auf grips-Bedürfnisse
zugeschnitten.)

=cut
