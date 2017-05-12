package Elive::Connection;
use warnings; use strict;

our $VERSION = '1.37';

use Carp;
use File::Spec::Unix;
use HTML::Entities;
use Scalar::Util;
require SOAP::Lite;
use URI;
use URI::Escape qw{};
use Try::Tiny;
use YAML::Syck;

use parent qw{Class::Accessor Class::Data::Inheritable};

use Elive;
use Elive::Util;

=head1 NAME

Elive::Connection - Manage Elluminate Live SOAP connections.

=head1 DESCRIPTION

This is an abstract class for managing connections and related resources.

Most of the time, you'll be dealing with specific class instances; See L<Elive::Connection::SDK> L<Elive::Connection::API>.

=cut

__PACKAGE__->mk_accessors( qw{_url user pass _soap debug type timeout} );

=head1 METHODS

=cut

=head2 connect

    my $sdk_c1 = Elive::Connection->connect('http://someserver.com/test',
                                        'user1', 'pass1', debug => 1,
    );

    my $url1 = $sdk_c1->url;   #  'http://someserver.com/test'

    my $sdk_c2 =  Elive::Connection->connect('http://user2:pass2@someserver.com/test');
    my $url2 = $sdk_c2->url;   #  'http://someserver.com/test'

Establishes a logical SOAP connection.

=cut

sub connect {
    my ($class, $url, $user, $pass, %opt) = @_;
    #
    # default connection - for backwards compatibility
    #
    require Elive::Connection::SDK;
    return Elive::Connection::SDK->connect($url, $user => $pass, %opt);
}

sub _connect {
    my ($class, $url, $user, $pass, %opt) = @_;

    my $debug = $opt{debug}||0;

    $url =~ s{/$}{}x;

    my $uri_obj = URI->new($url);

    my $userinfo = $uri_obj->userinfo;

    if ($userinfo) {

	#
	# extract and remove any credentials from the url
	#

	my ($uri_user, $uri_pass) = split(':',$userinfo, 2);

	if ($uri_user) {
	    if ($user && $user ne $uri_user) {
		carp 'ignoring user in URI scheme - overridden';
	    }
	    else {
		$user = URI::Escape::uri_unescape($uri_user);
	    }
	}

	if ($uri_pass) {
	    if ($pass && $pass ne $uri_pass) {
		carp 'ignoring pass in URI scheme - overridden';
	    }
	    else {
		$pass = URI::Escape::uri_unescape($uri_pass);
	    }
	}
    }

    my $uri_path = $uri_obj->path;

    $pass = '' unless defined $pass;

    my @path = File::Spec::Unix->splitdir($uri_path);

    shift (@path)
	if (@path && !$path[0]);

    pop (@path)
	if (@path && $path[-1] eq 'webservice.event');

    #
    # normalise the connection url by removing suffixes. The following
    # all reduce to http://mysite/myinst:
    # -- http://mysite/myinst/webservice.event
    # -- http://mysite/myinst/v2
    # -- http://mysite/myinst/v2/webservice.event
    # -- http://mysite/myinst/default
    # -- http://mysite/myinst/default/webservice.event
    #
    # there's some ambiguity, an instance named v1 ... v9 will cause trouble!
    #

    pop(@path)
        if (@path && $path[-1] =~ m{^v(\d+)$});

    $uri_obj->path(File::Spec::Unix->catdir(@path));

    my $soap_url = $uri_obj->as_string;

    #
    # remove any embedded credentials
    #
    $soap_url =~ s{\Q${userinfo}\E\@}{} if $userinfo;

    my $self = {};
    bless $self, $class;

    $self->url($soap_url);
    $self->user($user);
    $self->pass($pass);
    $self->debug($debug);
    $self->timeout($opt{timeout});

    return $self
}

sub _check_for_errors {
    my $class = shift;
    my $som = shift;

    die "No response from server\n"
	unless $som;

    die $som->fault->{ faultstring }."\n" if ($som->fault);

    my $result = $som->result;
    my @paramsout = $som->paramsout;

    warn YAML::Syck::Dump({result => $result, paramsout => \@paramsout})
	if ($class->debug);

    my @results = ($result, @paramsout);

    foreach my $result (@results) {
	next unless Scalar::Util::reftype($result);
    
	#
	# Look for Elluminate-specific errors
	#
	if ($result->{Code}
	    && (my $code = $result->{Code}{Value})) {

	    #
	    # Elluminate error!
	    #
	
	    my $reason = $result->{Reason}{Text};
	    my @stack_trace;

	    my $stack = $result->{Detail}{Stack};

	    if ($stack && (my $trace = $stack->{Trace})) {
		@stack_trace = (Elive::Util::_reftype($trace) eq 'ARRAY'
			       ? @$trace
			       : $trace);

	    }

	    my %seen;

	    my @error = grep {$_ && !$seen{$_}++} ($code, $reason, @stack_trace);
	    my $msg = @error ? join(' ', @error) : YAML::Syck::Dump($result);
	    die "$msg\n";
	}
    }
}

=head2 check_command

    my $command1 = Elive->check_command([qw{getUser listUser}])
    my $command2 = Elive->check_command(deleteUser => 'd')

Find the first known command in the list. Raise an error if it's unknown;

See also: elive_lint_config.

=cut

sub check_command {
    my $class = shift;
    my $commands = shift;
    my $crud = shift; #create, read, update or delete
    my $params = shift;

    if (Elive::Util::_reftype($commands) eq 'CODE') {
	$commands = $commands->($crud, $params);
    }

    $commands = [$commands]
	unless Elive::Util::_reftype($commands) eq 'ARRAY';

    my $usage = "usage: \$class->check_command(\$name[,'c'|'r'|'u'|'d'])";
    die $usage unless @$commands && $commands->[0];

    my $known_commands = $class->known_commands;

    die "no known commands for class: $class"
	unless $known_commands && (keys %{$known_commands});

    my ($command) = grep {exists $known_commands->{$_}} @$commands;

    croak "Unknown command(s): @{$commands}"
	unless $command;

    if ($crud) {
	$crud = lc(substr($crud,0,1));
	die $usage
	    unless $crud =~ m{^[c|r|u|d]$}xi;

	my $command_type = $known_commands->{$command};
	die "misconfigured command: $command"
	    unless $command_type &&  $command_type  =~ m{^[c|r|u|d]+$}xi;

	die "command $command. Type mismatch. Expected $crud, found $command_type"
	    unless ($crud =~ m{[$command_type]}i);
    }

    return $command;
}

=head2 known_commands

Returns an array of hash-value pairs for all Elluminate I<Live!> commands
required by Elive. This list is cross-checked by the script elive_lint_config. 

=cut

=head2 call

    my $som = $self->call( $cmd, %params );

Performs an Elluminate SOAP method call. Returns the response as a
SOAP::SOM object.

=cut

sub call {
    my ($self, $cmd, @params) = @_;

    $cmd = $self->check_command($cmd, undef, { @params });

    my @soap_params = $self->_preamble($cmd);
    my %idx;

    while (@params) {
	my $name = shift @params;
	die "odd number of call parameters"
	    unless @params;
	my $value = shift @params;

	$value = SOAP::Data->type(string => Elive::Util::string($value))
	    unless (Scalar::Util::blessed($value)
		    && try {$value->isa('SOAP::Data')});

	my $soap_param = $value->name($name);

	if (exists $idx{$name}) {
	    # duplicate parameter; override earilier value
	    $soap_params[ $idx{$name} ] = $soap_param
	}
	else {
	    $idx{$name} = scalar @soap_params;
	    push (@soap_params, $soap_param);
	}
    }

    my $som = $self->soap->call( @soap_params );

    return $som;
}

=head2 disconnect

Closes a connection.

=cut

sub disconnect {
    my $self = shift;
    return;
}

=head2 url

    my $url1 = $connection1->url;
    my $url2 = $connection2->url;

Returns a restful url for the connection.

=cut

sub url {
    my $self = shift;
    $self->_url(@_) if @_;
    return $self->_url;
}

sub DESTROY {
    shift->disconnect;
    return;
}

=head1 SEE ALSO

L<Elive::Connection::SDK> L<Elive::Connection::API> L<SOAP::Lite>

=cut

1;
