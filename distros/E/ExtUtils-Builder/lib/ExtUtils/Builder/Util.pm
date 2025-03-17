package ExtUtils::Builder::Util;
$ExtUtils::Builder::Util::VERSION = '0.015';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/get_perl require_module unix_to_native_path native_to_unix_path command code function/;

use Carp 'croak';
use Config;
use ExtUtils::Config;
use File::Spec;
use File::Spec::Unix;
use Scalar::Util 'tainted';

sub get_perl {
	my (%opts) = @_;
	my $config = $opts{config} // ExtUtils::Config->new;

	if (File::Spec->file_name_is_absolute($^X) and not tainted($^X)) {
		return $^X;
	}
	elsif ($config->get('userelocatableinc')) {
		require Devel::FindPerl;
		return Devel::FindPerl::find_perl_interpreter($config);
	}
	else {
		return $opts{config}->get('perlpath');
	}
}

sub require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

sub command {
	my (@command) = @_;
	require ExtUtils::Builder::Action::Command;
	return ExtUtils::Builder::Action::Command->new(command => \@command);
}

sub code {
	my %args = @_;
	require ExtUtils::Builder::Action::Code;
	return ExtUtils::Builder::Action::Code->new(%args);
}

sub function {
	my %args = @_;
	require ExtUtils::Builder::Action::Function;
	return ExtUtils::Builder::Action::Function->new(%args);
}

my %cache;
sub glob_to_regex {
	my $input = shift;
	return $cache{$input} ||= do {
		my $regex = _glob_to_regex_string($input);
		qr/^$regex$/;
	};
}

sub _glob_to_regex_string {
	my $glob = shift;
	my $in_curlies;
	local $_ = $glob;

	my $regex = !/\A(?=\.)/ ? '(?=[^\.])' : '';
	while (!/\G\z/mgc) {
		if (/\G([^\/.()|+^\$@%\\*?{},\[\]]+)/gc) {
			$regex .= $1;
		}
		elsif (m{\G/}gc) {
			$regex .= !/\G(?=\.)/gc ? '/(?=[^\.])' : '/'
		}
		elsif (/ \G ( [.()|+^\$@%] ) /xmgc) {
			$regex .= quotemeta $1;
		}
		elsif (/ \G \\ ( [*?{}\\,] ) /xmgc) {
			$regex .= quotemeta $1;
		}
		elsif (/\G\*/mgc) {
			$regex .= "[^/]*";
		}
		elsif (/\G\?/mgc) {
			$regex .= "[^/]";
		}
		elsif (/\G\{/mgc) {
			$regex .= "(";
			++$in_curlies;
		}
		elsif (/\G \[ ( [^\]]+ ) \] /xgc) {
			$regex .= "[\Q$1\E]";
		}
		elsif ($in_curlies && /\G\}/mgc) {
			$regex .= ")";
			--$in_curlies;
		}
		elsif ($in_curlies && /\G,/mgc) {
			$regex .= "|";
		}
		elsif (/\G([},]+)/gc) {
			$regex .= $1;
		}
		else {
			croak sprintf "Couldn't parse at %s|%s", substr($_, 0 , pos), substr $_, pos;
		}
	}

	return $regex;
}

sub unix_to_native_path {
	my ($input) = @_;
	my ($volume, $unix_dir, $file) = File::Spec::Unix->splitpath($input);
	my @splitdir = File::Spec::Unix->splitdir($unix_dir);
	my $catdir = File::Spec->catdir(@splitdir);
	return File::Spec->catpath($volume, $catdir, $file);
}

sub native_to_unix_path {
	my ($input) = @_;
	my ($volume, $unix_dir, $file) = File::Spec->splitpath($input);
	my @splitdir = File::Spec->splitdir($unix_dir);
	my $catdir = File::Spec::Unix->catdir(@splitdir);
	return File::Spec::Unix->catpath($volume, $catdir, $file);
}

1;

# ABSTRACT: Utility functions for ExtUtils::Builder

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Util - Utility functions for ExtUtils::Builder

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This is a module containing some helper functions for L<ExtUtils::Builder>.

=head1 FUNCTIONS

=head2 function(%arguments)

This is a shorthand for calling L<ExtUtils::Builder::Action::Function|ExtUtils::Builder::Action::Function>'s contructor.

=head2 command(%arguments)

This is a shorthand for calling L<ExtUtils::Builder::Action::Code|ExtUtils::Builder::Action::Code>'s contructor.

=head2 code(@command)

This is a shorthand for calling L<ExtUtils::Builder::Action::Code|ExtUtils::Builder::Action::Code>'s contructor, with C<@command> passed as its C<command> argument.

=head2 glob_to_regex($glob)

This translates a unix glob expression (e.g. C<*.txt>) to a regex.

=head2 unix_to_native_path($path)

This converts a unix path to a native path.

=head2 native_to_unix_path($path)

This converts a native path to a unix path.

=head2 get_perl(%options)

This function takes a hash with various (optional) keys:

=over 4

=item * config

An L<ExtUtils::Config|ExtUtils::Config> (compatible) object.

=back

=head2 require_module($module)

Dynamically require a module.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
