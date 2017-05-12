package KinoSearch1::Highlight::Formatter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars();
}

sub highlight_term { shift->abstract_death }

1;

__END__

=head1 NAME

KinoSearch1::Highlight::Formatter - format highlighted bits within excerpts

=head1 SYNOPSIS

	# abstract base class

=head1 DESCRIPTION

Formatter objects serve one purpose: they highlight pieces of text within an
excerpt.  The text might be a single term, or it might be a phrase.  

=head1 METHODS

=head2 highlight

	my $highlighted = $formatter->highlight($text);

Highlight text by e.g. surrounding it with asterisks, or html "strong" tags,
etc.

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
