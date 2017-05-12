package Dist::Zilla::Plugin::TextTabs;

use Moose;
use Text::Tabs qw( expand unexpand );

# ABSTRACT: Expand or unexpand tabs in your dist
our $VERSION = '0.03'; # VERSION


with 'Dist::Zilla::Role::FileMunger',
     'Dist::Zilla::Role::FileFinderUser' => {
       default_finders => [ ':InstallModules', ':ExecFiles' ],
     },
     'Dist::Zilla::Role::InstallTool',
;

use namespace::autoclean;

has tabstop => (
  is      => 'ro',
  isa     => 'Int',
  default => 8,
);

has unexpand => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has installer => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub munge_files
{
  my($self) = @_;
  return if $self->installer;
  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file
{
  my($self, $file) = @_;
  $self->log(($self->unexpand ? 'un' : '') . 'expanding ' . $file->name);
  local $Text::Tabs::tabstop = $self->tabstop;
  $file->content(join("\n", map { $self->unexpand ? unexpand $_ : expand $_ } split /\n/, $file->content));
  return;
}

sub setup_installer
{
  my($self) = @_;
  return unless $self->installer;
  foreach my $file (@{ $self->zilla->files })
  {
    next unless $file->name =~ /^(Makefile|Build).PL$/;
    $self->munge_file($file);
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TextTabs - Expand or unexpand tabs in your dist

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 [TextTabs]
 tabstop   = 8
 unexapand = 0

=head1 DESCRIPTION

This L<Dist::Zilla> plugin expands or unexpands tabs using L<Text::Tab>.

=head1 ATTRIBUTES

=head2 tabstop

The length of the tabstop in characters.  This is usually 8, but some people prefer 4 or 2.

=head2 unexpand

if set to true, then an unexpand is used on all the targeted files, that is spaces of the
right length are converted into an equivalent number of tabs.  The default is false, or
expand mode.

=head2 installer

Instead of doing its work during the usual file munger stage, if this
attribute is true (the default is false), then this plugin will munge
just the C<Makefile.PL> or C<Build.PL> (or both if you have both) files
during the C<InstallTool> phase.  This allows you to remove nauty
tabs from the installer than may have been put there by a nauty
C<InstallTool> plugin (take care to put C<[TextTabs]> in your C<dist.ini>
after the nauty installer plugin).

=head1 SEE ALSO

L<Text::Tabs>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
