use 5.006;
use strict;
use warnings;

package Metabase::Resource::perl::commit;

our $VERSION = '0.025';

use Carp ();

use Metabase::Resource::perl;
our @ISA = qw/Metabase::Resource::perl/;

sub _metadata_types {
    return { sha1 => '//str', };
}

sub _init {
    my ($self) = @_;

    my ($string) = $self =~ m{\Aperl:///commit/(.+)\z};
    Carp::confess("could not determine commit from '$self'\n")
      unless defined $string && length $string;

    my $sha1 = $1;
    Carp::confess("illegal commit hash")
      unless $sha1 =~ m/^[a-f0-9]+$/;

    $self->_add( 'sha1' => $sha1 );

    return $self;
}

#pod =method full_url
#pod
#pod   my $url = $self->full_url($host);
#pod
#pod Returns an ordinary HTTP URL to the resource.  If C<$host> is not
#pod given, it defaults to the official master Perl repository at
#pod L<http://perl5.git.perl.org>.
#pod
#pod =cut

sub full_url {
    my ( $self, $host ) = @_;
    $host ||= 'perl5.git.perl.org';
    return "http://${host}/perl.git/" . $self->sha1;
}

# 'commit' validates during _init, really
sub validate { 1 }

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   my $resource = Metabase::Resource->new(
#pod     'perl:///commit/8c576062',
#pod   );
#pod
#pod   my $resource_meta = $resource->metadata;
#pod   my $typemap       = $resource->metadata_types;
#pod   my $url = $self->full_url;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Generates resource metadata for resources of the scheme 'perl:///commit'.
#pod
#pod   my $resource = Metabase::Resource->new(
#pod     'perl:///commit/8c576062',
#pod   );
#pod
#pod For the example above, the resource metadata structure would contain the
#pod following elements:
#pod
#pod   scheme       => perl
#pod   type         => commit
#pod   sha1         => 8c576062
#pod
#pod =head1 BUGS
#pod
#pod Please report any bugs or feature using the CPAN Request Tracker.
#pod Bugs can be submitted through the web interface at
#pod L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>
#pod
#pod When submitting a bug or request, please include a test-file or a patch to an
#pod existing test-file that illustrates the bug or desired feature.
#pod
#pod =cut

1;

# ABSTRACT: class for Metabase resources about perl commits

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Resource::perl::commit - class for Metabase resources about perl commits

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $resource = Metabase::Resource->new(
    'perl:///commit/8c576062',
  );

  my $resource_meta = $resource->metadata;
  my $typemap       = $resource->metadata_types;
  my $url = $self->full_url;

=head1 DESCRIPTION

Generates resource metadata for resources of the scheme 'perl:///commit'.

  my $resource = Metabase::Resource->new(
    'perl:///commit/8c576062',
  );

For the example above, the resource metadata structure would contain the
following elements:

  scheme       => perl
  type         => commit
  sha1         => 8c576062

=head1 METHODS

=head2 full_url

  my $url = $self->full_url($host);

Returns an ordinary HTTP URL to the resource.  If C<$host> is not
given, it defaults to the official master Perl repository at
L<http://perl5.git.perl.org>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
