#---------------------------------------------------------------------
package Dist::Zilla::Plugin::ModuleBuild::Custom;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 11 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Allow a dist to have a custom Build.PL
#---------------------------------------------------------------------

our $VERSION = '4.26';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use Moose;
extends 'Dist::Zilla::Plugin::ModuleBuild';
with qw(Dist::Zilla::Role::FilePruner
        Dist::Zilla::Role::HashDumper);

use List::Util ();

# We're trying to make the template executable before it's filled in,
# so we want delimiters that look like comments:
has '+delim' => (
  default  => sub { [ '##{', '##}' ] },
);

has distmeta1 => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_distmeta1',
);

sub _build_distmeta1
{
  my $self = shift;

  require CPAN::Meta::Converter;
  CPAN::Meta::Converter->VERSION(2.101550); # improved downconversion

  my $converter = CPAN::Meta::Converter->new($self->zilla->distmeta);
  return $converter->convert(version => '1.4');
} # end _build_distmeta1

# Get rid of any META.yml we may have picked up from Module::Build:
sub prune_files {
  my ($self) = @_;

  my $files = $self->zilla->files;
  @$files = grep { not($_->name =~ /^META\.(?:yml|json)$/ and
                       $_->isa('Dist::Zilla::File::OnDisk')) } @$files;

  return;
} # end prune_files


sub get_meta
{
  my $self = shift;

  # Extract the wanted keys from distmeta:
  return $self->extract_keys(distmeta1 => $self->distmeta1, @_);
} # end get_meta
#---------------------------------------------------------------------


sub get_prereqs
{
  my ($self, $api_version) = @_;

  if ($api_version) {
    $self->log_fatal("api_version $api_version is not supported")
        unless $api_version == 1;
    local $@;
    $self->log(["WARNING: Dist::Zilla %s does not support api_version %d",
                Dist::Zilla->VERSION, $api_version ])
        unless eval { Dist::Zilla::Plugin::ModuleBuild->VERSION( 4.300032 ) };

    return $self->get_default(qw(build_requires configure_requires requires
                                 test_requires recommends conflicts));
  }

  $self->get_meta(qw(build_requires configure_requires requires recommends
                     conflicts));
} # end get_prereqs

#---------------------------------------------------------------------


has _default_mb_args => (
  is        => 'ro',
  isa       => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => 'module_build_args',
);

sub get_default
{
  my $self = shift;

  return $self->extract_keys(module_build => $self->_default_mb_args, @_);
} # end get_default

sub add_file {}                 # Don't let parent class add any files

#---------------------------------------------------------------------
sub setup_installer
{
  my $self = shift;

  my $file = List::Util::first { $_->name eq 'Build.PL' }
             @{ $self->zilla->files }
      or $self->log_fatal("No Build.PL found in dist");

  # Process Build.PL through Text::Template:
  my %data = (
     dist    => $self->zilla->name,
     meta    => $self->distmeta1,
     meta2   => $self->zilla->distmeta,
     plugin  => \$self,
     version => $self->zilla->version,
     zilla   => \$self->zilla,
  );

  # The STRICT option hasn't been implemented in a released version of
  # Text::Template, but you can apply Template_strict.patch.  Since
  # Text::Template ignores unknown options, this code will still work
  # even if you don't apply the patch; you just won't get strict checking.
  my %parms = (
    STRICT => 1,
    BROKEN => sub { $self->template_error(@_) },
  );

  $self->log_debug("Processing Build.PL as template");
  $file->content($self->fill_in_string($file->content, \%data, \%parms));

  return;
} # end setup_installer

sub template_error
{
  my ($self, %e) = @_;

  # Put the filename into the error message:
  my $err = $e{error};
  $err =~ s/ at template line (?=\d)/ at Build.PL line /g;

  $self->log_fatal($err);
} # end template_error

#---------------------------------------------------------------------
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::ModuleBuild::Custom - Allow a dist to have a custom Build.PL

=head1 VERSION

This document describes version 4.26 of
Dist::Zilla::Plugin::ModuleBuild::Custom, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In F<dist.ini>:

  [ModuleBuild::Custom]
  mb_version = 0.34  ; the default comes from the ModuleBuild plugin

In your F<Build.PL>:

  use Module::Build;

  my %module_build_args = (
    module_name => 'Foo::Bar',
  ##{ $plugin->get_prereqs(1) ##}
  ##{ $plugin->get_default('share_dir') ##}
  );

  unless ( eval { Module::Build->VERSION(0.4004) } ) {
    my $tr = delete $module_build_args{test_requires};
    my $br = $module_build_args{build_requires};
    for my $mod ( keys %$tr ) {
      if ( exists $br->{$mod} ) {
        $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
      }
      else {
        $br->{$mod} = $tr->{$mod};
      }
    }
  } # end unless Module::Build is 0.4004 or newer

  my $builder = Module::Build->new(%module_build_args);
  $builder->create_build_script;

Of course, your F<Build.PL> doesn't need to look exactly like this.
If you can require Module::Build 0.4004, then you can remove the
C<unless eval> section.  If you're not using C<share_dir>,
you can remove that line.

And if you're not adding your own code to F<Build.PL>,
you don't need this plugin.

=head1 DESCRIPTION

This plugin is for people who need something more complex than the
auto-generated F<Makefile.PL> or F<Build.PL> generated by the
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> or
L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild> plugins.

It is a subclass of the L<ModuleBuild plugin|Dist::Zilla::Plugin::ModuleBuild>,
but it does not write a F<Build.PL> for you.  Instead, you write your
own F<Build.PL>, which may do anything L<Module::Build> is capable of
(except generate a compatibility F<Makefile.PL>).

This plugin will process F<Build.PL> as a template (using
L<Text::Template>), which allows you to add data from Dist::Zilla to
the version you distribute (if you want).  The template delimiters are
C<##{> and C<##}>, because that makes them look like comments.
That makes it easier to have a F<Build.PL> that works both before and
after it is processed as a template.

This is particularly useful for XS-based modules, because it can allow
you to build and test the module without the overhead of S<C<dzil build>>
after every small change.

The template may use the following variables:

=over

=item C<$dist>

The name of the distribution.

=item C<$meta>

The hash of metadata (in META 1.4 format) that will be stored in F<META.yml>.

=item C<$meta2>

The hash of metadata (in META 2 format) that will be stored in F<META.json>.

=item C<$plugin>

The ModuleBuild::Custom object that is processing the template.

=item C<$version>

The distribution's version number.

=item C<$zilla>

The Dist::Zilla object that is creating the distribution.

=back

=head2 Using ModuleBuild::Custom with AutoPrereqs

If you are using the L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>
plugin, then you will probably want to set its C<configure_finder> to
a FileFinder that includes F<Build.PL>.  You may also want to set
this plugin's C<mb_version> parameter to 0 and allow AutoPrereqs to
get the version from your S<C<use Module::Build>> line.

Example F<dist.ini> configuration:

  [ModuleBuild::Custom]
  mb_version = 0 ; AutoPrereqs gets actual version from Build.PL

  [FileFinder::ByName / :BuildPL]
  file = Build.PL

  [AutoPrereqs]
  :version = 4.300005 ; need configure_finder
  configure_finder = :BuildPL
  ; Add next line if your Build.PL uses modules you ship in inc/
  configure_finder = :IncModules

Then in your F<Build.PL> you'd say:

  use Module::Build 0.28; # or whatever version you need

=head1 METHODS

=head2 get_default

  $plugin->get_default(qw(key1 key2 ...))

A template can call this method to extract the specified key(s) from
the default Module::Build arguments created by the normal ModuleBuild
plugin and have them formatted into a comma-separated list suitable
for a hash constructor or a method's parameter list.

If any key has no value (or its value is an empty hash or array ref)
it will be omitted from the list.  If all keys are omitted, the empty
string is returned.  Otherwise, the result always ends with a comma.

The most common usage would be

    ##{ $plugin->get_default('share_dir') ##}


=head2 get_meta

  $plugin->get_meta(qw(key1 key2 ...))

A template can call this method to extract the specified key(s) from
C<distmeta> and have them formatted into a comma-separated list
suitable for a hash constructor or a method's parameter list.  The
keys (and the returned values) are from the META 1.4 spec, because
that's what Module::Build uses in its API.

If any key has no value (or its value is an empty hash or array ref)
it will be omitted from the list.  If all keys are omitted, the empty
string is returned.  Otherwise, the result always ends with a comma.


=head2 get_prereqs

  $plugin->get_prereqs($api_version)

This returns all the keys that describe the distribution's
prerequisites.  The C<$api_version> indicates what keys
the template can handle.  The currently defined values are:

=over 8

=item C<0> (or undef)

This is equivalent to

  $plugin->get_meta(qw(build_requires configure_requires requires
                       recommends conflicts))

=item C<1>

This adds C<test_requires> as a separate key (which requires
Dist::Zilla 4.300032 or later).  It's equivalent to

  $plugin->get_default(qw(build_requires configure_requires requires
                          test_requires recommends conflicts))

Your F<Build.PL> should either require Module::Build 0.4004, or
fold test_requires into build_requires if an older version is used (as
shown in the SYNOPSIS).

=back

=head1 SEE ALSO

The L<MakeMaker::Custom|Dist::Zilla::Plugin::MakeMaker::Custom>
plugin does basically the same thing as this plugin, but for
F<Makefile.PL> (if you prefer L<ExtUtils::MakeMaker>).


=for Pod::Coverage
add_file
prune_files
setup_installer
template_error

=head1 DEPENDENCIES

ModuleBuild::Custom requires L<Dist::Zilla> (4.300009 or later) and
L<Text::Template>.  I also recommend applying F<Template_strict.patch>
to Text::Template.  This will add support for the STRICT option, which
will help catch errors in your templates.

=head1 INCOMPATIBILITIES

You must not use this in conjunction with the
L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild> plugin.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

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
