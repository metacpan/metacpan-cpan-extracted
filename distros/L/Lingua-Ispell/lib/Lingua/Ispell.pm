
#(@) Lingua::Ispell.pm - a module encapsulating access to the Ispell program.

=head1 NAME

Lingua::Ispell.pm - a module encapsulating access to the Ispell program.

Note: this module was previously known as Text::Ispell; if you have
Text::Ispell installed on your system, it is now obsolete and should be
replaced by Lingua::Ispell.

=head1 NOTA BENE

ispell, when reporting on misspelled words, indicates the string it was unable
to verify, as well as its starting offset in the input line.
No such information is returned for words which are deemed to be correctly spelled.
For example, in a line like "Can't buy a thrill", ispell simply reports that the
line contained four correctly spelled words.  

Lingua::Ispell would like to identify which substrings of the input
line are words -- correctly spelled or otherwise.  It used to attempt to split
the input line into words according to the same rules ispell uses; but that has
proven to be very difficult, resulting in both slow and error-prone code.

=head2 Consequences

Lingua::Ispell now operates only in "terse" mode.
In this mode, only misspelled words are reported.
Words which ispell verifies as correctly spelled are silently accepted.

In the report structures returned by C<spellcheck()>, the C<'term'> member
is now always identical to the C<'original'> member; of the two, you should 
probably use the C<'term'> member.  (Also consider the C<'offset'> member.)
ispell does not report this information for correctly spelled words; if at
some point in the future this capability is added to ispell, Lingua::Ispell
will be updated to take advantage of it.

Use of the C<$word_chars> variable has been removed; setting it no longer
has any effect.

C<terse_mode()> now does nothing.

=cut


package Lingua::Ispell;
use Exporter;
@Lingua::Ispell::ISA = qw(Exporter);
@Lingua::Ispell::EXPORT_OK = qw(
  spellcheck
  add_word
  add_word_lc
  accept_word
  parse_according_to
  set_params_by_language
  save_dictionary
  allow_compounds
  make_wild_guesses
  use_dictionary
  use_personal_dictionary
);
%Lingua::Ispell::EXPORT_TAGS = (
  'all' => \@Lingua::Ispell::EXPORT_OK,
);


use FileHandle;
use IPC::Open2;
use Carp;

use strict;

use vars qw( $VERSION );
$VERSION = '0.07';


=head1 SYNOPSIS

 # Brief:
 use Lingua::Ispell;
 Lingua::Ispell::spellcheck( $string );
 # or
 use Lingua::Ispell qw( spellcheck ); # import the function
 spellcheck( $string );

 # Useful:
 use Lingua::Ispell qw( :all );  # import all symbols
 for my $r ( spellcheck( "hello hacking perl shrdlu 42" ) ) {
   print "$r->{'type'}: $r->{'term'}\n";
 }


=head1 DESCRIPTION

Lingua::Ispell::spellcheck() takes one argument.  It must be a
string, and it should contain only printable characters.
One allowable exception is a terminal newline, which will be
chomped off anyway.  The line is fed to a coprocess running
ispell for analysis.  ispell parses the line into "terms"
according to the language-specific rules in effect.

The result of ispell's analysis of each term is a categorization
of the term into one of six types: ok, compound, root, miss, none,
and guess.  Some of these carry additional information.
The first three types are "correctly" spelled terms, and the last
three are for "incorrectly" spelled terms.

Lingua::Ispell::spellcheck returns a list of objects, each
corresponding to a term in the spellchecked string.  Each object
is a hash (hash-ref) with at least two entries: 'term' and 'type'.
The former contains the term ispell is reporting on, and the latter
is ispell's determination of that term's type (see above).
For types 'ok' and 'none', that is all the information there is.
For the type 'root', an additional hash entry is present: 'root'.
Its value is the word which ispell identified in the dictionary
as being the likely root of the current term.
For the type 'miss', an additional hash entry is present: 'misses'.
Its value is an ref to an array of words which ispell
identified as being "near-misses" of the current term, when
scanning the dictionary.

=head2 NOTE

As mentioned above, C<Lingua::Ispell::spellcheck()> currently only reports on misspelled terms.

=head2 EXAMPLE

 use Lingua::Ispell qw( spellcheck );
 Lingua::Ispell::allow_compounds(1);
 for my $r ( spellcheck( "hello hacking perl salmoning fruithammer shrdlu 42" ) ) {
   if ( $r->{'type'} eq 'ok' ) {
     # as in the case of 'hello'
     print "'$r->{'term'}' was found in the dictionary.\n";
   }
   elsif ( $r->{'type'} eq 'root' ) {
     # as in the case of 'hacking'
     print "'$r->{'term'}' can be formed from root '$r->{'root'}'\n";
   }
   elsif ( $r->{'type'} eq 'miss' ) {
     # as in the case of 'perl'
     print "'$r->{'term'}' was not found in the dictionary;\n";
     print "Near misses: @{$r->{'misses'}}\n";
   }
   elsif ( $r->{'type'} eq 'guess' ) {
     # as in the case of 'salmoning'
     print "'$r->{'term'}' was not found in the dictionary;\n";
     print "Root/affix Guesses: @{$r->{'guesses'}}\n";
   }
   elsif ( $r->{'type'} eq 'compound' ) {
     # as in the case of 'fruithammer'
     print "'$r->{'term'}' is a valid compound word.\n";
   }
   elsif ( $r->{'type'} eq 'none' ) {
     # as in the case of 'shrdlu'
     print "No match for term '$r->{'term'}'\n";
   }
   # and numbers are skipped entirely, as in the case of 42.
 }


=head2 ERRORS

C<Lingua::Ispell::spellcheck()> starts the ispell coprocess 
if the coprocess seems not to exist.  Ordinarily this is simply
the first time it's called.

ispell is spawned via the C<Open2::open2()> function, which
throws an exception (i.e. dies) if the spawn fails.  The caller
should be prepared to catch this exception -- unless, of course,
the default behavior of die is acceptable.

=head2 Nota Bene

The full location of the ispell executable is stored
in the variable C<$Lingua::Ispell::path>.  The default
value is F</usr/local/bin/ispell>.
If your ispell executable has some name other than
this, then you must set C<$Lingua::Ispell::path> accordingly
before you call C<Lingua::Ispell::spellcheck()> (or any other function
in the module) for the first time!

=cut


sub _init {
  unless ( $Lingua::Ispell::pid ) {
    my @options;
    while ( my( $k, $ar ) = each %Lingua::Ispell::options ) {
      if ( @$ar ) {
        for ( @$ar ) {
          #push @options, "$k $_";
          push @options, $k, $_;
        }
      }
      else {
        push @options, $k;
      }
    }

    $Lingua::Ispell::path ||= '/usr/local/bin/ispell';

    $Lingua::Ispell::pid = undef; # so that it's still undef if open2 fails.
    $Lingua::Ispell::pid = open2( # if open2 fails, it throws, but doesn't return.
      *Reader,
      *Writer,
      $Lingua::Ispell::path,
      '-a', '-S',
      @options,
    );

    my $hdr = scalar(<Reader>);

    # must be the same as ispell:
    $Lingua::Ispell::terse = 0;
    {
      # set up permanent terse mode:
      local $/ = "\n";
      local $\ = '';
      print Writer "!\n";
      $Lingua::Ispell::terse = 1;
    }
  }

  $Lingua::Ispell::pid
}

sub _exit {
  if ( $Lingua::Ispell::pid ) {
    close Reader;
    close Writer;
    kill $Lingua::Ispell::pid;
    $Lingua::Ispell::pid = undef;
  }
}


sub spellcheck {
  _init() or return();  # caller should really catch the exception from a failed open2.
  my $line = shift;
  local $/ = "\n"; local $\ = '';
  chomp $line;
  $line =~ s/\r//g; # kill the hate
  $line =~ /\n/ and croak "newlines not allowed in arguments to Lingua::Ispell::spellcheck!";
  print Writer "^$line\n";
  my @commentary;
  local $_;
  while ( <Reader> ) {
    chomp;
    last unless $_ gt '';
    push @commentary, $_;
  }

  my %types = (
    # correct words:
    '*' => 'ok',
    '-' => 'compound',
    '+' => 'root',

    # misspelled words:
    '#' => 'none',
    '&' => 'miss',
    '?' => 'guess',
  );
  # and there's one more type, unknown, which is
  # used when the first char is not in the above set.

  my %modisp = (
      'root' => sub {
        my $h = shift;
        $h->{'root'} = shift;
      },
      'none' => sub {
        my $h = shift;
        $h->{'original'} = shift;
        $h->{'offset'} = shift;
      },
      'miss' => sub { # also used for 'guess'
        my $h = shift;
        $h->{'original'} = shift;
        $h->{'count'} = shift; # count will always be 0, when $c eq '?'.
        $h->{'offset'} = shift;

        my @misses  = splice @_, 0, $h->{'count'};
        my @guesses = @_;

        $h->{'misses'}  = \@misses;
        $h->{'guesses'} = \@guesses;
      },
  );
  $modisp{'guess'} = $modisp{'miss'}; # same handler.

  my @results;
  for my $i ( 0 .. $#commentary ) {
    my %h = (
      'commentary' => $commentary[$i],
    );

    my @tail; # will get stuff after a colon, if any.

    if ( $h{'commentary'} =~ s/:\s+(.*)// ) {
      my $tail = $1;
      @tail = split /, /, $tail;
    }

    my( $c, @args ) = split ' ', $h{'commentary'};
  
    my $type = $types{$c} || 'unknown';

    $modisp{$type} and $modisp{$type}->( \%h, @args, @tail );

    $h{'type'} = $type;
    $h{'term'} = $h{'original'};

    push @results, \%h;
  }

  @results
}

sub _send_command($$) {
  my( $cmd, $arg ) = @_;
  defined $arg or $arg = '';
  local $/ = "\n"; local $\ = '';
  chomp $arg;
  _init();
  print Writer "$cmd$arg\n";
}


=head1 AUX FUNCTIONS

=head2 add_word(word)

Adds a word to the personal dictionary.  Be careful of capitalization.
If you want the word to be added "case-insensitively", you should
call C<add_word_lc()>

=cut

sub add_word($) {
  _send_command "\*", $_[0];
}

=head2 add_word_lc(word)

Adds a word to the personal dictionary, in lower-case form. 
This allows ispell to match it in a case-insensitive manner.

=cut

sub add_word_lc($) {
  _send_command "\&", $_[0];
}

=head2 accept_word(word)

Similar to adding a word to the dictionary, in that it causes
ispell to accept the word as valid, but it does not actually
add it to the dictionary.  Presumably the effects of this only
last for the current ispell session, which will mysteriously
end if any of the coprocess-restarting functions are called...

=cut

sub accept_word($) {
  _send_command "\@", $_[0];
}

=head2 parse_according_to(formatter)

Causes ispell to parse subsequent input lines according to
the specified formatter.  As of ispell v. 3.1.20, only
'tex' and 'nroff' are supported.

=cut

sub parse_according_to($) {
  # must be one of 'tex' or 'nroff'
  _send_command "\-", $_[0];
}

=head2 set_params_by_language(language) 

Causes ispell to set its internal operational parameters
according to the given language.  Legal arguments to this
function, and its effects, are currently unknown by the
author of Lingua::Ispell.

=cut

sub set_params_by_language($) {
  _send_command "\~", $_[0];
}

=head2 save_dictionary() 

Causes ispell to save the current state of the dictionary
to its disk file.  Presumably ispell would ordinarily
only do this upon exit.

=cut

sub save_dictionary() {
  _send_command "\#", '';
}

=head2 terse_mode(bool:terse)

I<B<NOTE:> This function has been disabled! 
Lingua::Ispell now always operates in terse mode.>

In terse mode, ispell will not produce reports for "correct" words.
This means that the calling program will not receive results of the
types 'ok', 'root', and 'compound'.

=cut

sub terse_mode($) {
#  my $bool = shift;
#  my $cmd = $bool ?  "\!" : "\%";
#  _send_command $cmd, '';
#  $Lingua::Ispell::terse = $bool;
}


=head1 FUNCTIONS THAT RESTART ISPELL

The following functions cause the current ispell coprocess, if any, to terminate. 
This means that all the changes to the state of ispell made by the above
functions will be lost, and their respective values reset to their defaults.
The only function above whose effect is persistent is C<save_dictionary()>.

Perhaps in the future we will figure out a good way to make this
state information carry over from one instantiation of the coprocess
to the next.

=head2 allow_compounds(bool)

When this value is set to True, compound words are
accepted as legal -- as long as both words are found in the
dictionary; more than two words are always illegal.
When this value is set to False, run-together words are
considered spelling errors.

The default value of this setting is dictionary-dependent,
so the caller should set it explicitly if it really matters.

=cut

sub allow_compounds {
  my $bool = shift;
  _exit();
  if ( $bool ) {
    $Lingua::Ispell::options{'-C'} = [];
    delete $Lingua::Ispell::options{'-B'};
  }
  else {
    $Lingua::Ispell::options{'-B'} = [];
    delete $Lingua::Ispell::options{'-C'};
  }
}

=head2 make_wild_guesses(bool)

This setting controls when ispell makes "wild" guesses.

If False, ispell only makes "sane" guesses, i.e.  possible
root/affix combinations that match the current dictionary;
only if it can find none will it make "wild" guesses,
which don't match the dictionary, and might in fact
be illegal words.

If True, wild guesses are always made, along with any "sane" guesses. 
This feature can be useful if the dictionary has a limited word list,
or a word list with few suffixes. 

The default value of this setting is dictionary-dependent,
so the caller should set it explicitly if it really matters.

=cut

sub make_wild_guesses {
  my $bool = shift;
  _exit();
  if ( $bool ) {
    $Lingua::Ispell::options{'-m'} = [];
    delete $Lingua::Ispell::options{'-P'};
  }
  else {
    $Lingua::Ispell::options{'-P'} = [];
    delete $Lingua::Ispell::options{'-m'};
  }
}

=head2 use_dictionary([dictionary])

Specifies what dictionary to use instead of the
default.  Dictionary names are actually file
names, and are searched for according to the
following rule: if the name does not contain a slash,
it is looked for in the directory containing the
default dictionary, typically /usr/local/lib.
Otherwise, it is used as is: if it does not begin
with a slash, it is construed from the current
directory.

If no argument is given, the default dictionary will be used.

=cut

sub use_dictionary {
  _exit();
  if ( @_ ) {
    $Lingua::Ispell::options{'-d'} = [ @_ ];
  }
  else {
    delete $Lingua::Ispell::options{'-d'};
  }
}

=head2 use_personal_dictionary([dictionary])

Specifies what personal dictionary to use
instead of the default.

Dictionary names are actually file names, and are
searched for according to the following rule:
if the name begins with a slash, it is used as
is (i.e. it is an absolute path name). Otherwise,
it is construed as relative to the user's home
directory ($HOME).

If no argument is given, the default personal
dictionary will be used.

=cut

sub use_personal_dictionary {
  _exit();
  if ( @_ ) {
    $Lingua::Ispell::options{'-p'} = [ @_ ];
  }
  else {
    delete $Lingua::Ispell::options{'-p'};
  }
}



1;


=head1 FUTURE ENHANCEMENTS

ispell options:

  -w chars
         Specify additional characters that can be part of a word.

=head1 DEPENDENCIES

Lingua::Ispell uses the external program ispell, which is
the "International Ispell", available at

  http://fmg-www.cs.ucla.edu/geoff/ispell.html

as well as various archives and mirrors, such as 

  ftp://ftp.math.orst.edu/pub/ispell-3.1/

This is a very popular program, and may already be
installed on your system.

Lingua::Ispell also uses the standard perl modules FileHandle,
IPC::Open2, and Carp.

=head1 AUTHOR

jdporter@min.net (John Porter)

=head1 COPYRIGHT

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

