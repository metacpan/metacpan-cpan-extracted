# ABSTRACT: Driver for the shortened Czech tagset of the Prague Spoken Corpus (Pražský mluvený korpus).
# Copyright © 2009, 2010, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Pmkkr;
use strict;
use warnings;
our $VERSION = '3.007';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::CS::Pmk';



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear.
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        # Unlike in the long tags, the short tags in the corpus really annotate style.
        # substantivum = noun
        # 2! druh 3. třída 4. valence 5! rod 6. číslo 7. pád 8. funkce 9! styl
        '1' => ['pos', 'noun_type', 'gender', 'style'],
        # adjektivum = adjective
        # 2! druh 3! poddruh 4. třída 5. valence 6. rod 7. číslo 8. pád 9. stupeň 10. funkce 11! styl
        '2' => ['pos', 'adjective_type', 'adjective_subtype', 'style'],
        # zájmeno = pronoun
        # 2! druh 3. valence 4. rod 5. číslo 6. pád 7. funkce 8. styl
        '3' => ['pos', 'pronoun_type', undef, 'style'],
        # číslovka = numeral
        # 2! druh 3. valence 4. rod 5. číslo 6. pád 7. pád subst./pron. 8. funkce 9. styl
        '4' => ['pos', 'numeral_type', undef, 'style'],
        # sloveso = verb
        # 2. vid 3. valence subjektová 4. valence 5. osoba/číslo 6. způsob/čas/slovesný rod 7. imper./neurč. tvary 8! víceslovnost a rezultativnost 9. jmenný rod 10! zápor 11! styl
        '5' => ['pos', 'multiwordness_and_resultativity', 'polarity', 'style'],
        # adverbium = adverb
        # 2! druh 3. třída 4. valence/funkce 5. stupeň 6! styl
        '6' => ['pos', 'adverb_type', undef, 'style'],
        # předložka = preposition
        # 2! druh 3. třída 4. valenční pád 5. funkční závislost levá 6! styl
        '7' => ['pos', 'preposition_type', undef, 'style'],
        # spojka = conjunction
        # 2! druh 3. třída 4. valence 5! styl
        '8' => ['pos', 'conjunction_type', undef, 'style'],
        # citoslovce = interjection
        # 2! druh 3. třída 4! styl
        '9' => ['pos', 'interjection_type', undef, 'style'],
        # částice = particle
        # 2! druh 3. třída 4. valence 5. modus věty 6! styl
        '0' => ['pos', 'particle_type', undef, 'style'],
        # idiom a frazém = idiom and set phrase
        # 2! druh; other positions are not defined for F6: 3. valence substantivní 4. valence
        'F1' => ['pos', 'idiom_type', undef, 'style'],
        'F2' => ['pos', 'idiom_type', undef, 'style'],
        'F3' => ['pos', 'idiom_type', undef, 'style'],
        'F4' => ['pos', 'idiom_type', undef, 'style'],
        'F5' => ['pos', 'idiom_type', undef, 'style'],
        'F6' => ['pos', 'idiom_type', undef, 'style'],
        # jiné = other (real type encoded at second position: CZP)
        # 2! skutečný druh: CZP 7! styl
        # pouze pro P: P3. druh P4. rod P5. číslo P6. pád
        'JC' => ['pos', 'other_real_type', undef, 'style'],
        'JZ' => ['pos', 'other_real_type', undef, 'style'],
        'JP' => ['pos', 'other_real_type', 'proper_noun_type', 'style']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atoms = $self->atoms();
    my $features = $self->feature_map();
    my $pos = $atoms->{pos}->encode($fs);
    if($pos eq 'J')
    {
        $pos .= $atoms->{other_real_type}->encode($fs);
    }
    elsif($pos eq 'F')
    {
        $pos .= $atoms->{idiom_type}->encode($fs);
    }
    my @values;
    if(exists($features->{$pos}))
    {
        my @features = @{$features->{$pos}};
        for(my $i = 0; $i<=$#features; $i++)
        {
            next if(!defined($features[$i]));
            confess("Unknown atom '$features[$i]'") if(!exists($atoms->{$features[$i]}));
            $values[$i] = $atoms->{$features[$i]}->encode($fs);
            if($features[$i] eq 'gender')
            {
                $values[$i] = Lingua::Interset::Tagset::CS::Pmk::_internal_to_surface_gender($pos, $values[$i]);
            }
        }
    }
    my $tag;
    # Convert the array of values to a tag in the XML format.
    # If $values[0] is empty, then all are empty.
    # untagged tokens in multi-word expressions have empty tags like this:
    # <i1></i1><i2></i2><i3></i3><i4></i4><i5></i5><i6></i6><i7></i7><i8></i8><i9></i9><i10></i10><i11></i11>
    if(!defined($values[0]) || $values[0] eq '')
    {
        $tag = '<i1></i1><i2></i2><i3></i3><i4></i4>';
    }
    else
    {
        for(my $i = 0; $i<4; $i++)
        {
            my $iplus = $i+1;
            my $value = $values[$i];
            $value = '_' if(!defined($value));
            # In the corpus, undefined feature values are encoded either as empty strings (<i10></i10>) or using underscores (<i10>_</i10>).
            # The choice is arbitrary and there is no meaningful difference between the two ways.
            # We do not attempt to reconstruct the tags in the corpus. Instead, our list of permitted tags always prefers the empty strings.
            $tag .= "<i$iplus>$value</i$iplus>";
        }
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 236 (pmk_kr.xml)
# after cleaning: 212
# after addition of missing other-resistant tags: 244
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
<i1>0</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>9</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>9</i3><i4>2</i4>
<i1>1</i1><i2>3</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>3</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>3</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>4</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>4</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>4</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>4</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>5</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>5</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>5</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>5</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>5</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>6</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>6</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>7</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>7</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>7</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>7</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>9</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>9</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>9</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>3</i4>
<i1>2</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>1</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>1</i3><i4>4</i4>
<i1>2</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>2</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>3</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>3</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>3</i4>
<i1>2</i1><i2>1</i2><i3>5</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>4</i4>
<i1>2</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>2</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>3</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>3</i4>
<i1>2</i1><i2>2</i2><i3>5</i3><i4>2</i4>
<i1>2</i1><i2>3</i2><i3>0</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>0</i3><i4>2</i4>
<i1>2</i1><i2>3</i2><i3>3</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>3</i3><i4>2</i4>
<i1>2</i1><i2>3</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>4</i3><i4>2</i4>
<i1>3</i1><i2>-</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>-</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>0</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>0</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>3</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>7</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>8</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>8</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>9</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>9</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>0</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>0</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>7</i2><i3>_</i3><i4>2</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>3</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>4</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>3</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>3</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>3</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>4</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>4</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>4</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>4</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>5</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>5</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>5</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>5</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>6</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>6</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>7</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>7</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>8</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>9</i2><i3>1</i3><i4>2</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>6</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>3</i4>
<i1>6</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>9</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>9</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>7</i2><i3>_</i3><i4>2</i4>
<i1></i1><i2></i2><i3></i3><i4></i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>3</i4>
<i1>F</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>3</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>4</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>1</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>2</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>4</i4>
<i1>J</i1><i2>P</i2><i3>1</i3><i4>1</i4>
<i1>J</i1><i2>P</i2><i3>1</i3><i4>2</i4>
<i1>J</i1><i2>P</i2><i3>2</i3><i4>1</i4>
<i1>J</i1><i2>P</i2><i3>2</i3><i4>2</i4>
<i1>J</i1><i2>Z</i2><i3>_</i3><i4>1</i4>
<i1>J</i1><i2>Z</i2><i3>_</i3><i4>2</i4>
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Pmkkr - Driver for the shortened Czech tagset of the Prague Spoken Corpus (Pražský mluvený korpus).

=head1 VERSION

version 3.007

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Pmk;
  my $driver = Lingua::Interset::Tagset::CS::Pmk->new();
  my $fs = $driver->decode('<i1>1</i1><i2>1</i2><i3>1</i3><i4>0</i4><i5>1</i5><i6>1</i6><i7>1</i7><i8>1</i8><i9>_</i9><i10>_</i10><i11></i11>');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::pmk', '<i1>1</i1><i2>1</i2><i3>1</i3><i4>0</i4><i5>1</i5><i6>1</i6><i7>1</i7><i8>1</i8><i9>_</i9><i10>_</i10><i11></i11>');

=head1 DESCRIPTION

Interset driver for the long tags of the Prague Spoken Corpus (Pražský mluvený korpus, PMK).

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::CS::Pmkkr>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
