package Lingua::FreeLing3::MorphAnalyzer;

use warnings;
use strict;

use 5.010;
use Carp;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Config;
use File::Spec::Functions 'catfile';
use Lingua::FreeLing3::Bindings;

our $VERSION = "0.01";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::MorphAnalyzer - Interface to FreeLing3 Morphological Analyzer

=head1 SYNOPSIS

   use Lingua::FreeLing3::MorphAnalyzer;

   my $morph = Lingua::FreeLing3::MorphAnalyzer->new("es",
    AffixAnalysis         => 1, AffixFile       => 'afixos.dat',
    QuantitiesDetection   => 0, QuantitiesFile  => "",
    MultiwordsDetection   => 1, LocutionsFile => 'locucions.dat',
    NumbersDetection      => 1,
    PunctuationDetection => 1, PunctuationFile => '../common/punct.dat',
    DatesDetection        => 1,
    DictionarySearch      => 1, DictionaryFile  => 'dicc.src',
    ProbabilityAssignment => 1, ProbabilityFile => 'probabilitats.dat',
    OrthographicCorrection => 1, CorrectorFile => 'corrector/corrector.dat',
    NERecognition => 1, NPdataFile => 'np.dat',
  );

  $sentence = $morph->analyze($sentence);

=head1 DESCRIPTION

Interface to the FreeLing3 Morphological Analyzer library.

=head2 C<new>

Object constructor. One argument is required: the languge code
(C<Lingua::FreeLing3> will search for the data file).

Returns the morphological analyzer object for that language, or undef
in case of failure.

=over 4

=item C<AffixAnalysis> (boolean)

=item C<MultiwordsDetection> (boolean)

=item C<NumbersDetection> (boolean)

=item C<PunctuationDetection> (boolean)

=item C<DatesDetection> (boolean)

=item C<QuantitiesDetection> (boolean)

=item C<DictionarySearch> (boolean)

=item C<ProbabilityAssignment> (boolean)

=item C<NERecognition> (boolean)

=item C<DecimalPoint> (string)

=item C<ThousandPoint> (string)

=item C<LocutionsFile> (file)

=item C<InverseDict> (boolean)

=item C<RetokContractions> (boolean)

=item C<QuantitiesFile> (file)

=item C<AffixFile> (file)

=item C<ProbabilityFile> (file)

=item C<DictionaryFile> (file)

=item C<NPdataFile> (file)

=item C<PunctuationFile> (file)

=item C<ProbabilityThreshold> (real)

=item C<UserMap> (boolean)

=item C<UserMapFile> (file)

=back

=cut

my %maco_valid_option = (
                         UserMap                => 'BOOLEAN',
                         UserMapFile            => 'FILE',
                         RetokContractions      => 'BOOLEAN',
                         InverseDict            => 'BOOLEAN',
                         AffixAnalysis          => 'BOOLEAN',
                         MultiwordsDetection    => 'BOOLEAN',
                         NumbersDetection       => 'BOOLEAN',
                         PunctuationDetection   => 'BOOLEAN',
                         DatesDetection         => 'BOOLEAN',
                         QuantitiesDetection    => 'BOOLEAN',
                         DictionarySearch       => 'BOOLEAN',
                         ProbabilityAssignment  => 'BOOLEAN',
                         NERecognition          => 'BOOLEAN',
                         DecimalPoint           => 'STRING',
                         ThousandPoint          => 'STRING',
                         LocutionsFile          => 'FILE',
                         QuantitiesFile         => 'FILE',
                         AffixFile              => 'FILE',
                         ProbabilityFile        => 'FILE',
                         DictionaryFile         => 'FILE',
                         NPdataFile             => 'FILE',
                         PunctuationFile        => 'FILE',
                         ProbabilityThreshold   => 'REAL',
                        );

sub _check_option {
    my ($self, $value, $type) = @_;

    if ($type eq "BOOLEAN") {
        $value = 1 if $value =~ /^yes$/i;
        $value = 1 if $value =~ /^true$/i;
        return $value eq "1" ? 1 : 0;
    }
    elsif ($type eq "REAL") {
        return $value =~ /(\d+(?:\.\d+))?/ ? $1 : undef;
    }
    elsif ($type eq "STRING") {
        $value =~ s/(?<!\\)"/\\"/g;
        return '"'.$value.'"';
    }
    elsif ($type eq "FILE") {
        $value    or return undef;
        -f $value and return '"'.$value.'"';

        my $ofile = catfile($self->{prefix} => $value);
        -f $ofile and return '"'.$ofile.'"';

        return undef;
    }
    else {
        return undef;
    }
}

sub new {
    my ($class, $lang, %maco_op) = @_;

    my $config = Lingua::FreeLing3::Config->new($lang);
    ## HACK
    my $dir = $config->config("TokenizerFile");
    $dir =~ s!/[^/]+$!!;

    # It might make sense to make this language-dependent
    my %default_ops = (
                       UserMap                => 0,
                       UserMapFile            => undef,
                       AffixAnalysis          => $config->config("AffixAnalysis"),
                       AffixFile              => $config->config("AffixFile"),
                       QuantitiesDetection    => $config->config("QuantitiesDetection"),
                       QuantitiesFile         => $config->config("QuantitiesFile"),
                       MultiwordsDetection    => $config->config("MultiwordsDetection"),
                       LocutionsFile          => $config->config("LocutionsFile"),
                       NumbersDetection       => $config->config("NumbersDetection"),
                       PunctuationDetection   => $config->config("PunctuationDetection"),
                       PunctuationFile        => $config->config("PunctuationFile"),
                       DatesDetection         => $config->config("DatesDetection"),
                       DictionarySearch       => $config->config("DictionarySearch"),
                       DictionaryFile         => $config->config("DictionaryFile"),
                       ProbabilityAssignment  => $config->config("ProbabilityAssignment"),
                       ProbabilityFile        => $config->config("ProbabilityFile"),
                       NERecognition          => $config->config("NERecognition"),
                       NPdataFile             => $config->config("NPDataFile"),
                       RetokContractions      => 0,
                       ProbabilityThreshold   => $config->config("ProbabilityThreshold"),
                       DecimalPoint           => $config->config("DecimalPoint"),
                       ThousandPoint          => $config->config("ThousandPoint"),
                      );

    my @keys = keys %{{ %maco_op, %default_ops }}; # as BingOS called it, hash shaving

    my $self = bless {
                      config => $config,
                      prefix => $dir,
                      maco_options => Lingua::FreeLing3::Bindings::maco_options->new($lang),
                     } => $class;

    my @to_deactivate = ();
    for my $op (@keys) {
        if ($maco_valid_option{$op}) {
            my $option = exists($maco_op{$op}) ? $maco_op{$op} : $default_ops{$op};


            if (defined($option = $self->_check_option($option, $maco_valid_option{$op}))) {
                eval "\$self->{maco_options}->swig_${op}_set($option);";
            } else {
                push @to_deactivate, $op if $op =~ /File$/;

                exists($maco_op{$op}) and carp "Option $op with invalid value: '$maco_op{$op}'.";
            }
        } else {
            carp "Option '$op' not recognized for MorphAnalyzer object."
        }
    }

    my %map = (AffixFile       => 'AffixAnalysis',
               QuantitiesFile  => 'QuantitiesDetection',
               LocutionsFile   => 'MultiwordsDetection',
               PunctuationFile => 'PunctuationDetection',
               DictionaryFile  => 'DictionarySearch',
               ProbabilityFile => 'ProbabilityAssignment',
               NPdataFile      => 'NERecognition'         );

    for my $op (@to_deactivate) {
        my $target = $map{$op};
        next unless $target && ($maco_op{$target} || $default_ops{$target});

        eval "\$self->{maco_options}->swig_${target}_set(0);";
    }

    $self->{maco} = Lingua::FreeLing3::Bindings::maco->new($self->{maco_options});
    return $self;
}

=head2 C<analyze>

=cut

sub analyze {
    my ($self, $sentences, %opts) = @_;

    unless (Lingua::FreeLing3::_is_sentence_list($sentences)) {
        carp "Error: analyze argument should be a list of sentences";
        return undef;
    }

    $sentences = $self->{maco}->analyze($sentences);

    for my $s (@$sentences) {
        $s->ACQUIRE();
        $s = Lingua::FreeLing3::Sentence->_new_from_binding($s);
    }

    return $sentences;

}



### TODO: maco_options
#
# *set_active_modules = *Lingua::FreeLing3::Bindingsc::maco_options_set_active_modules;
# *set_nummerical_points = *Lingua::FreeLing3::Bindingsc::maco_options_set_nummerical_points;
# *set_data_files = *Lingua::FreeLing3::Bindingsc::maco_options_set_data_files;
# *set_threshold = *Lingua::FreeLing3::Bindingsc::maco_options_set_threshold;
#
###


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

