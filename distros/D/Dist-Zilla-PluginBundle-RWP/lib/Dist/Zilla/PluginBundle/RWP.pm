# ABSTRACT: Add [@RWP] plugin bundle into dist.ini

use v5.37;


package Dist::Zilla::PluginBundle::RWP;
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';
use builtin qw( true false );
use experimental qw( builtin );

has major_version => (
  is      => 'ro' ,
  isa     => 'Int' ,
  lazy    => true ,
  default => 0 ,
);

sub configure ( $self ) {

  my @plugins = qw(
    CPANFile
    AutoPrereqs
    NextRelease
    MetaJSON

    PodWeaver
    InstallGuide
    MetaProvides::Package
  ); # Plugins added with default settings


  $self -> add_bundle(
    '@Filter' => {
      '-bundle' => '@Basic' ,
      '-remove' => [ 'ConfirmRelease' ] ,
    }
  ); # Git::Check, Git::Commit, Git::Tag, Git::Push

  $self -> add_bundle(
    '@Filter' => {
      '-bundle' => '@Git' ,
      '-remove' => [ 'Git::Check' ] ,
    }
  );

  $self -> add_plugins(

    @plugins ,

    [
      AutoVersion => {
        major => $self -> major_version
      }
    ] ,

    [
      PruneFiles => {
        filename => '_Deparsed_XSubs.pm' ,
        match    => '\.iml$' ,
      }
    ] ,

    [
      GenerateFile => {
        filename            => 'CONTRIBUTING' ,
        content_is_template => '1' ,

        content             => my $text = <<~ 'CONTRIBUTING'
        Please use project GitHub repository for your contributions.

        To contribute to this distribution you may:

        1. Create pull requests at: https://github.com/rwp-cpan/{{$dist -> name}}/pulls

        2. File issues at: https://github.com/rwp-cpan/{{$dist -> name}}/issues

        Thanks
        CONTRIBUTING
      }
    ] ,

    [
      GithubMeta => { # External plugin
        issues => 1
      }
    ] ,

    [
      'Git::Check' => { # External plugin
        untracked_files => 'ignore'
      }
    ]

  );

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::RWP - Add [@RWP] plugin bundle into dist.ini

=head1 VERSION

version 0.230470

=head1 SYNOPSIS

  # In F<dist.ini>

  [@RWP]

=head1 DESCRIPTION

RWP Dist-Zilla plugin bundle.

=head2 Plugins

The following plugins are used as part of this bundle.

=over 4

=item C<MetaJSON>

Kwalitee extra indicator L<has_meta_json|https://cpants.cpanauthors.org/kwalitee/has_meta_json>

=item C<MetaProvides::Package>

Kwalitee experimental indicator L<meta_yml_has_provides|https://cpants.cpanauthors.org/kwalitee/meta_yml_has_provides>
The plugin is from the L<Dist-Zilla-Plugin-MetaProvides-Package|https://metacpan.org/dist/Dist-Zilla-Plugin-MetaProvides-Package> distribution.

=back

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
