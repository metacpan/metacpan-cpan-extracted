package MealMaster;
use strict;
use MealMaster::Recipe;
use MealMaster::Ingredient;
our $VERSION = "0.28";
use base qw(Class::Accessor::Chained::Fast);

sub parse {
  my ($self, $filename) = @_;

  open(my $fh, $filename) || die $!;
  my $file = join '', <$fh>;

  return unless $file =~ /^(MMMMM|-----).+Meal-Master/;

  my @parts = split /^(?:MMMMM|-----).+Meal-Master.+$/m, $file;
  my @recipes;

  foreach my $part (@parts) {
    $part =~ s/^\s+//;
    my $recipe = MealMaster::Recipe->new;
    my $lines  = [ split /\n/, $part ];

    my $line;

    while (1) {
      $line = $self->_newline($lines);
      last unless defined $line;
      last if $line =~ /Title:/;
    }
    next unless defined $line;

    my ($title) = $line =~ /Title: (.+)$/;
    next unless $title;
    $title =~ s/^ +//;
    $title =~ s/ +$//;
    $recipe->title($title);

    $line = $self->_newline($lines);
    my ($categories) = $line =~ /Categories: (.+)$/;

    my @categories;
    @categories = split ', ', $categories if $categories;
    $recipe->categories(\@categories);

    $line = $self->_newline($lines);
    my ($yield) = $line =~ /(?:Yield|Servings): +(.+)$/;
    next unless $yield;
    $recipe->yield($yield);

    my $dflag = 0;
    my $ingredients;
    my $directions;

    while (defined($line = $self->_newline($lines))) {
      next unless $line;

      last if (!defined $line);
      next if (($dflag == 0) && ($line =~ m|^\s*$|));

      if ($line =~ /^[M-]+$/) {
        last;
      } elsif ($line =~ m(^[M|-]{4,})) {
        $line =~ s|^MMMMM||;
        $line =~ s|^\-+||;
        $line =~ s|\-+$||;
        $line =~ s|^ +||;
        $line =~ s|:$||;
        $directions .= "$line\n";
      } elsif ($line =~ m/^ *([A-Z ]+):$/) {
        $directions .= "$line\n";
      } elsif (length($line) > 12
        && (substr($line, 0, 7) =~ m|^[ 0-9\.\/]+$|)
        && (substr($line, 7, 4) =~ m|^ .. $|))
      {
        $ingredients .= "$line\n";
      } else {
        $line =~ s|^\s+||;
        if ($line) {
          $directions .= "$line\n";
          $dflag = 1;
        }
      }
    }

    $ingredients = $self->_parse_ingredients($ingredients);

    $recipe->ingredients($ingredients);
    $recipe->directions($directions);

    push @recipes, $recipe;
  }
  return @recipes;
}

sub _parse_ingredients {
  my ($self, $text) = @_;

  return [] unless $text;

  my @ingredients;
  my @ingredients2;
  foreach my $line (split "\n", $text) {

    # Two-column case:
    #    1/3 c  Instant cream of wheat

    #  1 1/3 c  Brown Sugar, Firmly Packed          1 c  Unbleached Flour
    # 12345678910121416182022242628303234363840424446485052
    if (length($line) > 40 && $line =~ /^.{40}  ...... .. ./) {
      my $quantity = substr($line, 0,  7);
      my $measure  = substr($line, 8,  2);
      my $product  = substr($line, 11, 29);
      $quantity =~ s/^ +//;
      $measure  =~ s/ ? ?$//;
      $product  =~ s/ +$//;
      my $i =
        MealMaster::Ingredient->new->quantity($quantity)->measure($measure)
        ->product($product);
      push @ingredients, $i;
      $quantity = substr($line, 41, 7);
      $measure  = substr($line, 49, 2);
      $product  = substr($line, 52);
      $quantity =~ s/^ +//;
      $measure  =~ s/ ? ?$//;
      $i =
        MealMaster::Ingredient->new->quantity($quantity)->measure($measure)
        ->product($product);
      push @ingredients2, $i;
    } else {

      # Simple case:
      #    1/4 c  Butter or margarine
      my $quantity = substr($line, 0, 7);
      my $measure  = substr($line, 8, 2);
      my $product = substr($line, 11);
      $quantity =~ s/^ +//;
      $measure  =~ s/ ? ?$//;
      $product  =~ s/ +$//;
      my $i =
        MealMaster::Ingredient->new->quantity($quantity)->measure($measure)
        ->product($product);
      push @ingredients, $i;
    }
  }

  @ingredients = (@ingredients, @ingredients2);

  # Fold
  #    1/3 c  Instant cream of wheat
  #           -(prepared)
  # to:
  #    1/3 c  Instant cream of wheat (prepared)

  my @folded_ingredients = ($ingredients[0]);
  foreach my $n (1 .. @ingredients - 1) {
    my $i = $ingredients[$n];
    if ( not defined $i->quantity
      && not defined $i->measure
      && $i->product =~ /^-/)
    {
      my $extra = $i->product;
      $extra =~ s/^--?//;
      my $old = $folded_ingredients[-1]->product;
      my $new = "$old $extra";
      $folded_ingredients[-1]->product($new);
    } else {
      push @folded_ingredients, $i;
    }
  }

  return \@folded_ingredients;
}

sub _newline {
  my ($self, $lines) = @_;
  my $line = shift @$lines;
  return unless defined $line;
  $line =~ s{\r|\n|\t}{}g;
  chomp $line;
  return $line;
}

1;

__END__

=head1 NAME

MealMaster - Parse MealMaster format recipe files

=head1 SYNOPSIS

  my $mm = MealMaster->new();
  my @recipes = $mm->parse("t/31000.mmf");
  foreach my $r (@recipes) {
    print "Title: " . $r->title . "\n";
    print "Categories: " . join(", ", sort @{$r->categories}) . "\n";
    print "Yield: " . $r->yield . "\n";
    print "Directions: " . $r->directions . "\n";
    print "Ingredients:\n";
    foreach my $i (@{$r->ingredients}) {
      print "  " . $i->quantity .
             " " . $i->measure  .
             " " . $i->product . 
             "\n";
    }

=head1 DESCRIPTION

People like to share food recipes on the internet. MealMaster is a
popular program for collating recipes. The L<MealMaster> module parses
the MealMaster recipe export format, providing you with recipe objects.
You can recognize these MealMaster format files as they generally start
with "Recipe via Meal-Master".

=head1 CONSTRUCTOR

=head2 new

The constructor. Takes no arguments:

  my $mm = MealMaster->new();

=head1 METHODS

=head2 parse($filename)

The parse method takes a filename and recipes an array of
L<MealMaster::Recipe> objects representing the recipes in the file:

  my @recipes = $mm->parse("t/31000.mmf");

=head1 SEE ALSO

L<MealMaster::Recipe>, L<MealMaster::Ingredient>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
