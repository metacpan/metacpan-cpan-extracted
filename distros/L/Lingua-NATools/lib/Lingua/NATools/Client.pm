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

package Lingua::NATools::Client;
our $VERSION = '0.7.12';

use 5.006;
use strict;
use warnings;
use CGI qw/:standard/;

use locale;
use Lingua::NATools;
use Data::Dumper;
use IO::Socket;



=head1 NAME

Lingua::NATools::Client - Simple API to query NAT Objects

=head1 SYNOPSIS

  use Lingua::NATools::Client;

  $client = Lingua::NATools::Client->new();

=head1 DESCRIPTION

Lingua::NATools::Client is a simple query API to talk with NAT copora Objects.
It can use a client-server approach (See nat-server) or directly with
local access to the filesystem.

=head1 Methods

This module includes functions to query NATools Objects. To query you
must first create a client object with the new method.

=head2 new

The new object receives an hash with configuration parameters, and
creates a client object. For instance,

  $client = Lingua::NATools::Client->new( Local => "/opt/corpora/foo" );

Known options are:


=over 4

=item PeerAddr

The IP address where the server is running on. Defaults to 127.0.0.1.

=item PeerPort

The port to be used in the connection. Defaults to 4000.

=item Local

A local directory with a NATools object. Note than not all methods
support local corpora.

=item LocalDumper

A local Data::Dumper object with a NATools PTD. Note than not all
methods support local NATools PTDs.

If the LocalDumper value is a reference to an array it is supposed to
contain two positions, with both dictionary filenames. If its value is
a string, it is supposed to be the filename with BOTH dictionaries
included.

=back

=cut

sub new {
  my $class = shift;
  my $self = { PeerAddr => '127.0.0.1',
               PeerPort => '4000',
               Proto    => 'tcp' };

  $self = bless {%$self, @_} => $class;

  $self->{local} = $self->{Local} if (exists($self->{Local}));
  $self->{localDumper} = $self->{LocalDumper} if (exists($self->{LocalDumper}));

  if (exists($self->{local})) {
    Lingua::NATools::corpus_info_open($self->{local});
		$self->{localcfg} = Lingua::NATools->load($self->{local})->{conf};
  }

  if (exists($self->{localDumper})) {
    our ($DIC1, $DIC2);

    if (ref($self->{localDumper}) eq "ARRAY") {

      die "File not found." unless -f $self->{localDumper}[0];
      $self->{d1} = do $self->{localDumper}[0];

      die "File not found." unless -f $self->{localDumper}[1];
      $self->{d2} = do $self->{localDumper}[1];

    } else {

      die "File not found." unless -f $self->{localDumper};

      do $self->{localDumper};

      $self->{d1} = $DIC1;
      $self->{d2} = $DIC2;
    }
  }

  if ($self->{crp}) {
    $self->set_corpus($self->{crp});
    delete($self->{crp});
  }

  return $self;
}

=head2 iterate

This method is used to iterate through a probabilistic translation
dictionary. Pass a function reference to handle each dictionary entry.
This function will be called with a flattened hash with keywords
C<word>, C<trans> and C<count>.

Use as first argument an hash reference to configure the method
behaviour. For instance:

  $client -> iterate( {Language => 'source'},
                      sub {
                        my %param = @_;
                        print "$param{word}\n";
                      });

=cut

sub iterate {
  local $/ = "\n";
  my $self = shift;

  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{Language} = "source" unless exists($conf->{Language}) &&
                                             $conf->{Language} eq "target";

  my $direction = "~#>";
  $direction = "<#~" if $conf->{Language} eq "target";

  my $func = shift;

  if (exists($self->{local}) && $self->{local}) {
    my $limit = Lingua::NATools::corpus_info_lexicon_size($direction eq "~#>" ? 1 : -1);
    $self->{iterator}{size} = $limit;

    for (my $i = 1; $i <= $limit; $i++) {
      my $data = $self->ptd({direction => $direction}, $i);
      $func->(word => $data->[2],
	      trans => $data->[1],
	      count => $data->[0]);
    }

  } elsif (exists($self->{localDumper})) {
    # ...
  } else {
    my $limit = $self->attribute("$conf->{Language}-forms");
    $self->{iterator}{size} = $limit;

    for (my $i = 1; $i <= $limit; $i++) {
      my $data = $self->ptd({direction => $direction}, $i);
      $func->(word => $data->[2],
	      trans => $data->[1],
	      count => $data->[0]);
    }
  }
}

=head2 meta_information

=cut

sub meta_information {
  local $/ = "\n";
  my $self = shift;
  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{crp} ||= $self->{select};

  return undef if exists $self->{localDumper};
  return undef if exists $self->{local};

  my $sock = new IO::Socket::INET (%$self);
  die "Socket coult not be created. Reason: $!\n" unless $sock;

  my %vars = ();

  print $sock "?? $conf->{crp}\n";
  my $value = <$sock>;
  while($value !~ m!\*\* DONE \*\*!) {

    chomp($value);
    $value =~ m!^([^=])+=(.*)$!;
    $vars{$1} = $2;

    $value = <$sock>;
  }
  $sock->close;
  return \%vars;
}

=head2 list

This method is only available on server mode. Returns an hash table
where keys are corpora names (identifiers). Values are hash tables
with keys "id", """source" and "target". Values are the corpus
identifier and the language names.

  $corpora = $client->list;

  # $corpora={ Crp1=> { id=> 1, source=> 'PT', target=> 'EN' } }

=cut

sub list {
  local $/ = "\n";
  my $self = shift;
  my $data;

  return undef if exists $self->{localDumper};
  return undef if exists $self->{local};

  my $sock = new IO::Socket::INET ( %$self );
  die "Socket could not be created. Reason: $!\n" unless $sock;

  print $sock "LIST\n";
  my $nr = <$sock>;
  while($nr) {
    my $corpus = <$sock>;
    $corpus =~ m!^\[(\d+)\]\s(.*)!;
    $data->{$2} = { id => $1 };
    $nr--;
  }

  $sock->close;

  for (keys %$data) {
    $data->{$_}{source} = $self->attribute({crp=>$data->{$_}{id}}, "source-language");
    $data->{$_}{target} = $self->attribute({crp=>$data->{$_}{id}}, "target-language");
  }

  return $data;
}

=head2 set_corpus

This method is also used only on server mode. It selects a corpus that
will be used by all subsequent queries.

  $client->set_corpus(3);

=cut

sub set_corpus {
  my ($self,$crp) = @_;
  $crp||=1;
  $self->{select} = $crp;
  return $self;
}

=head2 ptd

This method is used to query Probabilistic Translation
Dictionaries. As first argument you might pass a hash reference with
configuration options. The only mandatory one is the word being
searched.

Known options are:

=over 4

=item crp

A corpus identifier to use. If not set, will use the first one or the
one selected previously with C<set_corpus>

=item direction

This option chooses the direction on the query. By default, a query on
the source language is used. If direction is C<< <~ >> the target
language is used.

On local corpus mode, and server mode, you can query by identifier
instead of word. For that use as direction C<< ~#> >> or C<< <#~ >>.

=back

Returns an array reference. First element if the occurrence count of
the word, second is an hash with the translation probabilities, and
the third one is the word searched.

=cut

sub ptd {
  my $self = shift;

  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{crp} ||= $self->{select} || 1;
  $conf->{direction} = "~>" unless defined($conf->{direction}) &&
    ($conf->{direction} eq "<~" || $conf->{direction} eq "~#>" || $conf->{direction} eq "<#~");

  my $word = shift;

  if (exists($self->{localDumper}) && $self->{localDumper}) {

    my $dir = $conf->{direction} eq "~>" ? "d1" : "d2";

    return undef unless exists $self->{$dir}{$word};
    my ($o, %dic) = ($self->{$dir}{$word}{count}, %{$self->{$dir}{$word}{trans}});
    return [$o,\%dic,$word];


  } elsif (exists($self->{local}) && $self->{local}) {

    if ($conf->{direction} eq "~#>" || $conf->{direction} eq "<#~") {

      my $dir = $conf->{direction} eq "~#>" ? 1 : -1;

      $word = Lingua::NATools::corpus_info_word_from_wid($dir, $word);
      $word = "(none)" unless $word;
      my $x = Lingua::NATools::corpus_info_ptd_by_word($dir, $word);
      return undef unless $x;
      my ($o, %dic) = @$x;

      return [$o,\%dic,$word];

    } else {
      my $dir = $conf->{direction} eq "~>" ? 1 : -1;

      my $x = Lingua::NATools::corpus_info_ptd_by_word($dir, $word);
      return undef unless $x;
      my ($o,%dic) =  @$x;

      return [$o,\%dic,$word];
    }

  }  else {

    local $/ = "\n";

    my $sock = new IO::Socket::INET ( %$self );
    die "Socket could not be created. Reason: $!\n" unless $sock;

    print $sock "$conf->{direction} $conf->{crp} $word\n";

    $word = <$sock>;
    chomp($word);
    return undef if $word =~ m!^\*\* .* \*\*$!;

    my $occ = <$sock>;
    chomp($occ) if $occ;
    return undef unless $occ =~ m!^\d+$!;

    my $dic = {};
    my $trans = <$sock>;
    chomp($trans) if $trans;
    while($trans && $trans !~ /^\*\* .* \*\*$/) {
      $trans =~ m!^(\d+\.\d+)\s(\S+)!;
      $dic->{$2} = $1;

      $trans = <$sock>;
      chomp($trans) if $trans;
    }
    close ($sock);

    return [$occ, $dic, $word];
  }
}

=head2 attribute

To query meta-information use this method. At the moment it just works
for server corpora. Pass it a reference to a configuration hash if you
need to choose the corpus (see the C<ptd> documentation, for
instance). Mandatory parameter is the name of the attribute being
queried. Returns the value if found, undef otherwise.

=cut

sub attribute {
  local $/ = "\n";

  my $self = shift;
  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{crp} ||= $self->{select};

  my $var = shift;

  return undef if exists $self->{localDumper};

	if ($self->{local}) {
		return $self->{localcfg}->param($var) || undef;
	} else {
	  my $sock = new IO::Socket::INET ( %$self );
	  die "Socket could not be created. Reason: $!\n" unless $sock;

	  print $sock "? $conf->{crp} $var\n";
	  my $value = <$sock>;

	  chomp($value) if $value;
	  close ($sock);
	  return "" unless $value;
	  return $value;
	}
}

=head2 conc

This method is used to query for concordancies on the corpus. This
method is not available with C<LocalDumper>.

Mandatory arguments are one or two strings to search. First argument
might be an hash reference with configuratoin details:

=over 4

=item crp

The corpus identifier to be queried. Just used on server mode. If not
used, the identifier 1 is used, or the one selected before with the
C<set_corpus> method.

=item direction

The direction on which the query will be done. At the moment, it
defaults to query on the source side (thus, ignoring the second
argument). You might use C<< <- >> to query the target language (also
ignores the second argument) or to use C<< <-> >> to query both
languages.

If you want to do pattern matching, use one of C<< => >>, C<< <= >> or
C<< <=> >>.

TODO: make this interface cleaner.

=item count

Number of results to be presented. Defaults to 20. This value is
always limited by the server.

=back

=cut

sub conc {
  local $/ = "\n";

  my $self = shift;

  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{crp} ||= $self->{select};
  $conf->{crp} ||= 1;
  $conf->{direction} = "->" unless $conf->{direction};
  $conf->{count} ||= 20;

  return undef if exists $self->{localDumper};

  my $left = lc(shift());

  my $count = $conf->{count};

  if ($conf->{direction} eq "<->" or
      $conf->{direction} eq "<=>") {
    $left .= " $conf->{direction} ".lc(shift());
  }

  if (exists($self->{local}) && $self->{local}) {

    my $dir = ($conf->{direction} eq "<-" || $conf->{direction} eq "<=")?-1:1;
    my $both = ($conf->{direction} eq "<=>" || $conf->{direction} eq "<->")?1:0;
    my $match = ($conf->{direction} eq "<=" ||
		 $conf->{direction} eq "=>" || $conf->{direction} eq "<=>")?1:0;

    my $query = "$conf->{direction} 0 $left #$count";

    return Lingua::NATools::corpus_info_conc_by_str($dir, $both, $match, $query);

  } else {

    my $sock = new IO::Socket::INET ( %$self );
    die "Socket could not be created. Reason: $!\n" unless $sock;



    print $sock "$conf->{direction} $conf->{crp} $left #$count\n";
    my @r = ();
    my $b1 = <$sock>;
    chomp($b1) if $b1;
    while($b1 && $b1 !~ /^\*\* .* \*\*$/) {
      my $rank = -1;

      if ($b1 =~ m!^\%\ (\d+\.\d+)$!) {
	$rank = $1;
	$b1 = <$sock>;
	chomp($b1) if $b1;
      }

      my $b2 = <$sock>;
      chomp($b2) if $b2;

      if ($rank >= 0) {
	push (@r, [$b1, $b2, $rank]);
      } else {
	push (@r, [$b1, $b2]);
      }

      $b1 = <$sock>;
      chomp($b1) if $b1;
    }
    close($sock);
    return \@r
  }
}



=head2 ngrams

This method is used to query the ngram databases. Not all corpus have
the ngram indexes, thus, some answers might be just a reference to an
empty list.

At the moment use the same parameters for configuration as other
methods (C<diretion> and C<crp>), and a string with the query. For
instance:

  foo *        --> all bigram with "foo" as first word

  foo * bar    --> all trigrams with foo as first word
                   and bar as the last word

  foo bar      --> the bigram "foo bar"

It returns a list of ngrams. Each ngram is a list the the words, and
as the last element the occurrence count.

=cut

sub ngrams {
  my $self = shift;
  my $line;

  my $conf;
  $conf = shift if (ref($_[0]) eq "HASH");
  $conf->{crp} ||= $self->{select} || 1;
  $conf->{direction} = ":>" unless defined($conf->{direction}) && $conf->{direction} eq "<:";

  my $query = shift;

  if (exists($self->{localDumper}) && $self->{localDumper}) {

    return [];

  } elsif (exists($self->{local}) && $self->{local}) {

    my $q = "$conf->{direction} 0 $query";

    return Lingua::NATools::corpus_info_ngrams_by_str($conf->{direction} eq ':>'?1:-1, $q);

  }  else {

    local $/ = "\n";
    my $result = [];

    my $sock = new IO::Socket::INET ( %$self );
    die "Socket could not be created. Reason: $!\n" unless $sock;

    print $sock "$conf->{direction} $conf->{crp} $query\n";

    $line = <$sock>;
    chomp($line) if $line;

    while($line && $line !~ /^\*\* .* \*\*$/) {

      push @$result, [split /\s+/, $line];

      $line = <$sock>;
      chomp($line) if $line;
    }

    close ($sock);

    return $result;
  }
}



1;
__END__


=head1 SEE ALSO

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by Natura Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
