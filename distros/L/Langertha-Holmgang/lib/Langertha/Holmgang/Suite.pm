package Langertha::Holmgang::Suite;
# ABSTRACT: A suite: head, tools, defaults and its cases in load order

use Moose;
use namespace::autoclean;

our $VERSION = '0.001';


has id => ( is => 'ro', required => 1 );


has topic => ( is => 'ro', default => 'sonstiges' );


has $_ => ( is => 'ro' ) for qw( version title description license source threshold repeat digest );


has defaults => ( is => 'ro', default => sub { {} } );


has tools => ( is => 'ro', default => sub { [] } );


has cases => ( is => 'ro', default => sub { [] } );


# private: the files of a DSL suite's YAML export ({ files => [ [ name, bytes ] ],
# images => { name => path } }), set by Loader::assemble, written by Loader::export
has _export => ( is => 'ro', init_arg => '_export' );

sub case {
  my ( $self, $id ) = @_;
  my ( $c ) = grep { $_->id eq ( $id // '' ) } @{ $self->cases };
  return $c;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Suite - A suite: head, tools, defaults and its cases in load order

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $suite = Langertha::Holmgang::Loader->new->load('/srv/suites/example-lamp');

  $suite->id;          # 'example-lamp'
  $suite->topic;       # 'sonstiges' without one
  $suite->cases;       # [ Langertha::Holmgang::Case, … ] in file-name order
  $suite->digest;      # sha256 over the files and the generated texts
  $suite->case('c1');  # one case by id

=head1 DESCRIPTION

The head of suite format 2 (F<suite.yaml>) with its cases. Field names are
format 2's (ADR 0005); C<format: 2> is a property of the file, not of the
structure. Built by L<Langertha::Holmgang::Structure> through the loader or
the DSL.

=head2 id

Required. C<[a-z0-9-]>, the directory name in format 2.

=head2 topic

The axis of every evaluation; C<sonstiges> without one.

=head2 version

The suite's version, an integer from 1 up; format 2 requires it.

=head2 title

Required. The suite's title, a non-empty text.

=head2 description

Optional free text describing the suite, or C<undef>.

=head2 license

Optional license text of the suite, or C<undef>.

=head2 source

C<{ title, authors, license, url, location }>.

=head2 threshold

C<{ pass_rate, pass_k }> (each optional, 0..1) or C<undef>.

=head2 repeat

How often a run repeats the suite by default (1..100), or C<undef>.

=head2 digest

SHA-256 (hex) over the file names and bytes of F<suite.yaml> and every case
file, plus the generated texts — the same value, under the same name, that
cai-platform computes as its C<digest>, and the C<suite.digest> of a report.

=head2 defaults

C<system>, C<temperature>, C<max_tokens>, C<max_turns> as written.

=head2 tools

The tools as written in F<suite.yaml>, in file order.

=head2 cases

The L<Langertha::Holmgang::Case> objects in load order.

=head2 case

  my $case = $suite->case('c1');

The case with this id, or C<undef>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
