use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::CheckMetaResources;
# ABSTRACT: Ensure META includes resources
our $VERSION = '0.001'; # VERSION

# Dependencies
use Dist::Zilla 4 ();
use autodie 2.00;
use Moose 0.99;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

has [qw/repository bugtracker/] => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);

has homepage => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

with 'Dist::Zilla::Role::BeforeRelease';

# methods

sub before_release {
  my $self = shift;
  my $dm = $self->zilla->distmeta;

  $self->log("Checking META resources");

  my @keys = qw/repository bugtracker homepage/;
  my @errors = grep { $self->$_ && ! exists $dm->{resources}{$_} } @keys;

  if ( ! @errors ) {
    $self->log("META resources OK");
  }
  else {
    $self->log_fatal("META resources not specified: @errors");
  }

  return;
}

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=2 sts=2 sw=2 et:

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::CheckMetaResources - Ensure META includes resources

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # in dist.ini

  [CheckMetaResources]

=head1 DESCRIPTION

This is a "before release" L<Dist::Zilla> plugin that ensures that your META file
will contain some "resources" data.

By default, it requires you to have at least 'repository' and 'bugtracker'
sections, but 'homepage' is optional.

You can toggle any of these checks on or off.  For example:

  [CheckMetaResources]
  repository = 1
  bugtracker = 0
  homepage = 1

=for Pod::Coverage before_release

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::MetaResources>

=item *

L<Dist::Zilla::Plugin::GithubMetas>

=item *

L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

... and plenty more (search metacpan.org for "dist zilla plugin meta")

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckMetaResources>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dist-zilla-plugin-checkmetaresources>

  git clone https://github.com/dagolden/dist-zilla-plugin-checkmetaresources.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

