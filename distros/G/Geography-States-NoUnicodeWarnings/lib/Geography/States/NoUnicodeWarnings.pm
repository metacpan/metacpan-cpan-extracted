package Geography::States::NoUnicodeWarnings;

use 5.010;
use strict;
use warnings;
no warnings 'uninitialized';

use Module::Load;

our $VERSION = '0.004';
$VERSION = eval $VERSION;

=head1 NAME

Geography::States::NoUnicodeWarnings - use Geography::States without warnings

=head1 SYNOPSIS

 use open ':encoding(utf8)';
 use Geography::States::NoUnicodeWarnings;
 # STDERR is not full of warnings about characters not mapping to Unicode

=head1 DESCRIPTION

Geography::States is a decent Perl module, tried and tested. It hasn't updated
for a while, but then e.g. the USA, Canada etc. haven't added states recently,
so there hasn't been a need.

Under certain circumstances - specifically if you have set a global character
encoding for PerlIO - using Geography::States may cause warnings at compile-
time. Or it may not; you may be lucky. I haven't managed to narrow down
exactly what causes the lack of warnings - it's not simply a matter of locale,
for instance - but flavours of Perl between 5.10 and 5.14 appear to be
affected.

This module fixes that. Just say C<use Geography::States::NoUnicodeWarnings>
where you would otherwise have said C<use Geography::States> and the warnings
will go away.

The Brazilian States that give the warnings will probably not be corrupted,
although they may not be proper Unicode.

=cut

{
    use open ':std';
    Module::Load::load('Geography::States');
}

=head1 AUTHOR

Sam Kington <skington@cpan.org>

The source code for this module is hosted on GitHub
L<https://github.com/skington/geography-states-nounicodewarnings> - this is
probably the best place to look for suggestions and feedback.

=head1 COPYRIGHT

Copyright (c) 2015 Sam Kington

=cut

1;