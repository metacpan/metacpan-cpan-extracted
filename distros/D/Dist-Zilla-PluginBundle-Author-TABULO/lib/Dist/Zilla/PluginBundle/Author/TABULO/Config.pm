use 5.014;  # because we use the 'non-destructive substitution' feature (s///r)
use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::TABULO::Config;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: Configuration module for <Dist::Zilla::PluginBundle::Author::TABULO>
# KEYWORDS: author bundle distribution tool

our $VERSION = '0.198';
# AUTHORITY

use Git::Wrapper;
use List::Util 1.45 qw(pairs);

use Banal::Util::Mini qw(hash_access);
use Banal::Dist::Util::Git qw(detect_settings_from_git);

#use Memoize;
use Exporter::Shiny qw(configuration detect_settings);
use namespace::autoclean;

# PLUGIN-bundle info
my $bundle_name = (__PACKAGE__ =~ /^Dist::Zilla::PluginBundle::(.*)::Config$/) ? $1 : undef;
my %bundle      = (
  name          =>  $bundle_name,
  ini_section_name      =>  '@' . $bundle_name,
  ini_section   =>  '[' . '@' . $bundle_name . ']',
  pkg_name      =>  'Dist::Zilla::PluginBundle::' . $bundle_name,
);
$bundle{dist_name}  ||= $bundle{pkg_name}  =~ s/::/-/gr;
$bundle{msg_pfx}    ||= $bundle{ini_section} . ' ',  # prefix for error message output (warnings, etc)

# SETTINGS, DEFAULTS, ...
my %config = (

  # Info about this plugin-bundle
  bundle  => \%bundle,

  # These are the last resort defaults,
  #   which would be beaten by any known preferences of the 'authority' for the distribution at hand,
  #   which would in turn be beaten by the settings in dist.ini (payload)
  defaults => {
    airplane                            =>  0,
    authority                           =>  'cpan:TABULO',
    changes_version_columns             =>  12, # The version string gets formatted with : (this value - 2)
    commit_files_copied_from_release    =>  1,
    commit_file_after_release_implicit  =>  [ qw(README.md README.pod Changes) ],
    copy_file_from_release_implicit     =>  [ qw(LICENCE LICENSE CONTRIBUTING ppport.h INSTALL) ],
    fake_release                        =>  0,
    installer                           =>  [ 'MakeMaker::Fallback', 'ModuleBuildTiny' ],
    server                              =>  'github',
    spelling                            =>  'US',
    static_install_mode                 => 'auto',
    stopword                            => [ qw(irc IRC) ],
    surgical_podweaver                  =>  0,

    # Updating .ackrc is no longer needed after ack v2.16+ (which now supports the 'match:' operator for directories)
    update_ackrc_after_build            =>  0,

    # Ufff... But just conforming to the existing the behavior of ETHER's bundle (and adding some more OS user names)...
    verify_phases                       => ( ($ENV{USER} // '') =~ /^ether|tabulo|ayhan$/i ) ? 1 : 0,


    # default settings for POD Weaver (applies also to 'SurgicalPodWeaver' in the absence of specific settings for that)
    'PodWeaver.replacer'                    =>  'replace_with_comment',
    'PodWeaver.post_code_replacer'          =>  'replace_with_nothing',

    'MetaNoIndex.directory'                 => [ qw(t xt), qw(inc local perl5 fatlib examples share corpus demo) ],
    'Test::ReportPrereqs.include'           => [ qw(Dist::CheckConflicts Pod::Elemental::PerlMunger) ],



    # files that might be in the repository that should never be gathered
    never_gather_implicit               =>  [ grep { -e } qw(
        Makefile.PL ppport.h META.json META.yml cpanfile
        README README.md README.mkdn README.pod
        TODO CONTRIBUTING LICENCE LICENSE INSTALL
        TODO.yml todo.yml todo.txt notes.txt notes.COMMIT.txt
        .dzil.out
        inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
    )],

    # configs are applied when plugins match ->isa($key) or ->does($key)
    extra_args => {
      'Dist::Zilla::Plugin::MakeMaker' => { default_jobs => 9, 'eumm_version' => '0' },
      'Dist::Zilla::Plugin::ModuleBuildTiny' => { default_jobs => 9, ':version' => '0.012', version_method => 'conservative', static => 'auto' },
      'Dist::Zilla::Plugin::MakeMaker::Fallback' => { default_jobs => 9, ':version' => '0.012' },
      # default_jobs is no-op until Dist::Zilla 5.014
      'Dist::Zilla::Role::TestRunner' => { default_jobs => 9 },
      'Dist::Zilla::Plugin::ModuleBuild' => { mb_version => '0.28' },
      'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback' => { default_jobs => 9, static => 'auto',
                                                            ':version' => '0.018', version_method => 'conservative',  },
    },

    # Update '.ackrc' file.
    'update_ackrc.cmd'                  =>  <<'__EOD__' =~ tr/\n/ /r, # replace newlines with spaces, just in case
bash -c "test -e .ackrc && grep -q -- '--ignore-dir=.latest' .ackrc || echo '--ignore-dir=.latest' >> .ackrc;
if [[ `dirname '%d'` != .build ]]; then
  test -e .ackrc && grep -q -- '--ignore-dir=%d' .ackrc || echo '--ignore-dir=%d' >> .ackrc;
fi"
__EOD__


    'update_latest_links.eval'          => <<'__EOD__'
if ('%d' =~ /^%n-[.[:xdigit:]]+$/) { unlink '.latest'; symlink '%d', '.latest'; }
__EOD__


  },



  known_authors => {
      map {; ( 'cpan:'. $_->key => $_->value )  }
      pairs (
      'TABULO'  =>  { prefs => {
                        spelling => 'US',        keen_on_static_install => 0,
                        surgical_podweaver => 1,
                        'Authority.do_munging' => 1,  'Authority.locate_comment' => 1,

                        # options for [AutoMetaResources]
                        server_amr_opts_bitbucket => 'user:tabulo',
                        server_amr_opts_github => 'user:tabulon',

                        max_target_perl         => 5.014,  # Commented out, because we don't want to force distros for something ike this.

                        portability_options                 => 'test_dos_length = 0, test_one_dot = 0',

                      }
                   },
      'ETHER'   => { prefs =>{  spelling => 'GB', keen_on_static_install => 1 }},
      map { $_  => { prefs =>{  spelling => 'GB'} } } qw(
        ABERGMAN AVAR BINGOS BOBTFISH CHANSEN CHOLET FLORA GETTY ILMARI
        CHANSEN CHOLET FLORA GETTY ILMARI JAWNSY JQUELIN LEONT LLAP
        MSTROUT NUFFIN PERIGRIN PHAYLON
      ))
  },

);


# Method to retrieve configuration settings
#   - Without any arguments, it will return the entire config hash (tree)
#   - If given arguments, it return the item by 'diving' into the hash like so : $config{k0}{k1}{k2}
#       except that we try real hard to avoid auto-vivification
#       (hence the function call to the utility routine 'hash_access')
sub configuration { hash_access( \%config,  @_) }


sub pause_config {  my  $o = @_ % 2 ? shift : undef; Banal::Dist::Util::Pause::pause_config(@_) }

# Detects settings that may serve as defaults in the current execution
# environment
#memoize qw(detect_settings);
sub detect_settings {
  my  $o        = @_ % 2 ? shift : undef;
  my  %args     = @_;
  my  %detected = detect_settings_from_git(dir => $args{dir}, %args);
  wantarray ? (%detected) : \%detected;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::TABULO::Config - Configuration module for <Dist::Zilla::PluginBundle::Author::TABULO>

=head1 VERSION

version 0.198

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
