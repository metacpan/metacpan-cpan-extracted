package For::Else;

use strict;
use warnings;

use version 0.77;
our $VERSION = qv("v1.0.0");

use Filter::Simple;

my $parens_block;

$parens_block = qr{
  [(]
    (?>
      [^()]+ | (??{ $parens_block })
    )*
  [)]
}smx;

my $code_block;

$code_block = qr{
  {
    (?>
      [^{}]+ | (??{ $code_block })
    )*
  }
}smx;

FILTER_ONLY
  'code' => sub {
    1 while
    s{
      ( for(?:each)? [^(]* ($parens_block) \s*
        $code_block )                      \s*
      ( else                               \s*
        $code_block )
    }{
      if $2
      {
        $1
      }
      $3
    }smx;
  };

1;

__END__

=head1 NAME

For::Else - Enable else blocks with foreach blocks

=head1 SYNOPSIS

  use For::Else;

  foreach my $item ( @items ) {
    do_something( $item );
  }
  else {
    die 'no items';
  }

=head1 DESCRIPTION

We iterate over a list like this:

  foreach my $item ( @items ) {
    do_something( $item );
  }

However I find myself needing to accommodate for the exceptional case when the
list is empty:

  if ( @items ) {
    foreach my $item ( @items ) {
      do_something( $item );
    }
  }
  else {
    die 'no items';
  }

Since we don't enter the C<foreach> block when there are no items, I find the
C<if> to be rather redundant. Wouldn't it be nice to get rid of it? Well now
you can :)

  use For::Else;

  foreach my $item ( @items ) {
    do_something( $item );
  }
  else {
    die 'no items';
  }

=head1 FUNCTIONS

For::Else is a source filter and doesn't contain any functions.

=head1 SEE ALSO

Fur::Elise by Ludwig van Beethoven

The latest version can be found at:

  https://github.com/alfie/For-Else

Watch the repository and keep up with the latest changes:

  https://github.com/alfie/For-Else/subscription

=head1 SUPPORT

Please report any bugs or feature requests at:

  https://github.com/alfie/For-Else/issues

Feel free to fork the repository and submit pull requests :)

=head1 INSTALLATION

To install this module type the following:

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

=over

=item Filter::Simple

=back

=head1 AUTHOR

Alfie John E<lt>alfiej@opera.comE<gt>

=head1 WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
