package Lingua::FreeLing3::DepTxala;

use warnings;
use strict;

use Carp;
use Lingua::FreeLing3;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::ChartParser;
use Lingua::FreeLing3::Config;
use Lingua::FreeLing3::DepTree;
use Scalar::Util 'blessed';

use parent -norequire, 'Lingua::FreeLing3::Bindings::dep_txala';

our $VERSION = "0.01";


=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::DepTxala - Interface to FreeLing3 DetTxala

=head1 SYNOPSIS

   use Lingua::FreeLing3::DepTxala;

   my $pt_parser = Lingua::FreeLing3::DepTxala->new("pt");

   $taggedListOfSentences = $pt_parser->analyze($listOfSentences);

=head1 DESCRIPTION

Interface to the FreeLing3 txala parser library.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the parser and the txala data
files).

=over 4

=item C<ChartParser>

Specify a reference to a L<Lingua::FreeLing3::ChartParser> where the
grammar start symbol should be obtained.

=item C<StartSymbol>

If you do not have the C<ChartParser> but know what is the grammar
start symbol, pass it with this option.

=back

=cut

sub new {
    my ($class, $lang, %ops) = @_;

    my $start_symbol;

    if (exists($ops{ChartParser}) &&
        blessed($ops{ChartParser}) &&
        $ops{ChartParser}->isa('Lingua::FreeLing3::Bindings::chart_parser')) {
        $start_symbol = $ops{ChartParser}->start_symbol();
    }
    elsif (exists($ops{StartSymbol})) {
        $start_symbol = $ops{StartSymbol};
    }
    else {
        my $chartParser = Lingua::FreeLing3::ChartParser->new($lang);
        $chartParser or die "Cannot guess what chart parser to use";
        $start_symbol = $chartParser->start_symbol();
    }

    my $config = Lingua::FreeLing3::Config->new($lang);
    my $file = $config->config("DepTxalaFile");

    unless (-f $file) {
        carp "Cannot find txala data file. Tried [$file]\n";
        return undef;
    }

    my $self = Lingua::FreeLing3::Bindings::dep_txala->new($file, $start_symbol);
    return bless $self => $class #amen
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
    my ($self, $sentences) = @_;

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
