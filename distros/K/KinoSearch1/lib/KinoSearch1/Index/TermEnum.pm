package KinoSearch1::Index::TermEnum;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

BEGIN { __PACKAGE__->init_instance_vars(); }

=begin comment

    $term_enum->seek($term);

Locate the Enum to a particular spot.

=end comment
=cut

sub seek { shift->abstract_death }

=begin comment

    my $evil_twin = $term_enum->clone_enum;

Return a dupe, in the same state as the orig.

=end comment
=cut

sub clone_enum { shift->abstract_death }

=begin comment

    my $not_end_of_enum_yet = $term_enum->next;

Proceed to the next term.  Return true until we fall off the end of the Enum,
then return false.

=end comment
=cut

sub next { shift->abstract_death }

sub skip_to { shift->todo_death }

=begin comment

    my $termstring = $term_enum->get_termstring;

Return a termstring, if the Enum is in a state where it's valid to do so.
Otherwise, return undef.

=end comment
=cut

sub get_termstring { shift->abstract_death }

sub get_terminfo       { shift->abstract_death }
sub get_index_interval { shift->abstract_death }
sub get_size           { shift->abstract_death }

sub close { shift->abstract_death }

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermEnum - scan through a list of Terms

==head1 SYNOPSIS

    # abstract base class

==head1 DESCRIPTION

Conceptually, a TermEnum is a array of Term => TermInfo pairs, sorted
lexically by term field name, then term text.  The implementations in
KinoSearch1 solve the same problem that tied arrays solve: it is possible to
iterate through the array while loading as little as possible into memory.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut



