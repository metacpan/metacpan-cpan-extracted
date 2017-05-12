package Lingua::EN::Titlecase;
use strict;
use warnings;
no warnings "uninitialized";
require 5.006; # for POSIX classes

use parent "Class::Accessor::Fast";

__PACKAGE__->mk_accessors (qw{
                             uc_threshold
                             mixed_threshold
                             mixed_rx
                             wordish_rx
                             allow_mixed
                             word_punctuation
                             });

use overload '""' => sub { $_[0]->original ? $_[0]->title : ref $_[0] },
    fallback => 1;

# DEVELOPER NOTES
# story card it out including a TT2 plugin
# HOW will entities and utf8 be handled?
# should be raw; OO and functional both?
# lc, default is prepositions, articles, conjunctions, can point to a
# file or to a hash ref (like a tied file, should have recipe)
# canonical /different word/, like OSS or eBay?
# Hyphen-Behavior
# confidence
# titlecase, tc
# rules
# allow user to set order of applying look-up rules, lc > uc, e.g.

# NEED TO ALLOW FOR fixing or leaving things like pH, PERL, tied hash dictionary?

# new with 1 arg uses it as string
# with more than 1 tries constructors

# There are quite a few apostrophe edge cases right now and no
# utf8/entity handling

use List::Util "first";
use Carp;
our $VERSION = "0.15";

our %LC = map { $_ => 1 }
    qw( the a an and or but aboard about above across after against
        along amid among around as at before behind below beneath
        beside besides between beyond but by for from in inside into
        like minus near of off on onto opposite outside over past per
        plus regarding since than through to toward towards under
        underneath unlike until up upon versus via with within without
        v vs
        );

my %Attr = (
            word_punctuation => 1,
            original => 1,
            title => 1,
            uc_threshold => 1,
            mixed_threshold => 1,
            );

sub new : method {
    my $self = +shift->SUPER::new();

    if ( @_ == 1 )
    {
        $self->{_original} = $_[0];
    }
    else
    {
        my %args = @_; # might be empty
        for my $key ( keys %args )
        {
            croak "Construction parameter \"$key\" not allowed"
                unless $Attr{$key};
            $self->$key($args{$key});
        }
    }
    return $self->_init();
}

sub _init : method {
    my $self = shift;
    $self->{_titlecase} = "";
    $self->{_real_length} = 0;
    $self->{_mixedcase} = [];
    $self->{_wc} = [];
    $self->{_token_queue} = [];
    $self->{_uppercase} = [];
    $self->word_punctuation(qr/[[:punct:]]/) unless $self->word_punctuation;
    my $wp = $self->word_punctuation;
    $self->wordish_rx(qr/
                   [[:alpha:]]
                   (?: (?<=[[:alpha:]]) $wp (?=[[:alpha:]]) | [[:alpha:]] )*
                   [[:alpha:]]*
                   /x) unless $self->wordish_rx;
    $self->mixed_rx(
                    qr/(?<=[[:lower:]])[[:upper:]]
                    |
                    (?<=\A)[[:upper:]](?=[[:upper:]]+[[:lower:]])
                    |
                    (?<=\A)[[:upper:]](?=[[:lower:]]+[[:upper:]])
                    |
                    (?<=[[:lower:]]$wp)[[:upper:]]
                    |
                    \G(?<!\A)[[:upper:]]
                    /x) unless $self->mixed_rx;

    $self->allow_mixed(undef);
    $self->mixed_threshold(0.25) unless $self->mixed_threshold;
    $self->uc_threshold(0.90) unless $self->uc_threshold;
    return $self;
}

sub mixedcase : method {
    my $self = shift;
    $self->_parse unless $self->{_mixedcase};
    return @{$self->{_mixedcase}};
}

sub uppercase : method {
    my $self = shift;
    $self->_parse unless $self->{_uppercase};
    return @{$self->{_uppercase}};
}

sub whitespace : method {
    my $self = shift;
    $self->_parse unless $self->{_whitespace};
    return @{$self->{_whitespace}};
}

sub wc : method {
    my $self = shift;
    $self->_parse unless $self->{_wc};
    return @{$self->{_wc}};
}

sub title : method {
    my $self = shift;
    $self->original(+shift) if @_;
    $self->_parse();
    return $self->titlecase();
}

sub original : method {
    my $self = shift;
    if ( my $new = shift )
    {
        $self->{_parsed} = 0 if $self->{_original} ne $new;
        $self->{_original} = $new;
    }
    return $self->{_original};
}

sub _parse : method {
    my $self = shift;
    return if $self->{_parsed};
    $self->_init();
    my $string = $self->original();
    $self->{_uppercase} = [ $string =~ /[[:upper:]]/g ];
    # TOKEN ARRAYS
    # 0 - type: word|null
    # 1 - content
    # 2 - mixed array
    # 3 - uc array
    # 4 - first word token in queue -- "boolean" -- set in titlecase()

    my $wp = $self->word_punctuation;
    my $mixed_rx = $self->mixed_rx;

    while ( my $token = $self->lexer->($string) )
    {
        my @mixed = $token->[1] =~ /$mixed_rx/g;
        $token->[2] = @mixed ? \@mixed : undef;
        push @{$self->{_mixedcase}}, @mixed if @mixed;
        push @{$self->{_token_queue}}, $token;
        push @{$self->{_wc}}, $token->[1] if $token->[0];
        $self->{_real_length} += length($token->[1]) if $token->[0];
    }
    my $uc_ratio = eval { $self->uppercase / $self->{_real_length} } || 0;
    my $mixed_ratio = eval { $self->mixedcase / $self->{_real_length} } || 0;
    if ( $uc_ratio > $self->uc_threshold ) # too much uppercase to be real
    {
        $_->[1] = lc($_->[1]) for @{ $self->{_token_queue} };
#        carp "Original exceeds uppercase threshold (" .
#            $self->uc_threshold .
#            ") lower casing for pre-processing";
    }
    elsif ( $mixed_ratio > $self->mixed_threshold ) # too mixed to be real
    {
        $_->[1] = lc($_->[1]) for @{ $self->{_token_queue} };
#        carp "Original exceeds mixedcase threshold, lower casing for pre-processing";
    }
    else
    {
        $self->allow_mixed(1);
    }
    $self->{_parsed} = 1;
}

sub lexer : method {
    my $self = shift;
    $self->{_lexer} = shift if $@;
    return $self->{_lexer} if $self->{_lexer};

    my $wp = $self->word_punctuation;
    my $wordish = $self->wordish_rx;

    $self->{_lexer} = sub {
        $_[0] =~ s/\A($wordish)// and return [ "word", "$1" ];
        $_[0] =~ s/\A(.)//s and return [ undef, "$1" ];
        return ();
    };
}

sub titlecase : method {
    my $self = shift;
    # it's up to _parse to clear it
    return $self->{_titlecase} if $self->{_titlecase};

    # first word token
    my $fwt = first { $_->[0] } @{$self->{_token_queue} };
    $fwt->[4] = 1;

    for my $t ( @{ $self->{_token_queue} } )
    {
        if ( $t->[0] )
        {
            if ( $t->[2] and $self->allow_mixed )
            {
                $self->{_titlecase} .= $t->[1];
            }
            elsif ( $t->[4] ) # the initial word token
            {
                $self->{_titlecase} .= ucfirst $t->[1];
            }
            elsif ( $LC{lc($t->[1])} ) # lc/uc checks here
            {
                $self->{_titlecase} .= lc $t->[1];
            }
            else
            {
                $self->{_titlecase} .= ucfirst $t->[1];
            }
        }
        else # not a word token
        {
            $self->{_titlecase} .= $t->[1];
        }
    }
    return $self->{_titlecase};
}

1;

__END__

Behaviors?
Leave alone non-dictionary words? Like code bits: [\w]?

1. Process comment titles from a blog?
2. Normalize titles in a news feed.
3. Big list of cases
4. Add a callback to specifically address something, pre or post

=head1 NAME

Lingua::EN::Titlecase - Titlecase English words by traditional editorial rules.

=head1 VERSION

0.14

=head1 SYNOPSIS

 use Lingua::EN::Titlecase;
 my $tc = Lingua::EN::Titlecase->new("CAN YOU FIX A TITLE?");
 print $tc->title(), $/;

 $tc->title("and again but differently");
 print $tc->title(), $/;

 $tc->title("cookbook don't work, do she?");
 print "$tc\n";

=head1 DESCRIPTION

Editorial titlecasing in English is the initial capitalization of
regular words minus inner articles, prepositions, and conjunctions.

This is one of those problems that is somewhat easy to solve for the
general case but impossible to solve for all cases. Hence the lack of
module till now. This module takes an optimistic approach, assuming
that some words, unless there are clues to the contrary, are likely to
be correct already. Most titlecase implementations, for example,
convert everything to lowercase first. This is obviously flawed for
many common cases like proper names and abbreviations.

Simple techniques like--

 $data =~ s/(\w+)/\u\L$1/g;

Fail on words like "can't" and don't always take into account
editorial rules or cases like--

=over 4

=item compound words -- Perl-like

=item abbreviations -- USA

=item mixedcase and proper names -- eBay: nEw KEyBOArD

=item all caps -- SHOUT ME DOWN

=back

Lingua::EN::Titlecase attempts to cater to the general cases and
provide hooks to address the special.

=head1 INTERFACE

=over 4

=item $tc = Lingua::EN::Titlecase->new

The string to be titlecased can be set three ways. Single argument to
new. The "original" hash element to C<new>. With the C<title>
method.

 $tc = Lingua::EN::Titlecase->new("this should be titlecased");

 $tc = Lingua::EN::Titlecase->new(original => "no, this is",
                                  mixed_threshold => 0.5);

 $tc->title("i beg to differ");

The last is to be able to reuse the Titlecase object.

Lingua::EN::Titlecase objects stringify to their processed titlecase,
if they have a string, the ref of the object otherwise.

=item $tc->original

Returns the original string.

=item $tc->title

Set the original string, returns the titlecased version. Both can be
done at once.

 print $tc->title("did you get that thing i sent?"), "\n";

=item $tc->titlecase

Returns the titlecased string. Croaks if there is no original set via
the constructor or the method C<title>.

=item $tc->uppercase

Returns the list of uppercase letters found. Includes those mixed case
letters. Chiefly used internally for determining if string has
exceeded the set threshold to be considered "all caps."

=item $tc->word_punctuation(qr/['-]/)

Sets the regex which will be used to allow punctuation inside words.
The default is "[:punct:]." This is more reasonable that it might
sound as word boundaries generally have either a space or more than
one piece of punctuation. Any instance of the word_punctuation is
allowed inside a "word" if it is surrounded by [:alpha:]s. E.g.,
[:punct:] makes all these one "word" for titlecasing--

 can't
 cpan.org
 cow-catcher
 M!M

Set on construction or reset it to change the behavior--

 Lingua::EN::Titlecase->new(word_punctuation => "['-]");

 $tc->word_punctuation(qr/['-]/)
 # "can't" and "cow-catcher" are still one word
 # "cpan.org" is now two and the "Org" will get titlecased

=item $tc->lexer

Get/set the lexer sub ref. You should probably ignore this. If you
think otherwise, read the source for more.

=back

=head2 STRATEGIES

One of the hardest parts of properly titlecasing input is knowing if
part of it is already correct and should not be clobbered. E.g.--

 Old MacDonald had a farm

Is partly right and the proper name MacDonald should be left alone.
Lowercasing the whole string and then title casing would yield--

  Old Macdonald Had a Farm

So, to determine when to flatten a title to lowercase before
processing, we check the ratio of mixedcase and the ratio of caps.

=over 4

=item $tc->mixed_threshold

Set/get. The ratio of mixedcase to letters which triggers lowercasing
the whole string before trying to titlecase. The built-in threshold to
clobber is 0.25. Example breakpoints.

 0.09 --> Old Macdonald Had a Farm
 0.10 --> Old MacDonald Had a Farm

 0.14 --> An Ipod with Low Ph on Ebay
 0.15 --> An iPod with Low pH on eBay

=item $tc->uc_threshold

Same as mixed but for "all" caps. Default threshold is 0.95.

=item $tc->mixed_case

Scalar context returns count of mixedcase letters found. All caps and
initial caps are not counted. List context returns the letters. E.g.--

 my $tc = Lingua::EN::Titlecase->new();
 $tc->title("tHaT pROBABly Will nevEr BE CorrectlY hanDled");
 printf "%d, %s\n",
     scalar($tc->mixedcase),
     join(" ", $tc->mixedcase);

Yields--

 11, H T R O B A B E C Y D

This is useful for determining if a string is overly mixed. Substrings
like "pH" crop up now and then but they should never compose a high
percentage of a properly cased title.

=item $tc->wc

"Word" count. Scalar context returns count of "words." List returns
them.

=item $tc->mixedcase

Count/list of mixedcase letters found.

=item $tc->whitespace

Count/list of whitespace -- \s+ -- found.

=back

=head1 DIAGNOSTICS

=over 2

=item No diagnostics for you!

[Non-existent description of error here]

=back

=head1 TODO

Dictionary hook to allow BIG lists of proper names and lc to be
applied.

Handle internal punctuation like an em-dash as the equivalent of "--"?

Handle hypens; user hooks.

Move to Mouse or Moose?

Handle classes of things to be left alone if of a case. Like Roman
numerals? Better to have it be rule based where each rule is used to
find a thing, apply a threshold map, possibly convert lc/uc, and then
titlecase or accept. This could get much messier than a dictionary and
might cause problems with overlap like i v I.

Allow a grammar parser object (on demand, if available) to correctly
identify a word's part of speech before applying casing. "To" might be
a proper name, for example, and "A" might be a grade.

Debug ability. Log object or to carp?

Recipes. Including TT2 "plugin" recipe. Mini-scripts to test strings
or accomplish custom configuration goals.

Take out Class::Accessor...? For having it all in one place, checking
args, and slight speed gain.

Add ignore classes? Like \bhttp://...

Bigger test suite.

=head1 SEE ALSO

L<Lingua::EN::Titlecase::HTML> for titlecasing text with markup.

=head1 RECIPES

=head3 Passing L::E::T object to TT2

 use Template;
 use CGI "header";
 use Lingua::EN::Titlecase;
 my @titles = (
               "orphans of the sky",
               "childhood's end",
               "the many-colored land",
               "llana of gathol",
               );
 
 print header(-content_type => "text/plain");
 my $tt2 = Template->new();
 
 $tt2->process(\*DATA,
               { tc => Lingua::EN::Titlecase->new(),
                 title => \@titles }
               );
 __DATA__
 [%-USE format %]
 [%-pretty_print = format('%30s : %s') %]
 [%-FOR t IN title %]
 [% pretty_print( t, tc.title(t) ) %]
 [%-END %]

=head1 CONFIGURATION AND ENVIRONMENT

Lingua::EN::Titlecase requires no configuration files or environment variables.

=head1 DEPENDENCIES

Perl 5.6 or better to support POSIX regex classes.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-lingua-en-titlecase@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Ashley Pond V C<< <ashley@cpan.org> >>.

This module is free software; you can redistribute it and modify it
under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
