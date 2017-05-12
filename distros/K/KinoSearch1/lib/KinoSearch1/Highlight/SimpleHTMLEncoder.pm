package KinoSearch1::Highlight::SimpleHTMLEncoder;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars();
}

sub encode {
    my $text = $_[1];
    for ($text) {
        s/&/&amp;/g;
        s/"/&quot;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
    }
    return $text;
}

1;

__END__

=head1 NAME

KinoSearch1::Highlight::SimpleHTMLEncoder - encode a few HTML entities

=head1 SYNOPSIS

    # returns '&quot;Hey, you!&quot;'
    my $encoded = $encoder->encode('"Hey, you!"');

=head1 DESCRIPTION

Implemetation of L<KinoSearch1::Highlight::Encoder> which encodes HTML
entities.  Currently, this module takes a minimal approach, encoding only
'<', '>', '&', and '"'.  That is likely to change in the future.

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
