package Dist::Zilla::Plugin::MetaResources 6.032;
# ABSTRACT: provide arbitrary "resources" for distribution metadata

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin adds resources entries to the distribution's metadata.
#pod
#pod   [MetaResources]
#pod   homepage          = https://example.com/~dude/project.asp
#pod   bugtracker.web    = https://rt.cpan.org/Public/Dist/Display.html?Name=Project
#pod   bugtracker.mailto = bug-Project@rt.cpan.org
#pod   repository.url    = git://github.com/dude/project.git
#pod   repository.web    = https://github.com/dude/project
#pod   repository.type   = git
#pod
#pod =cut

has resources => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

around BUILDARGS => sub {
  my $orig = shift;
  my ($class, @arg) = @_;

  my $args = $class->$orig(@arg);
  my %copy = %{ $args };

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  if (exists $copy{license} && ref($copy{license}) ne 'ARRAY') {
      $copy{license} = [ $copy{license} ];
  }

  if (exists $copy{bugtracker}) {
    my $tracker = delete $copy{bugtracker};
    $copy{bugtracker}{web} = $tracker;
  }

  if (exists $copy{repository}) {
    my $repo = delete $copy{repository};
    $copy{repository}{url} = $repo;
  }

  for my $multi (qw( bugtracker repository )) {
    for my $key (grep { /^\Q$multi\E\./ } keys %copy) {
      my $subkey = (split /\./, $key, 2)[1];
      $copy{$multi}{$subkey} = delete $copy{$key};
    }
  }

  return {
    zilla       => $zilla,
    plugin_name => $name,
    resources   => \%copy,
  };
};

sub metadata {
  my ($self) = @_;

  return { resources => $self->resources };
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.
#pod
#pod Dist::Zilla plugins on the CPAN: L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaResources - provide arbitrary "resources" for distribution metadata

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin adds resources entries to the distribution's metadata.

  [MetaResources]
  homepage          = https://example.com/~dude/project.asp
  bugtracker.web    = https://rt.cpan.org/Public/Dist/Display.html?Name=Project
  bugtracker.mailto = bug-Project@rt.cpan.org
  repository.url    = git://github.com/dude/project.git
  repository.web    = https://github.com/dude/project
  repository.type   = git

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 SEE ALSO

Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.

Dist::Zilla plugins on the CPAN: L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
