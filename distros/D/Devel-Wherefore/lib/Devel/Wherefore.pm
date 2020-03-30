package Devel::Wherefore;

our $VERSION = '0.000003'; # v0.0.3

$VERSION = eval $VERSION;

use strict;
use warnings;
use B ();
use Sub::Identify qw(sub_fullname get_code_location);
use Package::Stash;
use Data::Munge qw(list2re);

# detect -d:Wherefore and disable debugger features
if (!defined &DB::DB && $^P & 0x02) {
  $^P = 0;
}

sub import {
  our (undef, $pkg) = @_;
  unless ($pkg) {
    my $prefix = list2re @INC, 'lib';
    if (my ($path) = $0 =~ m{^(?:${prefix}/)?(.*)\.pm$}) {
      $pkg = join '::', split '/', $path;
    } else {
      $pkg = 'main';
    }
  }
  B::minus_c;
}

sub CHECK {
  return unless our $pkg;
  my $subs = Package::Stash->new($pkg)->get_all_symbols('CODE');
  print "# Symbols found in package ${pkg} after compiling $0\n";
  foreach my $name (sort keys %$subs) {
    my $fullname = sub_fullname $subs->{$name};
    my ($file, $line) = get_code_location $subs->{$name};
    print join("\t",
      map +(defined() ? $_ : "\\N"), ${name}, ${fullname}, ${file}, ${line}
    )."\n";
  }
  close(STDERR);
}

1;

=head1 NAME

Devel::Wherefore - Where the heck did these subroutines come from?

=head1 SYNOPSIS

  $ perl -d:Wherefore myscript.pl

will dump symbols in main from myscript.pl

  $ perl -d:Wherefore=App::opan $(which opan)

will dump symbols from package App::opan in the installed opan script

  $ perl -d:Wherefore lib/Foo/Bar.pm

will dump symbols from package Foo::Bar (we guess the package by stripping
either 'lib' or any @INC entry off the front, then assuming the package
name is Foo::Bar for Foo/Bar.pm etc). Which means this also works:

  $ perl -d:Wherefore $(perldoc -lm App::Cpan)

Note that this code uses C<B::minus_c> to only compile the script so you
don't have to worry about it executing - does mean we'll miss runtime
require and import but hey, trade-offs.

=head1 DESCRIPTION

Rage driven development rapidly released.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the Devel::Wherefore L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
