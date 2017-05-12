# test the docs in TT.pm

use Test::More tests => 1;

use Inline (
    TT => q![% BLOCK simple %]
  Hello [% names.join(' and ') %], how are you?
      [% END %]
      !,
    PER_CHOMP => 0, TRIM_LEADING_SPACE => 0
);

my $output = simple( { names => ['Rob', 'Derek'] } );

is( $output,
	"\n  Hello Rob and Derek, how are you?",
	'passing array ref');

__END__
# Equivalent to the above, but at run time (also works as above):
#Inline->bind( TT => q!
#[% BLOCK simple %]
#  Hello [% names.join(' and ') %], how are you?
#[% END %]
#!,
#PRE_CHOMP => 0, TRIM_LEADING_SPACE => 0);

