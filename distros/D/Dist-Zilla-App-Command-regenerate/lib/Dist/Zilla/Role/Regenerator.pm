use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Role::Regenerator;

our $VERSION = '0.001003';

our $AUTHORITY = 'cpan:DBOOK'; # AUTHORITY

# ABSTRACT: A package which can regenerate source files

use Moose::Role qw( requires around );

requires 'regenerate';

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};

  ## no critic (RequireInterpolationOfMetachars)
  $payload->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION;
  return $config;
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Regenerator - A package which can regenerate source files

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

  package Dist::Zilla::Plugin::Regenerate::SomeThing;
  use Moose;
  use Path::Tiny qw( path );
  with "Dist::Zilla::Role::Plugin","Dist::Zilla::Role::Regenerator";

  ...
  sub regenerate {
    my ( $self, $config ) = @_;
    path($config->{root}, 'CONTRIBUTING.pod')->spew_raw($content);
    path($config->{build_root}, 'META.json')->copy(path($config->{root}, 'META.json'));
  }

=head1 DESCRIPTION

This role is for C<Dist::Zilla> C<Plugin>'s that wish to fire under C<dzil regenerate>

It is strongly recommended that this role not be lumped on randomly into packages that
will operate at other phases.

=head1 IMPLEMENTATION

Consumers of this role B<MUST> compose in C<Dist::Zilla::Role::Plugin> at some stage,
or at least, C<Dist::Zilla::Role::ConfigDumper>.

Consumers of this rule B<MUST> implement a method C<regenerate>.

=head2 C<regenerate> implementation

C<regenerate> will be called as a method and passed a configuration hash.

  {
      build_root => "path/to/where/dzil/build/writes/to"
      root       => "path/to/dzil/source/tree"
  }

You may do with these as you wish, but recommended usage is to employ C<Path::Tiny>
to do one of the following:

=over 4

=item * Write files directly from the plugin

  path($config->{root}, "CONTRIBUTING.pod")->spew_raw( ... );

Keep in mind how file encoding works if you get your data from other parts of C<Dist::Zilla>

=item * Copy files from the build tree

  path($config->{build_root}, "META.json")->copy($path->{root}, "META.json");

( Note: This case is implemented by L<< C<[Regenerate]>|Dist::Zilla::Plugin::Regenerate >> )

=item * (DON'T) Write files from C<zilla> to disk

How you'd do this is left to your imagination, but the details are ugly.

Take note of the calls to C<_write_out_file> in
L<< C<Dist::Zilla::Dist::Builder>|Dist::Zilla::Dist::Builder >>
and the implementation details of C<_write_out_file> in L<< C<Dist::Zilla>|Dist::Zilla >>

I suspect something like

  $self->zilla->_write_out_file( $self->zilla->files[0] , $config->{root} )

Might kinda work, but keep in mind, that will spew if the file already exists.

B<G>ood B<L>uck B<H>ave B<F>un.

Also, this approach is B<NOT> recommended, because the final release image is B<NOT>
drafted from C<< $self->zilla->files >> but from direct read of the C<< $config->{build_root} >>.

See C<Dist::Zilla/build_archive> which has the call sequence:

=over 4

=item * ensure_built_in ...

=item * write_out ...

=item * C<-AfterBuild>

=item * C<-BeforeArchive>

=item * C<_build_archive> ( from $write_out_dir )

=back

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
