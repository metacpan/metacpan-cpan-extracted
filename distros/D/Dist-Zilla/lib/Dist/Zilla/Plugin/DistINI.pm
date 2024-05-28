package Dist::Zilla::Plugin::DistINI 6.032;
# ABSTRACT: a plugin to add a dist.ini to newly-minted dists

use Moose;
with qw(Dist::Zilla::Role::FileGatherer);

use Dist::Zilla::Pragmas;

use Dist::Zilla::File::FromCode;

use MooseX::Types::Moose qw(ArrayRef Str);
use Dist::Zilla::Path;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugins produces a F<dist.ini> file in a new dist, specifying the required
#pod core attributes from the dist being minted.
#pod
#pod This plugin is dead simple and pretty stupid, but should get better as dist
#pod minting facilities improve.  For example, it will not specify any plugins.
#pod
#pod In the meantime, you may be happier with a F<dist.ini> template.
#pod
#pod =attr append_file
#pod
#pod This parameter may be a filename in the profile's directory to append to the
#pod generated F<dist.ini> with things like plugins.  In other words, if your make
#pod this file, called F<plugins.ini>:
#pod
#pod   [@Basic]
#pod   [NextRelease]
#pod   [@Git]
#pod
#pod ...and your F<profile.ini> includes:
#pod
#pod   [DistINI]
#pod   append_file = plugins.ini
#pod
#pod ...then the generated C<dist.ini> in a newly-minted dist will look something
#pod like this:
#pod
#pod   name    = My-New-Dist
#pod   author  = E. Xavier Ample <example@example.com>
#pod   license = Perl_5
#pod   copyright_holder = E. Xavier Ample
#pod   copyright_year   = 2010
#pod
#pod   [@Basic]
#pod   [NextRelease]
#pod   [@Git]
#pod
#pod =cut

sub mvp_multivalue_args { qw(append_file) }

has append_file => (
  is  => 'ro',
  isa => ArrayRef[ Str ],
  default => sub { [] },
);

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $postlude = '';

  for (@{ $self->append_file }) {
    my $fn = $self->zilla->root->child($_);

    $postlude .= path($fn)->slurp_utf8;
  }

  my $code = sub {
    my @core_attrs = qw(name authors copyright_holder);

    my $license = ref $zilla->license;
    if ($license =~ /^Software::License::(.+)$/) {
      $license = $1;
    } else {
      $license = "=$license";
    }

    my $content = '';
    $content .= sprintf "name    = %s\n", $zilla->name;
    $content .= sprintf "author  = %s\n", $_ for @{ $zilla->authors };
    $content .= sprintf "license = %s\n", $license;
    $content .= sprintf "copyright_holder = %s\n", $zilla->copyright_holder;
    $content .= sprintf "copyright_year   = %s\n", (localtime)[5] + 1900;
    $content .= "\n";

    $content .= $postlude;
  };

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'dist.ini',
    code => $code,
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DistINI - a plugin to add a dist.ini to newly-minted dists

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugins produces a F<dist.ini> file in a new dist, specifying the required
core attributes from the dist being minted.

This plugin is dead simple and pretty stupid, but should get better as dist
minting facilities improve.  For example, it will not specify any plugins.

In the meantime, you may be happier with a F<dist.ini> template.

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

=head2 append_file

This parameter may be a filename in the profile's directory to append to the
generated F<dist.ini> with things like plugins.  In other words, if your make
this file, called F<plugins.ini>:

  [@Basic]
  [NextRelease]
  [@Git]

...and your F<profile.ini> includes:

  [DistINI]
  append_file = plugins.ini

...then the generated C<dist.ini> in a newly-minted dist will look something
like this:

  name    = My-New-Dist
  author  = E. Xavier Ample <example@example.com>
  license = Perl_5
  copyright_holder = E. Xavier Ample
  copyright_year   = 2010

  [@Basic]
  [NextRelease]
  [@Git]

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
