package Dist::Zilla::Plugin::Substitute;
$Dist::Zilla::Plugin::Substitute::VERSION = '0.007';
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw/ArrayRef CodeRef Str/;
use List::Util 'first';
use Carp 'croak';

enum 'Mode', [qw/lines whole/];

with 'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	};

my $codeliteral = subtype as CodeRef;
coerce $codeliteral, from ArrayRef, via {
	my $code = sprintf 'sub { %s }', join "\n", @{$_};
	eval $code or croak "Couldn't eval: $@";
};

has code => (
	is       => 'ro',
	isa      => $codeliteral,
	coerce   => 1,
	required => 1,
);
has filename_code => (
	is        => 'ro',
	isa       => $codeliteral,
	coerce    => 1,
	predicate => '_has_filename_code',
);

sub mvp_multivalue_args {
	return qw/code filename_code files/;
}

sub mvp_aliases {
	return {
		content_code => 'code',
		file         => 'files',
	};
}

has mode => (
	is => 'ro',
	isa => 'Mode',
	default => 'lines',
);

has files => (
	isa     => ArrayRef[Str],
	traits  => ['Array'],
	lazy    => 1,
	default => sub { [] },
	handles => {
		files => 'elements',
	},
);

sub munge_files {
	my $self = shift;

	if (my @filenames = $self->files) {
		foreach my $file (@{ $self->zilla->files }) {
			$self->munge_file($file) if first { $file->name eq $_ } @filenames;
		}
	}
	else {
		$self->munge_file($_) for @{ $self->found_files };
	}

	return;
}

sub munge_file {
	my ($self, $file) = @_;

	my $code = $self->code;

	if ($self->mode eq 'lines') {
		my @content = split /^/m, $file->content;
		$code->() for @content;
		$file->content(join '', @content);
	}
	else {
		my $content = $file->content;
		$code->() for $content;
		$file->content($content);
	}

	if ($self->_has_filename_code) {
		my $filename      = $file->name;
		my $filename_code = $self->filename_code;
		$filename_code->() for $filename;
		$file->name($filename);
	}

	return;
}

1;

# ABSTRACT: Substitutions for files in dzil

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Substitute - Substitutions for files in dzil

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 [Substitute]
 finder = :ExecFiles
 code = s/Foo/Bar/g
 
 ; alternatively
 [Substitute]
 file = lib/Buz.pm
 code = s/Buz/Quz/g
 filename_code = s/Buz/Quz/

=head1 DESCRIPTION

This module performs substitutions on files in Dist::Zilla.

=head1 ATTRIBUTES

=head2 code (or content_code)

An arrayref of lines of code. This is converted into a sub that's called for each line, with C<$_> containing that line. Alternatively, it may be a subref if passed from for example a pluginbundle. Mandatory.

=head2 mode

Either C<lines>(the default) or C<whole>. This determines if the substitution is done per line or per whole file.

=head2 filename_code

Like C<content_code> but the resulting sub is called for the filename.
Optional.

=head2 finders

The finders to use for the substitutions. Defaults to C<:InstallModules, :ExecFiles>. May also be spelled as C<finder> in the dist.ini.

=head2 files

The files to substitute. It defaults to the files in C<finders>. May also be spelled as C<file> in the dist.ini.

# vim: ts=4 sts=4 sw=4 noet :

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
