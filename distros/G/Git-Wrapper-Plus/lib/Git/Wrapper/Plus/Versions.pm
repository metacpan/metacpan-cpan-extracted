use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Versions;

our $VERSION = '0.004011';

# ABSTRACT: Analyze and compare git versions

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( has );
use Sort::Versions qw( versioncmp );




























has git => required => 1, is => ro =>;







sub current_version {
  my ($self) = @_;
  return $self->git->version;
}











sub newer_than {
  my ( $self, $v ) = @_;
  return versioncmp( $self->current_version, $v ) >= 0;
}











sub older_than {
  my ( $self, $v ) = @_;
  return versioncmp( $self->current_version, $v ) < 0;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Versions - Analyze and compare git versions

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Versions;
    my $v = Git::Wrapper::Plus::Versions->new(
        git => $git_wrapper
    );

    print $v->current_version; # Current V String.

    # Larger or equal to 1.5
    if ( $v->newer_than('1.5') ) {

    }

    # Lesser than 1.5
    if ( $v->older_than('1.5') ) {

    }

=head1 METHODS

=head2 C<current_version>

Reports the current C<git> version.

=head2 C<newer_than>

    if ( $v->newer_than('1.5') ) {

    }

Reports if git is 1.5 or larger.

=head2 C<older_than>

    if ( $v->older_than('1.5') ) {

    }

Reports if git is C<< <1.5 >>

=head1 ATTRIBUTES

=head2 C<git>

B<REQUIRED>: A Git::Wrapper compatible object.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Git::Wrapper::Plus::Versions",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
