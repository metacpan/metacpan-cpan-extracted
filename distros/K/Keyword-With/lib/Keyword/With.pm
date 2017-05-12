package Keyword::With;
# ABSTRACT: provide new syntax to use a 'given' statement without an experimental warning
$Keyword::With::VERSION = '0.003';
use strict;
use warnings;

use Keyword::Declare;

sub import {
    keyword with (List $expr, Block $block) {{{
        foreach ( scalar <{$expr}> ) <{$block}>
    }}}
    return; 
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Keyword::With - provide new syntax to use a 'given' statement without an experimental warning

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Provide a construct almost identical to `given (...) { }` that evaluates an list expression in scalar context (assigning it to `$_`) then executing a block of code. 

=head1 NAME 

Keyword::With 

=head1 SYNOPSIS 

 use Keyword::With; 

 with (5*3) {
     print; 
 }

or 

 with ( some_func() ) {
     print "matches\n" if grep { m/$_/ } qr/abc/, qr/def/;
     print "does not match\n"; 
 } 

=head1 ADVANTAGES 

No experimental warning

=head1 DISADVANTAGES 

Cannot use builtins that modify `$_` with with blocks because they will clobber the `$_` value set by `with (...) { }`. This was already a disadvantage of given blocks. A reasonable approach would be to create a new lexical variable within the `with` block:

 with ( [qw(1 2 3 5 8 13 21)] ) {
     my @first_7_fibs = @$_;
     my @new_first_7_fibs = map { $_ + 1 } @first_7_fibs;
     ...
 }

=head1 AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
