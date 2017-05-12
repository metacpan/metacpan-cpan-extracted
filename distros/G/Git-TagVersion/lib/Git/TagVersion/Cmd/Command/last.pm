package Git::TagVersion::Cmd::Command::last;

use Moose;

extends 'Git::TagVersion::Cmd::Command';

our $VERSION = '1.01'; # VERSION
# ABSTRACT: print last version

sub execute {
  my ( $self, $opt, $args ) = @_;
 
  if( defined $self->tag_version->last_version ) {
    print $self->tag_version->last_version->as_string."\n";
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Cmd::Command::last - print last version

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
