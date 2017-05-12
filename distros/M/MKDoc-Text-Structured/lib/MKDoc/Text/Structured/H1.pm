package MKDoc::Text::Structured::H1;
use MKDoc::Text::Structured::Inline;
use warnings;
use strict;


sub process
{
    my $self = shift;
    my $text = join "\n", @{$self->{lines}};
    $text = MKDoc::Text::Structured::Inline::process ($text);
    return "<h1>$text</h1>";
}


1;


__END__
