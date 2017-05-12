package Devel::LineName;
use strict;
use warnings;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

use Carp;

sub import {
    my ($pkg, $prag, $hashref) = @_;
    my $callpkg = caller(1);

    defined $hashref or croak "$pkg must be use()ed with two args";
    
    $prag =~ /^\w+\z/   or croak "Invalid $pkg line naming pragma [$prag]";
    ref $hashref eq 'HASH' or croak "2nd arg to 'use $pkg' must be a hashref";

    my $filename = $INC{'Devel/LineName.pm'};
    $INC{"$prag.pm"} ||= $filename;
    if ($INC{"$prag.pm"} ne $filename) {
        croak "$pkg pragma [$prag] clashes with the $prag module";
    }

    no strict 'refs';
    no warnings 'redefine';
    *{$prag.'::import'} = sub {
        my ($pkg, $linename, $offset) = @_;
        $offset ||= 0;

        $hashref->{$linename} = (caller(1))[2] + $offset;
    };
}

1;

__END__

=head1 NAME

Devel::LineName - give names to source code lines

=head1 SYNOPSIS

  my %Line;
  use Devel::LineName linename => \%Line;

  eval {
      die "oops";   use linename 'foo';
  };

  $@ eq "oops at $0 line $Line{foo}.\n" or die "message wrong";

=head1 DESCRIPTION

Allows you to give symbolic names to lines in Perl source code.

This is useful mainly for testing things that deal with line numbers.
For example, suppose you're testing a function that dies with a stack
backtrace, such as L<Carp/confess>.  You might do something like:

  use Test::More tests => 1;

  eval {
      outer_sub()
  };

  is $@, <<END;
  woo at $0 line 19
      main::inner_sub() called at $0 line 15
      main::outer_sub() called at $0 line 4
      eval {...} called at $0 line 3
  END

  sub outer_sub {
      inner_sub();
  }

  sub inner_sub {
      confess "woo";
  }

This works, but you can't see that the line numbers are correct at a
glance, you have to count lines.  I prefer to give meaningful names
to the lines of interest:

  use Test::More tests => 1;

  my %Line;
  use Devel::LineName linename => \%Line;

  eval {                use linename 'eval';
      outer_sub();      use linename 'outer_call';
  };

  is $@, <<END;
  woo at $0 line $Line{confess}
      main::inner_sub() called at $0 line $Line{inner_call}
      main::outer_sub() called at $0 line $Line{outer_call}
      eval {...} called at $0 line $Line{eval}
  END

  sub outer_sub {
      inner_sub();      use linename 'inner_call';
  }

  sub inner_sub {
      confess "woo";    use linename 'confess';
  }

=head1 IMPORTING

When you use() this module, you must pass a pair of arguments to the
use() call.  The first sets the name of the line naming pragma that
will be created, and the second must be a reference to the hash in
which line numbers are to be placed.

The line naming pragma must consist of word characters only.  Your
choice of line naming pragma is a compromise between clarity and brevity.
I like to use C<linename> when there's room, but if space is short then
C<line> or even just C<l> may be better.  Be sure not the use the name
of an existing Perl pragma or module.

=head1 NAMING LINES

To name a line, you add a call to the line naming pragma to the end
of the line.  The argument is the name to be given to the line.

You can specify a line offset as a second argument; these three
examples are all equivalent:

  # normal use
  foo();  use linename 'foo';

  # name the line below
  use linename 'foo', +1;
  foo();

  # name the line above
  foo();
  use linename 'foo', -1;

=head1 AUTHOR

Nick Cleaton, E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by Nick Cleaton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
