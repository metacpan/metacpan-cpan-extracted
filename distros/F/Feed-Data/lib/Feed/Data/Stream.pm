package Feed::Data::Stream;

use Moo;
use Carp qw/croak/;
use LWP::UserAgent;
use HTTP::Request;
use Compiled::Params::OO qw/cpo/;

use Types::Standard qw/Str Any Object/;
our $validate;
BEGIN {
	$validate = cpo(
		open_stream => [Object],
		open_url => [Object],
		open_file => [Object],
		open_string => [Object],
		write_file => [Object, Str]
	);
}

our $VERSION = '0.01';

has 'stream' => (
	is  => 'rw',
	isa => Str,
	lazy => 1,
	default => q{}
);

has 'stream_type' => (
	is	  => 'ro',
	isa	 => Str,
	default => sub {
		my $self = shift;
		return 'url' if $self->stream =~ m{^http}xms;
		return 'string' if $self->stream =~ m{\<\?xml}xms;
		return 'file' if $self->stream =~ m{(\.xml|\.html)}xms; 
	}
);

sub open_stream {
	my ($self) = $validate->open_stream->(@_);
	my $type = 'open_' . $self->stream_type;
	return $self->$type;
}

sub open_url {
	my ($self) = $validate->open_url->(@_);
	my $stream = $self->stream;
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
	$ua->env_proxy;
	$ua->agent("Mozilla/8.0");
	my $req = HTTP::Request->new( GET => $stream );
	$req->header( 'Accept-Encoding', 'gzip' );
	my $res = $ua->request($req) or croak "Failed to fetch URI: $stream";
	if ( $res->code == 410 ) {
		croak "This feed has been permantly removed";
	}
	my $content = $res->decoded_content(charset => 'utf8');
	return \$content;
}

sub open_file {
	my ($self) = $validate->open_file->(@_);

	my $stream = $self->stream;

	open ( my $fh, '<', $stream ) or croak "could not open file: $stream";

	my $content = do { local $/; <$fh> };
	close $fh;

	return \$content;
}

sub open_string { 
	my ($self) = $validate->open_string(@_);	
	return shift->stream; 
}

sub write_file {
	my ($self, $feed) = $validate->write_file->(@_);
	my $stream = $self->stream;
	open my $FILE, ">", $stream  or croak "could not open file: $stream";
	print $FILE $feed;
	close $FILE;
}

1; # End of Feed::Data
