# NAME

Grammar::Improver - A Perl module for improving grammar using LanguageTool API.

# VERSION

Version 0.02

# SYNOPSIS

    use Grammar::Improver;

    my $improver = Grammar::Improver->new(
            api_url => 'https://api.languagetool.org/v2/check',
            api_key => $ENV{'LANGUAGETOOL_KEY'},
    );

    my $text = 'This are a sample text with mistake.';
    my $corrected_text = $improver->improve_grammar($text);

    print "Corrected Text: $corrected_text\n";

# DESCRIPTION

The `Grammar::Improver` module interfaces with the LanguageTool API to analyze and improve grammar in text input.

# METHODS

## new

    my $improver = Grammar::Improver->new(%args);

Creates a new `Grammar::Improver` object.

## improve\_grammar

    my $corrected_text = $improver->improve_grammar($text);

Analyzes, improves and corrects the grammar of the input text.
Returns the corrected text.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>
