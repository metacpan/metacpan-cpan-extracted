package EntityModel::Apache2::Apache;
BEGIN {
  $EntityModel::Apache2::Apache::VERSION = '0.001';
}
use EntityModel::Class { };

=head1 NAME

EntityModel::Web::Apache2::Apache - wrapper around Apache's request object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Apache2::RequestRec;
use Apache2::Request;
use Apache2::RequestUtil;
use APR::Table;
use HTTP::Date;

our @urlList;

BEGIN {
# Apache2::RequestRec wrappers
	foreach my $method (qw/uri unparsed_uri method headers_out no_cache hostname/) {
		no strict 'refs';
		*{__PACKAGE__ . '::' . $method} = sub {
			my ($self, @data) = @_;
			my $r = $self->{ r } || return;
			return $r->$method(@data);
		};
	}

# Apache2::Request wrappers
	foreach my $method (qw/param/) {
		no strict 'refs';
		*{__PACKAGE__ . '::' . $method} = sub {
			my ($self, @data) = @_;
			my $req = $self->req || return;
			return $req->$method(@data);
		};
	}
}

sub new {
	my $class = shift;
	my $r = shift || return;

	logStack("Bad type: %s", ref($r)) unless $r && ref($r) && $r->isa('Apache2::RequestRec');

	my $self = {
		r	=> $r
	};
	bless $self, $class;
	return $self;
}

sub r { shift->{ r } }

sub req {
	my $self = shift;
	unless ($self->{ req }) {
		# my $req = APR::Request::Apache2->handle($self->{r});
		# $req->read_limit(512*1024*1024);
		# $req->parse();
		$self->{ req } = new Apache2::Request($self->{r});
	}
	return $self->{ req };
}

sub setLifetime {
	my $self = shift;
	my $hours = shift;

	my $r = $self->{ r } || return;

# Apache2::RequestRec;
# APR::Table;
	if ($r->protocol =~ /(\d\.\d)/ && $1 >= 1.1) {
	    $r->headers_out->add('Cache-Control', "max-age=" . $hours * 60 * 60);
	} else {
	    $r->headers_out->add('Expires',
			   HTTP::Date::time2str(time + $hours * 24 * 60 * 60));
	}
	return $self;
}

sub content_type {
	my $self = shift;
	my $type = shift;
	my $r = $self->{ r } || return;
	logDebug("Already set content type to [%s], now [%s]?", $self->{ content_type }, $type) if $self->{content_type};
	$self->{ content_type } = $type;
	return $r->content_type($type);
}

sub print {
	my ($self, @data) = @_;
	my $r = $self->{ r } || return;
	$self->content_type('text/html') unless $self->{ content_type };
	return $r->print(@data);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.