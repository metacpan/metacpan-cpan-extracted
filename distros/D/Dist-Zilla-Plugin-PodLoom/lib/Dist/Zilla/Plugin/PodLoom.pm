#---------------------------------------------------------------------
package Dist::Zilla::Plugin::PodLoom;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 7 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Process module documentation through Pod::Loom
#---------------------------------------------------------------------

our $VERSION = '5.001';
# This file is part of Dist-Zilla-Plugin-PodLoom 5.001 (July 18, 2015)


use Moose 0.65; # attr fulfills requires
use Moose::Autobox;
with(qw(Dist::Zilla::Role::FileMunger
        Dist::Zilla::Role::ModuleInfo
        Dist::Zilla::Role::FileFinderUser) => {
          default_finders => [ ':InstallModules' ],
        },
);

# List minimum versions for AutoPrereqs:
use 5.008;
use Dist::Zilla 4.200001 ();               # abstract_from_file change
use Dist::Zilla::Role::ModuleInfo 0.08 (); # from Plugins, not PluginBundle

use Hash::Merge::Simple ();
use Pod::Loom 0.05 (); # bugtracker


has template => (
  is      => 'ro',
  isa     => 'Str',
  default => 'Default',
);


has data_file => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => 'data',
);

has data => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  builder  => '_initialize_data',
);

has loom => (
  is       => 'ro',
  isa      => 'Pod::Loom',
  init_arg => undef,
  lazy     => 1,
  default  => sub { Pod::Loom->new(template => shift->template) },
);

#---------------------------------------------------------------------
sub _initialize_data
{
  my $plugin = shift;

  my $fname = $plugin->data_file;

  return {} unless $fname;

  open my $fh, '<', $fname or die "can't open $fname for reading: $!";
  my $code = do { local $/; <$fh> };
  close $fh;

  local $@;
  my $result = eval "package Dist::Zilla::Plugin::PodLoom::_eval; $code";

  die $@ if $@;

  return $result;
} # end _initialize_data

#---------------------------------------------------------------------
sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for $self->found_files->flatten;
} # end munge_files

#---------------------------------------------------------------------
sub munge_file
{
  my ($self, $file) = @_;

  my $info = $self->get_module_info($file);

  my $abstract = Dist::Zilla::Util->abstract_from_file($file);
  my $repo     = $self->zilla->distmeta->{resources}{repository};

  my $module = $info->name;
  if (!$module or $module eq 'main') {
    $module = $file->name;
    $module =~ s!^.*/!!s;       # Strip directory names
  }

  my $dataHash = Hash::Merge::Simple::merge(
    {
      ($abstract ? (abstract => $abstract) : ()),
      authors        => $self->zilla->authors,
      dist           => $self->zilla->name,
      license_notice => $self->zilla->license->notice,
      module         => $module,
      bugtracker     => $self->zilla->distmeta->{resources}{bugtracker},
      repository     => $repo->{web} || $repo->{url},
      # Have to stringify version object:
      ($info->version ? (version => q{} . $info->version) : ()),
      zilla          => $self->zilla,
    }, $self->data,
  );

  my $method = Dist::Zilla->VERSION < 5 ? 'content' : 'encoded_content';

  my $content = $file->$method;

  $file->$method( $self->loom->weave(\$content, $file->name, $dataHash) );

  return;
} # end munge_file

#---------------------------------------------------------------------
around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  $config->{'Pod::Loom version'} = Pod::Loom->VERSION;

  return $config;
}; # end dump_config

#---------------------------------------------------------------------
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::PodLoom - Process module documentation through Pod::Loom

=head1 VERSION

This document describes version 5.001 of
Dist::Zilla::Plugin::PodLoom, released July 18, 2015
as part of Dist-Zilla-Plugin-PodLoom version 5.001.

=head1 SYNOPSIS

In your F<dist.ini>:

  [PodLoom]
  template = Default      ; this is the default
  data = loom.pl          ; there is no default for this

=head1 DESCRIPTION

If included, this plugin will process each F<.pm> and F<.pod> file
under F<lib> or in the root directory through Pod::Loom.

=head1 ATTRIBUTES

=head2 data

Since Pod::Loom templates may want configuration that doesn't fit in
an INI file, you can specify a file containing Perl code to evaluate.
The result should be a hash reference, which will be passed to
Pod::Loom's C<weave> method.

PodLoom automatically includes the following keys, which will be
merged with the hashref from your code.  (Your code can override these
values.)

=over

=item abstract

The abstract for the file being processed (if it can be determined)

=item authors

C<< $zilla->authors >>

=item dist

C<< $zilla->name >>

=item license_notice

C<< $zilla->license->notice >>

=item module

The primary package of the file being processed.  If Module::Metadata
could not determine the package, or if it is explicitly C<main>, this
is the filename (without directories), because that's the equivalent
of a package name for scripts.

=item repository

C<< $zilla->distmeta->{resources}{repository}{web} >>
(or the C<url> key if C<web> is not set)

=item version

The version number of the file being processed
(if Module::Metadata could determine it)

=item zilla

The Dist::Zilla object itself

=back


=for Pod::Coverage
munge_files?

=head2 finder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
whose files will be processed by L<Pod::Loom>.  It may be specified
multiple times.  The default value is C<:InstallModules>.


=head2 template

This will be passed to Pod::Loom as its C<template>.
Defaults to C<Default>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugin-PodLoom AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugin-PodLoom >>.

You can follow or contribute to Dist-Zilla-Plugin-PodLoom's development at
L<< https://github.com/madsen/dist-zilla-plugin-podloom >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
