package DynScalar;

$VERSION = '1.02';

use overload (
  '""' => sub { $_[0]->() },
  fallback => 1,
);


sub import {
  my $pkg = caller;
  my $name = (@_ == 1) ? 'dynamic' : pop;
  *{"${pkg}::$name"} = \&dynamic;
}


sub dynamic (&) { bless shift }


1;

__END__

=head1 NAME

DynScalar - closure-in-a-box for simple scalars

=head1 SYNOPSIS

  use DynScalar;  # imports as dynamic()
  use strict;
  use vars '$name';
  
  my $foo = dynamic { "Hello, $name!\n" };
  for $name ("Jeff", "Joe", "Jonas") { print $foo }

=head1 DESCRIPTION

This module creates closures, and masks them as objects that stringify
themselves when used.  This allows you to make incredibly simplistic string
templates:

  use DynScalar 'delay';  # import as delay()
  use strict;
  use vars qw( $name $age $sex );
  
  my $template = delay {
    "Hello, $name.  You're a good-looking $age-year-old $sex.\n"
  };
  
  while (my $rec = get_person()) {
    ($name,$age,$sex) = $rec->features;
    print $template;
  }

You can embed arbitrarily complex code in the block.

=head1 CAVEATS

Lexically scoped variables can be used inside the block, but you must do so
with caution.  The variable must be visible, as in this example:

  use DynScalar;
  
  my $name;
  my $str = dynamic { $name };
  for ("Jeff", "Joe", "Jonas") { $name = $_; print $str }

If you use the lexically scoped variable as the iterator variable in the loop,
however, Perl will scope it even further, and the C<DynScalar> object will
not be able to see it:

  use DynScalar;
  
  my $name;
  my $str = dynamic { $name };
  # this next line will not print as you hoped
  for $name ("Jeff", "Joe", "Jonas") { print $str }

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut

