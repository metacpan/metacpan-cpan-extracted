package EntityModel::Web::Apache2::Request;
BEGIN {
  $EntityModel::Web::Apache2::Request::VERSION = '0.001';
}
use EntityModel::Class {
	_isa	=> ['EntityModel::Web::Request'],
	r	=> { type => 'Apache2::RequestRec' },
	req	=> { type => 'Apache2::Request' },
};

=head1 NAME

EntityModel::Web::Authorization - handle permissions for page and object access

=head1 VERSION

version 0.001

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

use EntityModel::Web::Request;

# Handle modules.
eval {
	# PERL_DL_NONLAZY=1 is set by default, and we don't have our symbols available outside
	# Apache so this would fail normally - waiting for APR::Request::Magic to 'fix' this.
	require Apache2::RequestRec;
	require Apache2::Request;
};
use Apache2::RequestUtil;
use APR::Table;
use Apache2::RequestIO;
use Apache2::Const qw/OK DECLINED REDIRECT SERVER_ERROR MODE_READBYTES NOT_FOUND/;
use APR::Const qw/NONBLOCK_READ/;
use Apache2::ServerRec;
use Apache2::Process;
use Apache2::Filter;
use APR::Bucket;
use HTTP::Date;
use URI;

use constant IOBUFSIZE => 4096;

sub new {
	my $class = shift;
	my $r = shift;
	my ($proto) = $r->protocol =~ m{^HTTP/(.*)$};
	my $self = $class->SUPER::new(
		method	=> lc $r->method,
		path	=> $r->uri,
		version	=> $proto,
		header	=> [
			{ name => 'Host',	value => $r->hostname },
			{ name => 'User-Agent', value => 'EntityModel/0.1' },
		]
	);
	return $self;
}

sub old {
	my $class = shift;
	my $r = shift || return;

	logStack("Bad type: %s", ref($r)) unless $r && ref($r) && $r->isa('Apache2::RequestRec');

	my $self = { r	=> $r };
	bless $self, $class;
	my $q = Apache2::Request->new($r);
	$self->req($q);

# Apply some standard Apache2 data, likely to be needed for each request
	$self->$_($r->$_) foreach (qw(uri hostname method));

# All POST data
	my %postKeys;
	@postKeys{$q->param} = ();
	$self->post->set($_, $q->param($_)) foreach sort keys %postKeys;

# All GET data
	my $uri = URI->new($r->unparsed_uri);
	my %getKeys = $uri->query_form;
	# @getKeys{$q->args} = ();
	$self->get->set($_, $getKeys{$_}) foreach sort keys %getKeys;

	return $self;
}

sub setLifetime {
	my $self = shift;
	my $hours = shift;
	my $r = $self->r or return;

# Apache2::RequestRec;
# APR::Table;
	if ($r->protocol =~ /(\d\.\d)/ && $1 >= 1.1) {
		my $v = "max-age=" . $hours * 60 * 60;
		logDebug("Set cache control to [%s]", $v);
		$r->headers_out->add('Cache-Control', $v);
	} else {
		my $v = HTTP::Date::time2str(time + $hours * 24 * 60 * 60);
		logDebug("Set old expires header to [%s]", $v);
		$r->headers_out->add('Expires', $v);
	}
	return $self;
}

sub no_cache {
	my $self = shift;
	$self->r->no_cache(1);
	return $self;
}

sub protocol {
	my $self = shift;
	return $self->r->protocol;
}

sub content_type {
	my $self = shift;
	my $type = shift;
	my $r = $self->r or return;
	logDebug("Already set content type to [%s], now [%s]?", $self->{ content_type }, $type) if $self->{content_type};
	$self->{ content_type } = $type;
	return $r->content_type($type);
}

sub print {
	my ($self, @data) = @_;
	my $r = $self->r or return;
	$self->content_type('text/html') unless $self->{ content_type };
	return $r->print(@data);
}

sub post_body {
	my $r = shift;

	my $bb = APR::Brigade->new($r->pool, $r->connection->bucket_alloc);

	my $data = '';
	my $seen_eos = 0;
	do {
		$r->input_filters->get_brigade($bb, Apache2::Const::MODE_READBYTES, APR::Const::NONBLOCK_READ, IOBUFSIZE);

		for (my $b = $bb->first; $b; $b = $bb->next($b)) {
			if ($b->is_eos) {
				$seen_eos++;
				last;
			}

			if ($b->read(my $buf)) {
				$data .= $buf;
			}

			$b->remove;
		}
	} while (!$seen_eos);

	$bb->destroy;

	return $data;

}

sub cookie {
	my $self = shift;
	my $k = shift;
	if(@_) {
		my $v = shift;
		my $c = Apache2::Cookie->new(
			$self->r,
			-name => $k,
			-value => $v,
			-path => '/',
			-expires => '+1d',
		);
		$self->r->err_headers_out->add('Set-Cookie' => $c->as_string);
		return $self;
	}
	my $c = $self->r->headers_in->{'Cookie'};
	my ($v) = $c ? ($c =~ /\b\Q$k\E=([^;]*)/) : ();
	$c = $self->r->err_headers_out->get('Cookie');
	my ($ov) = $c ? ($c =~ /\b\Q$k\E=([^;]*)/) : ();
	$v = $ov if defined $ov;
	return $v;
}

sub ok { Apache2::Const::OK; }

sub redirectStatus { Apache2::Const::REDIRECT; }

sub notFound { Apache2::Const::NOT_FOUND; }

sub wantRedirect {
	my $self = shift;
	return 1 if $self->redirect;
}

sub followRedirect {
	my $self = shift;
	die "No redirect" unless $self->redirect;
	logDebug("Redirect to [%s]", $self->redirect);
	$self->r->headers_out->set(Location => $self->redirect);
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.