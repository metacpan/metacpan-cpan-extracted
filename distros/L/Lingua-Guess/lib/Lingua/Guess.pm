package Lingua::Guess;

use strict;
use warnings;
require 5.008;
use Carp;
use File::Spec::Functions 'catfile';
use Unicode::Normalize qw/NFC/;
use Unicode::UCD 'charinfo';

our $VERSION = '0.01';

our $MAX = 300;

our @BASIC_LATIN = qw/English cebuano hausa somali pig_latin klingon indonesian
		      hawaiian welsh latin swahili/;

our @EXOTIC_LATIN = qw/Czech Polish Croatian Romanian Slovak Slovene Turkish Hungarian 
		       Azeri Lithuanian Estonian/;
our @ACCENTED_LATIN = (qw/Albanian Spanish French German Dutch Italian Danish 
			  Icelandic 	Norwegian Swedish Finnish Latvian Portuguese 
			 /, @EXOTIC_LATIN);

our @ALL_LATIN = ( @BASIC_LATIN, @EXOTIC_LATIN, @ACCENTED_LATIN);

our @CYRILLIC   = qw/Russian Ukrainian Belarussian Kazakh Uzbek Mongolian 
		     Serbian Macedonian Bulgarian Kyrgyz/;
our @ARABIC     = qw/Arabic Farsi Jawi Kurdish Pashto Sindhi Urdu/;
our @DEVANAGARI = qw/Bhojpuri Bihari Hindi Kashmiri Konkani Marathi Nepali
		     Sanskrit/;

our @SINGLETONS  = qw/Armenian Hebrew Bengali Gurumkhi Greek Gujarati Oriya 
		      Tamil Telugu Kannada Malayalam Sinhala Thai Lao Tibetan 
		      Burmese Georgian Mongolian/;

sub new
{
    my ($class, %params) = @_;
    if (! $params{modeldir}) {
	my $md = __FILE__;
	$md =~ s!\.pm$!/train!;
	$params{modeldir} = $md;
    }
    unless (exists $params{modeldir}) {
        croak "Must provide a model directory";
    }
    unless (-d $params{modeldir}) {
        croak "Model directory '$params{modeldir}' does not exist";
    }
    my $self = bless { %params }, $class;
    return $self;
}


sub guess 
{
    my ($self, $string) = @_;
    unless (defined $self->{models}) {
        $self->load_models();
    }
    my @runs = find_runs($string);
    my @langs;
    my %scripts;
    for my $run (@runs) {
	$scripts{$run->[1]}++;
    }
    return $self->identify ($string, %scripts);
}

sub simple_guess 
{
    my ($self, $string) = @_;
    my $got = $self->guess ($string);
    return $got->[0]{name};
}

sub load_models 
{
    my ($self) = @_;

    opendir my $dh, $self->{modeldir} or die "Unable to open dir:$!";
    my %models;
    while (my $f = readdir $dh) {
	unless ($f =~ /\.train$/) {
	    next;
	}
	my ($name) = $f =~ m|(.*)\.|;
	my $path = catfile ($self->{modeldir}, $f);
	open my $fh, "<:encoding(utf8)", $path or die "Failed to open file: $!";
	my %model;
	while (my $line = <$fh>) {
	    chomp $line;
	    my ($k, $v) = $line =~ m|(.{3})\s+(.*)|;
	    unless (defined $k) {
	        next;
	    }
	    $model{$k} = $v;
	}
	$models{$name} = \%model;
    }
    $self->{models} = \%models;
}

sub find_runs 
{
    my ($raw) = @_;
    my @chars = split m//, $raw;
    my $prev = '';
    my @c;
    my @runs;
    my @run_types;
    my $current_run = -1;
	
    for my $c (@chars) {
	my $is_alph = $c =~ /[[:alpha:]]/o;
	my $inf = get_charinfo ($c);
	if ($is_alph and ! ($inf->{block} eq $prev)) {
	    $prev = $inf->{block};
	    @c = ();
	    $current_run++;
	    $run_types[$current_run] = $prev;
	}
	push @c, $c;
	if ($current_run > -1) {
	    push @{ $runs[$current_run] }, $c;
	}
    }
	
    my ($newruns, $newtypes) = reconcile_latin (\@runs, \@run_types);
    my $counter = 0;
    my @result;
    for my $r (@$newruns) {
	push @result, [ $r, $newtypes->[$counter]];
	$counter++;
    }
    return @result;
}

# Cached lookups from charinfo

my %cache;

# Look up characters using charinfo, but with a cache to save repeated
# lookups.

sub get_charinfo 
{
    my ($char) = @_;
    my $known = $cache{$char};
    if ($known) {
	return $known;
    }
    my $inf = charinfo (ord ($char));
    $cache{$char} = $inf;
    return $inf;
}

sub reconcile_latin 
{
    my ($runs, $types) = @_;
    my @types = @$types;
    my (@new_runs, @new_types);
    my $last_type = '';
	
    my $upgrade;
    if (has_supplemental_latin (@$types)) {
        $upgrade = 'Accented Latin';
    }
    if (has_extended_latin (@$types)) {
        $upgrade = 'Exotic Latin'  ;
    }
    if (has_latin_extended_additional (@$types)) {
        $upgrade = 'Superfreak Latin';
    }
    unless ($upgrade) {
        return ($runs, $types);
    }
    my $run_count = -1;
    for my $r (@$runs) {
	my $type = shift @types;
	if ($type =~ /Latin/) {
	    $type = $upgrade;
	}
	unless ($type eq $last_type) {
	    $run_count++;
	}
	push @{$new_runs[$run_count]}, @$r;
	$new_types[$run_count] = $type;
	$last_type = $type;
    }	
    return (\@new_runs, \@new_types);
}


sub has_extended_latin 
{
    my (@types) = @_;
    return scalar grep { /Latin Extended-A/ } @types;
}

sub has_supplemental_latin 
{
    my (@types) = @_;
    return scalar grep { /Latin-1 Supplement/ } @types;
}

sub has_latin_extended_additional 
{
    my (@types) = @_;
    return scalar grep { /Latin Extended Additional/ } @types;
}


sub identify 
{
    my ($self, $sample, %scripts) = @_;
    # Check for Korean
    if (exists $scripts{'Hangul Syllables'} ||
	exists $scripts{'Hangul Jamo'} ||
	exists $scripts{'Hangul Compatibility Jamo'} ||
	exists $scripts{'Hangul'}) {
	return [{ name =>'korean', score => 1 }];
    }
    if (exists $scripts{'Greek and Coptic'}) { 
		
	return [{ name =>'greek', score => 1 }];
    }
	
    if (exists $scripts{'Katakana'} || 
	exists $scripts{'Hiragana'} ||
	exists $scripts{'Katakana Phonetic Extensions'}) {
	return [{ name =>'japanese', score => 1 }];
    }
	
	
    if (exists $scripts{'CJK Unified Ideographs'} ||
	exists $scripts{'Bopomofo'} ||
	exists $scripts{'Bopomofo Extended'} ||
	exists $scripts{'KangXi Radicals'} ||
	 exists $scripts{'Arabic Presentation Forms-A'}) {
	return [{ name => 'chinese', score => 1 }];		
    }
	
    if (exists $scripts{'Cyrillic'}) {
	return $self->check ($sample, @CYRILLIC);
    }
	
	
    if (exists $scripts{'Arabic'} ||
	 exists $scripts{'Arabic Presentation Forms-A'} ||
	 exists $scripts{'Arabic Presentation Forms-B'}) {
	return $self->check ($sample, @ARABIC);
    }
	
    if (exists $scripts{'Devanagari'}) {
	return $self->check ($sample, @DEVANAGARI);
    }
	
	
    # Try languages with unique scripts

    for my $s (@SINGLETONS) {
	if (exists $scripts{$s}) {
	    return [{ name => lc ($s), score => 1 }];
	}
    }
	
    if (exists $scripts{'Superfreak Latin'}) {
	return [{ name => 'vietnamese', score => 1 }];
    }
	
    if (exists $scripts{'Exotic Latin'}) {
	return $self->check ($sample, @EXOTIC_LATIN);
    }	
	
    if (exists $scripts{'Accented Latin'}) {
	return $self->check ($sample, @ACCENTED_LATIN);
    }
	
	
    if (exists $scripts{'Basic Latin'}) {
	return $self->check ($sample, @ALL_LATIN);
    }	
	
    return [{ name =>  "unknown script: '". (join ", ", keys %scripts)."'", score => 1}];
	
}


sub check 
{
    my ($self, $sample, @langs)  = @_;
    my $mod = __make_model ($sample);
    my $num_tri = scalar keys %$mod;
    my %scores;
    for my $key (@langs) {
	my $l = lc ($key);
	unless (exists $self->{models}{$l}) {
	    next;
	}
	my $score = __distance ($mod, $self->{models}{$l});
	$scores{$l} = $score;
    }
    my @sorted = sort { $scores{$a} <=> $scores{$b} } keys %scores;
    my @out;
    $num_tri ||=1;
    for my $s (@sorted) {
	my $norm = $scores{$s}/$num_tri;
	push @out, { name => $s , score => int ($norm) };
    }
    return [splice (@out, 0, 4)];
	
    if (@sorted) {
	return splice (@sorted, 0, 4);
	my @all;
	my $firstscore = $scores{$sorted[0]};
	while (my $next = shift @sorted) {
	    unless ($scores{$next} == $firstscore) {
	        last;
	    }
	    push @all, $next;
	}
	return join ', ', @all;
    }
    return { name => 'unknown'. (join ' ', @langs), score => 1 };
}


sub __distance 
{
    my ($m1, $m2) = @_;
    my $dist =0;
    for my $k (keys %$m1) {
	$dist += (exists $m2->{$k} ? abs($m2->{$k} - $m1->{$k}) : $MAX);
    }
    return $dist;
}


sub __make_model 
{
    my ($content) = @_;
    my %trigrams;
    $content = NFC ($content);	# normal form C
    $content =~ s/[^[:alpha:]']/ /g;
    for (my $i = 0; $i < length ($content) - 2; $i++) {
	my $tri = lc (substr ($content, $i, 3));
	$trigrams{$tri}++;
    }
	
    my @sorted = sort { $trigrams{$b} == $trigrams{$a} ?
			$a cmp $b :
			$trigrams{$b} <=> $trigrams{$a} }
        grep { !/\s\s/o } keys %trigrams;
    my @trimmed = splice (@sorted, 0, 300);
    my $counter = 0;
    my %res;
    for my $t (@trimmed) {
	$res{$t} = $counter++;
    }
    return \%res;
}

1;
