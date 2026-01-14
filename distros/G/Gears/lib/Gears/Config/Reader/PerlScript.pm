package Gears::Config::Reader::PerlScript;
$Gears::Config::Reader::PerlScript::VERSION = '0.101';
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
	my $_result;
	my $vars = $_[2];

	# avoid raising $@ when $@ is local
	my $_err = do {
		local $@;
		$_result = eval $_[1];
		$@;
	};

	die $_err if $_err;
	return $_result;
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
				qq{sub $_ { \$vars->{$_}->(\@_) }};
			}
			else {
				qq{sub $_ { \$vars->{$_} }};
			}
		}
		keys %vars;

	state $id = 0;
	++$id;
	my $eval = join ' ', split /\v/, <<~PERL;
	package Gears::Config::Reader::PerlScript::Sandbox$id;
	use strict;
	use warnings;
	use builtin qw(true false);
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

__END__

=head1 NAME

Gears::Config::Reader::PerlScript - Configuration reader for Perl scripts

=head1 SYNOPSIS

	use Gears::Config;
	use Gears::Config::Reader::PerlScript;

	my $reader = Gears::Config::Reader::PerlScript->new(
		declared_vars => {
			env => sub { $ENV{$_[0]} },
		},
	);

	my $config = Gears::Config->new(readers => [$reader]);
	$config->add(file => 'config.pl');

	# config.pl can contain:
	# {
	#     database => {
	#         host => env('DB_HOST'),
	#         port => 5432,
	#     },
	#     debug => false,
	# }

=head1 DESCRIPTION

Gears::Config::Reader::PerlScript reads configuration from Perl script files
that return hash references. The scripts are evaluated in a restricted sandbox
with C<strict> and C<warnings> enabled, and have access to C<true> and C<false>
from L<builtin>.

This reader provides an C<include> function automatically, allowing
configuration files to include other files relative to their location. Additional
functions or values can be made available through the C<declared_vars>
attribute.

Example configuration file:

	{
		app => {
			name => 'My Application',
			version => '1.0',
		},
		database => include('db_config.yml'),
		features => {
			cache => true,
			debug => false,
		},
	}

=head1 INTERFACE

=head2 Attributes

=head3 declared_vars

A hash reference of variables to make available in the configuration script.
Values can be either scalars or code references. Scalars are exposed as
functions returning that value, while code references are exposed as
functions calling that code with passed arguments.

I<Available in constructor>

Example:

	my $reader = Gears::Config::Reader::PerlScript->new(
		declared_vars => {
			hostname => 'localhost',          # a => hostname,
			env => sub { $ENV{$_[0]} },       # b => env(HOME),
		},
	);

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 handled_extensions

	@extensions = $reader->handled_extensions()

Returns C<('pl')>, indicating this reader handles files with the C<.pl>
extension.

=head3 parse

	$hash_ref = $reader->parse($config, $filename)

Evaluates the Perl script in the file and returns the resulting hash reference.
The script is evaluated in a clean package namespace with C<strict> and
C<warnings> enabled.

Raises C<Gears::X::Config> if there is an error evaluating the script.

