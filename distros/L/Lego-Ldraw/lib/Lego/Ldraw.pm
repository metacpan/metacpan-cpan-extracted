package Lego::Ldraw;

use 5.008004;
use strict;
use warnings; no warnings qw/uninitialized/;

use Carp;
use Lego::Ldraw::Line;

use File::Basename;

use overload
    '@{}' => \&lines,
    '""' => \&stringify;



our $VERSION = "0.5.8";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

    $self->{lines} = [];
    $self->{file}  = undef;
    $self->{name}  = undef;
    $self->{description}  = undef;
    $self->{dir}   = undef;

    bless ($self, $class);
    return $self;
}

sub DESTROY {
  my $self = shift;
  $_->{model} = undef for @{$self->lines};
  $self = undef;
}

sub new_from_file {
    my $self = shift->new;
    my $file = shift || \*STDIN;

    unless (ref $file eq 'GLOB') {
	croak "Error $? opening $file" unless -e $file;
	open LDRAW, $file or croak "Error $? opening $file";
	$self->{file} = $file;
	$self->{name} = basename($file);
	$self->{dir}  = dirname($file);
	$file = \*LDRAW;
    }

    while (<$file>) {
	chomp;
	unless (/^\s*$/) {
	    my $line = Lego::Ldraw::Line->new_from_string($_);
	    $self->{description} = $line->command unless $.;
	    $self->add($line);
	}
    }
    close $file unless ref $file;
    return $self;
}

sub copy {
  my $self = shift;
  my $copy = Lego::Ldraw->new;

  $copy->{file} = $self->{file};
  $copy->{name} = $self->{name};
  $copy->{dir} = $self->{dir};

  for (@$self) {
    my $line = Lego::Ldraw::Line->new_from_string("$_");
    $copy->add($line);
  }
  return $copy;
}

sub add {
    my $self = shift;
    my $line = shift;
    my $pos = shift;

    $pos = 0 unless @{$self->{lines}};

    if ($pos) {
	splice @{$self->{lines}}, $pos, 0, $line;
    } else {
	push @{$self->{lines}}, $line;
    }
    $self->{tree}->{$line->part}->{$line->color}++;
    $line->dir($self->dir);
}

sub splice {
    my $self = shift;
    my ($what, $offset, $length) = @_;

    for (ref $what) {
      /^Lego::Ldraw::Line$/ && do {
	splice @{$self->{lines}}, $offset, $length, $what;
	last;
      };
      /^Lego::Ldraw$/ && do {
	splice @{$self->{lines}}, $offset, $length, @{$what->{lines}};
	last;
      };
    }
}

sub lines {
    my $self = shift;
    return wantarray ? @{$self->{lines}} : $self->{lines};
}

sub stringify {
    my $self = shift;
    return join "\n", @{$self};
}

sub length {
    my $self = shift;
    return scalar @{$self->{lines}};
}

sub subparts {
  my $self = shift;
  return grep { $_->type == 1 } @{ $self };
}

sub colors {
  my $self = shift;
  my %colors;
  for ($self->lines) {
    next unless my $c = $_->color;
    $colors{$c}++;
  }
  return sort keys %colors;
}

###################################################
# quick fixes for file, name, tree
###################################################

sub file {
  return shift->{file};
}

sub name {
  return shift->{name};
}

sub tree {
  return shift->{tree}
}

sub parts {
  return sort keys %{ shift->{tree} };
}

sub dir {
  return shift->{dir}
}

sub description {
  my $self = shift;
  $self->{description} = shift if @_;
  return $self->{description}
}

sub partsdirs {
  return Lego::Ldraw::Line->partsdirs;
}

sub basedir {
  return Lego::Ldraw::Line->basedir;
}


##################################################
# experimental part: build tree with callback
##################################################

sub Lego::Ldraw::build_tree {
  my $ldraw = shift;
  my $callback = shift;
  my $test = shift;

  my $b; # part tree: $d->{$part}->{$subpart}         means $subpart is used in $part;
  my $d; # reverse part tree: $d->{$subpart}->{$part} means $subpart is used in $part;
  my $s; # recursed parts list. Value is 1 if list is ready to be built for subpart

  $ldraw->recurse_part_tree(\$b, \$d, \$s, $test);

  # while there are parts ready for list building
  while (my @l = grep { $d->{$_} } keys %{$s}) {
    for my $p (@l) {
      # if part has no subparts
      if ($s->{$p}) {
	# build a list for the part
	print STDERR "traversing tree for $p";
	# Lego::Ldraw::Display->build_list($p);
	&{$callback}($p);
	# delete part from list of parts that need building lists
	# delete $s->{$p}; # = 0;
	# set parts that use it as ready for list building
	my @r = keys %{$d->{$p}}; # all parts that use this subpart
	for (@r) {
	  delete $b->{$_}->{$p}; # delete subpart from part tree
	  $s->{$_} = 1 unless keys %{$b->{$_}} # is there are no subparts list can be built
	}
	# delete part reverse tree
	delete $d->{$p};
      }
    }
  }
  my $t;
  $b = undef;
  $d = undef;
  $s = undef;
}

sub Lego::Ldraw::recurse_part_tree {
  my $tree = shift->copy;
  my ($b, $d, $s, $test) = @_;
  $test = $test || sub { shift->type == 1 };

  $$s->{$tree->name} = 1;
  for (@$tree) {
    if (&{$test}($_)) {
      $$b->{$tree->name}->{$_->name}++;
      $$d->{$_->name}->{$tree->name}++;
      $$s->{$tree->name} = 0;
      unless (defined $$s->{$_->name}) {
	my $x = $_->explode;
	$x->recurse_part_tree($b, $d, $s);
      }
    }
  }
  $b = undef;
  $d = undef;
  $s = undef;
  $tree = undef;
}

1;
__END__
