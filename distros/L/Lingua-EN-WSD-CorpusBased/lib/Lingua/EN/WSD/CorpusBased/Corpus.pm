package Lingua::EN::WSD::CorpusBased::Corpus;

our $VERSION = '0.11';


use stem;
use warnings;
use strict;

# The demo- and test corpus
my %democorpus = ('1' => ['hello','world'],
		  '2' => ['application','e-mail'],
		  '3' => ['world','peace','love'],
		  '4' => ['e-mail','program'],
		  '5' => ['e-mail','job']);

sub new {
    my $class = shift;
    my %args = ('debug' => 0,
		'wnref' => 0,
		@_);

    return -1 if (! exists($args{'corpus'}));

    my $this = { 'filename' => $args{'corpus'},
		 'debug' => $args{'debug'},
		 'initialized' => 0,
		 'wnref' => $args{'wnref'},
		 'stemmer' => stem->new($args{'wnref'}) };
    
    if ($this->{'filename'} eq '_democorpus_') {
	$this->{'corpus'} = \%democorpus;
    } else {
	open FH, $this->{'filename'};
	my $linenumber = 1;
	while(<FH>) {
	    my $line = $_;
	    $line = $this->{'stemmer'}->stemString($_) if ($this->{'wnref'});
	    my @line = split(/ /, $line);
	    #pop @line;
	    $this->{'corpus'}->{$linenumber} = \@line;
	    $linenumber++;
	};
	close FH;
    };
   
    $this->{'cache'} = {};
    print STDERR "Corpus object created.\n" if ($this->{'debug'} > 0);
    return bless $this, $class;
}

sub init {
    my ($self) = @_;
    foreach my $linenumber (keys %{$self->{'corpus'}}) {
	my @sentence = @{ $self->{'corpus'}->{$linenumber} };
	foreach my $word (@sentence) {
	    $self->{'corpusptr'}->{$word}->{$linenumber} = 1;
	};
    };
    $self->{'initialized'} = 1;
    print STDERR "Corpus object initialized.\n" if ($self->{'debug'} > 0);
}

sub sentences {
    my $self = shift;
    my @words = @_;

    if ($self->{'initialized'}) {
	my @gsen = keys %{$self->{'corpus'}};
	my $good = \@gsen;
	foreach my $word (@words) {
	    #print ref $self->{'corpusptr'}->{$word};
	    my @t = keys %{$self->{'corpusptr'}->{$word}};
	    $good = $self->merge_lists($good, \@t);
	};
	print 'Words ('.join(',',@words).') are in sentences '.join(',',@$good)."\n" 
	    if ($self->{'debug'} > 1);
	return @$good;
    };
    return ();
}

# The function returns the number of sentences containing these words
sub count {
    my $self = shift;
    # @_ contains a list of words. 

    my @words = @_;
    
    if (exists $self->{'cache'}->{join('-',@words)}) {
	my $c = $self->{'cache'}->{join('-',@words)};
	print STDERR "   ".join(",",@words).": $c (cached)\n" if ($self->{'debug'} > 0);
	return $c;
    };
    
    my $c = 0;
    if ($self->{'initialized'}) {
	$c = scalar $self->sentences(@words);
    } else {
	foreach my $sentence (values %{$self->{'corpus'}}) {
	    my $one = 1;
	    #print $sentence;
	    foreach my $word (@words) {
		my $regexp = $word; #.($self->{'flexibility'}?'s?':'');
		$one = 0 if (! grep { /^$regexp$/i } @$sentence);
	    }
	    $c++ if ($one);
	};
	
    };
    print STDERR "   ".join(",",@words).": $c\n"  if ($self->{'debug'} > 0);
    $self->{'cache'}->{join('-',@words)} = $c;
    return $c; 

}

sub merge_lists {
    my ($self,$list1,$list2) = @_;
    my @result = ();
    foreach my $item (@$list1) {
	push (@result, $item) if (grep /$item/, @$list2);
    }
    return \@result;
}

sub empty_cache {
    my ($self) = @_;
    $self->{'cache'} = {};
}

sub line {
    my ($self,$num) = @_;
    return $self->{'corpus'}->{$num};
}

1;


__END__

=head1 NAME

Lingua::EN::WSD::CorpusBased::Corpus

=head1 SYNOPSIS

    my $wn = WordNet::QueryData->new;
    my $corpus = Lingua::EN::WSD::CorpusBased::Corpus->new('corpus' => '_democorpus_',
                                                           'wnref' => $wn);
    
    print join(' ', @{ $corpus->line(1) });            # prints 'hello world'
    print join(' ', @{ $corpus->sentences('hello') }); # prints '1'

=head1 DESCRIPTION

This module represents a corpus. Basically, it allows to extract the number of occurrences of a given word or a given word combination in a "fast" way. "fast" hereby means faster than just iterating over the lines and matching patterns. The basic access method is count(). 

If one calls init() once, the module stores an internal index, which lists for every word, in which sentences it occures. 

This module is a helper module for L<Lingua::EN::WSD::CorpusBased>.

=head1 METHODS

=over 4

=item new

Creates a new Corpus object and reads in the corpus file. 

Parameters:

B<debug>  If set to a true value, the module will generate some debug information to STDERR. Optional, default: 0.

B<wnref>  You can supply a reference to a L<WordNet::QueryData> object. While reading the corpus, the words are then transformed to their stem forms. If you do not supply a value, the strings are used as they are in the corpus. If you supply a value other than a reference to a WordNet::QueryData object, the results are undefined (and untested ...). Optional, default: 0.

B<corpus>  The name of the file containing the corpus. The method expects to find the corpus sentence by sentence, each sentence in one line. Obligatory. For testing purposes, one can use '_democorpus_' as filename of the corpus. In this case, no file is read but instead the internal hard-coded corpus, which is included in the module, is used:

   hello world
   application e-mail
   world peace love
   e-mail program
   e-mail job

Returns: A blessed reference. 

=item init

This method iterates over the corpus and indexes the words, so that it knows for each word in which sentences it occurs. No parameters. No return value. 

=item count

This method expects a list of words as parameters and returns the number of sentences, in which (all of) these words occur in any order. 

    $obj->count("hello", "world");

To make things clear: The method removes the first argument from the args list (which is the reference to the object itself) and takes the entire rest of the list as the list of words. Therefore

    count($obj, "hello", "world");

is equivalent to the line above. 

=item sentences

This method takes the same arguments as count, namely a list of words. It then returns a list of sentences, in which each of these words occur. This method works only if init is run before, i.e. if the corpus is indexed. 

=item line

This method takes a number larger than 0 and returns a reference to the list of words in this line of the corpus. 

=item merge_lists

This method is used internally. It takes references to two lists as arguments and returns a reference to a new list, containing the elements that were in both lists. 

    $obj->merge_lists(['a','b'],['b','c']); 

The above example returns a reference to the list 

    ('b')

Note that the method makes only flat copies of the elements. If a list contains a reference to another list b, the reference in the new list still points to list b. 

=item empty_cache

Empties the cache. 

=back

=head1 BUGS

Currently, the module is not able to return a list of sentences, in which the words occured. Since this is most unfortunate, it will change in future versions. 

=head1 COPYRIGHT

Copyright (c) 2006 by Nils Reiter.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


