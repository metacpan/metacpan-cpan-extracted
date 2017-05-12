package Lingua::EN::Alphabet::Shaw;

use 5.005;
use strict;
use warnings;
use DBI;
use Encode;
use File::ShareDir qw(dist_file);
use HTML::Parser;

our $VERSION = 0.64;

sub new {
    my ($class) = @_;
    my $self = {
	dbh => undef,
	sth => undef,
	map => undef,
	# default behaviour for "unknown" is to return its argument
	unknown => sub { $_[0]; },
    };
    return bless($self, $class);
}

sub unknown_handler {
    my ($self, $handler) = @_;

    $self->{unknown} = $handler if defined $handler;

    return $self->{unknown};
}

my %_source_to_bank = (
    0 => 'W', # Shavian wiki
    1 => 'C', # CMUDict
    2 => 'A', # Androcles and the Lion
    );

sub transliterate_details {

    my @result;

    my ($self, @texts) = @_;

    unless (defined $self->{dbh}) {
	my $filename;

	# allow a local override
	$filename = glob('~/.cache/shavian/shavian-set.sqlite');
	$filename = dist_file('Lingua-EN-Alphabet-Shaw', 'shavian-set.sqlite') unless -e $filename;

	$self->{dbh} = DBI->connect("dbi:SQLite:dbname=$filename","","");
	$self->{sth} = $self->{dbh}->prepare('select shaw, pos, dab, source from words where latn=?');
    }

    my $prevpos = 'n'; # sensible default

    my $lookup_word = sub {
	my ($word) = @_;

	$self->{sth}->execute(lc $word);
	my $homonyms = $self->{sth}->fetchall_arrayref();
	return {
	    bank => 'U',
	    src => $word,
	    text => $self->{'unknown'}->($word, $word),
	    } unless @$homonyms;
	my $candidate = $homonyms->[0];
	for (@$homonyms) {
	    $candidate = $_ if $_->[2] =~ $prevpos;
	    $candidate = $_ if $_->[2] eq 'g' && $word =~ /^[A-Z]/;
	    $candidate = $_ if $_->[2] eq 'h' && $word =~ /^[a-z]/;
	}

	$prevpos = $candidate->[1];

	my $result = {
	    bank => $_source_to_bank{$candidate->[3]} || '?',
	    src => $word,
	    text => decode_utf8($candidate->[0]),
	};

	$result->{'dab'}=1 if scalar(@$homonyms)>1;

	return $result;
    };

    my $store_literal = sub {
	my ($literal) = @_;
	return if $literal eq '';

	if (@result && $result[-1]->{'bank'} eq 'L') {
	    $result[-1]->{'text'} .= $literal;
	} else {
	    push @result, { bank=>'L', text=>$literal };
	}
    };

    while (@texts) {
	my $text = shift @texts;

	my @splittext = split(m/(?<!%)(?<!\\)\b([a-z]|[a-z][a-z']*[a-z])\b/i, $text);

	while (@splittext) {
	    $store_literal->(shift @splittext);

	    push @result, $lookup_word->(shift @splittext) if @splittext;
	}

	$store_literal->(shift @texts) if @texts;
    }

    return @result if wantarray;
    return [@result];
}

sub transliterate {
    my ($self, @texts) = @_;

    return join('', map { $_->{'text'} } $self->transliterate_details(@texts) );
}

sub mapping {

    my ($self, $text) = @_;

    unless (defined $self->{map}) {
	$self->{map} = {};
	my $codepoint = 66640;
	for (qw(p t k f T s S c j N b d g v H z
                Z J w h l m i e A a o U Q y r n
                I E F u O M q Y R P X x D C W V)) {
	    $self->{map}->{chr($codepoint)} = $_;
	    $self->{map}->{$_} = chr($codepoint);
	    $codepoint++;
	}

	my $naming_dot = chr(0xB7);
	$self->{map}->{$naming_dot} = 'G';
	$self->{map}->{'G'} = $naming_dot;
	$self->{map}->{'B'} = $naming_dot;
	# some standards also map it to the solidus
	# but that will stop this function being
	# its own inverse
    }

    my $remap = sub {
	my ($char) = @_;
	return $self->{map}->{$char} if defined $self->{map}->{$char};
	return $char;
    };

    $text =~ s/(.)/$remap->($1)/ge;
    return $text;
}

sub normalise {
    my ($self, $shaw) = @_;

    my %mappings = (
	chr(66664).chr(66670) => chr(66680), # ash + roar = are
	chr(66666).chr(66670) => chr(66681), # on + roar = or
	chr(66663).chr(66670) => chr(66682), # egg + roar = air
	chr(66675).chr(66670) => chr(66683), # up + roar = err
	chr(66665).chr(66670) => chr(66684), # ado + roar = array
	chr(66662).chr(66670) => chr(66685), # if + roar = ear
	chr(66662).chr(66665) => chr(66686), # if + ado = ian
	chr(66648).chr(66677) => chr(66687), # yea + ooze = yew
	);

    for (keys %mappings) {
	$shaw =~ s/$_/$mappings{$_}/g;
    }

    return $shaw;
}

sub transliterate_html {
    my ($self, $html, %flags) = @_;

    my @content;
    my $result;

    my %toplevel_tags = map {$_=>1} qw(p div h1 h2 h3 h4 h5 h6 ul ol li dt dd dl title);
    my %text_attrs = map {$_=>1} qw(alt title);

    my $generator_seen = 0;
    my $generator_name = ref($self);

    my $output = sub {
	my ($repr, $tag) = @_;

	if (!$tag || $toplevel_tags{$tag}) {
	    my $want_tag = 0;
	    my @ordered = ('');
	    for (@content) {
		my $is_tag = /^</;
		if ($want_tag != $is_tag) {
		    push @ordered, '';
		    $want_tag = $is_tag;
		}
		$ordered[-1] .= $_;
	    }
	    if ($flags{'titles'}) {
		# FIXME we should also include class="dab" if they ask for it
		my $entity = 0;
		for my $detail ($self->transliterate_details(@ordered)) {
		    if (defined $detail->{'src'} && !$entity) {
			$result .= '<span title="' .
			    $detail->{'src'} .
			    '">' .
			    $detail->{'text'} .
			    '</span>';
		    } else {
			$result .= $detail->{'text'};
			$entity = ($detail->{'text'} =~ /&$/);
		    }
		}
	    } else {
		$result .= $self->transliterate(@ordered);
	    }
	    @content = ();
	    $result .= $repr;
	} else {
	    push @content, $repr;
	}
    };

    my $p = HTML::Parser->new( api_version => 3,
			       handlers => {
				   text => [sub {
				       my ($text) = @_;
				       push @content, $text;
					    }, 'text'],
				   start => [sub {
				       my ($tag, $attrs) = @_;
				       my $repr = "<$tag";
				       for my $attr (sort keys %$attrs) {
					   next if $attr eq '/';
					   my $value = $attrs->{$attr};
					   $value = $self->transliterate($value)
					       if $text_attrs{$attr};
					   $repr .= " $attr=\"$value\"";
				       }
				       $repr .= '/' if $attrs->{'/'};
				       $repr .= '>';

				       if ($tag eq 'meta' &&
					   lc($attrs->{'name'}) eq 'generator' &&
					   lc($attrs->{'content'}) eq lc($generator_name)) {
					   
					   $generator_seen = 1;
				       }

				       $output->($repr, $tag);
					     }, 'tagname, attr'],
				   end => [sub {
				       my ($tag) = @_;
				       my $repr .= "</$tag>";

				       if ($tag eq 'head' && !$generator_seen) {
					   $output->("<meta name=\"generator\" content=\"$generator_name\" />",
						     $tag);
				       }

				       $output->($repr, $tag);
					   }, 'tagname'],
				   comment => [sub {
				       my ($text) = @_;
				       push @content, $text;
					       }, 'text'],
			       },
			       marked_sections => 1,
	);

    $p->parse($html);
    $p->eof();
    $output->('');

    return $result;
}

sub DESTROY {
    my ($self) = @_;

    $self->{sth}->finish() if defined $self->{sth};
}

1;
=head1 NAME

Lingua::EN::Alphabet::Shaw - transliterate the Latin to Shavian alphabets

=head1 AUTHOR

Thomas Thurman <tthurman@gnome.org>

=head1 SYNOPSIS

  use Lingua::EN::Alphabet::Shaw;

  my $shaw = Lingua::EN::Alphabet::Shaw->new();
  print $shaw->transliterate('I live near a live wire.');

=head1 DESCRIPTION

The Shaw or Shavian alphabet was commissioned by the will of the playwright
George Bernard Shaw in the early 1960s as a replacement for the Latin
alphabet for representing English.  It is designed to have a one-to-one
phonemic (not phonetic) mapping with the sounds of English.

Its ISO 15924 code is "Shaw" 281.

This module transliterates English text from the Latin alphabet into the
Shavian alphabet.

The API has changed since version 0.03 to be object-based.

If you find an error in the translation database, you can change it
yourself at http://shavian.org.uk/wiki/ .  You may download a current
copy of the dataset at http://shavian.org.uk/set/ .
If you want to override the database shipped with this module,
place the new copy at ~/.cache/shavian/shavian-set.sqlite and it will
be used in preference.

=head1 METHODS

=head2 Lingua::EN::Alphabet::Shaw->new()

Constructor.  Currently takes no arguments.

=head2 $shaw->transliterate($phrase)

Returns the transliteration of the given phrase into the Shavian alphabet.
Can handle multi-word phrases.  Does a reasonable job resolving homonym
ambiguity ("does he like does?").

If you pass multiple arguments, the results will be concatenated, and only the
odd-numbered arguments will be transliterated.  The state of homonym
resolution is maintained.  This allows you to embed chunks of text
which should not be transliterated into the line, such as XML tags.

=head2 $shaw->unknown_handler([$handler])

If a word is not found in the translation database, the transliteration
routines will call a particular handler to find out what to do, with the
unknown word as both its first and second arguments.  (This is to allow
later expansion; see BUGS AND ISSUES, below.)
The result of the handler should be
a string, which will be inserted into the result of the transliteration
routine at the correct place.

This method allows you to set a new handler by passing it as an argument.
If you pass no argument, this method returns the current handler.

The default handler only returns its argument.  A replacement handler could,
for example, make an attempt at guessing the transliteration; it could die,
to abort the transliteration process; it could return its argument but
also store the new value in a table so that a list of missing words could
later be reported to the user.

=head2 $shaw->mapping($phrase)

There is a quasi-standard mapping of the conventional alphabet onto the Shavian
alphabet.  This method maps Shavian text into the conventional alphabet
and vice versa. It does not transliterate.
Think of this as a kind of ASCII-armouring.

Various versions of the standard map the naming dot to "G", "B", and "/".
This method does not support "/", but maps both "G" and "B" to the naming
dot; in reverse, it maps the naming dot to "G".

The letters "K" and "L" have no mapping to Shavian letters, and are
left alone.

=head2 $shaw->normalise($shavian_text)

Certain letters in the Shavian alphabet are ligatures of pairs of
other letters: because of this, these pairs should not exist separately.
(For example, the letter YEW is a ligature of YEA and OOZE.) This method
replaces these pairs with their ligature equivalents.

=head2 $shaw->transliterate_html($html)

Given a block of text in the conventional alphabet which is formatted
as HTML, this will make a reasonable attempt at returning the same text
transliterated into the Shavian alphabet.  It is aware of which tags
commonly break the flow of sentences, and handles homonym resolution
accordingly.

=head1 BUGS AND ISSUES

There should be a version of the main transliteration method which
returned a list of hashes, each of which gave the source and
destination forms of a word, part of speech and disambiguation
information, and a marking of the source (CMUDict or
Shavian Wiki).

It should probably be possible to transliterate in reverse,
from Shavian to the conventional alphabet.

It should be possible to handle other alternative scripts, such as
Deseret and Tengwar.  This shouldn't be very difficult.
It would also allow representation in the IPA, which would mean
this module could be used for simple text-to-speech processing.

The portion of the database which is taken from CMUdict exhibits
unhelpful mergers (notably father/bother).  There isn't much that
can be done about this except extending the Shavian wiki further.
In addition, in some cases it does not use the letters ARRAY and
ADO in unstressed syllables as they should be; this could and should be
fixed.

It would be useful on initialisation to read a text file
in a standard location, which gave a local mapping overriding the
database for given words.

It would be helpful if there was a callback for any words found
from the CMUDict data rather than from the Shavian Wiki data, so that
the wiki could be updated.

The HTML transliterator should mark its output as being
encoded in UTF-8, whatever the source encoding.  (Shavian cannot
be represented in any other standard encoding.)

The HTML transliterator should have an option which put a span
around each word whose title was the word's spelling in the
conventional alphabet, in the manner of translate.google.com.

The HTML transliterator should have an option to rewrite the
destinations of links, and to add a target to them, so that
it can be used by a web script to link back to itself.

The HTML transliterator should add a "generator" META tag
referencing itself, if one is not already present.

The HTML transliterator should ignore sections marked as
being written in non-English languages.

The HTML transliterator should have an option to
allow loading documents in chunks, as C<HTML::Parser> already does.

The mapping() method should have an extra parameter to
cause it to map in one direction only.

Most of these will be implemented before this module reaches
version 1.00.

=head1 FONTS

You will need a Shavian Unicode font to use this module.
There are several such fonts at http://marnanel.org/shavian/fonts/ .
Please be sure to get a Unicode font and not one with the "Latin mapping".

However, the Mac can handle the Shavian alphabet out of the box.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2009-2010.
This is free software, and can be used/modified under the same terms as
Perl itself.

The transliteration data is available under various free licences,
which are reproduced below.

=head1 LICENCES

=head2 Androcles and the Lion

Part of the transliteration data was taken from the 1962 Shavian alphabet
edition of "Androcles and the Lion"; this data is in the public domain.

=head2 Shavian Wiki

Part of the transliteration data was taken from the Shavian Wiki, and
this is available under the Creative Commons cc-by-sa licence.

=head2 CMUdict

Another part of the transliteration data was taken from CMUdict.  Its
licence is reproduced below.

Copyright (C) 1993-2008 Carnegie Mellon University. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
   The contents of this file are deemed to be source code.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

This work was supported in part by funding from the Defense Advanced
Research Projects Agency, the Office of Naval Research and the National
Science Foundation of the United States of America, and by member
companies of the Carnegie Mellon Sphinx Speech Consortium. We acknowledge
the contributions of many volunteers to the expansion and improvement of
this dictionary.

THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND
ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head2 Brown tagger

The part-of-speech data was taken from the Brown tagger (although the
tagger built into this model is not the Brown tagger, so its first
sentence is inaccurate).  Its licence is also reproduced below:

This software was written by Eric Brill.

This software is being provided to you, the LICENSEE, by the 
Massachusetts Institute of Technology (M.I.T.) under the following 
license.  By obtaining, using and/or copying this software, you agree 
that you have read, understood, and will comply with these terms and 
conditions:  

Permission to [use, copy, modify and distribute, including the right to 
grant others rights to distribute at any tier, this software and its 
documentation for any purpose and without fee or royalty] is hereby 
granted, provided that you agree to comply with the following copyright 
notice and statements, including the disclaimer, and that the same 
appear on ALL copies of the software and documentation, including 
modifications that you make for internal use or for distribution:

Copyright 1993 by the Massachusetts Institute of Technology and the
University of Pennsylvania.  All rights reserved.  

THIS SOFTWARE IS PROVIDED "AS IS", AND M.I.T. MAKES NO REPRESENTATIONS 
OR WARRANTIES, EXPRESS OR IMPLIED.  By way of example, but not 
limitation, M.I.T. MAKES NO REPRESENTATIONS OR WARRANTIES OF 
MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF 
THE LICENSED SOFTWARE OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY 
PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.   

The name of the Massachusetts Institute of Technology or M.I.T. may NOT 
be used in advertising or publicity pertaining to distribution of the 
software.  Title to copyright in this software and any associated 
documentation shall at all times remain with M.I.T., and USER agrees to 
preserve same.  
