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

package Lingua::NATools::PCorpus;
our $VERSION = '0.7.10';
use 5.006;
use strict;
use warnings;
use Data::Dumper;

use IPC::Open2;
use Lingua::NATools;



sub size {
    my $file = shift;
    my $size;
    open F, "<$file" or die "Cannot open file $file: $!";
    read F, $size, 4;
    $size = unpack "L", $size;
    close F;
    return $size;
}

##
# PUBLIC
sub new {
    my $self = {};
    my ($read, $write);
    my ($corpus1lex, $corpus1crp, $corpus2lex, $corpus2crp, $rankfile, %conf) = @_;

    return undef unless (defined $corpus1lex && defined $corpus1crp &&
                         defined $corpus2lex && defined $corpus2crp &&
                         (defined $rankfile || defined $conf{norank}));

    print STDERR "So far, so good 2\n";

    ($self->{lex1}, $self->{crp1}) = ($corpus1lex, $corpus1crp);
    ($self->{lex2}, $self->{crp2}) = ($corpus2lex, $corpus2crp);

    my $flagi = " -i";
    $self->{quality} = 0;

    my $flagq = "";
    if (defined($conf{words}) && $conf{words}) {
        $flagi = "";
    }

    if (defined($rankfile)) {
        $flagq = " -q $rankfile";
        $self->{quality} = 1;
    }

    my $flagc = "";
    if (defined($conf{chunks}) && $conf{chunks} >=2) {
        $flagc = " -c $conf{chunks}";
    }

    my $cmd = "$Lingua::NATools::BINPREFIX/nat-css $flagi$flagq$flagc $corpus1lex $corpus1crp $corpus2lex $corpus2crp";

    print STDERR "CMD: $cmd\n";

    $self->{pid} = open2($read, $write, $cmd);
    ($self->{read}, $self->{write}) = ($read, $write);

    $self = bless($self);
    $self->ready();

    return $self;
}

##
# PUBLIC
sub search {
  my $self = shift;
  my $string = shift;
  $string = lc($string);

  print {$self->{write}} "$string\n";

  return $self->answer(quality => 0);
}

##
# PUBLIC
sub qsearch {
  my $self = shift;
  my $string = shift;

  print {$self->{write}} "$string\n";

  return $self->answer(quality => 1);
}


## PRIVATE
sub answer {
  my $self = shift;
  return $self->ready(@_);
}

## PRIVATE
sub ready {
  my $self = shift;
  my %opt = @_;
  my @ans = ();
  my $read = $self->{read};
  my ($rbuff0, $rbuff1, $rbuff2);
  for (;;) {
    chop($rbuff0 = <$read>);
    last unless neod($rbuff0);
    chop($rbuff1 = <$read>);
    if ($self->{quality}) {
      chop($rbuff2 = <$read>);
      if ($opt{quality}) {
	push @ans, [$rbuff0, $rbuff1, $rbuff2];
      } else {
	push @ans, [$rbuff1, $rbuff2];
      }
    } else {
      push @ans, [$rbuff0, $rbuff1];
    }
  }
  return @ans;
}

# neod stands for Not End Of Data
# PRIVATE
sub neod {
  my $s = shift;
  return $s ne "-*- READY -*-";
}

1;
__END__

=head1 NAME

Lingua::NATools::PCorpus - Perl extension to inter-operate with a NATool Parallel Corpus

=head1 SYNOPSIS

  use Lingua::NATools::PCorpus;

  $corpus = Lingua::NATools::PCorpus::new("lex1","crp1","lex2","crp2");

  @trans = $corpus->search("sentence");

=head1 DESCRIPTION



=head1 SEE ALSO

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
