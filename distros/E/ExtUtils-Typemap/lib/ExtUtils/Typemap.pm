package ExtUtils::Typemap;
use 5.006001;
use strict;
use warnings;
our $VERSION = '1.00';
use ExtUtils::Typemaps;
our @ISA = qw(ExtUtils::Typemaps);

=head1 NAME

ExtUtils::Typemap - Read/Write/Modify Perl/XS typemap files

=head1 SYNOPSIS

See C<ExtUtils::Typemaps> instead!

=head1 DESCRIPTION

This module exists merely as a compatibility wrapper around
L<ExtUtils::Typemaps>. In a nutshell, C<ExtUtils::Typemap> was
renamed to C<ExtUtils::Typemaps> because the F<Typemap> directory
in F<lib/> could collide with the F<typemap> file on
case-insensitive file systems.

The C<ExtUtils::Typemaps> module is part of the L<ExtUtils::ParseXS>
distribution and ships with the standard library of perl starting
with perl version 5.16.

=head1 SEE ALSO

L<ExtUtils::Typemaps>, L<ExtUtils::ParseXS>.

For details on typemaps: L<perlxstut>, L<perlxs>.

=head1 AUTHOR

Steffen Mueller C<<smueller@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010, 2011 Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

