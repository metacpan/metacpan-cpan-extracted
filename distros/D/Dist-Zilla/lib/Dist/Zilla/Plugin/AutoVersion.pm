package Dist::Zilla::Plugin::AutoVersion 6.032;
# ABSTRACT: take care of numbering versions so you don't have to

use Moose;
with(
  'Dist::Zilla::Role::VersionProvider',
  'Dist::Zilla::Role::TextTemplate',
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin automatically produces a version string, generally based on the
#pod current time.  By default, it will be in the format: 1.yyDDDn
#pod
#pod =cut

#pod =attr major
#pod
#pod The C<major> attribute is just an integer that is meant to store the major
#pod version number.  If no value is specified in configuration, it will default to
#pod 1.
#pod
#pod This attribute's value can be referred to in the autoversion format template.
#pod
#pod =cut

has major => (
  is   => 'ro',
  isa  => 'Int',
  required => 1,
  default  => 1,
);

#pod =attr format
#pod
#pod The format is a L<Text::Template> string that will be rendered to form the
#pod version.  It is meant to access to one variable, C<$major>, and one subroutine,
#pod C<cldr>, which will format the current time (in GMT) using CLDR patterns (for
#pod which consult the L<DateTime> documentation).
#pod
#pod The default value is:
#pod
#pod   {{ $major }}.{{ cldr('yyDDD') }}
#pod   {{ sprintf('%01u', ($ENV{N} || 0)) }}
#pod   {{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}
#pod
#pod =cut

has time_zone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  default  => 'GMT',
);

has format => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  default  => q<{{ $major }}.{{ cldr('yyDDD') }}>
            . q<{{ sprintf('%01u', ($ENV{N} || 0)) }}>
            . q<{{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}>
);

sub provide_version {
  my ($self) = @_;

  if (exists $ENV{V}) {
    $self->log_debug([ 'providing version %s', $ENV{V} ]);
    return $ENV{V};
  }

  # TODO declare this as a 'develop' prereq as we want it in
  # `dzil listdeps --author`
  require DateTime;
  DateTime->VERSION('0.44'); # CLDR fixes

  my $now;

  my $version = $self->fill_in_string(
    $self->format,
    {
      major => \( $self->major ),
      cldr  => sub {
        $now ||= do {
          require DateTime;
          DateTime->VERSION('0.44'); # CLDR fixes
          DateTime->now(time_zone => $self->time_zone);
        };
        $now->format_cldr($_[0])
      },
    },
  );

  $self->log_debug([ 'providing version %s', $version ]);

  return $version;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins:
#pod L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
#pod L<PodVersion|Dist::Zilla::Plugin::PodVersion>,
#pod L<NextRelease|Dist::Zilla::Plugin::NextRelease>.
#pod
#pod Dist::Zilla roles:
#pod L<VersionProvider|Dist::Zilla::Role::VersionProvider>,
#pod L<TextTemplate|Dist::Zilla::Role::TextTemplate>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AutoVersion - take care of numbering versions so you don't have to

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin automatically produces a version string, generally based on the
current time.  By default, it will be in the format: 1.yyDDDn

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

=head2 major

The C<major> attribute is just an integer that is meant to store the major
version number.  If no value is specified in configuration, it will default to
1.

This attribute's value can be referred to in the autoversion format template.

=head2 format

The format is a L<Text::Template> string that will be rendered to form the
version.  It is meant to access to one variable, C<$major>, and one subroutine,
C<cldr>, which will format the current time (in GMT) using CLDR patterns (for
which consult the L<DateTime> documentation).

The default value is:

  {{ $major }}.{{ cldr('yyDDD') }}
  {{ sprintf('%01u', ($ENV{N} || 0)) }}
  {{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<PodVersion|Dist::Zilla::Plugin::PodVersion>,
L<NextRelease|Dist::Zilla::Plugin::NextRelease>.

Dist::Zilla roles:
L<VersionProvider|Dist::Zilla::Role::VersionProvider>,
L<TextTemplate|Dist::Zilla::Role::TextTemplate>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
