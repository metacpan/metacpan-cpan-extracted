package Lingua::FreeLing3::RelaxTagger;

use warnings;
use strict;

use Carp;
use Lingua::FreeLing3;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::Config;

use parent -norequire, 'Lingua::FreeLing3::Bindings::relax_tagger';

our $VERSION = "0.01";


=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::RelaxTagger - Interface to FreeLing3 RelaxTagger

=head1 SYNOPSIS

   use Lingua::FreeLing3::RelaxTagger;

   my $pt_tagger = Lingua::FreeLing3::RelaxTagger->new("pt");

   $taggedListOfSentences = $pt_tagger->analyze($listOfSentences);

=head1 DESCRIPTION

Interface to the FreeLing3 relax tagger library.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the tagger data file).

The format of the constraint file is described in FreeLing
documentation.  This file can be generated from a tagged corpus using
the script src/utilitities/TRAIN provided in FreeLing package. See
comments in the script file to find out which format the corpus is
expected to have.

The constructor returns the tagger object for that language, or undef
in case of failure.

It understands the following options:

=over 4

=item C<maxIterations>

An integer stating the maximum number of iterations to wait for
convergence before stopping the disambiguation algorithm. Default
value if 500.

=item C<scaleFactor>

A real number representing the scale factor of the constraint
weights. Defaults to 670.

=item C<threshold>

 A real number representing the threshold under which any changes will
be considered too small. Used to detect convergence. Defaults to
0.001.

=item C<retokenize>

A boolean stating whether words that carry retokenization information
(e.g. set by the dictionary or affix handling modules) must be
retokenized (that is, splitted in two or more words) after the
tagging. Defaults to a true value.

=item C<ambiguityResolution>

An options stating whether and when the tagger must select only one
analysis in case of ambiguity. Possbile values are: C<FORCE_NONE>: no
selection forced, words ambiguous after the tagger, remain
ambiguous. C<FORCE_TAGGER>: force selection immediately after tagging,
and before retokenization. C<FORCE_RETOK>: force selection after
retokenization. Default is C<FORCE_RETOK>.

=back

=cut

sub new {
    my ($class, $lang, %ops) = @_;

    my $config = Lingua::FreeLing3::Config->new($lang);
    my $file = $config->config("TaggerRelaxFile");

    unless (-f $file) {
        carp "Cannot find relax_tagger data file. Tried [$file]\n";
        return undef;
    }

    my $maxIterations = Lingua::FreeLing3::_validate_integer($ops{maxIterations},
                                                             $config->config("TaggerRelaxMaxIter"));
    my $scaleFactor = Lingua::FreeLing3::_validate_real($ops{scaleFactor},
                                                        $config->config("TaggerRelaxScaleFactor"));
    my $threshold = Lingua::FreeLing3::_validate_real($ops{threshold},
                                                      $config->config("TaggerRelaxEpsilon"));
    my $retokenize = Lingua::FreeLing3::_validate_bool($ops{retokenize},
                                                       $config->config("TaggerRetokenize"));
    my $ft = $config->config("TaggerForceSelect");
    $ft = "FORCE_NONE"   if $ft eq "none";
    $ft = "FORCE_TAGGER" if $ft eq "tagger";
    $ft = "FORCE_RETOK"  if $ft eq "retok";
    my $ambiguityRes  = Lingua::FreeLing3::_validate_option( $ops{ambiguityResolution},
                                                             {
                                                              FORCE_NONE   => 0,
                                                              FORCE_TAGGER => 1,
                                                              FORCE_RETOK  => 2,
                                                             }, $ft);


    my $self = $class->SUPER::new($file, $maxIterations, $scaleFactor, $threshold,
                                  $retokenize, $ambiguityRes);
    return bless $self => $class
}


=head2 C<tag>

Alias to C<analyze>.

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

Copyright (C) 2011 by Projecto Natura

=cut
