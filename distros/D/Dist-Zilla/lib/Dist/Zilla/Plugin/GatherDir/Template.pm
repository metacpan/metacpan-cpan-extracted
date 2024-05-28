package Dist::Zilla::Plugin::GatherDir::Template 6.032;
# ABSTRACT: gather all the files in a directory and use them as templates

use Moose;
extends 'Dist::Zilla::Plugin::GatherDir';
with 'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use autodie;
use Dist::Zilla::File::FromCode;
use Dist::Zilla::Path;

#pod =head1 DESCRIPTION
#pod
#pod This is a subclass of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
#pod plugin.  It works just like its parent class, except that each
#pod gathered file is processed through L<Text::Template>.
#pod
#pod The variables C<$plugin> and C<$dist> will be provided to the
#pod template, set to the GatherDir::Template plugin and the Dist::Zilla
#pod object, respectively.
#pod
#pod It is meant to be used when minting dists with C<dzil new>, but could be used
#pod in building existing dists, too.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod =head2 rename
#pod
#pod Use this to rename files while they are being gathered.  This is a list of
#pod key/value pairs, specified thus:
#pod
#pod     [GatherDir::Template]
#pod     rename.DISTNAME = $dist->name =~ s/...//r
#pod     rename.DISTVER  = $dist->version
#pod
#pod This example will replace the tokens C<DISTNAME> and C<DISTVER> with the
#pod expressions they are associated with. These expressions will be treated as
#pod though they were miniature Text::Template sections, and hence will receive the
#pod same variables that the file itself receives, i.e. C<$dist> and C<$plugin>.
#pod
#pod =cut

has _rename => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { +{} },
);

around BUILDARGS => sub {
  my $orig = shift;
  my ($class, @arg) = @_;

  my $args = $class->$orig(@arg);
  my %retargs = %$args;

  for my $rename (grep /^rename/, keys %retargs) {
    my $expr = delete $retargs{$rename};
    $rename =~ s/^rename\.//;
    $retargs{_rename}->{$rename} = $expr;
  }

  return \%retargs;
};

sub _file_from_filename {
  my ($self, $filename) = @_;

  my $template = path($filename)->slurp_utf8;

  my @stat = stat $filename or $self->log_fatal("$filename does not exist!");

  my $new_filename = $filename;

  for my $token (keys %{$self->_rename}) {
    my $expr = $self->_rename->{$token};
    my $temp_temp = "{{ $expr }}";
    my $replacement = $self->fill_in_string(
      $temp_temp,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );

    $new_filename =~ s/\Q$token/$replacement/g;
  }

  return Dist::Zilla::File::FromCode->new({
    name => $new_filename,
    mode => ($stat[2] & 0755) | 0200, # kill world-writeability, make sure owner-writable.
    code => sub {
      my ($file_obj) = @_;
      $self->fill_in_string(
        $template,
        {
          dist   => \($self->zilla),
          plugin => \($self),
        },
      );
    },
  });
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GatherDir::Template - gather all the files in a directory and use them as templates

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This is a subclass of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
plugin.  It works just like its parent class, except that each
gathered file is processed through L<Text::Template>.

The variables C<$plugin> and C<$dist> will be provided to the
template, set to the GatherDir::Template plugin and the Dist::Zilla
object, respectively.

It is meant to be used when minting dists with C<dzil new>, but could be used
in building existing dists, too.

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

=head1 ATTRIBUTES

=head2 rename

Use this to rename files while they are being gathered.  This is a list of
key/value pairs, specified thus:

    [GatherDir::Template]
    rename.DISTNAME = $dist->name =~ s/...//r
    rename.DISTVER  = $dist->version

This example will replace the tokens C<DISTNAME> and C<DISTVER> with the
expressions they are associated with. These expressions will be treated as
though they were miniature Text::Template sections, and hence will receive the
same variables that the file itself receives, i.e. C<$dist> and C<$plugin>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
