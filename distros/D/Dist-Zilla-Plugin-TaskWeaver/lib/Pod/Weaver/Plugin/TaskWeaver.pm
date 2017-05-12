package Pod::Weaver::Plugin::TaskWeaver;
# ABSTRACT: Dist::Zilla::Plugin::TaskWeaver's helper
$Pod::Weaver::Plugin::TaskWeaver::VERSION = '0.101628';
use Moose;
with 'Pod::Weaver::Role::Dialect', 'Pod::Weaver::Role::Section';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod B<Achtung!>  This class should not need to exist; it should be possible for
#pod Dist::Zilla::Plugin::TaskWeaver to also be a Pod::Weaver plugin, but a subtle
#pod bug in Moose prevents this from happening right now.  In the future, this class
#pod may go away.
#pod
#pod This is a Pod::Weaver plugin.  It functions as both a Dialect and a Section,
#pod although this is basically hackery to get things into the right order.  For
#pod more information consult the L<Dist::Zilla::Plugin::TaskWeaver> documentation.
#pod
#pod =cut

use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;

has zillaplugin => (is => 'ro', isa => 'Object', required => 1);

sub record_prereq {
  my ($self, $pkg, $ver) = @_;
  $self->zillaplugin->prereq->{$pkg} = defined $ver ? $ver : 0;
}

sub translate_dialect {
  my ($self, $document) = @_;

  my $pkg_nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(pkg) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(over item back) ]),
    ],
  });

  $pkg_nester->transform_node($document);

  my $pkgroup_nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(pkgroup pkggroup) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(pkg) ]),
    ],
  });

  $pkgroup_nester->transform_node($document);

  return;
}

sub weave_section {
  my ($self, $document, $input) = @_;

  my $input_pod = $input->{pod_document};

  my @pkgroups;
  for my $i (reverse(0 .. $#{ $input_pod->children })) {
    my $child = $input_pod->children->[ $i ];
    unshift @pkgroups, splice(@{$input_pod->children}, $i, 1)
      if  $child->does('Pod::Elemental::Command')
      and ($child->command eq 'pkgroup' or $child->command eq 'pkggroup');
  }

  for my $pkgroup (@pkgroups) {
    $pkgroup->command('head2');

    for my $child (@{ $pkgroup->children }) {
      next unless $child->does('Pod::Elemental::Command')
           and    $child->command eq 'pkg';

      $child->command('head3');

      my ($pkg, $ver, $reason) = split /\s+/sm, $child->content, 3;
      $self->record_prereq($pkg, $ver);

      $child->content(defined $ver ? "L<$pkg> $ver" : "L<$pkg>");

      if (defined $ver and defined $reason) {
        unshift @{ $child->children }, (
          Pod::Elemental::Element::Pod5::Ordinary->new({
            content => "Version $ver required because: $reason",
          })
        );
      }
    }
  }

  my $section = Pod::Elemental::Element::Nested->new({
    command  => 'head1',
    content  => 'TASK CONTENTS',
    children => \@pkgroups,
  });

  unshift @{ $input_pod->children}, $section;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::TaskWeaver - Dist::Zilla::Plugin::TaskWeaver's helper

=head1 VERSION

version 0.101628

=head1 DESCRIPTION

B<Achtung!>  This class should not need to exist; it should be possible for
Dist::Zilla::Plugin::TaskWeaver to also be a Pod::Weaver plugin, but a subtle
bug in Moose prevents this from happening right now.  In the future, this class
may go away.

This is a Pod::Weaver plugin.  It functions as both a Dialect and a Section,
although this is basically hackery to get things into the right order.  For
more information consult the L<Dist::Zilla::Plugin::TaskWeaver> documentation.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
