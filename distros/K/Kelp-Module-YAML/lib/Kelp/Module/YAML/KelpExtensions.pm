package Kelp::Module::YAML::KelpExtensions;
$Kelp::Module::YAML::KelpExtensions::VERSION = '2.00';
use Kelp::Base -strict;

use Kelp::Module::YAML;
use Kelp::Request;
use Kelp::Response;
use Kelp::Test;

use Try::Tiny;
use Test::More;
use Test::Deep;

sub _replace
{
	my ($name, $new) = @_;

	no strict 'refs';
	no warnings 'redefine';

	my $old = \&{$name};
	*{$name} = sub {
		unshift @_, $old;
		goto $new;
	};
}

sub Kelp::Request::is_yaml
{
	my $self = shift;
	return 0 unless $self->content_type;
	return $self->content_type =~ m{$Kelp::Module::YAML::content_type_re};
}

sub Kelp::Request::yaml_param
{
	my $self = shift;

	my $hash = $self->{_param_yaml_content} //= do {
		my $hash = $self->yaml_content // {};
		ref $hash eq 'HASH' ? $hash : {ref $hash, $hash};
	};

	return $hash->{$_[0]} if @_;
	return keys %$hash;
}

sub Kelp::Request::yaml_content
{
	my $self = shift;
	return undef unless $self->is_yaml;

	return try {
		my @documents = $self->app->get_encoder(yaml => 'internal')->decode($self->content);
		die if @documents > 1;
		return $documents[0];
	}
	catch {
		undef;
	};
}

# Response

sub Kelp::Response::yaml
{
	my $self = shift;
	$self->set_content_type(
		$Kelp::Module::YAML::content_type,
		$self->charset || $self->app->charset
	);

	return $self;
}

_replace(
	'Kelp::Response::_render_ref',
	sub {
		my ($super, $self, $body) = @_;

		if ($self->content_type =~ m{$Kelp::Module::YAML::content_type_re}) {
			return $self->app->get_encoder(yaml => 'internal')->encode($body);
		}
		else {
			return $super->($self, $body);
		}
	}
);

# Test

sub Kelp::Test::yaml_content
{
	my $self = shift;
	my $result;
	my $decoder = $self->app->get_encoder(yaml => 'internal');
	try {
		$result = $decoder->decode(
			$self->_decode($self->res->content)
		);
	}
	catch {
		fail("Poorly formatted YAML");
	};
	return $result;
}

sub Kelp::Test::yaml_cmp
{
	my ($self, $expected, $test_name) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$test_name ||= "YAML structure matches";
	like $self->res->header('content-type'), qr/yaml/, 'Content-Type is YAML'
		or return $self;
	my $json = $self->yaml_content;
	cmp_deeply($json, $expected, $test_name) or diag explain $json;
	return $self;
}

1;

