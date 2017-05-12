package Lingua::FreeLing3::HMMTagger;

use warnings;
use strict;

use Carp;
use Lingua::FreeLing3;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::Config;
use Lingua::FreeLing3::ConfigData;

use parent -norequire, 'Lingua::FreeLing3::Bindings::hmm_tagger';

our $VERSION = "0.03";


=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::HMMTagger - Interface to FreeLing3 HMMTagger

=head1 SYNOPSIS

   use Lingua::FreeLing3::HMMTagger;

   my $pt_tagger = Lingua::FreeLing3::HMMTagger->new("pt");

   $taggedListOfSentences = $pt_tagger->analyze($listOfSentences);

=head1 DESCRIPTION

Interface to the FreeLing3 hmm tagger library.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the tagger data file).

Returns the tagger object for that language, or undef in case of
failure.

It understands the following options:

=over 4

=item C<Retokenize> (boolean)

States whether words that carry retokenization information (e.g. set
by the dictionary or affix handling modules) must be retokenized (that
is, splitted in two or more words) after the tagging.

=item C<AmbiguityResolution> (option)

States whether and when the tagger must select only one analysis in
case of ambiguity. Possible values are: FORCE_NONE: no selection
forced, words ambiguous after the tagger, remain
ambiguous. FORCE_TAGGER: force selection immediately after tagging,
and before retokenization. FORCE_RETOK: force selection after
retokenization.

=item C<KBest> (integer)

This option, only available with FreeLing 3.1, states how many best
tag sequences the tagger must try to compute. If not specified, this
parameter defaults to 1. Since a sentence may have less possible tag
sequences than the given k value, the results may contain a number of
sequences smaller than k.

=back

=cut

sub new {
    my ($class, $lang, %ops) = @_;

    my $config = Lingua::FreeLing3::Config->new($lang);
    my $file = $config->config("TaggerHMMFile");

    unless (-f $file) {
        carp "Cannot find hmm_tagger data file. Tried [$file]\n";
        return undef;
    }

    my $retok = Lingua::FreeLing3::_validate_bool($ops{Retokenize},
                                                  $config->config('TaggerRetokenize')); # bool
    my $ft = $config->config("TaggerForceSelect");
    $ft = "FORCE_NONE"   if $ft eq "none";
    $ft = "FORCE_TAGGER" if $ft eq "tagger";
    $ft = "FORCE_RETOK"  if $ft eq "retok";
    my $amb   = Lingua::FreeLing3::_validate_option($ops{AmbiguityResolution},
                                                    {
                                                     FORCE_NONE   => 0,
                                                     FORCE_TAGGER => 1,
                                                     FORCE_RETOK  => 2,
                                                    }, $ft);

    my $kbest = $ops{KBest} || 1;

    my $self;

    if (Lingua::FreeLing3::ConfigData->config("fl_minor") == 0) {
        $self = $class->SUPER::new($lang, $file, $retok, $amb);
    } else {
        $self = $class->SUPER::new($file, $retok, $amb, $kbest);
    }

    return bless $self => $class
}


=head2 C<tag>

Alias to C<analyze>

=cut

sub tag { &analyze }

=head2 C<analyze>

Receives a list of sentences, and returns that same list of sentences
after tagging process. Basically, selected the most probable
(accordingly with the tagger model) analysis for each word.

=cut

sub analyze {
    my ($self, $sentences, %opts) = @_;

    unless (Lingua::FreeLing3::_is_sentence_list($sentences)) {
        carp "Error: analyze argument isn't a list of sentences";
        return undef;
    }

    $sentences = $self->SUPER::analyze($sentences);

    for my $s (@$sentences) {
	$s->ACQUIRE();
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

Copyright (C) 2011-2013 by Projecto Natura

=cut
