package Dunce::time::Zerofill;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

sub import {
    my($class, $digit) = @_;
    $digit = 10 unless defined $digit;
    my $caller = caller;
    {
	no strict 'refs';
	*{$caller.'::time'} = sub {
	    return sprintf '%' . $digit . 'd', time;
	};
    }
}

1;
    
__END__

=head1 NAME

Dunce::time::Zerofill - Protects against sloppy use of time.

=head1 SYNOPSIS

  use Dunce::time::Zerofill;

  # time() returns zero-filled 10 digit time.
  my $this = time;

  print $this;     #  '0992251492'
  print $this + 0; # as used to be, 992251492 for numerically context

  # for 11 digit time
  use Dunce::time::Zerofill '11'; # not numeric 11, interpreted as versoin

=head1 DESCRIPTION

On Sun Sep 9 01:46:40 2001 GMT, time_t (UNIX epoch) reaches 10 digits.
So, we should use already zero-filled 10 digit time_t!

When Dunce::time::Zerofill is used, it provides special version of
time() which returns zero-filled time. It doesn't break anything in
numeric context, and comparing times as string will lead to
"0992251492 comes before 1000000000", which should be an expected
result.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>, with idea from M. Simon
Cavalletto <simonm@evolution.com>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dunce::time>, L<D::oh::Year>.

=cut
