use strict;
package Lingua::Lexicon::IDP;

use Carp;
use IO::File;
use Memoize;

use File::Spec::Functions qw (:DEFAULT);

use constant MAX_TRIES         => 64;
use constant LANG_DEFAULT      => "en";
use constant LANG_TRANSLATIONS => { "en" => [ "de","es","fr","it","la","pt" ] };

$Lingua::Lexicon::IDP::VERSION = '1.0';

sub new {
  my $pkg  = shift;

  my $self = {'__lang' => LANG_DEFAULT };
  bless $self,$pkg;

  $self->_init();
  return $self;
}

sub _init {
  my $self = shift;

  $self->{'__datadir'} ||=
    join("/",
	 (grep { -d $_ }
	  map { catdir($_,split("::",__PACKAGE__)) }
	  exists $INC{"blib.pm"} ? grep {/blib/} @INC : @INC)[0],
	 "Data");

  foreach my $tr (@{LANG_TRANSLATIONS->{$self->lang()}}) {
    my $datafile = join("/",
			$self->{'__datadir'},
			join("_",$self->lang(),"$tr.txt"));

    no strict "refs";

    *{join("::",__PACKAGE__,$tr)} = sub {
      my $self = shift; 
      return $self->_query($datafile,$_[0]);
    };
  }

  return 1;
}

sub lang {
  my $self = shift;
  return $self->{'__lang'};
}

sub translations {
  my $self = shift;
  return LANG_TRANSLATIONS->{$self->lang()};
}

sub _query {
  my $self = shift;
  my $data = shift;
  my $word = shift;

  if ((exists($self->{'__fh'})) && ($self->{'__datafile'} ne $data)) {
    $self->{'__fh'}->close();

    delete $self->{'__datafile'};
    delete $self->{'__len'};
    delete $self->{'__fh'};
  }

  if (! $self->{'__fh'}) {
    $self->{'__datafile'} = $data;

    $self->{'__fh'} = IO::File->new($self->{'__datafile'});

    if (! $self->{'__fh'}) {
      carp "Unable to create fh, $!\n";
      return undef;
    }
  }

  if (! $self->{'__len'}) {
    $self->{'__len'} = (stat($self->{'__datafile'}))[7];
  }

  # For reasons I don't understand, I
  # cant pass \*$self->{'__fh'} without
  # generating errors....
  my $fh = $self->{'__fh'};

  return &_do_query(\*$fh,$self->{'__len'},$word);
}

sub _do_query {
  my $fh   = shift;
  my $len  = shift;
  my $word = shift;

  #

  my $begin = 0;
  my $end   = $len;

  my $tries = 0;

  my $first = undef;
  my $last  = undef;

  my $found        = 0;
  my @translations = ();

  while (! $found) {

    if (($begin +1) == $end) {
      return undef;
    }

    # Just because you're paranoid
    # Don't mean they're not after you

    if ($tries >= MAX_TRIES) {
      carp "Tried query ".MAX_TRIES." times without success. Something is probably wrong.\n";
      return undef;
    }

    my $guess = int(($begin + $end) /2);
    #print STDERR "[B] $begin [E] $end\n";
    #print STDERR "[$tries] Guess is $guess\n";

    my $pos  = $guess;
    my $char = "";
    my $stop = 0;

    # First thing is to back up
    # to the start of the line

    while (! $stop) {
      sysseek($fh,$pos,0);
      sysread ($fh,$char,1);

      if ($char =~ /\n/) {
        $stop = 1;
        $pos  = $pos+2;
      }

      $pos--;

      if (! $pos) {
        $stop = 1;
      }
    }

    # Next, try to see if we can find
    # any matches at all

    $first = $pos;
    $stop  = 0;

    my $line  = undef;
    my $match = 0;

    while (! $stop) {
      sysseek($fh,$pos,0);
      sysread($fh,$char,1);

      # We've found the word we're
      # looking for. Make a note of
      # this so that we can stop 
      # performing this regex(p) and
      # start collecting the translation.

      if ($line =~ /$word\t.*/) {
	$match = 1;
	$stop  = 1;
      }

      # We're not sure if we've found
      # a match but the current line looks
      # like it could still be the word
      # we're looking for.

      elsif ($word =~ /^$line/) {
        $line .= $char;
        $pos++;
      }

      # This is not the droid, we're looking for.
      # The only question now is whether to look
      # forwards or backwards.

      else {

	if ([sort ($word,$line)]->[0] eq $word) {
	  $end = $guess;
	}

	else {
	  $begin = $guess;
	  }

	$stop = 1;
      }

    }

    # Did not find anything.
    # Try again
    next unless ($match);

    # Okay, since we're doing a boolean
    # search we have to back up to find
    # the first instance of the word.

    $stop = 0;
    $line = undef;

    # So far, we think that the
    # first instance of $word is here
    my $first_instance = $first;

    # print STDERR "FIRST INSTANCE '$first_instance'\n";

    # Back up past the newline
    $pos = $first_instance - 2;

    # print STDERR "START AT '$pos'\n";

    while (! $stop) {
      sysseek($fh,$pos,0);
      sysread($fh,$char,1);

      # print STDERR "[$pos] '$char' '$line'\n";
      
      if ($char =~ /\n/) {

	# print STDERR "CHECKING '$line'\n";

	# Okay, well this line has an entry
	# for $word so we'll mark it as the
	# the first entry and keep going.
	if ($line =~ /$word\t/) {
	  $first_instance = $pos +1;

	  $line = undef;
	  $pos--;
	}

	# Different word. Stop.
	else { $stop = 1; }
      }

      else {
	$line = $char.$line;
	$pos--;
      }
    }

    # Start recording.
    # Go to the first instance.
    $pos   = $first_instance;

    $line  = undef;
    $match = 0;
    $stop  = 0;

    my $translation = undef;

    # print STDERR "START LOOKING AT '$pos'\n";

    while (! $stop) {
      sysseek($fh,$pos,0);
      sysread($fh,$char,1);

      # print STDERR " [$word][$match][$pos] '$line' '$translation'\n";

      # We've found the word we're
      # looking for and now we're just
      # reading the translation.

      if ($match)  {

	# End of the line.
	# Hello, translation.

	# Note, that we'll keep going trying
	# to find additional translations.

	if ($char =~ /\n/) {

	  push @translations, $translation;

	  $line        = undef;
	  $translation = undef;
	  $match       = 0;

	  $pos++;
	}

	# Munge munge munge

	else {
	  $translation .= $char;
	  $pos++;
	}
      }

      # We've found the word we're
      # looking for. Make a note of
      # this so that we can stop 
      # performing this regex(p) and
      # start collecting the translation.

      elsif ($line =~ /$word\t.*/) {
	$match = 1;
      }

      # We're not sure if we've found
      # a match but the current line looks
      # like it could still be the word
      # we're looking for.

      elsif ($word =~ /^$line/) {
        $line .= $char;
        $pos++;
      }

      # Stop.

      else {
	$found = 1;
	$stop  = 1;
      }
    }

    $tries++;
  }

  return @translations;
}

END { memoize("_do_query"); }
return 1;

__END__

=head1 NAME

Lingua::Lexicon::IDP - OOP interface for parsing Internet Dictionary Project files

=head1 SYNOPSIS

 use Lingua::Lexicon::IDP
 use Data::Denter;

 my $idp = Lingua::Lexicon::IDP->new("en");
 print Indent([ $idp->pt("dog")])."\n";'

 # prints:

 @
     cachorro[Noun]
     ca~o[Noun]
     "c%e3o[Noun]"

=head1 DESCRIPTION

An OOP interface for parsing translation files from the Internet
Dictionary Project (IDP).

The package uses a boolean-search for doing lookups and the I<Memoize>
package for caching.

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($lang)

Currently, this method doesn't actually accept any parameters since
the IDP has only released English-to-Foobar files.

Eventually, there might be a variety of different Foo-to-Bar files,
in which case you will be able to specify I<$lang>.

The default language is English.

Returns an object. Woot!

=cut

=head1 OBJECT METHODS

When an object is instantiated, the package automagically populates
the symbol table with methods corresponding to the languages for
which translation files exist.

Object methods return a list of words, or phrases.

=head2 English (en)

Available method for translating English words are:

=over 4

=item *

B<de>

Translate to German.

=item *

B<es>

Translate to Spanish.

=item *

B<fr>

Translate to French.

=item *

B<it>

Translate to Italian.

=item *

B<la>

Translate to Latin.

=item *

B<pt>

Translate to Portugese.

=back

=head2 $pkg->lang()

Return the language code for the current language.

=head2 $pkg->translations()

Return an array ref of language codes for which their are
translation files available for $pkg->lang().

=cut

=head1 VERSION

1.0

=head1 DATE

$Date: 2003/02/04 14:03:59 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://www.ilovelanguages.com/IDP/

=head1 BUGS

Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2003, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under 
the same terms as Perl itself.

=cut
