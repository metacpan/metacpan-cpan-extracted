package FL3;

use warnings;
use strict;

use Lingua::FreeLing3;
use Lingua::FreeLing3::Tokenizer;
use Lingua::FreeLing3::Splitter;
use Lingua::FreeLing3::MorphAnalyzer;
use Lingua::FreeLing3::HMMTagger;
use Lingua::FreeLing3::RelaxTagger;
use Lingua::FreeLing3::ChartParser;
use Lingua::FreeLing3::DepTxala;
use Lingua::FreeLing3::NEC;
use Carp;

use parent 'Exporter';

my %map = (
           'Tokenizer'     => { method_name => 'tokenizer' },
           'Splitter'      => { method_name => 'splitter'  },
           'MorphAnalyzer' => { method_name => 'morph'     },
           'HMMTagger'     => { method_name => 'hmm'       },
           'NEC'           => { method_name => 'nec'       },
           'RelaxTagger'   => { method_name => 'relax'     },
           'ChartParser'   => { method_name => 'chart'     },
           'DepTxala'      => { method_name => 'txala',
                                before => sub {
                                    my @args;
                                    if (@_ > 1) {
                                        push @args, shift(@_) if @_ % 1;
                                        my %ops = @_;
                                        if (!$ops{ChartParser} && !$ops{StartSymbol}) {
                                            ## XXX - This works when invoked with a language,
                                            ##       doesn't when invoked with a filepath.
                                            $ops{ChartParser} = chart(@args);
                                        }
                                        push @args, %ops;
                                    } else {
                                        @args = @_;
                                    }
                                    return @args;
                                }
                              },
          );

our @EXPORT = (qw(set_language release_language word sentence),
               map { $map{$_}{method_name} } keys %map);

our $VERSION = '0.03';

our $selected_language = undef;
our $tools_cache = {};

=encoding utf-8

=head1 NAME

FL3 - A shortcut module for Lingua::FreeLing3.

=head1 SYNOPSIS

  use FL3 'en';

  # This is the usual workflow:

  # 1. tokenize your text
  $tokens = tokenizer->tokenize($text);
  $atomos = tokenizer('pt')->tokenize($texto);

  # 2. divide tokens in groups: sentences
  $sentences = splitter->split($tokens);
  $frases = splitter('pt')->split($atomos);

  # 3. use a morphologic analyzer to tag words
  $sentences = morph->analyze($sentences);
  $frases = morph('pt')->analyze($frases);

  # 4. use HMM or RELAX tagger to disambiguate
  $sentences = hmm->analyze($sentences);
  $frases = relax('pt')->tag($sentences);

  # 5. use chart parser to parse tree
  $sentences = chart->parse($sentences);
  $ptree = $sentences->[0]->parse_tree;


  # other utility methods

  $word = word("cavalo");
  @words = word("cavalo", "alado");

  $sentence = sentence(word(qw(gosto muito de ti)));

=head1 DESCRIPTION

Implements a set of utility functions to access C<Lingua::FreeLing3>
objects.

Everytime one of the accessors is used just with the language
code/language data file (or using the default language), the cached
processor is returned if it exists. If any other arguments are used, a
new processor is created. This means that if you want to use the
morphological analyzer more than once, with different arguments, you
should first initialize it, using:

    morph( en => (AffixFile => 'myAfixes.dat',
                  DictionaryFile => 'myFile.src'));

And then, when analyzing sentences, use:

    morph('en')->analyze($sentences);

This way, the processor initialized before will be used without
reinitialziation.

=head2 C<set_language>

Sets the current language for subsequent methods calls. Returns the
old set language, if any.

=cut

sub set_language {
    my $v = $selected_language;
    $selected_language = shift;
    return $v;
}

=head2 C<release_language>

Some resources take too much space on memory. Use this method to
release the resources for a specific language. If you need them again,
they will be recreated.

Only one argument is mandatory: the name of the language. Unlike the
other method, this method B<requires> that you supply the language
name. It B<does not> use the default language.

Extra arguments are the name of the modules to be released (same names
as their accessor methods).

=cut

sub release_language {
    if (@_ < 1) {
        carp "One argument (language name) is mandatory for 'release_langauge'";
        return;
    }

    my $language = shift;
    if (@_) {
        for my $module (@_) {
            delete $tools_cache->{$language}{$module} if (exists($tools_cache->{$language}) and
                                                          exists($tools_cache->{$language}{$module}));
        }
    } else {
        delete $tools_cache->{$language} if exists $tools_cache->{$language};
    }
}

=head2 C<tokenizer>

Accesses a tokenizer (L<Lingua::FreeLing3::Tokenizer>).

=head2 C<splitter>

Accesses a splitter (L<Lingua::FreeLing3::Splitter>).

=head2 C<morph>

Accesses a morphological analyzer (L<Lingua::FreeLing3::MorphAnalyzer>).

=head2 C<hmm>

Accesses a HMM-based tagger (L<Lingua::FreeLing3::HMMTagger>).

=head2 C<relax>

Accesses a Relax-based tagger (L<Lingua::FreeLing3::RelaxTagger>).

=head2 C<chart>

Accesses a Chart-based parser (L<Lingua::FreeLing3::ChartParser>).

=head2 C<txala>

Accesses a Txala-based dependency parser (L<Lingua::FreeLing3::DepTxala>).

=head2 C<nec>

Accesses a Name Entity parser (L<Lingua::FreeLing3::NEC>).

=head2 C<word>

C<Lingua::FreeLing3::Word> object constructor shortcut.

=cut

sub word {
    return (wantarray) ?
	map { Lingua::FreeLing3::Word->new($_) } @_
	:
	Lingua::FreeLing3::Word->new($_[0]);
}

=head2 C<sentence>

C<Lingua::FreeLing3::Sentence> object constructor shortcut.

=cut

sub sentence {
    Lingua::FreeLing3::Sentence->new( @_ );
}


for my $accessor (keys %map) {
    my $lc = $map{$accessor}{method_name};
    my $before = exists($map{$accessor}{before}) ? $map{$accessor}{before} : sub { @_ };
    no strict 'refs';
    *{"FL3::$lc"} = sub {
        my $l;
        my @a = $before->(@_);
        if (@a <= 1) {
            $l = shift || $selected_language;
            unless (exists($tools_cache->{$l}{$accessor})) {
                $tools_cache->{$l}{$accessor} = "Lingua::FreeLing3::$accessor"->new($l);
            }
        } else {
            $l = $selected_language;
            $l = shift @a if @a % 2;
            $tools_cache->{$l}{$accessor} = "Lingua::FreeLing3::$accessor"->new($l => @a);
        }
        return $tools_cache->{$l}{$accessor}
    };
}

sub import {
    my $self = shift;
    my $lang = shift;
    $selected_language = $lang if $lang;

    $self->export_to_level(1, undef, @EXPORT);
}

=head1 SEE ALSO

Lingua::FreeLing3(3)

=head1 AUTHOR

Alberto Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alberto Simões

=cut

1;

