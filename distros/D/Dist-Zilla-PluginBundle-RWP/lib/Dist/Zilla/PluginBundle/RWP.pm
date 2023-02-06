# ABSTRACT: Add [@RWP] plugin bundle into dist.ini

use v5.37;

package Dist::Zilla::PluginBundle::RWP;
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure ( $self ) {

  my @plugins = qw(
    CPANFile
    AutoPrereqs
    NextRelease

    PodWeaver
    InstallGuide
    Git::Commit
    Git::Tag
  ); # Plugins added with default settings


  $self -> add_bundle( '@Filter' => {
    '-bundle' => '@Basic' ,
    '-remove' => [ 'ConfirmRelease' ] ,
  }
  );

  $self -> add_plugins( @plugins );

  $self -> add_plugins( [ AutoVersion => { major => 0 } ] , );

  $self -> add_plugins(
    [
      PruneFiles => {
        filename => '_Deparsed_XSubs.pm' ,
        match    => '\.iml$' ,
      }
    ] ,
  );

  $self -> add_plugins( [ GithubMeta => { issues => 1 } ] , );                 # External plugin
  $self -> add_plugins( [ 'Git::Check' => { untracked_files => 'warn' } ] , ); # External plugin

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::RWP - Add [@RWP] plugin bundle into dist.ini

=head1 VERSION

version 0.230350

https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Easy

https://metacpan.org/release/RJBS/Dist-Zilla-PluginBundle-RJBS-5.023/source/lib/Dist/Zilla/PluginBundle/RJBS.pm

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
