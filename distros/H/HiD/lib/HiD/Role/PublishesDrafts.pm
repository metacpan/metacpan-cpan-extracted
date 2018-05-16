#ABSTRACT: Role for the 'publishes_drafts' attr

package HiD::Role::PublishesDrafts;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Role::PublishesDrafts::VERSION = '1.992';
use Moose::Role;

requires '_run';


has publish_drafts=> (
  is          => 'ro' ,
  isa         => 'Bool' ,
  cmd_aliases => 'D' ,
  traits      => [ 'Getopt' ] ,
);

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Role::PublishesDrafts - Role for the 'publishes_drafts' attr

=head1 ATTRIBUTES

=head2 publish_drafts

Flag indicating whether or not to publish draft posts stored in the drafts
directory (which defaults to '_drafts' but can be set with the 'drafts_dir'
config key).

=head1 VERSION

version 1.992

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
