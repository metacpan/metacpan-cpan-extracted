package Lingua::EN::Phoneme;
our $VERSION = 0.01;
require 5.005;

use strict;
use warnings;
use DB_File;
use File::ShareDir qw(dist_file);

sub new {
    my ($class) = @_;

    my %self;

    tie %self, 'DB_File', dist_file('Lingua-EN-Phoneme', 'cmudict.db'), O_RDONLY, 0644, $DB_File::DB_HASH
	or die "Can't tie: $!";

    return bless(\%self, $class);
}

sub DESTROY {
    my ($self) = @_;

    untie %$self or die "Can't untie: $!";
}

sub phoneme {
    my ($self, $latin) = @_;

    if (wantarray) {
	return split /\s+/, $self->{uc $latin};
    } else {
	return $self->{uc $latin};
    }
}

1;

=head1 NAME

Lingua::EN::Phoneme - Simple and fast access to cmudict English pronunciation data

=head1 AUTHOR

Thomas Thurman <tthurman@gnome.org>

=head1 SYNOPSIS

  use Lingua::EN::Phoneme;
  my $lep = new Lingua::EN::Phoneme();
  for ($lep->phoneme('cakes')) { print "$_ is a phoneme"; }
  # prints:
  #   K is a phoneme
  #   EY1 is a phoneme
  #   K is a phoneme
  #   S is a phoneme
  print scalar($lep->phoneme('ale'));
  # prints:
  #   EY1 L

=head1 DESCRIPTION

C<Lingua::EN::Phoneme> provides simple access to the phonemic English data in the
Carnegie-Mellon pronouncing dictionary.  Unlike C<Lingua::Phoneme>, it does not
require a DBI connection to run, or any setup time on the host computer.  The
data is supplied in a standard Berkeley database, which should be entirely
platform-independent.

=head1 METHODS

=head2 phoneme($latin)

The argument is the representation of an English word in the Latin alphabet.
In array context, the method returns a list of the phonemes in the word.
Vowels have "0", "1", or "2" suffixes to indicate no, primary, or secondary stress.
In scalar context, the method returns the same list joined into a string by single spaces.
If the word is not in the dictionary, returns an empty list or undef according
to the context.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2009.
This is free software, and can be used/modified under the same terms as Perl itself.

The licence for CMUDict, the phonemic data, is as follows:

 ========================================================================
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

 ========================================================================

=head1 SEE ALSO

C<Lingua::Phoneme>.
