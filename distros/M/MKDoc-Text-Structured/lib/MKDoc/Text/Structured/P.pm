package MKDoc::Text::Structured::P;
use MKDoc::Text::Structured::Inline;
use warnings;
use strict;

sub process
{
    my $self = shift;
    my $text = join "\n", @{$self->{lines}};
    $text = MKDoc::Text::Structured::Inline::process ($text);
    return "<p>$text</p>";
}

1;

__END__
