package MKDoc::Text::Structured::H2;
use MKDoc::Text::Structured::Inline;
use warnings;
use strict;


sub process
{
    my $self = shift;
    my $text = join "\n", @{$self->{lines}};
    $text = MKDoc::Text::Structured::Inline::process ($text);
    return "<h2>$text</h2>";
}


1;


__END__
