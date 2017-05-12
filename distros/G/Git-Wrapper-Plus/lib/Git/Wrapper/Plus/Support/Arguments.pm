use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::Arguments;

our $VERSION = '0.004011';

# ABSTRACT: Database of command argument support data

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );




























has 'entries' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_entries {
  my $hash = {};
  require Git::Wrapper::Plus::Support::RangeDictionary;
  $hash->{'cat-file'} = Git::Wrapper::Plus::Support::RangeDictionary->new();
  $hash->{'cat-file'}->add_range(
    '-e' => {
      'min'      => '1.0.0',
      'min_tag'  => '0.99.9l',
      'min_sha1' => '7950571ad75c1c97e5e53626d8342b01b167c790',
    },
  );
  return $hash;
}











sub commands {
  my ($self)  = @_;
  my (@items) = sort keys %{ $self->entries };
  return @items;
}











sub arguments {
  my ( $self, $command ) = @_;
  return unless $self->has_command($command);
  return $self->entries->{$command}->entries;
}











sub has_command {
  my ( $self, $command ) = @_;
  return exists $self->entries->{$command};
}











sub has_argument {
  my ( $self, $command, $argument ) = @_;
  return unless $self->has_command($command);
  return $self->entries->{$command}->has_entry($argument);
}









sub argument_supports {
  my ( $self, $command, $argument, $version_object ) = @_;
  return unless $self->has_argument( $command, $argument );
  return $self->entries->{$command}->entry_supports( $argument, $version_object );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::Arguments - Database of command argument support data

=head1 VERSION

version 0.004011

=head1 METHODS

=head2 C<commands>

Returns a list of C<git> commands we have support data for.

    for my $cmd ( $arg->commands ) {

    }

=head2 C<arguments>

Returns a list of argument names we have support data for, with the given command

    for my $argument ( $arg->arguments('cat-file') ) {

    }

=head2 C<has_command>

Determines if a given command is listed in the support data

    if ( $arg->has_command('cat-file') ) {

    }

=head2 C<has_argument>

Determines if a given C<argument> is listed in the support data

    if ( $arg->has_argument('cat-file', '-e' ) ) {

    }

=head2 C<argument_supports>

Determine if a given argument is supported by a given C<git> version

    $arg->argument_support( 'cat-file', '-e', $GWP->versions );

=head1 ATTRIBUTES

=head2 C<entries>

2D Hash of command/argument/ranges

Though you never want to deal with this complex data directly...

    cat-file => {
        ::RangeDictionary->new( dictionary => {
                '-e' => RangeSet->new(
                            items => [  Range->new( min => '1.0.0' ) ]
               )
            },
        ),
    };

=head1 SUPPORTED ARGUMENTS

=head2 C<cat-file>

=head3 C<-e>

C<cat-file -e> Was added in Git 1.0.0

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
