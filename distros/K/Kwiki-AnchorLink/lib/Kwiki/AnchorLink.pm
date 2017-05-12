package Kwiki::AnchorLink;
use Kwiki::Plugin -Base;
our $VERSION = '0.03';

const class_id => 'anchor_link';
const class_title => 'Anchor Link';

sub register {
    my $registry = shift;
    $registry->add(wafl => anchor => 'Kwiki::AnchorLink::Point');
    $registry->add(wafl => anchorlink => 'Kwiki::AnchorLink::Ref');
}


package Kwiki::AnchorLink::Ref;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my ($anchor,$title) = split(/\s+/,$self->arguments,2);
    $title ||= $anchor;
    return qq{<a href="#$anchor">$title</a>};
}

package Kwiki::AnchorLink::Point;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my $anchor_name = $self->arguments;
    return qq{<a name="$anchor_name"></a>};
}

__END__

=head1 NAME

Kwiki::AnchorLink - Provide Anchor wafl phrase to kwiki

=head1 SYNOPSIS

    {anchor: mybio}
    == My Bio

    ......

    {anchorlink: mybio Look at My Bio}

=head1 DESCRIPTION

This kwiki plugin provide one missing function to kwiki: anchor
points.  With {anchor: <anchor_name>} wafl phrase you could create a
anchor link at the point. It actually generate something like this:

    <a name="mybio"></a>

Then, in the other place of the same page, you could use {anchorlink:
<name> <title>} to put a link to that anchor, it'll generate something
like this:

    <a href="#mybio">Look at My Bio</a>

The first agrument to {anchorlink} is taken as the name of anchor
point, and the rests are used as the link title.

So far it doesn't not generate corss-page anchor link, so please
be patient, or send me patch. :)

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
