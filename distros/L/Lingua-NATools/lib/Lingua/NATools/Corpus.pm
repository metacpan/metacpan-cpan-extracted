# NATools - Package with parallel corpora tools
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

package Lingua::NATools::Corpus;
our $VERSION = '0.7.10';
use 5.006;
use strict;
use warnings;
use Data::Dumper;

use Lingua::NATools;


sub new {
    my ($class, $filename) = @_;
    die "Corpus.pm, old new called" unless $class eq "Lingua::NATools::Corpus";
    return undef unless -f $filename;

    my $id = Lingua::NATools::corpus_open($filename);
    return undef if $id < 0;

    my $self = {id => $id};
    return bless $self => $class #amen
}

sub sentences_nr {
    my $self = shift;

    if (!$self->{nrsentences}) {
        $self->{nrsentences} = Lingua::NATools::corpus_sentences_nr_xs($self->{id});
    }

    return $self->{nrsentences}
}

sub iterator {
    my $self = shift;
    return Lingua::NATools::Corpus::Iterator->new($self);
}

sub first_sentence {
    my $self = shift;
    return Lingua::NATools::corpus_first_sentence_xs($self->{id});
}

sub next_sentence {
    my $self = shift;
    return Lingua::NATools::corpus_next_sentence_xs($self->{id});
}

sub free {
    my $self = shift;
    Lingua::NATools::corpus_free_xs($self->{id});
}

package Lingua::NATools::Corpus::Iterator;

our $VERSION = '0.7.10';

sub new {
    my ($class, $corpusObject) = @_;
    my $self = { corpus => $corpusObject };
    my $fs = $self->{corpus}->first_sentence;
    $self->{csentence} = $fs;
    return bless $self => $class #amen
}

sub next {
    my $self = shift;
    my $sentence = $self->{csentence};
    if ($sentence) {
        my $fs = $self->{corpus}->next_sentence;
        $self->{csentence} = $fs;
    }
    return $sentence;
}



1;
__END__

=head1 NAME

Lingua::NATools::Corpus - To inter-operate with NATools Corpus files

=head1 SYNOPSIS

  use Lingua::NATools::Corpus;

  $corpus = Lingua::NATools::Corpus->new("crp1");

=head1 DESCRIPTION

=head1 SEE ALSO

To use the parallel corpus (search sentences and so one) use the
NAT::PCorpus module.

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by NATURA Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
