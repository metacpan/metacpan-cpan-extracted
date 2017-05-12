use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support;

our $VERSION = '0.004011';

# ABSTRACT: Determine what versions of things support what

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );























has 'git' => ( is => ro =>, required => 1 );

has 'versions' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_versions {
  my ( $self, ) = @_;
  require Git::Wrapper::Plus::Versions;
  return Git::Wrapper::Plus::Versions->new( git => $self->git );
}








has 'commands' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_commands {
  require Git::Wrapper::Plus::Support::Commands;
  return Git::Wrapper::Plus::Support::Commands->new();
}








has 'behaviors' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_behaviors {
  require Git::Wrapper::Plus::Support::Behaviors;
  return Git::Wrapper::Plus::Support::Behaviors->new();
}








has 'arguments' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_arguments {
  require Git::Wrapper::Plus::Support::Arguments;
  return Git::Wrapper::Plus::Support::Arguments->new();
}





















sub supports_command {
  my ( $self, $command ) = @_;
  return unless $self->commands->has_entry($command);
  return 1 if $self->commands->entry_supports( $command, $self->versions );
  return 0;
}





















sub supports_behavior {
  my ( $self, $beh ) = @_;
  return unless $self->behaviors->has_entry($beh);
  return 1 if $self->behaviors->entry_supports( $beh, $self->versions );
  return 0;
}





















sub supports_argument {
  my ( $self, $command, $argument ) = @_;
  return unless $self->arguments->has_argument( $command, $argument );
  return 1 if $self->arguments->argument_supports( $command, $argument, $self->versions );
  return 0;

}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support - Determine what versions of things support what

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Support;

    my $support = Git::Wrapper::Plus::Support->new(
        git => <git::wrapper>
    );
    if ( $support->supports_command( 'for-each-ref' ) ) {

    }
    if ( $support->supports_behavior('add-updates-index') ) {

    }

=head1 METHODS

=head2 C<supports_command>

Determines if a given command is supported on the current git.

This works by using a hand-coded table for interesting values
by processing C<git log> for git itself.

Returns C<undef> if the status of a command is unknown ( that is, has not been added
to the map yet ), C<0> if it is not supported, and C<1> if it is.

    if ( $supporter->supports_command('for-each-ref') ) ) {
        ...
    } else {
        ...
    }

See L<< C<::Support::Commands>|Git::Wrapper::Plus::Support::Commands >> for details.

=head2 C<supports_behavior>

Indicates if a given command behaves in a certain way

This works by using a hand-coded table for interesting values
by processing C<git log> for git itself.

Returns C<undef> if the status of a commands behavior is unknown ( that is, has not been added
to the map yet ), C<0> if it is not supported, and C<1> if it is.

    if ( $supporter->supports_behavior('add-updates-index') ) ) {
        ...
    } else {
        ...
    }

See L<< C<::Support::Behaviors>|Git::Wrapper::Plus::Support::Behaviors >> for details.

=head2 C<supports_argument>

Indicates if a given command accepts a specific argument.

This works by using a hand-coded table for interesting values
by processing C<git log> for git itself.

Returns C<undef> if the status of a commands argument is unknown ( that is, has not been added
to the map yet ), C<0> if it is not supported, and C<1> if it is.

    if ( $supporter->supports_argument('cat-file','-e') ) ) {
        ...
    } else {
        ...
    }

See L<< C<::Support::Arguments>|Git::Wrapper::Plus::Support::Arguments >> for details.

=head1 ATTRIBUTES

=head2 C<git>

=head2 C<versions>

=head2 C<commands>

This attribute contains a L<< C<::Support::Commands>|Git::Wrapper::Plus::Support::Commands >>
object for data on git command support.

=head2 C<behaviors>

This attribute contains a L<< C<::Support::Behaviors>|Git::Wrapper::Plus::Support::Behaviors >>
object for data on git command behavior support.

=head2 C<arguments>

This attribute contains a L<< C<::Support::Arguments>|Git::Wrapper::Plus::Support::Arguments >>
object for data on git command argument support.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
