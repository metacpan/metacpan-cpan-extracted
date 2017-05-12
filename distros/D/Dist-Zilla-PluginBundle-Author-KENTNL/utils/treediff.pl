#!/usr/bin/env perl
# FILENAME: treediff.pl
# CREATED: 11/30/13 22:47:06 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Compare two paths with cherry-picked exclusions

use strict;
use warnings;
use utf8;

{

  package Compare;
  use Path::Tiny;
  use List::MoreUtils qw(uniq);

  use Class::Tiny {
    a         => './a',
    b         => './b',
    a_path    => sub { Path::Tiny->new( $_[0]->a ) },
    b_path    => sub { Path::Tiny->new( $_[0]->b ) },
    a_exclude => sub { [] },
    b_exclude => sub { [] },
    a_files   => sub {
      my ($self) = @_;
      my @out;
      my $iter = $self->a_path->iterator( { recurse => 1, follow_symlinks => 0 } );
      while ( my $path = $iter->() ) {
        next if $self->_exclude_a($path);
        push @out, $path->relative( $self->a_path );
      }
      return \@out;
    },
    b_files => sub {
      my ($self) = @_;
      my @out;
      my $iter = $self->b_path->iterator( { recurse => 1, follow_symlinks => 0 } );
      while ( my $path = $iter->() ) {
        next if $self->_exclude_b($path);
        push @out, $path->relative( $self->b_path );
      }
      return \@out;
    },
  };

  sub _exclude_a {
    my ( $self, $file ) = @_;
    for my $matcher ( @{ $self->a_exclude } ) {
      return 1 if $matcher->($file);
    }
    return;
  }

  sub add_exclude_a {
    my ( $self, $sub ) = @_;
    push @{ $self->a_exclude }, $sub;
  }

  sub _exclude_b {
    my ( $self, $file ) = @_;
    for my $matcher ( @{ $self->b_exclude } ) {
      return 1 if $matcher->($file);
    }
    return;
  }

  sub add_exclude_b {
    my ( $self, $sub ) = @_;
    push @{ $self->b_exclude }, $sub;
  }

  sub a_hash {
    my ($self) = @_;
    my %hash;
    for my $file ( @{ $self->a_files } ) {
      my $abs = $file->absolute( $self->a_path );
      next unless -f $abs;
      $hash{"$file"} = $abs;
    }
    return \%hash;
  }

  sub b_hash {
    my ($self) = @_;
    my %hash;
    for my $file ( @{ $self->b_files } ) {
      my $abs = $file->absolute( $self->b_path );
      next unless -f $abs;
      $hash{"$file"} = $abs;
    }

    return \%hash;
  }

  sub pairs {
    my ($self) = @_;
    my (%a)    = %{ $self->a_hash };
    my (%b)    = %{ $self->b_hash };
    my @all;
    push @all, keys %a;
    push @all, keys %b;
    @all = uniq sort @all;
    my @out;

    for my $item (@all) {
      if ( exists $a{$item} and not exists $b{$item} ) {
        push @out, [ $a{$item}, $a{$item}->relative( $self->a_path )->absolute( $self->b_path ) ];
        next;
      }
      if ( not exists $a{$item} and exists $b{$item} ) {
        push @out, [ $b{$item}->relative( $self->b_path )->absolute( $self->a_path ), $b{$item} ];
        next;
      }
      push @out, [ $a{$item}, $b{$item} ];
    }
    return @out;
  }

}

my $compare = Compare->new(
  a => './GraphViz2-Abstract-Node-0.001002',
  b => './'
);

$compare->add_exclude_b(
  sub {
    my $file = shift;
    return 1 if $file->relative('.') =~ /[.]git\//;
    return 1 if $file->relative('.') =~ qr{/?GraphViz2-Abstract-Node-[\d.]+};
    return;
  }
);

use Capture::Tiny qw(capture_stdout);
my @pairs = $compare->pairs;

#open my $target , '>', './delta.patch';
for my $pair (@pairs) {
  my ($a) = $pair->[0]->absolute('.');
  my ($b) = $pair->[1]->absolute('.');

  #printf "\e[31m CMP a = %s b = %s \e[0m\n", $a, $b;
  my $output = capture_stdout {
    local $ENV{LC_ALL} = 'C';
    local $ENV{TZ}     = 'UTC';

    #    system( 'diff', '-Naur', '--label', $pair->[1]->absolute('a'), '--label', $pair->[1]->absolute('b'), $a, $b );
    system( 'git', 'diff', '--', $a, $b );

  };
  next unless length $output;
  my (@lines) = split /\n/, $output;

  #  if ( $lines[0] !~ '---' ) {
  #    die "Diff line is $lines[0]";
  #  }

  #   $target->print($output);

  print "\e[31m$lines[0]\e[0m\n";
  print "\e[32m$lines[1]\e[0m\n";

}

#system('xz','-v9e','./delta.patch');
