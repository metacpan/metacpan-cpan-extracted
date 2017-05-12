package EntityModel::Web::Request;
{
  $EntityModel::Web::Request::VERSION = '0.004';
}
use EntityModel::Class {
	post		=> { type => 'hash' },
	get		=> { type => 'hash' },
	uri		=> { type => 'URI::URL' },
	path		=> { type => 'string' },
	hostname	=> { type => 'string' },
	method		=> { type => 'string' },
	content_type	=> { type => 'string' },
	no_cache	=> { type => 'data' },
	protocol	=> { type => 'data' },
	version		=> { type => 'string' },
	redirect	=> { type => 'string' },
	header		=> { type => 'array', subclass => 'EntityModel::Web::Header' },
	header_by_name	=> { type => 'hash', scope => 'private', watch => { header => 'name' } },
};

=head1 NAME

EntityModel::Web::Request - abstraction for incoming HTTP request

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use EntityModel::Web::Request;
 my $req = EntityModel::Web::Request->new(
 );

=head1 DESCRIPTION

=cut

use URI;
use URI::QueryParam;
use HTTP::Date;
use EntityModel::Web::Header;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = @_;
	$self->{uri} = URI::URL->new;
	$self->{uri}->scheme('http');
	if(my $uri = delete $args{uri}) {
		$self->uri($uri);
	}
	$self->$_(delete $args{$_}) for grep { exists $args{$_} } qw{method path version hostname};
	if(my $header = delete $args{header}) {
		my @hdr;
		foreach my $item (@$header) {
			push @hdr, EntityModel::Web::Header->new(
				name	=> $item->{name},
				value	=> $item->{value},
			);
		}
		$self->header->push(@hdr);
	}
	if(my $host = $self->header_by_name->get('Host')) {
		$self->hostname($host->value);
	}
	return $self;
}

sub path {
	my $self = shift;
	if(@_) {
		$self->{path} = shift;
		$self->uri->path($self->{path});
		return $self;
	}
	return $self->{path};
}

sub hostname {
	my $self = shift;
	if(@_) {
		$self->{hostname} = shift;
		$self->uri->host($self->{hostname});
		return $self;
	}
	return $self->{hostname};
}

sub uri {
	my $self = shift;
	if(@_) {
		my $uri = shift;
		$self->update_uri_from($uri);
		return $self;
	}
	return $self->{uri};
}

sub update_uri_from {
	my ($self, $uri) = @_;
	$self->{uri} = $uri;
	$self->hostname($uri->host);
	$self->path($uri->path);
	$self->get->set($_, $uri->query_param($_)) for sort $uri->query_param;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
