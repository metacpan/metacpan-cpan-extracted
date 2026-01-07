package Gears::Config::Reader::PerlScript;
$Gears::Config::Reader::PerlScript::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Config;
use Path::Tiny qw(path);

extends 'Gears::Config::Reader';

has param 'declared_vars' => (
	isa => HashRef,
	default => sub { {} },
);

sub handled_extensions ($self)
{
	return qw(pl);
}

# declare no lexical vars other than $vars (visible in eval)
sub _clean_eval
{
	local $@;
	my $vars = $_[2];
	my $result = eval $_[1];
	die $@ if $@;

	return $result;
}

sub parse ($self, $config, $filename)
{
	my %vars = $self->declared_vars->%*;
	$vars{include} = sub ($inc_filename) {
		my $dir = path($filename)->parent;
		$config->parse(file => $dir->child($inc_filename));
	};

	my $vars_string = join '',
		map {
			if (ref $vars{$_} eq 'CODE') {
				qq{sub $_ { \$vars->{$_}->(\@_) } };
			}
			else {
				qq{sub $_ { \$vars->{$_} } };
			}
		}
		keys %vars;

	state $id = 0;
	++$id;
	my $eval = join ' ', split /\v/, <<~PERL;
	package Gears::Config::Reader::PerlScript::Sandbox::$id;
	use v5.40;
	$vars_string
	PERL

	try {
		return $self->_clean_eval(
			$eval . $self->_get_contents($filename),
			\%vars,
		);
	}
	catch ($ex) {
		Gears::X::Config->raise("error in $filename: $ex");
	}
}

