package Lingua::Treebank::HeadFinder;
use strict;
use Carp;
use Lingua::Treebank;
#################################
sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    croak "format not defined" unless defined $self->{format};

    if ($self->{format} eq 'roark') {
	$self->read_roark_rules($self->{file});
    }
    elsif ($self->{format} eq 'charniak') {
	$self->read_charniak_rules($self->{file});
    }

    return $self;
}
#################################
sub read_charniak_rules {
  my $self = shift;
  my $file = shift;
  open my $fh, "<", $file
    or die "Can't open charniak rules file '$file' for reading: $!\n";
  while (<$fh>) {
    chomp;
    next if /^\s*#/;

    s/^(\S+)\s+//;
    my $parent = $1;
    if ($parent eq '*default*') {
      $parent = 'DEFAULT';
    }

    while (length $_) {
      s/\( ([^()]+?) \)//x;
      my $ruleset = $1;

      my ($direction, @candidates) = split " ", $ruleset;
      s/^\s+//;
      s/\s+$//;
      if ($direction eq 'r') {
	$direction = 'right';
      }
      elsif ($direction eq 'l') {
	$direction = 'left';
      }
      croak "line $. of $file direction is wrong\n"
	unless $direction eq 'right' or $direction eq 'left';

      $self->add_rule(parent => $parent,
		      direction => $direction,
		      candidates => \@candidates,
		      text => $_);
    }
  } # loop over lines
  close $fh
    or die "can't close rules file '$file' after reading: $!\n";
}
#################################
sub read_roark_rules {
    my ($self) = shift;
    my ($file) = @_;

    open (my $fh, "<", $file)
      or die "can't open rules file '$file' for reading: $!\n";

    while (<$fh>) {
	chomp;

	# comment lines begin with a sharp
	next if /^\s*#/;

	# lines look like: NP right NP NN NT

	# and a second line with the same target will be used only if
	# the first line fails, so fallback choices can be encoded,
	# e.g.:

	# NP right AJ AAJ

	# also there can be a DEFAULT right NP NN NT  -- used last

	my ($parent, $direction, @candidates) = split;

	$direction = lc $direction; # don't care about caps

	if ($direction eq 'r') {
	    $direction = 'right';
	}
	elsif ($direction eq 'l') {
	    $direction = 'left';
	}

	if ($parent eq '*default*') {
	    $parent = 'DEFAULT';
	}

	croak "line $. of $file direction is wrong\n"
	  unless $direction eq 'right' or $direction eq 'left';

	$self->add_rule(parent => $parent,
			direction => $direction,
			candidates => \@candidates,
			text => $_);

    }
    close $fh
      or die "can't close rules file '$file' after reading: $!\n";
}
#################################
sub add_rule {
    my $self = shift;
    my %args = @_;

    my %cands = map { $_ => 1 } @{$args{candidates}};

    my $rule =  [ $args{direction},
		  \%cands,
		  $args{text},
		];
    push @{$self->{$args{parent}}}, $rule;
}
#################################
sub select_head {
    my $self = shift;
    my Lingua::Treebank::Const $tree = shift;
    my $tag = $tree->tag();
    my @children = @{$tree->children()};

  RULE:
    for my $rule (@{$self->{$tag}}, @{$self->{DEFAULT}}) {
	my @search;
	if ($rule->[0] eq 'left' ) {
	    @search =  @children ;
	}
	else {
	    @search = reverse @children;
	}
	for my $tok (@search) {
	    if (not keys %{$rule->[1]}) {
		# rule is empty but has direction; match anything so
		# pick the first one
		return $tok;
	    }
	    my $child_tag = $tok->tag();
	    if ($rule->[1]{$child_tag}) {
		# carp "selecting $child_tag as head of $tag";
		return $tok;
	    }
	}
	# carp "rejecting rule $rule->[2]";
    }
    carp "no rule found for $tag";
}
#################################
sub annotate_heads {
    # recursively annotate a tree
    my $self = shift;
    my Lingua::Treebank::Const $tree = shift;

    return if $tree->is_terminal();

    my $headchild = $self->select_head($tree);
    $tree->headchild($headchild);

    for my $branch (@{$tree->children()}) {
	$self->annotate_heads($branch);
    }
}
#################################

1;

__END__

=head1 NAME

Lingua::Treebank::HeadFinder - Head-finding in Lingua::Treebank

=head1 SYNOPSIS

  use Lingua::Treebank;

  my @utterances = Lingua::Treebank->from_penn_file($filename);

  foreach (@utterances) {
    # $_ is a Lingua::Treebank::Const now

    foreach ($_->get_all_terminals) {
      # $_ is a Lingua::Treebank::Const that is a terminal (word)

      print $_->word(), ' ' $_->tag(), "\n";
    }

    print "\n\n";

  }

=head1 ABSTRACT

  Lingua::Treebank::HeadFinder is an object that reads a
  Magerman-style head-finding list and performs headfinding on
  Lingua::Treebank::Const trees.

=head1 DESCRIPTION


  The L::TB::HeadFinder object is initialized from a list like the one in 

To do

=cut
