package Lingua::FI::Transcribe;

use strict;

use vars qw($VERSION);

$VERSION = 0.03;

use Lingua::FI::Hyphenate qw(tavuta);

sub English {
    shift; # drop the class

    my %T = (
	     'a'     =>      'ah',
	     'aa'    =>      'ahh',
	     'ai'    =>      'igh',
	     'au'    =>      'ow',
	     'b'     =>      'b',
	     'c'     =>      'k',
	     'd'     =>      'd',
	     'e'     =>      'eh',
	     'ee'    =>      'ehh',
	     'ei'    =>      'ey',
	     'f'     =>      'f',
	     'g'     =>      'g',
	     'h'     =>      'hh',
	     'i'     =>      'ee',
	     'j'     =>      'y',
	     'k'     =>      'k',
	     'l'     =>      'l',
	     'm'     =>      'm',
	     'n'     =>      'n',
	     'ng'    =>      'nng',
	     'nk'    =>      'ng',
	     'o'     =>      'aw',
	     'oi'    =>      'oy',
	     'oo'    =>      'aww',
	     'ou'    =>      'ow',
	     'p'     =>      'p',
	     'q'     =>      'q',
	     'r'     =>      'rr',
	     's'     =>      's',
	     't'     =>      't',
	     'u'     =>      'oo',
	     'v'     =>      'v',
	     'w'     =>      'v',
	     'x'     =>      'ks',
	     'y'     =>      'ew',
	     'y'     =>      'eww',
	     'z'     =>      'ts',
	     'å'     =>      'aw',
	     'ä'     =>      'a',
	     'ö'     =>      'ur',
	     'öö'    =>      'urr',
	    );

    my $T = join("|", sort { length($b) <=> length($a) || $a cmp $b } keys %T);

    my $English = sub {
	my @tavut = tavuta($_[0]);
	for (@tavut) { s/($T)/$T{$1}/g }
	join("-", @tavut);
    };

    my @a;
    my $a;

    for (@_) {
	($a = $_) =~ s/([aeiouyäåöAEIOUYÅÄÖbcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]+)/$English->($1)/eg;
	push @a, $a;
    }

    wantarray ? @a : $a[0];
}

=pod

=head1 NAME

Lingua::FI::Transcribe - Finnish transcription

=head1 SYNOPIS

    use Lingua::FI::Transcribe;

    print Lingua::FI::Transcribe->English("sauna"), "\n";
    print Lingua::FI::Transcribe->English("sisu"), "\n";
    print Lingua::FI::Transcribe->English("olut"), "\n";

    print Lingua::FI::Transcribe->English("jarkko hietaniemi"), "\n";

    # The results being

    sow-nah
    see-soo
    aw-loot
    yahrrk-kaw hheeeh-tah-neeeh-mee

=head1 DESCRIPTION

With this module you can get a rough approximation of Finnish
pronunciation by I<transcribing> Finnish into something
(awful mess, usually) that sounds somewhat similar to Finnish
if read aloud (with a straight face).  In addition to transcribing
the sounds the module also hyphenates the word so that you get more
hints as to the correct rhytm.  (The stress is always on the first
syllable.)

However, currently only transcription into English is implemented.
Contributions from speakers of other languages gladly accepted.

One more time: the approximation is very rough.  I disclaim
any responsibility if after ordering a beer in a Finnish pub
the bartender looks at you funny and hands you an umbrella.

=head2 About the English transcription

Note that the transcription of Finnish to "English" is very rough:
it is basically a very simple substitution of one or more letters of
Finnish to one or more letters of "English".  The highly irregular
pronunciation of English doesn't help things.  The vowels are the
hardest part to right.  In principle the basic vowels

        a   e   i   o   u

are simple: just use the simple vowel sounds you can find
in the English words

	pun pet pit pot put

but consider how "pun" and "put" have different vowels, and when
Finnish diphthongs like "au" are introduced, the above simple rule
breaks down horribly.  (That particular Finnish diphthong is
pronounced like the English "ow" in "how", in case your are
wondering.)

=head1 ABOUT FINNISH

Finnish is a highly phonemic and phonetic language-- what this means
is that the correlation between graphemes/letters and phonemes/sounds
is really strong: all you can see you can hear, all you can hear you
can see. One letter corresponds to one sound, and no silent
letters.  Since Finnish is a natural language, this is of course an
oversimplification, there are nuances and exceptions to the above
ideal.  More information about Finnish pronunciation can be found from

  http://www.cs.tut.fi/~jkorpela/finnish.pronunciation.html

and sound examples from

  http://www.helsinki-hs.net/thisishelsinki/kieli.html

=head1 LIMITATIONS

Only English transcription has been implemented.

Only lowercase letters are transcribed.

Only Latin-1 (ISO 8859-1) is supported as the encoding.

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT AND LICENSE

Copyright 2001 Jarkko Hietaniemi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
