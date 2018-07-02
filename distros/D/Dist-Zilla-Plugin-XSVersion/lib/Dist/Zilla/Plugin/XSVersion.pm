package Dist::Zilla::Plugin::XSVersion;
# ABSTRACT: a thing
$Dist::Zilla::Plugin::XSVersion::VERSION = '0.01';

use strict;
use warnings;
use Moose;

with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;
  return unless $file->name =~ /\.pm$/;
  my $perl = $file->content;
  my ($line, $module) = $perl =~ /((\$[\w:]+?::)VERSION.+?;)/;
  $perl =~ s/((\$[\w:]+?::)VERSION.+?;)/$2XS_VERSION = $1/;
  $perl =~ s/XSLoader::load\(([^)]+)\)/XSLoader::load($1, ${module}XS_VERSION)/;
  $file->content($perl);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::XSVersion - a thing

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  # dist.ini
  [XSVersion]

  # MyModule.pm
  package MyModule;

  require XSLoader;
  XSLoader::load('MyModule');

=head1 DESCRIPTION

A hackey, quick plugin to implement the commonly used $XS_VERSION pattern
required in order to support XS-loading of trial releases. This is not
possible using L<Dist::Zilla::Plugin::PkgVersion>, which will generate
something like:

  $MyModule::VERSION = '0.123_1'; # first line for CPAN indexer
  $MyModule::VERSION = '0.1231';  # next line for internal versioning

Without an explicit second argument, L<XSLoader/load> will attempt to load the
compiled module using a C<VERSIONCHECK> against the value of
C<$MyModule::VERSION>, which no longer matches C<0.123_1> after being
overwritten.

  $MyModule::VERSION = '0.123_1'; # first line for CPAN indexer
  $MyModule::VERSION = '0.1231';  # next line for internal versioning
  XSLoader::load('MyModule');     # gets the wrong $VERSION

This plugin rewrites the code above to something like:

  $MyModule::XS_VERSION = $MyModule::VERSION = '0.123_1';
  $MyModule::VERSION = '0.1231';
  XSLoader::load('MyModule', $MyModule::XS_VERSION);

=head1 CAVEATS

I have no patience for PPI, so instead I fudged it with a couple of quick
regexes. So long as you are using C<PkgVersion> to add $VERSION and do not do
anything fancy on your C<XSLoader::load> line (such as load the result of
evaluating an expression), everything should work. If not... well,
I<patches welcome>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
