package MKDoc::Text::Structured::H3;
use MKDoc::Text::Structured::Inline;
use warnings;
use strict;


sub process
{
    my $self = shift;
    my $text = join "\n", @{$self->{lines}};
    $text = MKDoc::Text::Structured::Inline::process ($text);
    return "<h3>$text</h3>";
}


1;


__END__
