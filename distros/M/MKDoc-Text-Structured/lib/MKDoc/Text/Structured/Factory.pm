package MKDoc::Text::Structured::Factory;
use MKDoc::Text::Structured::Block;
use MKDoc::Text::Structured::SIG;
use MKDoc::Text::Structured::PRE;
use MKDoc::Text::Structured::BQ;
use MKDoc::Text::Structured::UL;
use MKDoc::Text::Structured::OL;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $line  = shift;
    return MKDoc::Text::Structured::UL->new    ($line) ||
           MKDoc::Text::Structured::OL->new    ($line) ||
           MKDoc::Text::Structured::BQ->new    ($line) ||
           MKDoc::Text::Structured::PRE->new   ($line) ||
           MKDoc::Text::Structured::SIG->new   ($line) ||
           # P + H1 + H2 + H3
           MKDoc::Text::Structured::Block->new ($line);
}


1;

__END__
