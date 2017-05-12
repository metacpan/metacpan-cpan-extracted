package Lingua::FreeLing3::ChartParser;

use warnings;
use strict;

use Carp;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Config;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Sentence;

use parent -norequire, 'Lingua::FreeLing3::Bindings::chart_parser';

our $VERSION = "0.01";


=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::ChartParser - Interface to FreeLing3 ChartParser

=head1 SYNOPSIS

   use Lingua::FreeLing3::ChartParser;

   my $pt_cparser = Lingua::FreeLing3::ChartParser->new("pt");

   $taggedListOfSentences = $pt_cparser->analyze($listOfSentences);

=head1 DESCRIPTION

Interface to the FreeLing3 chart parser library.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the tagger data file).

=cut

sub new {
    my ($class, $lang) = @_;

    my $config = Lingua::FreeLing3::Config->new($lang);
    my $file = $config->config("GrammarFile");

    unless (-f $file) {
        carp "Cannot find chart tagger data file. Tried [$file]\n";
        return undef;
    }

    my $self = $class->SUPER::new($file);
    return bless $self => $class
}

=head2 C<parse>

Alias to C<analyze>.

=cut

sub parse { &analyze }

=head2 C<analyze>

Receives a list of sentences, and returns that same list of sentences
after tagging process, enriching each sentence with a parse tree.

=cut

sub analyze {
    my ($self, $sentences, %opts) = @_;

    unless (Lingua::FreeLing3::_is_sentence_list($sentences)) {
        carp "Error: analyze argument isn't a list of sentences";
        return undef;
    }

    $sentences = $self->SUPER::analyze($sentences);

    for my $s (@$sentences) {
        $s = Lingua::FreeLing3::Sentence->_new_from_binding($s);
    }
    return $sentences;
}

=head2 C<start_symbol>

Returns the start symbol for the chart parser.

=cut

sub start_symbol {
    my $self = shift;
    return $self->SUPER::get_start_symbol();
}

1;

__END__

=head1 SEE ALSO

Lingua::FreeLing3 (3), freeling, perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

Jorge Cunha Mendes E<lt>jorgecunhamendes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Projecto Natura

=cut
