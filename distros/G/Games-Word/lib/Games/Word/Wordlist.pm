package Games::Word::Wordlist;
BEGIN {
  $Games::Word::Wordlist::AUTHORITY = 'cpan:DOY';
}
{
  $Games::Word::Wordlist::VERSION = '0.06';
}
use strict;
use warnings;
use Games::Word qw/all_permutations all_subpermutations/;
use List::MoreUtils qw/uniq/;
# ABSTRACT: manages a list of words



sub new {
    my $class = shift;
    my $word_list = shift;
    my $self = {
        cache => 1,
        @_,

        file => $word_list,
        word_list => [],
        word_hash => {},
    };

    if (ref($word_list) eq 'ARRAY') {
        $self->{cache} = 1;
        $self->{file} = '';
        $self->{word_list} = $word_list;
        $self->{word_hash}{$_} = 1 for @$word_list;
    }
    else {
        die "Can't read word list: $word_list" unless -r $word_list;
        if ($self->{cache} && -s $word_list) {
            open my $fh, '<', $word_list or die "Opening $word_list failed";
            while (<$fh>) {
                chomp;
                $self->{word_hash}{$_} = 1;
            }
            $self->{word_list} = [keys %{$self->{word_hash}}];
        }
    }

    bless $self, $class;
    return $self;
}


sub add_words {
    my $self = shift;
    my $word_list = shift;

    die "Can't add words to a non-cached word list" unless $self->{cache};

    if (ref($word_list) eq 'ARRAY') {
        $self->{word_hash}{$_} = 1 for @$word_list;
    }
    else {
        open my $fh, '<', $word_list or die "Opening $word_list failed";
        $self->{word_hash}{$_} = 1 for <$fh>;
    }
    $self->{word_list} = [keys %{$self->{word_hash}}];

    return;
}


sub remove_words {
    my $self = shift;

    die "Can't remove words from a non-cached word list" unless $self->{cache};

    delete $self->{word_hash}{$_} for (@_);
    $self->{word_list} = [keys %{$self->{word_hash}}];

    return;
}


sub words {
    my $self = shift;

    return @{$self->{word_list}} if $self->{cache};
    open my $fh, '<', $self->{file} or die "Opening $self->{file} failed";
    while (<$fh>) {}

    return $.;
}

sub _random_word_cache {
    my $self = shift;
    my $length = shift;

    my @word_list;
    if (defined $length) {
        @word_list = $self->words_like(qr/^\w{$length}$/);
        return unless @word_list;
    }
    else {
        @word_list = @{$self->{word_list}};
        return unless @word_list;
    }

    return $word_list[int rand @word_list];
}

sub _random_word_nocache {
    my $self = shift;
    my $length = shift;

    open my $fh, '<', $self->{file} or die "Opening $self->{file} failed";
    return unless -s $self->{file};
    my $word;
    my $lineno = 0;
    while (<$fh>) {
        next unless !defined $length || /^\w{$length}$/;
        $lineno++;
        $word = $_ if int(rand $lineno) == 0;
    }
    return unless defined $word;
    chomp $word;

    return $word;
}


sub random_word {
    my $self = shift;

    return $self->_random_word_cache(@_) if $self->{cache};
    return $self->_random_word_nocache(@_);
}

sub _is_word_cache {
    my $self = shift;
    my $word = shift;

    return $self->{word_hash}{$word};
}

sub _is_word_nocache {
    my $self = shift;
    my $word = shift;

    open my $fh, '<', $self->{file} or die "Opening $self->{file} failed";
    while (<$fh>) {
        chomp;
        return 1 if $_ eq $word;
    }

    return 0;
}


sub is_word {
    my $self = shift;

    return $self->_is_word_cache(@_) if $self->{cache};
    return $self->_is_word_nocache(@_);
}

sub _each_word_cache {
    my $self = shift;
    my $code = shift;

    &$code($_) for @{$self->{word_list}};

    return;
}

sub _each_word_nocache {
    my $self = shift;
    my $code = shift;

    open my $fh, '<', $self->{file} or die "Opening $self->{file} failed";
    while (<$fh>) {
        chomp;
        &$code($_);
    }

    return;
}


sub each_word {
    my $self = shift;

    return $self->_each_word_cache(@_) if $self->{cache};
    return $self->_each_word_nocache(@_);
}


sub anagrams {
    my $self = shift;
    my $word = shift;

    return grep {$self->is_word($_)} all_permutations($word);
}


sub words_like {
    my $self = shift;
    my $re = shift;

    my @words = ();
    $self->each_word(sub { push @words, $_[0] if $_[0] =~ $re });

    return @words;
}


sub subwords_of {
    my $self = shift;
    my $string = shift;

    return grep {$self->is_word($_)} all_subpermutations($string);
}


1;

__END__
=pod

=head1 NAME

Games::Word::Wordlist - manages a list of words

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Games::Word::Wordlist;
    my $wl = Games::Word::Wordlist->new('/usr/share/dict/words');
    my $word = $wl->random_word;
    print "we have a word" if $wl->is_word($word);

=head1 DESCRIPTION

Games::Word::Wordlist manages a list of words, either from a wordlist file on
your computer or from a list of words you specify. You can use it to query
things about the list, such as whether a given string is a word, or how many
words are in the list, and you can also get words from the list, either
randomly or by regex.

=head1 METHODS

=head2 new <FILENAME|ARRAYREF> PARAMHASH

The constructor initializes the word list with words, either from a file or
from an arrayref, given as the first argument. The remaining arguments are a
paramhash which recognizes these options:

=over 4

=item cache

Whether or not we want to keep an in memory cache of the words in the word
list. Defaults to true, since this is what we want in almost all cases, as it
speeds up lookups by several orders of magnitude. Can be set to false if either
memory is a significant issue (word lists can be several megabytes in size) or
if the word list is expected to change frequently during the running of the
program.

=back

=head2 add_words <FILENAME|ARRAYREF>

Add words to the word list. Only works if the word list has been cached.

Takes either a reference to an array containing the new words, or the name of a
file to read in the words from. Ignores any words already in the word list.

=head2 remove_words LIST

Removes words in LIST from the word list. Only works if the word list is cached.

=head2 words

Returns the number of words in the word list.

=head2 random_word [LENGTH]

Returns a random word from the word list, optionally of length LENGTH.

=head2 is_word STRING

Returns true if STRING is found in the word list, and false otherwise.

=head2 each_word CODE

Call CODE for each word in the word list. The current word will be passed into
CODE as its only argument.

=head2 anagrams STRING

Returns a list of all permutations of STRING that are found in the word list.

=head2 words_like REGEX

Returns a list containing all words in the word list which match REGEX.

=head2 subwords_of STRING

Returns a list of words from the word list which can be made using the letters
in STRING.

=head1 SEE ALSO

L<Games::Word>

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

