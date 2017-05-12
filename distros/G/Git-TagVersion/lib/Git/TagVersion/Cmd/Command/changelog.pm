package Git::TagVersion::Cmd::Command::changelog;

use Moose;

extends 'Git::TagVersion::Cmd::Command';

our $VERSION = '1.01'; # VERSION
# ABSTRACT: generate a changelog

has 'style' => (
  is => 'rw', isa => 'Str', default => 'simple',
  traits => [ 'Getopt' ],
  cmd_aliases => 's',
  documentation => 'format of changelog',
);

sub execute {
  my ( $self, $opt, $args ) = @_;

  foreach my $v ( @{$self->tag_version->versions} ) {
    print $v->render( $self->style );
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Cmd::Command::changelog - generate a changelog

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
