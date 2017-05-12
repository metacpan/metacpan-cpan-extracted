package Games::Jumble;

use warnings;
use strict;
use Carp;
use vars qw($VERSION $AUTOLOAD);

=head1 NAME

Games::Jumble - Create and solve Jumble word puzzles.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use Games::Jumble;

    my $jumble = Games::Jumble->new();
    $jumble->set_num_words(6);
    $jumble->set_word_lengths_allowed(5,6);
    $jumble->set_word_lengths_not_allowed(7,8);
    $jumble->set_dict('/home/doug/crossword_dict/unixdict.txt');

    my @jumble = $jumble->create_jumble;

    foreach my $word (@jumble) {
        print "$word\n";
    }

    # Solve jumbled word
    my @good_words = $jumble->solve_word('rta');

    if (@good_words) {
        foreach my $good_word (@good_words) {
            print "$good_word\n";
        }
    } else {
        print "No words found\n";
    }

    # Create jumbled word
    my $word = 'camel';
    my $jumbled_word = $jumble->jumble_word($word);

    print "$jumbled_word ($word)\n";

=head1 DESCRIPTION

C<Games::Jumble> is used to create and solve Jumble word puzzles.

Currently C<Games::Jumble> will create random five- and six-letter
jumbled words from dictionary. Future versions of C<Games::Jumble> will
allow user to create custom jumbles by using a user defined word file
with words of any length.
Individual words of any length may be jumbled by using the 
C<jumble_word()> method.

Default number of words is 5.
Default dictionary is '/usr/dict/words'.
Dictionary file must contain one word per line.

=cut

{
    # Encapsulated data
    my %_attr_data =              #    DEFAULT               ACCESSIBILITY
      (
        _num_words                => [ 5,                    'read/write' ],
        _dict                     => [ '/usr/dict/words',    'read/write' ],
        _word_lengths_allowed     => [ '',                   'read' ],
        _word_lengths_not_allowed => [ '',                   'read' ],
      );

    # Class methods, to operate on encapsulated class data
    sub _accessible {
        my ( $self, $attr, $mode ) = @_;
        $_attr_data{$attr}[1] =~ /$mode/;
    }

    # Classwide efault value for a specified object attribute
    sub _default_for {
        my ( $self, $attr ) = @_;
        $_attr_data{$attr}[0];
    }

    # List of names of all specified object attributes
    sub _standard_keys {
        keys %_attr_data;
    }
}

=head2 new

This is the constructor for a new Games::Jumble object. 

my $jumble = Games::Jumble->new();

If C<num_words> is passed, this method will set the number of words for the puzzle, otherwise number of words is set to default value of 5.

my $jumble = Games::Jumble->new(num_words=>$num_words);

=cut

sub new {
    my ( $caller, %arg ) = @_;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    foreach my $attrname ( $self->_standard_keys() ) {
        my ($argname) = ( $attrname =~ /^_(.*)/ );
        if ( exists $arg{$argname} ) {
            $self->{$attrname} = $arg{$argname};
        }
        elsif ($caller_is_obj) {
            $self->{$attrname} = $caller->{$attrname};
        }
        else {
            $self->{$attrname} = $self->_default_for($attrname);
        }
    }
    return $self;
}

sub DESTROY {

    # This space deliberately left blank
}

# Non autoloaded methods here

=head2 set_word_lengths_allowed ( length1 [, length2, length3,...] )

If C<lengthx> is(are) passed, this method will set word lengths 
that will be used when creating jumble.  
The default setting will use all word lengths. 
Note: Allow all is designated by empty hash.

=cut

sub set_word_lengths_allowed {
    my($self) = shift;
    if(@_) { 
        my %allowed;
        foreach my $allow( @_ ) {
            $allowed{$allow}++; 
        }
        $self->{_word_lengths_allowed} = \%allowed;
    }
}

=head2 set_word_lengths_not_allowed ( length1 [, length2, length3,...] )

If C<lengthx> is(are) passed, this method will set word lengths 
that will be skipped when creating jumble.
The default setting will not skip any word lengths. 
Note: Skip none is designated by empty hash.

=cut

sub set_word_lengths_not_allowed {
    my($self) = shift;
    if(@_) { 
        my %not_allowed;
        foreach my $length( @_ ) {
            $not_allowed{$length}++; 
        }
        $self->{_word_lengths_not_allowed} = \%not_allowed;
    }
}

=head2 create_jumble

This method creates the jumble.

=cut

sub create_jumble {

    my($self) = shift;
    my @jumble;
    my @jumble_out;
    my %words;

    # Read dictionary and get words
    open FH, $self->get_dict or croak "Cannot open $self->get_dict: $!";
    while(<FH>) {
        chomp;
        my $word = lc $_;             # Lower case all words
        next if $word !~ /^[a-z]+$/;  # Letters only

        # Sort letters so we can check for unique "unjumble"
        my @temp_array = split(//, $word);
        @temp_array = sort(@temp_array);
        my $key = join('', @temp_array);

        # Check for word lengths allowed
        if( $self->get_word_lengths_allowed ) {
            my $allowed_ref = $self->get_word_lengths_allowed;
            next unless exists $allowed_ref->{length $_};
        }

        # Check for word lengths not allowed
        if( $self->get_word_lengths_not_allowed ) {
            my $not_allowed_ref = $self->get_word_lengths_not_allowed;
            next if exists $not_allowed_ref->{length $_};
        }

        # perlreftut is your friend
        push @{$words{$key}}, $_;
       
    }
    close FH;

    # Get words that only "unjumble" one way
    my @unique_words;

    foreach my $word (keys %words) {
        my $length = @{$words{$word}};
        if ($length == 1) {
            push @unique_words, @{$words{$word}};
        }
    }
    @unique_words = sort @unique_words;


    # Get random words for jumble
    for (1..$self->get_num_words) {
            my $el = $unique_words[rand @unique_words];
            redo if $el =~ /(\w)\1+/;  # No words like ii, ooo or aaa
            push(@jumble, $el);
    }

    # Scramble the words
    foreach my $word (@jumble) {
        my $jumbled_word = $self->jumble_word($word);
        push @jumble_out, "$jumbled_word ($word)";
    }

    return @jumble_out;

}

=head2 jumble_word ( WORD )

This method will create a jumbled word.
Returns scalar containing jumbled word.

=cut

sub jumble_word {

    my($self) = shift;
    my $word;

    if(@_) { 
        $word = shift;
    } else {
        $word = undef;
        return $word;
    }

    my @temp_array = split(//, $word);

    # From the camel
    my $array = \@temp_array;
    my $jumbled_word = $word;

    # Make sure we actually scramble the word
    while( $jumbled_word eq $word ) {
        for (my $i = @$array; --$i; ) {
            my $j = int rand ($i+1);
            next if $i == $j;
            @$array[$i,$j] = @$array[$j,$i];
        }
        $jumbled_word = join('', @temp_array);
    }

    return $jumbled_word;
}

=head2 solve_word ( WORD )

This method will solve a jumbled word.
Returns list of solved words.

=cut

sub solve_word {
    my($self) = shift;
    my @good_words;
   
    if(@_) { 
        $self->{word} = lc(shift);
    } else {
        croak "No word to solve\n";
    }

    my @temp_array = split(//, $self->{word});
    @temp_array = sort(@temp_array);
    $self->{key} = join('', @temp_array);

    # Read dictionary and get words same length as $self->{word}
    open FH, $self->get_dict or croak "Cannot open $self->get_dict: $!";
    while(<FH>) {
        chomp;
        my $word = lc $_;             # Lower case all words
        next if $word !~ /^[a-z]+$/;  # Letters only
        next if length($word) ne length($self->{word});

        # Sort letters so we can check for unique "unjumble"
        my @temp_array = split(//, $word);
        @temp_array = sort(@temp_array);
        my $key = join('', @temp_array);

        if ($self->{key} eq $key) {
            push @good_words, $word;
        }
    }
    close FH;

    return @good_words;
}

=head2 solve_crossword ( WORD )

This method will solve an incomplete word as needed for a crossword.
WORD format: 'c?m?l' where question marks are used a placeholders
for unknown letter.
Returns list of solved words.

=cut

sub solve_crossword {
    my($self) = shift;
    my @good_words;
   
    if(@_) { 
        $self->{word} = lc(shift);
    } else {
        croak "No word to solve\n";
    }
    
    # Set regex
    ($self->{word_regex} = $self->{word}) =~ s/\?/\\w{1}/g;

    # Read dictionary and get all words same length as $self->{word}
    open FH, $self->get_dict or croak "Cannot open $self->get_dict: $!";
    while(<FH>) {
        chomp;
        my $word = lc $_;             # Lower case all words
        next if $word !~ /^[a-z]+$/;  # Letters only
        next if length($word) ne length($self->{word});

        if ($word =~ $self->{word_regex}) {
            push @good_words, $word;
        }
    }
    close FH;

    return @good_words;
}

### autoloaded methods ###
# get_num_words, get_dict
# set_num_words, set_dict
# set_word_lengths_allowed, set_word_lengths_not_allowed

sub AUTOLOAD {
    no strict "refs";
    my ( $self, $newval ) = @_;

    # Was it a get_... method?
    if ( $AUTOLOAD =~ /.*::get(_\w+)/ && $self->_accessible( $1, 'read' ) ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
        return $self->{$attr_name};
    }

    # Was it a set_... method?
    if ( $AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible( $1, 'write' ) ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
        $self->{$1} = $newval;
        return;
    }

    # Must have been a mistake then
    croak "No such method: $AUTOLOAD";
}

1;

=head1 AUTHOR

Doug Sparling, C<< <usr_bin_perl at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-jumble at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Jumble>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Jumble

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Jumble>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Jumble>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Jumble>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Jumble>

=back

=head1 ACKNOWLEDGEMENTS

Tim Maher for pointing out some outdated documentation in the Synopsis.

=head1 COPYRIGHT & LICENSE

Copyright 2001-2007 Doug Sparling, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Jumble
