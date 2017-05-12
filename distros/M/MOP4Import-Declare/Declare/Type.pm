package MOP4Import::Declare::Type;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Declare -as_base, qw/Opts/;

sub declare_type {
  (my $myPack, my Opts $opts, my $callpack, my ($name, @spec)) = @_;

  if ($opts->{basepkg}) {
    unshift @spec, [base => $opts->{basepkg}];
  } elsif ($opts->{extending}) {
    my $sub = $opts->{destpkg}->can($name)
      or croak "Can't find base class $name in parents of $opts->{destpkg}";
    unshift @spec, [base => $sub->($opts->{destpkg})];
  }

  my $innerClass = join("::", $opts->{destpkg}, $name);

  $myPack->declare_alias($opts, $callpack, $name, $innerClass);

  if (@spec) {
    $myPack->dispatch_declare($opts->with_objpkg($innerClass)
			      , $callpack
			      , @spec);
  } else {
    # Note: To make sure %FIELDS is defined. Without this we get:
    #   No such class Foo at (eval 45) line 1, near "(my Foo"
    #
    $myPack->declare_fields($opts->with_objpkg($innerClass), $callpack);
  }
}

sub declare_subtypes {
  (my $myPack, my Opts $opts, my $callpack, my @specs) = @_;

  $myPack->dispatch_pairs_as(type => $opts->with_basepkg($opts->{objpkg})
			     , $callpack, @specs);
}

1;
