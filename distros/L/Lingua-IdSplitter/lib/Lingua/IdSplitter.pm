package Lingua::IdSplitter;
# ABSTRACT: split identifiers into words

use strict;
use warnings;

use Text::Aspell;
use LWP::Simple;
use String::CamelCase qw/decamelize/;
use File::ShareDir ':ALL';
use Data::Dumper;

sub new {
  my ($class, @dicts) = @_;
  my $self = bless({}, $class);

  $self->{dicts} = [];
  foreach (@dicts) {
    if (ref($_) eq 'HASH') {
      push @{$self->{dicts}}, $_;
    }
    if (ref($_) eq '') {
      my $d = $self->_load_dict($_);
      push @{$self->{dicts}}, $d;
    }
  }
  $self->{speller} = Text::Aspell->new;

  return $self;
}

sub _load_dict {
  my ($self, $name) = @_;
  $name .= '.csv' unless ($name =~ m/\.csv$/);

  my $file;
  $file = $name if (-e $name);
  unless ($file) {
    $file = "share/dictionaries/$name" if (-e "share/dictionaries/$name");
  }
  eval "require Lingua::IdSplitter;";  # XXX - be nice
  unless ($file) {
    $file = dist_file('Lingua-IdSplitter', "dictionaries/$name") unless $@;
  }
  unless ($file) {
    print "$name not found";
    exit;
  }

  my $words = {};
  open F, '<', $file;
  while (<F>) {
    chomp;
    my ($left, $right) = split /\s*,\s*/, $_;
    $words->{lc $left} = lc $right;
  }

  return { weight=>0.6, words=>$words };
}

sub soft_split {
  my ($self, $id) = @_;
  $id = lc $id;
  return () unless ($self->{speller} and $id);

  # test if the id is a single word or abbreviation
  my $test = $self->_valid_word($id);
  if ($test and $test->{w} > 0) {
    push @{$self->{explain_rank}}, "$test->{t}(<-$test->{s}) ---> $test->{w}\n" if ($test->{w} ne $test->{s});
    return ($test);
  }

  # set initial values
  $self->{full} = $id;
  $self->{max} = length($id);
  $self->{found} = {};
  $self->{cand} = [];

  # create possible words for each level
  my @chars = split //, $id;
  my $i = 0;
  while ($i < length($id)) {
    $self->{found}->{$i} = [$self->_find_words(join('', @chars[$i .. length($id)-1]))];
    $i++;
  }

  # create list of possible candidates
  foreach (@{$self->{found}->{0}}) {
    $self->_find_next(length($_->{s}), $_);
  }

  # post-process candidates list
  $self->_post_process;

  # compute rank for each solution and sort by rank
  my @rank;
  foreach (@{$self->{cand}}) {
    my $expr = $self->_calc_score($_);
    my $score = eval $expr;
    push @rank, {terms=>$_, expr=>$expr, score=>$score};
  }
  @rank = sort {$b->{score}<=>$a->{score}} @rank;
  $self->{rank} = [@rank];

  my $top = shift @rank;
  push @{$self->{explain_rank}}, $self->_explain_rank();

  return $top ? @{$top->{terms}} : ({s=>$self->{full},t=>$self->{full}});
}

sub _find_words {
  my ($self, $term) = @_;
  my @res;

  my @chars = split //, $term;
  my $left = '';
  while (@chars) {
    $left .= shift @chars;
    push @res, $self->_valid_word($left) if ($self->_valid_word($left));
  }

  return @res;
}

sub _find_next {
  my ($self, $lvl, @curr) = @_;

  if ($lvl < $self->{max}) {
    foreach (@{$self->{found}->{$lvl}}) {
      $self->_find_next($lvl+length($_->{s}), @curr, $_);
    }
  }
  else {
    my @strs = map {$_->{s}} @curr;
    push @{$self->{cand}}, [@curr] if (join('', @strs) eq $self->{full});
  }
}

sub _calc_score {
  my ($self,$cand) = @_;

  my @mul = ();
  my $max_len = 0;
  foreach (@$cand) {
    push @mul, '('.$_->{w}.'*'.($_->{s}?length($_->{s}):0).')';
    $max_len = length($_->{t}) if length($_->{t})>$max_len;
  }
  my $expr = '('.join('*', @mul).') * '.$max_len.' / ('.scalar(@$cand).'*'.scalar(@$cand).')';
  #my $expr = '('.join('*', @mul).') / ('.scalar(@$cand).'*'.scalar(@$cand).')';

  return $expr;
}

sub _valid_word {
  my ($self, $word) = @_;

  # consider number valid words
  if ($word =~ m/^\d+$/) {
    return {s=>$word,t=>$word,w=>0.3};
  }

  foreach my $d (@{$self->{dicts}}) {
    foreach my $w (keys %{$d->{words}}) {
      my $o = $w;
      $w =~ s#/##g;

      return {s=>$o,t=>$d->{words}->{$o},w=>$d->{weight}} if ($w eq $word);
    }
  }

  if ($self->{speller}->check($word)) {
    return {s=>$word,t=>$word,w=>0.3};
  }

  # word not found
  return undef;
}

# experimental
sub _post_process {
  my ($self) = @_;

  foreach my $cand (@{$self->{cand}}) {
    $self->_post_process_cand($cand, 0, 2);
    $self->_post_process_cand($cand, 0, 3);
  }
}

sub _post_process_cand {
  my ($self, $cand, $offset, $n) = @_;
  my @cand = @$cand;
  return unless ( scalar(@cand)>=($offset+$offset+$n) );

  my @bef = splice @cand, 0, $offset;
  my (@itens) = splice @cand, $offset, $offset+$n;
  foreach (@itens) { return unless $_; }
  #return unless ($a and $b and $c);
  if ( $self->_post_process_cand_verify(@itens) ) {
         my $word = join('', map {$_->{s}} @itens);
         my @new = ( @bef, {s=>$word,t=>$word,w=>0.1}, @cand );
         push @{$self->{cand}}, [@new];
  }

  my @next = @$cand;
  if ( scalar(@next) >= $n ) {
    shift @next;
    $self->_post_process_cand([@next],$offset+1,$n);
  }
}

sub _post_process_cand_verify {
  my ($self, @cand) = @_;

  foreach (@cand) {
    return 0 unless ($_ and length($_->{s})==1 and length($_->{t})==1);
  }

  return 1;
}

sub hard_split {
  my ($self, $id) = @_;

  my @first;
  if ($id =~ m/[_\.\-\:]/) {
    $id =~ s/^_+//g;
    $id =~ s/_+$//g;

    @first = split /[_\.\-\:]+/, $id;
    push @{$self->{hard}}, {tech=>"'_' separator", terms=>[@first]};
  }
  push @first, $id unless @first;

  my @res;
  foreach my $i (@first) {
    if ( ($i =~ m/[A-Z][a-z0-9]+(.*?)[A-Z][a-z0-9]+/) or ($i =~ m/[a-z0-9]+(.*?)[A-Z]/) ) { # FIXME CamelCase detection
      my @snd = split /_/, decamelize($i);
      @snd = map {lc} @snd;
      push @res, @snd;
      push @{$self->{hard}}, {tech=>'CamelCase', terms=>[@res]};
    }
    else {
      push @res, $i;
    }
  }

  my @final;
  if (@res) {
    push @final, {s=>$_, t=>$_} foreach @res;
  }
  else {
    push @final, {s=>$id, t=>$id};
  }
  return @final;
}

sub split {
  my ($self, $id) = @_;

  # hard splits first
  my @res = $self->hard_split($id);

  # soft splits second
  my @final;
  foreach (@res) {
    push @final, $self->soft_split($_->{s});
  }

  return @final;
}

sub explain {
  my ($self) = @_;
  my $str;

  if ($self->{hard}) {
    $str .= "\n## hard split\n";
    foreach (@{$self->{hard}}) {
      $str .= "Technique: $_->{tech}\n";
      $str .= "Terms: ".join(',',@{$_->{terms}});
      $str .= "\n";
    }
  }

  if ( $self->{explain_rank}) {
    $str .= "\n## soft split rank(s):\n";
    $str .= join("\n", @{$self->{explain_rank}});
  }

  return $str;
}

sub _explain_rank {
  my ($self) = @_;

  my $r;
  foreach (@{$self->{rank}}) {
    my @parts;
    foreach (@{$_->{terms}}) {
      if ($_->{t} eq $_->{s}) {
        push @parts, $_->{t};
      }
      else {
        push @parts, "$_->{t}(<-$_->{s})";
      }
    }
    $r .= join(',',@parts) . " ---> $_->{expr} = $_->{score}\n";
  }

  return $r;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::IdSplitter - split identifiers into words

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Lingua::IdSplitter;

    my $splitter = Lingua::IdSplitter->new;
    $splitter->split($identifier);

=head1 DESCRIPTION

This module implements and algorithm to identify and split multi-word
identifier in their individual words. For example, "UserFind" in "user"
and "find", or "timesort" in "time" and "sort".

For more details on the algorithm check the following
L<article|http://www.sciencedirect.com/science/article/pii/S0164121214002179>
(also available L<here|http://hdl.handle.net/10198/11577>).

=head1 FUNCTIONS

=head2 new

Create a new splitter object. A list of specific dictionaries is optional,
check the C<bin/id-splitter> command for an example on how to use more
dictionaries.

=head2 soft_split

Perform a soft split of the identifier, ie split words without using
explicit markers (eg, the underscore character, or CamelCase notation).

=head2 hard_split

Perform a hard split of the identifier, ie split words using
explicit markers (eg, the underscore character, or CamelCase notation).

=head2 split

Perform a split applying first a hard split, and the applying a soft split
to the resulting set of the first split.

=head2 explain

Show the computed ranked (including scores) for a split.

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Project Natura <natura@natura.di.uminho.pt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
