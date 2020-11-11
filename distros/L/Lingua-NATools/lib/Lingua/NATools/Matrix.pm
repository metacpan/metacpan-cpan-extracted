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

package Lingua::NATools::Matrix;
our $VERSION = '0.7.12';
use 5.006;
use strict;
use warnings;
use CGI qw/:standard/;
require Exporter;

use Lingua::NATools::Client;
use Lingua::NATools::PatternRules;

use IPC::Open2;
use Lingua::PT::PLNbase;
use Data::Dumper;
use IO::Socket;


=head1 NAME

Lingua::NATools::Matrix - Module to align a sentence by blocks

=head1 SYNOPSIS

  use Lingua::NATools::Matrix;

=head1 DESCRIPTION

=head2 C<new>

This function...

=cut

sub new {
    my ($class, $client, $rules, $s1, $s2, $user_conf) = @_;

    $user_conf ||= {};

    my $self = bless {
                      user_conf => $user_conf,
                      sentence => [undef],
                     } => $class;

    if (ref($s1) eq "ARRAY") {
        $self->{s1} = [@$s1];
        $self->{sentence}[1] = join(" ", @$s1);
    } else {
        $self->{sentence}[1] = $s1;
        $self->{s1} = [atomiza({keep_quotes => 1}, lc($s1))];
    }

    if (ref($s2) eq "ARRAY") {
        $self->{s2} = [@$s2];
        $self->{sentence}[2] = join(" ", @$s2);
    } else {
        $self->{sentence}[2] = $s2;
        $self->{s2} = [atomiza({keep_quotes => 1}, lc($s2))];
    }

    if ($rules) {
        $self->{patternRules} = $rules;
        if (ref($self->{patternRules}[-1]) eq "HASH") {
            $self->{patternCode} = pop @{$self->{patternRules}};
            $self->{patternCode} = $self->{patternCode}{perl};
        } else {
            $self->{patternCode} = ""
        }
    }

    eval($self->{patternCode}) if $self->{patternCode};

    # Using scalar we get the number of elements... not the last index
    $self->{size} = [undef,
                     scalar(@{$self->{s1}}),
                     scalar(@{$self->{s2}})];

    my ($i,$j);
    $i = 0;
    for $s1 (@{$self->{s1}}) {
        $j=0;
        for $s2 (@{$self->{s2}}) {
            $self->{matrix}[$i][$j] = $self->prob($client,$s1,$s2);
            $j++;
        }
        $i++;
    }

    return $self;
}

=head2 C<findDiagonal>

This function...

=cut

sub findDiagonal {
    my ($self) = @_;

    $self->initResultMatrix;
    $self->setProbabilitiesForEqualStrings;
    $self->enhanceDiagonal;
    $self->markPoints;
    $self->markPatterns;

    #  my ($x,$y) = (0,0);
    #  $self->markOrigin;
    #  $self->connectD($x,$y);

    return $self;
}

=head2 C<setProbabilitiesForEqualStraings>

This function...

=cut

sub setProbabilitiesForEqualStrings {
    my ($self) = @_;

    for my $i (0..$self->{size}[1]-1) {
        for my $j (0..$self->{size}[2]-1) {
            if ($self->{s1}[$i] eq $self->{s2}[$j] &&
                length($self->{s1}[$i]) > 2) {
                $self->{matrix}[$i][$j] = 80
            }
        }
    }
}

=head2 C<initResultMatrix>

This function...

=cut

sub initResultMatrix {
    my ($self) = @_;
    for my $i (0..$self->{size}[1]-1) {
        for my $j (0..$self->{size}[2]-1) {
            $self->{res}[$i][$j] = 0;
        }
    }
}

=head2 C<grep_blocks>

This function...

=cut

sub grep_blocks {
    my ($self) = @_;

    my $blocks;
    my $justX = 1;
    my ($i,$j) = (0,0);

    while ($i < $self->{size}[1]) {
        $j = 0;
      LOOP: while ($j < $self->{size}[2]) {

            my ($ii, $jj) = ($i,$j);

            while ($ii<$self->{size}[1] && $self->{res}[$ii][$j]) {
                $justX = 0 if $self->{res}[$ii][$j] !~ m!^X!;
                $ii++
            }
            while ($jj<$self->{size}[2] && $self->{res}[$i][$jj]) {
                $justX = 0 if $self->{res}[$i][$jj] !~ m!^X!;
                $jj++
            }

            my ($h, $w) = ($ii-$i, $jj-$j);
            if ($h && $w) {
                push @$blocks, { i=> $i, j=> $j, h=> $h, w=> $w };

                if ($self->{res}[$ii-1][$jj-1] =~ m!^X! && !$justX ) {
                    $ii--;
                    $jj--;
                    for (;;) {
                        if ($ii > 0 && $self->{res}[$ii-1][$jj] =~ m!^X!) {
                            $ii--
                        } elsif ($jj > 0 && $self->{res}[$ii][$jj-1] =~ m!^X!) {
                            $jj--
                        } else {
                            last
                        }
                    }
                    $i = $ii;
                    $j = $jj;
                } else {
                    if (($j+$w<$self->{size}[2] && $self->{res}[$i+$h-1][$j+$w]) ||
                        ($i+$h<$self->{size}[1] && $self->{res}[$i+$h][$j+$w-1])) {
                        $i += $h - 1;
                        $j += $w - 1;
                    } else {
                        $i += $h ;
                        $j += $w ;
                    }
                }
                $justX = 1;
                next LOOP;
            }
            $j++;
        }
        $i++;
        $justX = 1;
    }
    return $blocks
}

=head2 C<combine_blocks>

This function...

=cut

sub combine_blocks {
    my ($self, $blocks, $size) = @_;

    my $nr_blocks = scalar(@$blocks);

    my $combined_blocks;
    for (0..$nr_blocks-$size) {
        my $block = { i => $blocks->[$_]{i}, j => $blocks->[$_]{j} };
        $block->{h} = $blocks->[$_+$size-1]{i} + $blocks->[$_+$size-1]{h} -  $block->{i};
        $block->{w} = $blocks->[$_+$size-1]{j} + $blocks->[$_+$size-1]{w} -  $block->{j};
        push @$combined_blocks, $block;
    }
    return $combined_blocks;
}

=head2 C<dump_block>

This function...

=cut

sub dump_block {
  my ($self,$b) = @_;

  return [join(" ", map { $self->{s1}[$_] } ($b->{i}..$b->{i}-1+$b->{h})),
	  join(" ", map { $self->{s2}[$_] } ($b->{j}..$b->{j}-1+$b->{w}))];
}

=head2 C<relate>

This function...

=cut

sub relate {
  my ($self,$blocks) = @_;

  my $ans;

  for my $b (@$blocks) {
    push @$ans, [join(" ", map { $self->{s1}[$_] } ($b->{i}..$b->{i}-1+$b->{h})),
		 join(" ", map { $self->{s2}[$_] } ($b->{j}..$b->{j}-1+$b->{w}))]
  }

  return $ans;
}

=head2 C<connectD>

This function...

=cut

sub connectD {
  my ($self,$i,$j) = @_;

  my ($size1,$size2) = ($self->{size}[1],$self->{size}[2]);

  if ($i >= $size2 || $j >= $size1) {
    return $self;
  }

  if ($j < $size1-1 &&
      ($self->{res}[$j+1][$i] eq 'P' ||
       $self->{res}[$j+1][$i] =~ m!^X!)) {
    return $self->connectD($i,$j+1);
  }

  if ($i < $size2-1 && 
      ($self->{res}[$j][$i+1] eq 'P' ||
       $self->{res}[$j][$i+1] =~ m!^X!)) {
    return $self->connectD($i+1,$j);
  }

  if ($j < $size1-1 && $i < $size2-1 &&
      ($self->{res}[$j+1][$i+1] eq 'P' ||
       $self->{res}[$j+1][$i+1] =~ m!^X!)) {
    return $self->connectD($i+1,$j+1);
  }

  my $x = 1;
  my ($pi,$pj) = ($i+1,$j+1);
  my ($nextstarti, $nextstartj) = (undef, undef);
  my ($starti, $startj) = ($i,$j);
  my $max = max($size1, $size2);

 SEARCH: while($x+$i < $max || $x+$j < $max) {

    # Skip a pattern
    if ($self->{res}[$startj][$starti] =~ m!^X!) {
      for (;;) {
	if ($startj-1 >= 0 && $self->{res}[$startj-1][$starti] =~ m!^X!) {
	  $startj--
	} elsif ($starti-1 >= 0 && $self->{res}[$startj][$starti-1] =~ m!^X!) {
	  $starti--
	} else {
	  last
	}
      }
    }


    # Search neighborhood
    for my $y (reverse (0 .. $x)) {
      if ($j+$y < $size1 && $i+$x < $size2 &&
	  ($self->{res}[$j+$y][$i+$x] eq 'P' ||
	   $self->{res}[$j+$y][$i+$x] =~ m!^X!)) {

	my ($jj,$ii) = ($j+$y,$i+$x);
	if ($self->{res}[$jj][$ii] =~ m!^X!) {
	  ($nextstarti, $nextstartj) = ($ii,$jj);
	  for (;;) {
	    if ($jj < $size1-1 && $self->{res}[$jj+1][$ii] =~ m!^X!) {
	      $jj++
	    } elsif ($ii < $size2-1 && $self->{res}[$jj][$ii+1] =~ m!^X!) {
	      $ii++
	    } else {
	      last
	    }
	  }
	}
	$pi = $ii;
	$pj = $jj;
	last SEARCH;
      } elsif ($j+$x < $size1 && $i+$y < $size2 &&
	       ($self->{res}[$j+$x][$i+$y] eq 'P' ||
		$self->{res}[$j+$x][$i+$y] =~ m!^X!)) {

	my ($jj,$ii) = ($j+$x,$i+$y);
	if ($self->{res}[$jj][$ii] =~ m!^X!) {
	  ($nextstarti, $nextstartj) = ($ii,$jj);
	  for (;;) {
	    if ($jj < $size1-1 && $self->{res}[$jj+1][$ii] =~ m!^X!) {
	      $jj++
	    } elsif ($ii < $size2-1 && $self->{res}[$jj][$ii+1] =~ m!^X!) {
	      $ii++
	    } else {
	      last
	    }
	  }
	}
	$pi = $ii;
	$pj = $jj;
	last SEARCH;
      }
    }

    $x++;
  }


  for my $ii ($starti..$pi) {
    $ii = $size2-1 if $ii >= $size2;
    for my $jj ($startj..$pj) {
      $jj = $size1-1 if $jj >= $size1;
      $self->{res}[$jj][$ii] = "G" unless $self->{res}[$jj][$ii] =~ m!^X!;
    }
  }
  $i = $nextstarti || $pi;
  $j = $nextstartj || $pj;

  $self->connectD($i,$j);

  return $self;
}


=head2 C<max>

This function returns the maximum value of the two arguments passed.

=cut

sub max { $_[0]>$_[1]?$_[0]:$_[1] }


=head2 C<min>

This function returns the minimum value of the two arguments passed.

=cut

sub min { $_[0]<$_[1]?$_[0]:$_[1] }

=head2 C<markPatterns>

This function...

=cut

sub markPatterns {
  my $self = shift;

  my $patterns = $self->{patternRules} || undef;
  $self->{patternCode}  ||= "";

  # [A] A B C = C B A
  # [B] A B = B A
  # [C] A B C = C A B
  # [D] A B C = C A
  my @patterns = (bless( [[{'var' => 'A'},{'var' => 'B'},{'var' => 'C'}],
			  [{'var' => 'C'},{'var' => 'B'},{'var' => 'A'}],
			  'A'], 'Lingua::NATools::PatternRules' ),
		  bless( [[{'var' => 'A'},{'var' => 'B'}],
			  [{'var' => 'B'},{'var' => 'A'}],
			  'B'], 'Lingua::NATools::PatternRules' ),
		  bless( [[{'var' => 'A'},{'var' => 'B'},{'var' => 'C'}],
			  [{'var' => 'C'},{'var' => 'A'},{'var' => 'B'}],
			  'C'], 'Lingua::NATools::PatternRules' ),
		  bless( [[{'var' => 'A'},{'var' => 'B'},{'var' => 'C'}],
			  [{'var' => 'C'},{'var' => 'A'}],
			  'D'], 'Lingua::NATools::PatternRules' ));

  $patterns = \@patterns unless defined $patterns;

  for my $pat (@$patterns) {
    $self->markPattern($pat);
  }

  return $self;
}

=head2 C<markPattern>

This function...

=cut

sub markPattern {
    my ($self, $m, $code) = @_;

    my $id = $m->name;
    my $P = $m->matrix;
    my ($Py,$Px) = (scalar @$P, scalar @{$P->[0]});

    # Word Restrictions
    #------------------------------------------------------
    my $text_rules = $m->text_rules;
    # $text_rules e' uma lista de 2 elementos
    # cada elemento tem um hash
    # primeiro elemento corresponde 'as colunas da matriz...
    # chave do hash corresponde 'a posicao (comeca em 0)
    # valor do hash corresponde 'a palavra em causa

    for my $x (0..$self->{size}[1]-$Px) {
        for my $y (0..$self->{size}[2]-$Py) {

            my $found = 1;

            # Find a suitable pattern
            for my $XX ($x..$x+$Px-1) {
                for my $YY ($y..$y+$Py-1) {

                    next if exists($text_rules->[0]{$XX-$x}) && exists($text_rules->[1]{$YY-$y});
                    # AQUI ESTOU A TRANSPOR A MATRIZ PROPOSITADAMENTE...
                    $found = 0 unless $self->{res}[$XX][$YY] eq $P->[$YY-$y][$XX-$x]
                }
            }

            # Calculate probability
            my @prob;
            for my $XX ($x..$x+$Px-1) {
                for my $YY ($y..$y+$Py-1) {
                    push @prob, $self->{matrix}[$XX][$YY] if $P->[$YY-$y][$XX-$x];
                }
            }


            # de-select if overlapping patterns
            if ($found) {
                for my $XX ($x..$x+$Px-1) {
                    $found = 0 if ($self->{patCol}[$XX])
                }
                if ($found) {
                    for my $YY ($y..$y+$Py-1) {
                        $found = 0 if ($self->{patRow}[$YY])
                    }
                }
            }

            my $s1 = $self->{s1};
            my $s2 = $self->{s2};

            # Check words restrictions
            if ($found) {

                for my $k (keys %{$text_rules->[0]}) {
                    $found = 0 unless match($s1->[$k+$x],$text_rules->[0]{$k});
                }

                # steal some seconds if the first tests failed...
                if ($found) {
                    for my $k (keys %{$text_rules->[1]}) {
                        $found = 0 unless match($s2->[$k+$y],$text_rules->[1]{$k});
                    }
                }
            }

            # Check Morphologic predicates

            ## SOURCE LANGUAGE
            if ($found && $self->{user_conf}{MORPH}[0][0]) {
                my $k = 0;
                for my $pat (@{$m->[0]}) {
                    last unless $found;
                    if (exists($pat->{var}) && exists($pat->{props}{pre})) {
                        local $/ = "\n";
                        my $required = $pat->{props}{pre};
                        print {$self->{user_conf}{MORPH}[0][1]} $s1->[$x+$k],"\n";
                        my $tmp = readline($self->{user_conf}{MORPH}[0][0]);						
                        my $anals = eval($tmp);
                        my $myfound = 0;
                        for my $anal (@$anals) {
                            last if $myfound;
                            my $temp = 1;
                            for my $key (keys %$required) {
                                $temp = 0 unless exists($anal->{$key}) && ($anal->{$key} eq $required->{$key});
                            }
                            $myfound = $temp;
                        }
                        $found = $myfound;
                    }

                    if (exists($pat->{var}) && exists($pat->{props}{preg})) {
                        local $/ = "\n";
                        my $required = $pat->{props}{preg};
                        print {$self->{user_conf}{MORPH}[0][1]} $s1->[$x+$k],"\n";
                        my $tmp = readline($self->{user_conf}{MORPH}[0][0]);						
                        my $anals = eval($tmp);
                        my $myfound = 0;
                        for my $anal (@$anals) {
                            last if $myfound;
                            my $temp = 1;
                            for my $key (keys %$required) {
                                $temp = 0 unless exists($anal->{$key}) && ($anal->{$key} =~ $required->{$key});
                            }
                            $myfound = $temp;
                        }
                        $found = $myfound;
                    }
                    ++$k;
                }
            }

            ## TARGET LANGUAGE
            if ($found && $self->{user_conf}{MORPH}[1][0]) {
                my $k = 0;
                for my $pat (@{$m->[1]}) {
                    last unless $found;
                    if (exists($pat->{var}) && exists ($pat->{props}{pre})) {
                        local $/ = "\n";
                        my $required = $pat->{props}{pre};
                        print {$self->{user_conf}{MORPH}[1][1]} $s2->[$y+$k],"\n";
                        my $tmp = readline($self->{user_conf}{MORPH}[1][0]);
                        my $anals = eval($tmp);
                        my $myfound = 0;
                        for my $anal (@$anals) {
                            last if $myfound;
                            my $temp = 1;
                            for my $key (keys %$required) {
                                $temp = 0 unless exists($anal->{$key}) && ($anal->{$key} eq $required->{$key});
                            }
                            $myfound = $temp;
                        }
                        $found = $myfound;
                    }

                    if (exists($pat->{var}) && exists ($pat->{props}{preg})) {
                        local $/ = "\n";
                        my $required = $pat->{props}{preg};
                        print {$self->{user_conf}{MORPH}[1][1]} $s2->[$y+$k],"\n";
                        my $tmp = readline($self->{user_conf}{MORPH}[1][0]);
                        my $anals = eval($tmp);
                        my $myfound = 0;
                        for my $anal (@$anals) {
                            last if $myfound;
                            my $temp = 1;
                            for my $key (keys %$required) {
                                $temp = 0 unless exists($anal->{$key}) && ($anal->{$key} =~ $required->{$key});
                            }
                            $myfound = $temp;
                        }
                        $found = $myfound;
                    }
                    ++$k;
                }
            }

            # Check perl predicates
            if ($found) {
                my $predicates = $m->predicates;

                for my $predicate (@{$predicates->[0]}) {
                    $found =
                      check_predicate($self,
                                      $predicate->{predicate},
                                      @{$s1}[($predicate->{index}+$x)..($predicate->{index}+$predicate->{length}-1+$x)]);
                    last unless $found;
                }

                if ($found) {
                    for my $predicate (@{$predicates->[1]}) {
                        $found = 
                          check_predicate($self,
                                          $predicate->{predicate},
                                          @{$s2}[($predicate->{index}+$y)..($predicate->{index}+$predicate->{length}-1+$y)]);
                        last unless $found;
                    }
                }
            }

            if ($found) {
                my $prob = _average(@prob);
                push @{$self->{patterns}}, { id => $id, i=>$x, j=>$y, h=>$Px, w=>$Py, prob => $prob};

                # Mark found pattern on row/col arrays
                for my $XX ($x..$x+$Px-1) {
                    $self->{patCol}[$XX] = 1;
                    for my $YY ($y..$y+$Py-1) {
                        $self->{patRow}[$YY] = 1;
                        $self->{res}[$XX][$YY] = "X-$id"
                    }
                }
            }
        }
    }

    return $self;
}

sub check_predicate {
  my ($self, $predicate, @words) = @_;
  @words = map { "'$_'" } @words;
  my $v = eval("$predicate(".join(",",@words).");");
#  print STDERR "$predicate(".join(",",@words).") --> $v\n";
  print STDERR "$@\n" if $@;
  return 0 if $@;
  return $v;
}

=head2 C<markOrigin>

This function...

=cut

sub markOrigin {
  my ($self) = @_;

  $self->{res}[0][0] = 'P';
  $self->{res}[-1][-1] = 'P';
  return $self;
}

=head2 C<markPoints>

This function...

=cut

sub markPoints {
  my $self = shift;

  my $p = 4 * 2 / ($self->{size}[1]+$self->{size}[2]);

  $p = $p > .2 ? $p : .2;

  for my $i (0..$self->{size}[1]-1) {
    for my $j (0..$self->{size}[2]-1) {

      my $maxR = $self->getMaxRow20($i);
      my $maxC = $self->getMaxCol20($j);

      $self->{res}[$i][$j] = 'P' if ($maxR == $maxC &&
				     $maxC == $self->{matrix}[$i][$j] &&
				     abs($j/$self->{size}[2]-$i/$self->{size}[1]) < $p);
    }
  }

  return $self;
}



=head2 C<getMaxRow20>

This function...

=cut

sub getMaxRow20 {
  my ($self, $r) = @_;

  my $max = 0.01;
  my $found = 0;

  for (0..$self->{size}[2]-1) {
    if ($self->{matrix}[$r][$_] > $max) {
      if ($self->{matrix}[$r][$_] > $max + 10) {
	$max = $self->{matrix}[$r][$_];
	$found = 1;
      } else {
	$found = 0;
      }
    }
  }
  return $found?$max:-1;
}

=head2 C<getMaxCol20>

This function...

=cut

sub getMaxCol20 {
  my ($self, $c) = @_;

  my $max = 0.01;
  my $found = 0;

  for (0..$self->{size}[1]-1) {
    if ($self->{matrix}[$_][$c] > $max) {
      if ($self->{matrix}[$_][$c] > $max + 10) {
	$max = $self->{matrix}[$_][$c];
	$found = 1;
      } else {
	$found = 0;
      }
    }
  }
  return $found?$max:-1;
}

=head2 C<prob>

This function...

=cut

sub prob {
  my ($self,$client,$l,$r) = @_;

  my $ret = 0;

  my $ll = $client->ptd({direction => "~>"}, $l);
  my $rr = $client->ptd({direction => "<~"}, $r);

  if ($ll && exists($ll->[1]{$r})) {
    $ret += 100*$ll->[1]{$r}
  }

  if ($rr && exists($rr->[1]{$l})) {
    $ret += 100*$rr->[1]{$l}
  }

  $ret /= 2;

  $ret;
}

=head2 C<enhanceDiagonal>

This function...

=cut

sub enhanceDiagonal {
  my ($self) = @_;

  for my $i (0..$self->{size}[1]-1) {
    for my $j (0..$self->{size}[2]-1) {
      $self->{matrix}[$i][$j] ||= 0;
      $self->{matrix}[$i][$j] *= (1-abs($i/$self->{size}[1] - $j/$self->{size}[2]))
    }
  }
}


sub match {
  my ($str, $array) = @_;
  for (@$array) {
    return 1 if $str eq $_;
  }
  return 0;
}

sub _average {
    return 0 unless @_;
    my $total = 0;
    $total += $_ for @_;
    return $total/scalar(@_);
}

1;
__END__

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

