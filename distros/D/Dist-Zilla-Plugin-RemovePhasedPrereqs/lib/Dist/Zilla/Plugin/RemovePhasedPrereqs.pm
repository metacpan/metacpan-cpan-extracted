use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::RemovePhasedPrereqs;
# ABSTRACT: Remove gathered prereqs from particular phases
our $VERSION = '0.002'; # VERSION

use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

use Moose::Autobox;

use MooseX::Types::Moose qw(ArrayRef);
use MooseX::Types::Perl  qw(ModuleName);

my @phases = qw(configure build test runtime develop);

my @types  = qw(requires recommends suggests conflicts);

my %attr_map = map { $_ => "remove_$_" } @phases;

sub mvp_multivalue_args { values %attr_map }

has [ values %attr_map ] => (
  is  => 'ro',
  isa => ArrayRef[ ModuleName ],
  default => sub { [] },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = { map { $_ => $self->$_ } values %attr_map };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

sub register_prereqs {
  my ($self) = @_;

  my $prereqs = $self->zilla->prereqs;

  for my $p (@phases) {
    my $meth = $attr_map{$p};
    for my $t (@types) {
      for my $m ($self->$meth->flatten) {
        $prereqs->requirements_for($p, $t)->clear_requirement($m);
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::RemovePhasedPrereqs - Remove gathered prereqs from particular phases

=head1 VERSION

version 0.002

=head1 SYNOPSIS

In F<dist.ini>:

    [RemovePhasedPrereqs]
    remove_runtime = Foo
    remove_runtime = Bar

=head1 DESCRIPTION

This module is adapted from L<Dist::Zilla::Plugin::RemovePrereqs> to let you
specify particular requirements sections to remove from instead of removing
from all of them.

Valid configuration options are:

=over 4

=item *

remove_build

=item *

remove_configure

=item *

remove_develop

=item *

remove_runtime

=item *

remove_test

=back

These may be used more than once to remove multiple modules.

Modules are removed from all types within a section (e.g. "requires",
"recommends", "suggests", etc.).

=for Pod::Coverage register_prereqs mvp_multivalue_args

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::Prereqs>

=item *

L<Dist::Zilla::Plugin::AutoPrereqs>

=item *

L<Dist::Zilla::Plugin::RemovePrereqs>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/dist-zilla-plugin-removephasedprereqs/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dist-zilla-plugin-removephasedprereqs>

  git clone git://github.com/dagolden/dist-zilla-plugin-removephasedprereqs.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
