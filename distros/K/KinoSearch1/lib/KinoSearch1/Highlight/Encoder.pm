package KinoSearch1::Highlight::Encoder;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars();
}

sub encode { shift->abstract_death }

1;

__END__

=head1 NAME

KinoSearch1::Highlight::Encoder - encode excerpted text

=head1 SYNOPSIS

    # abstract base class

=head1 DESCRIPTION

Encoder objects are invoked by Highlighter objects for every piece of text
that makes it into an excerpt.  The archetypal implementation is
KinoSearch1::Highlight::SimpleHTMLEncoder.

=head1 METHODS

=head2 encode

    my $encoded = $encoder->encode($text);

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
