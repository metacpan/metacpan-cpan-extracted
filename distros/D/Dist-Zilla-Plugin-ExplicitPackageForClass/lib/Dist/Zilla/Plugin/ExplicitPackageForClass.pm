use v5.26;
use warnings;

package Dist::Zilla::Plugin::ExplicitPackageForClass;
# ABSTRACT: Insert an explicit package statement for class declarations
$Dist::Zilla::Plugin::ExplicitPackageForClass::VERSION = '1.00';

use Dist::Zilla;
use Moose;
use namespace::autoclean;
use version 0.9915 ();

with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileFinderUser' => {
	default_finders => [ ':InstallModules' ]
};


sub munge_files {
	# uncoverable pod - see Dist::Zilla::Role::FileMunger
	my ($self) = @_;
	
	$self->munge_file($_) for $self->found_files->@*;
}


sub munge_file {
	# uncoverable pod - see Dist::Zilla::Role::FileMunger
	my ($self, $file) = @_;
	
	my $original = $file->content;
	my $munged   = $self->_munge_chunk($file, $original);
	
	$file->content($munged) if $munged ne $original;
}


sub _munge_chunk {
	my ($self, $file, $chunk) = @_;
	
	my ($keyword, $name) = $chunk =~ m{^\h*\K (class|role) \h+ ([^\s\{;#]+)}mpx;
	return $chunk unless defined $name;
	
	my $before = ${^PREMATCH};
	my $after = ${^POSTMATCH};
	my $class = ${^MATCH};
	
	my $version = version->parse( $self->zilla->version )->stringify;
	$version =~ tr/_//d;
	my $package = "package $name $version;";
	$package .= ' # TRIAL' if $self->zilla->is_trial;
	
	if ($before =~ s{\n\h* (\n\h*) \z}{$1$package$1}x) {
		# The regex doesn't recognise a class declaration at the beginning
		# of the file. However, current versions of perl require something
		# like `use feature 'class'` to come before it anyway.
		
		$after = $self->_munge_chunk($file, $after);  # handle multiple classes
		return $before . $class . $after;
	}
	else {
		$self->log_fatal(
			sprintf 'No blank line for package before "%s %s" in %s',
			$keyword, $name, $file->name );
	}
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ExplicitPackageForClass - Insert an explicit package statement for class declarations

=head1 VERSION

version 1.00

=head1 SYNOPSIS

F<dist.ini>:

  version = v1.23
  [ExplicitPackageForClass]

Perl module source file in the working directory,
with an empty line before C<class>:

  ...
  
  class Some::Module;

Resulting module file in the built distribution, with
a C<package NAMESPACE VERSION> statement inserted:

  ...
  package Some::Module v1.23;
  class Some::Module;

=head1 DESCRIPTION

During the build, this L<FileMunger|Dist::Zilla::Role::FileMunger>
plugin for L<Dist::Zilla> will look through your code for
L<C<class>|perlclass/"class"> and C<role> declarations and insert
a corresponding L<C<package>|perlfunc/"package"> statement before
them, along with the package version.

If you've tried the L<perlclass> feature (also known as "Corinna")
introduced with S<Perl v5.38>, you may have run into problems with
the toolchain. Corinna defines new keywords such as C<class> that
can replace keywords like C<package> in modern code. Unfortunately,
as of 2023, many tools used by developers to process Perl module
distributions don't expect that Perl namespaces are declared
by any other keyword than C<package>. Even Dist::Zilla itself
is affected, as is L<PPI>, which is used by a number of
Dist::Zilla plugins, leading to the possibility of error messages
like these for files that declare namespaces with C<class>:

  [PkgVersion] skipping lib/Foo/Bar.pm: no package statement found
  [MetaProvides::Package] No namespaces detected in file lib/Foo/Baz.pm
  ... and so on

L<Object::Pad/"File Layout"> suggests that the C<class> declaration
should be preceded by a C<package> statement until toolchain
modules catch up. But manually duplicating the package name not
only looks ugly, it's also a chore and a possible source of bugs.
That's why this plugin will insert a C<package> statement for you
automatically before every C<class> / C<role> declaration.

The insertion only happens in the built distribution. The Perl
source files in your working directory will never be touched by
this plugin.

To ensure that line numbers won't change, it's required that the
line before the C<class> declaration is empty in your source file.
The empty line will be replaced with a C<package NAMESPACE VERSION>
statement by this plugin. Because that already includes the module
version, use of the L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>
plugin alongside this plugin should be avoided (or at least, custom
file finders should be used to avoid that both of them work on the
same files).

This plugin will only work on declarations where the C<class> /
C<role> keyword is the first non-whitespace part of a line and
is immediately followed by the namespace. However, it can't
distinguish between Perl code on the one hand and heredocs /
pod / data sections on the other. If valid class declarations
exist outside the code, this plugin may erroneously try to insert
a package declaration where it perhaps shouldn't.

This plugin is a stopgap that will hopefully become redundant
as the new experimental class feature stabilises and more parts
of Perl's toolchain add support for it.

=head1 ATTRIBUTES

=head2 finder

  [FileFinder::Filter / ModulesExceptFoo]
  finder = :InstallModules
  skip = Foo\.pm
  
  [ExplicitPackageForClass]
  finder = ModulesExceptFoo

The name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
for assembling the list of modules to work on. Defaults to
just C<:InstallModules>. May be given multiple times.

=head1 SEE ALSO

L<Object::Pad/"File Layout">

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
