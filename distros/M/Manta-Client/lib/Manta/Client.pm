package Manta::Client 0.6;

use strict;
use warnings;
use Carp 'croak';
use Crypt::OpenSSL::RSA;
use JSON::Parse 'parse_json';
use LWP::UserAgent;
use MIME::Base64 'encode_base64';
use Net::SSH::Perl::Key;

sub new {
	my $class = shift;
	croak "Illegal parameter list has odd number of values" if @_ % 2;
	my %params = @_;
	my $self = {};
	bless $self, $class;
	for my $required (qw{ user url key_file }) {
		croak "Required parameter '$required' not passed to '$class' constructor" unless defined $params{$required};  
		$self->{$required} = $params{$required};
	}
	return $self;
}

sub _request {
	my $self = shift;
	croak "Illegal parameter list has odd number of values" if @_ % 2;
	my %params = @_;
	for my $required (qw{ method path }) {
		croak "Required parameter '$required' not passed to _request method" unless defined $params{$required};  
	}
	my $date = scalar gmtime;
	my $date_header = "date: $date";
	open F, "<$self->{key_file}";
	my $key = join '', <F>;
	close F;
	my $fingerprint = Net::SSH::Perl::Key->read_private("RSA", $self->{key_file})->fingerprint("md5");
	my $privatekey = Crypt::OpenSSL::RSA->new_private_key($key);
	$privatekey->use_sha256_hash();
	my $signature = encode_base64($privatekey->sign($date_header), "");
	my $h = HTTP::Headers->new(%{$params{headers}});
	$h->header(date => $date);
	$h->header('Authorization' => "Signature keyId=\"/$self->{user}/keys/$fingerprint\",algorithm=\"rsa-sha256\",signature=\"$signature\"");
	my $ua = LWP::UserAgent->new(default_headers => $h);
	my $response;
	if ($params{method} eq "GET") {
		$response = $ua->get("$self->{url}/$params{path}");
		if ($response->is_success) {
			return $response->decoded_content;
		} else {
			return undef;
		}
	} elsif ($params{method} eq "PUT") {
		$response = $ua->put("$self->{url}/$params{path}", Content => $params{content}, %$h);
		return !!$response->is_success;
	} elsif ($params{method} eq "DELETE") {
		$response = $ua->delete("$self->{url}/$params{path}");
		return !!$response->is_success;
	} else {
		croak ("bad method");
	}
}

sub get {
	my ($self, $path) = @_;
	my $response = $self->_request(path => $path, method => "GET");
	return $response;
}

sub put {
	my $self = shift;
	croak "Illegal parameter list has odd number of values" if @_ % 2;
	my %params = @_;
	croak "Required parameter 'path' not passed to put method put" unless defined $params{path};
	return $self->_request(path => $params{path}, method => "PUT", content => $params{content}, headers => {"content-type" => $params{"content-type"}});
}

sub rm {
	my ($self, $path) = @_;
	my $response = $self->_request(path => $path, method => "DELETE");
	return $response;
}

sub mkdir {
	my ($self, $path) = @_;
	return $self->put(path => $path, "content-type" => "application/json; type=directory");
}

sub ls {
	# FIXME - limited to 256 objects
	my ($self, $path) = @_;
	my $response = $self->_request(path => $path, method => "GET");
	if ($response) {
		my %results;
		foreach(split '\n', $response) {
			my $json = parse_json($_);
			$results{$json->{name}} = { type => $json->{type}, mtime => $json->{mtime}, size => $json->{size}, etag => $json->{etag} };
		}
		return \%results;
	}
	return undef;
}

sub ln {
	my ($self, $src, $dst) = @_;
	return $self->_request(path => $dst, method => "PUT", headers => {Location => $src, "content-type" => "application/json; type=link"});
}

1;

__END__

=head1 NAME

Manta::Client - a Manta client implementation in Perl

=head1 SYNOPSIS

  my $manta = Manta::Client->new(user => $username,
    url => "https://us-east.manta.joyent.com",
    key_file => "/root/.ssh/id_rsa");
  my $object = $manta->get("/$username/stor/file.txt");
  $manta->put(path => "/$username/stor/file.txt",
    content => $content,
    "content-type" => "text/plain");
  $manta->rm("$username/stor/file.txt");
  $manta->mkdir("/$username/stor/new_directory");
  my $files = $manta->ls("$username/stor");

=head1 DESCRIPTION

Manta::Client communicates with some of the API endpoints defined at L<https://apidocs.joyent.com/manta/>.

=head1 CLASS METHODS

=head2 new

This is the constructor method. It requires a hash argument containing three elements: C<user> - the Manta username; C<url> - the URL of the Manta API endpoint; and C<key_file> - the path to an SSH private key file

=head2 get

Gets an object. It requires a single argument, the Manta path of the object to retrieve. It returns the contents of the object, or undef on failure.

=head2 put

Put an object. It requires a hash argument containing: C<path> - destination Manta path; C<content> - contents of the object to be uploaded; and C<content-type> (optional) - the MIME type of the object (defaults to application/octet-stream)

It returns true on success and false on failure.

=head2 rm

Destroy an object. It requires a single argument, the Manta path of the object to destroy. It returns true on success and false on failure.

=head2 mkdir

Create a directory. It requires a single argument, the Manta path of the directory to create. It returns true on success and false on failure.

=head2 ls

List contents of a directory. It requires a single argument, the Manta path of the directory to list. It returns a hashref (keying on the object path) of hashrefs (or undef on failure). Each hashref has the following keys: C<type> - the MIME type; C<mtime> - the modification time in YYYY-mm-ddTHH:MM:ss.sssZ format; C<size> - size of the object in bytes; and C<etag> - UUID of the object

=head2 ln

Create a snaplink. It requires two parameters, the path from the source object and the path to the new snaplink.

It returns true on success and false on failure.
