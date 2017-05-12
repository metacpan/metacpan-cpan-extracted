#---------------------------------------------------------------------
package Dist::Zilla::Plugin::MakeMaker::Custom;
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
# ABSTRACT: Allow a dist to have a custom Makefile.PL
#---------------------------------------------------------------------

our $VERSION = '4.26';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use Moose;
use Dist::Zilla::Plugin::MakeMaker 4.300009; # improved subclassing
extends 'Dist::Zilla::Plugin::MakeMaker';
with qw(Dist::Zilla::Role::FilePruner
        Dist::Zilla::Role::HashDumper);

use List::Util ();

# We're trying to make the template executable before it's filled in,
# so we want delimiters that look like comments:
has '+delim' => (
  default  => sub { [ '##{', '##}' ] },
);

# Need to cache write_makefile_args for the get_default method
has _mmc_write_makefile_args => (
  is       => 'ro',
  isa      => 'HashRef',
  lazy     => 1,
  init_arg => undef,
  builder  => 'write_makefile_args',
);

# Get rid of any META.yml we may have picked up from MakeMaker:
sub prune_files
{
  my ($self) = @_;

  my $files = $self->zilla->files;
  @$files = grep { not($_->name =~ /^META\.(?:yml|json)$/ and
                       $_->isa('Dist::Zilla::File::OnDisk')) } @$files;

  return;
} # end prune_files
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
        unless eval { Dist::Zilla::Plugin::MakeMaker->VERSION( 4.300032 ) };
  }

  # Get the prerequisites as a hashref:
  my $prereqs = $self->extract_keys_as_hash(
    WriteMakefile => $self->_mmc_write_makefile_args,
    qw(BUILD_REQUIRES CONFIGURE_REQUIRES PREREQ_PM TEST_REQUIRES)
  );

  # If we have TEST_REQUIRES, but the template doesn't understand them,
  # merge them into BUILD_REQUIRES (if any)
  if ($prereqs->{TEST_REQUIRES} and not $api_version) {
    if ($prereqs->{BUILD_REQUIRES}) {
      # have both BUILD_REQUIRES & TEST_REQUIRES, so merge them:
      require CPAN::Meta::Requirements;
      CPAN::Meta::Requirements->VERSION(2.121);
      my ($buildreq, $testreq) = map {
        CPAN::Meta::Requirements->from_string_hash( $prereqs->{$_} )
      } qw(BUILD_REQUIRES TEST_REQUIRES);

      $buildreq->add_requirements( $testreq );

      delete $prereqs->{TEST_REQUIRES};
      $prereqs->{BUILD_REQUIRES} = $buildreq->as_string_hash;
    } else {
      # no BUILD_REQUIRES, so we can just rename TEST_REQUIRES:
      $prereqs->{BUILD_REQUIRES} = delete $prereqs->{TEST_REQUIRES};
    }
  } # end if TEST_REQUIRES and $api_version is 0

  $self->hash_as_string( $prereqs );
} # end get_prereqs

#---------------------------------------------------------------------


sub get_default
{
  my $self = shift;

  return $self->extract_keys(WriteMakefile => $self->_mmc_write_makefile_args,
                             @_);
} # end get_default

sub add_file {}                 # Don't let parent class add any files

#---------------------------------------------------------------------
around setup_installer => sub {
  my $orig = shift;
  my $self = shift;

  my $file = List::Util::first { $_->name eq 'Makefile.PL' }
             @{ $self->zilla->files }
      or $self->log_fatal("No Makefile.PL found in dist");

  my $write_makefile_args = $self->_mmc_write_makefile_args;
  my $perl_prereq = $write_makefile_args->{MIN_PERL_VERSION};
  my $share_dir_code = $self->share_dir_code;

  # Process Makefile.PL through Text::Template:
  my %data = (
     dist    => $self->zilla->name,
     meta    => $self->zilla->distmeta,
     plugin  => \$self,
     version => $self->zilla->version,
     zilla   => \$self->zilla,
     default_args    => $write_makefile_args,
     eumm_version    => \($self->eumm_version),
     perl_prereq     => \$perl_prereq,
     share_dir_code  => $share_dir_code,
     # Recreate share_dir_block for backwards compatibility:
     share_dir_block => [ $share_dir_code->{preamble}  || '',
                          $share_dir_code->{postamble} || '' ],
  );

  # The STRICT option hasn't been implemented in a released version of
  # Text::Template, but you can apply Template_strict.patch.  Since
  # Text::Template ignores unknown options, this code will still work
  # even if you don't apply the patch; you just won't get strict checking.
  my %parms = (
    STRICT => 1,
    BROKEN => sub { $self->template_error(@_) },
  );

  $self->log_debug("Processing Makefile.PL as template");
  $file->content($self->fill_in_string($file->content, \%data, \%parms));

  return;
}; # end setup_installer

sub template_error
{
  my ($self, %e) = @_;

  # Put the filename into the error message:
  my $err = $e{error};
  $err =~ s/ at template line (?=\d)/ at Makefile.PL line /g;

  $self->log_fatal($err);
} # end template_error

#---------------------------------------------------------------------
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::Custom - Allow a dist to have a custom Makefile.PL

=head1 VERSION

This document describes version 4.26 of
Dist::Zilla::Plugin::MakeMaker::Custom, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In F<dist.ini>:

  [MakeMaker::Custom]
  eumm_version = 0.34  ; the default comes from the MakeMaker plugin

In your F<Makefile.PL>:

  use ExtUtils::MakeMaker;

  ##{ $share_dir_code{preamble} || '' ##}

  my %args = (
    NAME => "My::Module",
  ##{ $plugin->get_default(qw(ABSTRACT AUTHOR LICENSE VERSION)) ##}
  ##{ $plugin->get_prereqs(1) ##}
  );

  unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $args{TEST_REQUIRES};
    my $br = $args{BUILD_REQUIRES};
    for my $mod ( keys %$tr ) {
      if ( exists $br->{$mod} ) {
        $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
      }
      else {
        $br->{$mod} = $tr->{$mod};
      }
    }
  } # end unless ExtUtils::MakeMaker is 6.63_03 or newer

  unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $args{BUILD_REQUIRES};
    my $pp = $args{PREREQ_PM};
    for my $mod ( keys %$br ) {
      if ( exists $pp->{$mod} ) {
        $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
      }
      else {
        $pp->{$mod} = $br->{$mod};
      }
    }
  } # end unless ExtUtils::MakeMaker is 6.56 or newer

  delete $args{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

  delete $args{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

  WriteMakefile(%args);

  ##{ $share_dir_code{postamble} || '' ##}

Of course, your F<Makefile.PL> doesn't need to look exactly like this.
If you increase the minimum version of ExtUtils::MakeMaker, you can
remove any C<unless eval> sections whose version test is less than or
equal to C<eumm_version>.  If you're not using C<share_dir>,
you can remove those lines.

And if you're not adding your own code to F<Makefile.PL>,
you don't need this plugin.

=head1 DESCRIPTION

This plugin is for people who need something more complex than the
auto-generated F<Makefile.PL> or F<Build.PL> generated by the
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> or
L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild> plugins.

It is a subclass of the L<MakeMaker plugin|Dist::Zilla::Plugin::MakeMaker>,
but it does not write a F<Makefile.PL> for you.  Instead, you write your
own F<Makefile.PL>, which may do anything L<ExtUtils::MakeMaker> is capable of.

This plugin will process F<Makefile.PL> as a template (using
L<Text::Template>), which allows you to add data from Dist::Zilla to
the version you distribute (if you want).  The template delimiters are
C<##{> and C<##}>, because that makes them look like comments.
That makes it easier to have a F<Makefile.PL> that works both before and
after it is processed as a template.

This is particularly useful for XS-based modules, because it can allow
you to build and test the module without the overhead of S<C<dzil build>>
after every small change.

The template may use the following variables:

=over

=item C<%default_args>

The hash of arguments for WriteMakefile generated by the normal
MakeMaker plugin.

=item C<$dist>

The name of the distribution.

=item C<$eumm_version>

The minimum version of ExtUtils::MakeMaker required
(from the C<eumm_version> attribute of this plugin).

=item C<%meta>

The hash of metadata (in META 2 format) that will be stored in F<META.json>.

=item C<$perl_prereq>

The minimum version of Perl required (from the prerequisites in the metadata).
May be C<undef>.  Equivalent to C<$default_args{MIN_PERL_VERSION}>.

=item C<$plugin>

The MakeMaker::Custom object that is processing the template.

=item C<%share_dir_code>

A hash of strings containing the code for loading
C<File::ShareDir::Install> (if it's used by this dist).  Put
S<C<##{ $share_dir_code{preamble} || '' ##}>> after the
S<C<use ExtUtils::MakeMaker>> line, and put
S<C<##{ $share_dir_code{postamble} || '' ##}>> after the C<WriteMakefile>
call.  (You can omit the S<C<|| ''>> if you're sure the dist is using
File::ShareDir.

For backwards compatibility, this code is also available in the array
C<@share_dir_block>, but you should update your templates to use
C<%share_dir_code> instead.

=item C<$version>

The distribution's version number.

=item C<$zilla>

The Dist::Zilla object that is creating the distribution.

=back

=head2 Using MakeMaker::Custom with AutoPrereqs

If you are using the L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>
plugin, then you will probably want to set its C<configure_finder> to
a FileFinder that includes F<Makefile.PL>.  You may also want to set
this plugin's C<eumm_version> parameter to 0 and allow AutoPrereqs to
get the version from your S<C<use ExtUtils::MakeMaker>> line.

Example F<dist.ini> configuration:

  [MakeMaker::Custom]
  eumm_version = 0 ; AutoPrereqs gets actual version from Makefile.PL

  [FileFinder::ByName / :MakefilePL]
  file = Makefile.PL

  [AutoPrereqs]
  :version = 4.300005 ; need configure_finder
  configure_finder = :MakefilePL
  ; Add next line if your Makefile.PL uses modules you ship in inc/
  configure_finder = :IncModules

Then in your F<Makefile.PL> you'd say:

  use ExtUtils::MakeMaker 6.32; # or whatever version you need

=head1 METHODS

=head2 get_default

  $plugin->get_default(qw(key1 key2 ...))

A template can call this method to extract the specified key(s) from
the default WriteMakefile arguments created by the normal MakeMaker
plugin and have them formatted into a comma-separated list suitable
for a hash constructor or a function's parameter list.

If any key has no value (or its value is an empty hash or array ref)
it will be omitted from the list.  If all keys are omitted, the empty
string is returned.  Otherwise, the result always ends with a comma.


=head2 get_prereqs

  $plugin->get_prereqs($api_version);

This is mostly equivalent to

  $plugin->get_default(qw(BUILD_REQUIRES CONFIGURE_REQUIRES PREREQ_PM
                          TEST_REQUIRES))

In other words, it returns all the keys that describe the
distribution's prerequisites.  The C<$api_version> indicates what keys
the template can handle.  The currently defined values are:

=over 8

=item C<0> (or undef)
- Fold TEST_REQUIRES into BUILD_REQUIRES.  This provides backwards
compatibility with older versions of this plugin and Dist::Zilla.

=item C<1>
- Return TEST_REQUIRES (introduced in ExtUtils::MakeMaker 6.63_03) as
a separate key (assuming it's not empty), which requires Dist::Zilla
4.300032 or later.  Your F<Makefile.PL> should either require
ExtUtils::MakeMaker 6.63_03, or fold TEST_REQUIRES into BUILD_REQUIRES
if an older version is used (as shown in the SYNOPSIS).

=back

=head1 SEE ALSO

The L<ModuleBuild::Custom|Dist::Zilla::Plugin::ModuleBuild::Custom>
plugin does basically the same thing as this plugin, but for
F<Build.PL> (if you prefer L<Module::Build>).

The L<MakeMaker::Awesome|Dist::Zilla::Plugin::MakeMaker::Awesome>
plugin allows you to do similar things to your F<Makefile.PL>, but it
works in a very different way.  With MakeMaker::Awesome, you subclass
the plugin and override the methods that generate F<Makefile.PL>.  In
my opinion, MakeMaker::Awesome has two disadvantages: it's
unnecessarily complex, and it doesn't allow you to build your module
without doing C<dzil build>.  The only advantage of MakeMaker::Awesome
that I can see is that if you had several dists with very similar
F<Makefile.PL>s, you could write one subclass of MakeMaker::Awesome
and use it in each dist.


=for Pod::Coverage
add_file
prune_files
setup_installer
template_error

=head1 DEPENDENCIES

MakeMaker::Custom requires L<Dist::Zilla> (4.300009 or later) and
L<Text::Template>.  I also recommend applying F<Template_strict.patch>
to Text::Template.  This will add support for the STRICT option, which
will help catch errors in your templates.

=head1 INCOMPATIBILITIES

You must not use this in conjunction with the
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> or
L<MakeMaker::Awesome|Dist::Zilla::Plugin::MakeMaker::Awesome> plugins.

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
