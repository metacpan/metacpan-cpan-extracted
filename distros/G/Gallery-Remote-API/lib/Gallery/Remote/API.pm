package Gallery::Remote::API;

use strict;
use warnings;

use version 0.77; our $VERSION = qv('v0.1.4');

use base qw(Class::Accessor);
Gallery::Remote::API->mk_ro_accessors(qw(
	url username password version _remoteurl _cookiejar _useragent
));
Gallery::Remote::API->mk_accessors(qw(response result));

use Carp;
use URI;
use URI::QueryParam;
use LWP::UserAgent;
use HTTP::Cookies;
use File::Temp;
use Config::Properties;
use Data::Diver qw(Dive);
use Sub::Name;
use Scalar::Util qw(blessed);
use Fcntl qw(:seek);


#constants

use constant PROTOCOL_VERSION => 2.9;

use constant ACCESSPAGE => {
	1 => 'gallery_remote2.php',
	2 => 'main.php'
};

## actions

## we auto-build methods for each known Protocol command

BEGIN {
	
    no strict 'refs';

	foreach (qw(
		fetch_albums
		fetch_albums_prune
		add_item
		album_properties
		new_album
		fetch_album_images
		move_album
		increment_view_count
		image_properties
		no_op
	)) {
		my $cmd = $_; $cmd =~ s/\_/\-/g;
		my $method = sub {
			my ($self,$params) = @_;
			return $self->execute_command("$cmd",$params);
		};
		my $methname = "Gallery::Remote::API::$_";
		subname($methname,$method);
		*{$methname} = $method;
	}
};

#except for login, for which we want the user/pass goodness

sub login {
	my $self = shift;

	croak "Must define username during object construction to login"
		unless my $u = $self->username;
	croak "Must define password during object construction to login"
		unless my $p = $self->password;

	return $self->execute_command('login', {
			uname    => $u, password => $p
	});
}

# the big boy

sub execute_command {
	my ($self,$command,$params) = @_;

	#clear any previous response and result
	$self->response(undef);
	$self->result(undef);

	croak "Must pass a command" unless $command;
	$params = {} unless defined $params;

	$params->{protocol_version} ||= PROTOCOL_VERSION;
	#if you try and send this, I'm just going to overwrite
	$params->{cmd} = $command;

	my $useparams = {};
	if ($self->version == 2) {
		foreach (keys %$params) {
			next if $_ =~ /^userfile/;
			$useparams->{"g2_form[$_]"} = $params->{$_};
		}

		#hack these goofy exceptions
		# see: http://codex.gallery2.org/Gallery_Remote:Protocol#G2_support
		if (my $uf = $params->{userfile}) {
			#also do the arrayref bit here so lwp knows to read the file
			$useparams->{g2_userfile} = [$uf];
		}
		if (my $ufn = $params->{userfile_name}) {
			$useparams->{g2_userfile_name} = $ufn;
		}
	}
	else {
		$useparams = $params;
	}

	#do it!
	my $res = $self->_useragent->post(
		$self->_remoteurl,
		Content_Type => $command eq 'add-item' ?
			'multipart/form-data' : 'application/x-www-form-urlencoded',
		Content => $useparams
	);
	
	if ($res->is_success) {
		$self->response($res->content);
		return $self->_parse_response;
	}

	#carp "Server Error: ".$res->status_line."\n";
	# fake an error in the same style as those returned by the protocol
	# throw in the response object itself in case anyone finds it useful
	$self->result({status => 'server_error', status_text => $res->message, response => $res});
	return;
}

sub _parse_response {
	my $self = shift;
	if (my $response = $self->response) {

		#drop anything before the proto tag
		$response =~ s/^(.*)#__GR2PROTO/#__GR2PROTO/;

		#this is stupid. They return a Java Properties stream. We
		#want Config::Properties to deserialize it for us, but that
		#module wants to load from a filehandle, it doesn't look like
		#you can just pass it data. Hence...
		my $virtualfile = '';
		open(my $fh, '+>', \$virtualfile)
			|| croak "Failed to open virtual file: $!";
		print $fh $response;
		seek($fh,0,SEEK_SET);

		my $cp = new Config::Properties;
		$cp->load($fh);

		my $result = $cp->splitToTree;

		#now let's improve deserialization on a few things where we get a csv
		#list that ought to be an array (does Properties not serialize
		#on the "value" side? I don't see any way to differentiate a csv from
		#ordinary data with a comma in it)

			# use DataDiver so as not to autovivify if not there

		#from fetch-albums & fetch-abums-prune
		if (my $ef = Dive($result, qw( album info extrafields ))) {
			foreach (keys %$ef) {
				$result->{album}->{info}->{extrafields}->{$_} = [
					split(',',$result->{album}->{info}->{extrafields}->{$_})
				];
			}
		}
		#from album-properties
		if (my $ef = Dive($result, qw(extrafields))) {
			$result->{extrafields} = [ split(',',$ef) ];
		}

		$self->result($result);
		unless (exists $result->{status}) {
			$result->{status} = 'unknown_error';
			$result->{status_text} = $result->{Error} || 'unknown error';
		}

		unless ($result->{status}) { #success is 0, don't do on fail
			#add/replace the security token, if present
			if (my $newtoken = $result->{auth_token}) {
				$self->_remoteurl->query_param(g2_authToken => $newtoken);
			}
			return $result 
		};
	}
	return;
}


#constructor

# Override parent C:A's new method to do some validation and default
# as needed before passing arguments into the RO accessors

sub new {
	my ($class,$args) = @_;
	$class = ref $class || $class;

	my $cleanargs = $class->_parse_constructor_args($args);
	my $self = $class->SUPER::new($cleanargs);
	bless $self,$class;

	return $self;
}

sub _parse_constructor_args {
	my ($self,$args) = @_;

	unless (ref $args eq 'HASH') {
		croak "Must pass arguments as a hashref; 'url' required at minimum";
	}

	my %cleanargs;
	$args->{version} ||= 2;
	foreach (keys %$args) {
		if (($_ eq 'url') && (my $u = $args->{url})) {

			if (ref $u && blessed $u && $u->isa('URI')) {
				$cleanargs{$_} = $u;
			}
			elsif (ref $u) {
				croak "url must be a URI object, or a string";
			}
			else {
				$u  = "http://$u" unless (substr($u,0,7) eq 'http://');
				$cleanargs{$_} = URI->new($u);
			}
		}
		elsif ($_ eq 'version') {
			if ($args->{$_} =~ /^[12]$/) {
				$cleanargs{$_} = $args->{$_};
			}
			else {
				croak "Accepted values for Gallery version are '1' or '2'";
			}
		}
		elsif ($self->can($_)) {
			$cleanargs{$_} = $args->{$_};
		}
		else {
			carp "Unkown argument '$_'";
		}
	}

	if (my $u = $cleanargs{url}) {
		my $v = $cleanargs{version};
		$cleanargs{_remoteurl} = URI->new($u->canonical . ACCESSPAGE->{$v});
		if ($v == 2) {
			$cleanargs{_remoteurl}->query_param(g2_controller => 'remote:GalleryRemote');
		}
	}
	else {
		croak "'url' to the gallery installation is a required argument";
	}

	my $cj = File::Temp->new->filename;
	$cleanargs{_cookiejar} = $cj;

	my $ua = new LWP::UserAgent;
    $ua->cookie_jar(HTTP::Cookies->new(file => $cj, autosave => 1));
	$cleanargs{_useragent} = $ua;

	return \%cleanargs;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gallery::Remote::API - Interact with Gallery via the Gallery Remote Protocol


=head1 VERSION

This document describes Gallery::Remote::API version 0.01.01


=head1 SYNOPSIS
	
	use Gallery::Remote::API;

	my $gallery = new Gallery::Remote::API ({
		url => $url, version => $ver, username => $user, password => $pass
	});

	$gallery->login || die "can't log in!";


	## Then...

	if (my $result = $gallery->fetch_albums) { #etc
		# success! $result is a hashref of returned data
	}
	else {
		# failed! But we can still get $result, to see the error
		my $result = $gallery->result;
		print "error = " . $result->{status_text};
	}

=head1 DESCRIPTION

"Gallery" is a PHP web photo gallery package; this module allows you to
interact with their Remote Protocol API. It is an alternative to
Gallery::Remote, which does not support Gallery2.


=head1 INTERFACE - COMMON METHODS

These are the general-purpose methods you'll use to interact with this class.

=head2 C<new>

	my $gallery = new Gallery::Remote::API ({
		url => $url, version => $ver, username => $user, password => $pass
	});

Constructs a new Gallery::Remote::API object. Arguments, which must be passed
as a hashref, are as follows:

=over 4

=item C<url> (required)

The main url to your Gallery installation, e.g. "mygallerysite.com", or
"http://mybigbadsite.com/galleries/". The 'http://' is optional. Can be
passed as either a string or as a L<URI|URI> object.

Note that you probably can't use the url of an embedded Gallery installation,
you need to use the primary installation url. At least, that's my experience
with an installation embedded under Wordpress, where I have a
C<mygallery.mywordpresssite.com> primary installation embedded under a
C<mywordpresssite.com/gallery> address, the remote protocol only works under
C<mygallery.mywordpresssite.com>.


=item C<version>

The (major) version of your Gallery installation.
Accepted values are '1' or '2'; defaults to '2'.

=item C<username>

=item C<password>

The Gallery username and password under which you wish to log in

=back


=head2 C<result>

	my $result = $gallery->result

Returns a hashref containing the deserialized data tree resulting from the
most recently performed request. This is the same data that is returned from
a successful request, but you'll need this to get the error message on a fail.

The $result data will ALWAYS contain at least the following:

	{ status => $status_code, status_text => $message }

A status of '0' indicates a success, any other value is an error code.
'Proper' Remote Protocol error codes will be numeric, and the status_text
will describe the error.

See L<http://codex.gallery2.org/Gallery_Remote:Protocol#Appendix_A> for the
current list of status codes.

In the event that we fail to contact the remote server at all, we provide
the following, which includes the HTTP::Response object itself:

	{ status => 'server_error', status_text => $http_response->message,
		response => $http_response }

All other data included in the C<$result> is contextual to the request that
was made.


=head2 C<response>

	my $response = $gallery->response;

Returns the raw, un-deserialized response data resulting from the most
recently performed request. Data is formatted in a Java "Properties" stream,
exactly as returned by the Gallery Remote Protocol.

You shouldn't normally need this, but it may be useful for debugging.

=head2 C<url>

=head2 C<username>

=head2 C<password>

=head2 C<version>

	my $url = $gallery->url; #etc

Read-only accessors to retrieve the data you assigned on construction.


=head1 INTERFACE - PROTOCOL COMMAND METHODS

These are the methods which perform specific commands correlating to their
similarly named equivalents as specified by the protocol.

=head2 C<login>

	$gallery->login
		|| die "Can't log in: " . $gallery->result->{status_text};

Logs into the Gallery installation using the username and password that were
passed to the constructor. Not strictly necessary, as you may operate as a
"Guest", just like on the site, but you probably can't do much in that case.

=head2 C<fetch_albums>

=head2 C<fetch_albums_prune>

=head2 C<add_item>

=head2 C<album_properties>

=head2 C<new_album>

=head2 C<fetch_album_images>

=head2 C<move_album>

=head2 C<increment_view_count>

=head2 C<image_properties>

=head2 C<no_op>

Each of the above executes the corresponding command against the protocol.
Usage of each is identical:

	#general form

	my $result = $gallery->method_name(\%params) ||
		my $error_result = $gallery->result;

	#example

	my $result = $gallery->fetch_albums({ no_perms => 'yes' }) ||
		print "error = " . $gallery->result->{status_text} ."\n";

The parameters that can be passed to each individual method are documented
in the Gallery Codex at L<http://codex.gallery2.org/Gallery_Remote:Protocol>

In order to keep this module flexible, and reasonably backward-and-forward
compatible, we do no checking whatsover on what parameters you send, we let
it be between you and the remote server to determine what should or
shouldn't work.

However, you do NOT need to send the C<cmd> or C<protocol_version> parameters,
the module will handle these two for you. If you do send C<cmd>, it will be
ignored. However if you send C<protocol_version>, your value will be used
instead of the default (protocol_version = 2.9 as of this release).

I allow this because I can't find any good documentation regarding why we
send that parameter, or what happens when it changes, so I'll let you
overwrite it, if that helps you. If nothing else I imagine it may prove
useful for forward compatibility.

Also note, you do not need to specify your Gallery2 parameters in the

	g2_form[parametername]

format. Just use the parameter name itself, we will wrap it in the C<g2_form[]>.

Finally let me emphasize one point regarding parameters from Gallery's docs
that bit me until I remembered:

	album "names" and image "names" are actually the unique identifier (an 
	integer) of the object in G2, rather than an alphanumeric name

Let me add to that: these are I<not> the "reference numbers" which are returned
by, say fetch-albums, they are the ids that those reference nums point to.
So, for example, fetch-albums returns:

          'album' => { 'name' => { '6' => '116' } }

'116' here is the item id which they're calling 'name', not '6'. I'm not
sure where the '6' comes from, or if it's at all useful, except for referencing
back to other keys in that same result hash.


=head2 C<execute_command>
	
	my $result = $gallery->execute_command($command,\%params) ||
		my $error_result = $gallery->result;

C<execute_command> is the method which all of the above convenience methods
actually call underneath. I make it public again for forward/backward
compatibility -- you can use this method directly if there's an old or new
command available that you need, that we haven't covered with a convenience
method.

It works just like the methods above, except that you must pass the name
of the command to be executed as the first argument. Use the Gallery-native
form of the command, e.g. C<fetch-albums>, not C<fetch_albums>.


=head1 COMMAND LINE UTILITY C<remotegallery>

A barebones command line utility called C<remotegallery> is included with
the distribution which will allow you to execute arbitrary commands against
a Gallery server via this module. See the program's own docs at
L<remotegallery|bin/remotegallery> for complete
instructions, but general use is:

	remotegallery --url url --version N
		--username myusername --password mypassword
		--command thecommand  --parameters param1=val1&parm2=val2...


=head1 CONFIGURATION AND ENVIRONMENT
  
Gallery::Remote::API requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Class::Accessor|Class::Accessor>

L<URI|URI>

L<URI::QueryParam|URI::QueryParam>

L<LWP::UserAgent|LWP::UserAgent>

L<HTTP::Cookies|HTTP::Cookies>

L<File::Temp|File::Temp>

L<Config::Properties|Config::Properties>

L<Data::Diver|Data::Diver>

L<Sub::Name|Sub::Name>

L<Scalar::Util|Scalar::Util>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Limitations: this module has been tested and runs fine against a server
running Gallery Version 2.3.1, which reports server_version 2.14 (which I
believe to be the same as the protocol_version? But it's the newest release
and the docs say the protocol goes to 2.9? And what's up with different
protocol_versions for Gallery1 vs Gallery2, do I care? Their documents are
somewhat thin and frustrating. But hey, it's open source, and I'm not 
volunteering). So, YMMV as to whether this works for your installation, and
any input to help make sure this thing works for any implementation is
appreciated.

Please report any bugs or feature requests to
C<bug-gallery-remoteapi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

Gallery - L<http://gallery.sf.net/>

Gallery Remote:Protocol - L<http://codex.gallery2.org/Gallery_Remote:Protocol>

galleryadd.pl - L<http://freshmeat.net/projects/galleryadd/>

L<Gallery::Remote|Gallery::Remote>

=head1 AUTHOR

Jonathan Wright  C<< <mysteryte@cpan.org> >>

Latest development version available at 
L<http://github.com/mysteryte/gallery-remote-api>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Jonathan Wright C<< <mysteryte@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
