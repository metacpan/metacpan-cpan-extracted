package Lingua::EN::Numbers::Easy;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2014120401';
our %N;

use Lingua::EN::Numbers 1.01 qw [num2en];

sub import {
    my ($pkg, $hash) = grep {$_ ne 'American' and
                             $_ ne 'British'} @_;
    
    my $callpkg = caller;
    $hash = 'N' unless defined $hash;
    $hash =~ s/^%//;

    no strict 'refs';
    *{"${callpkg}::$hash"} = \%N;
}


sub TIEHASH {bless {0 => 'zero'} => __PACKAGE__}
sub FETCH {
    my $self  = shift;
    my $value = shift;
    return $self -> {$value} if exists $self -> {$value};
    my $n = num2en  ($value) or return;
    $self -> {$value} = lc $n;
}

sub STORE    {die}
sub EXISTS   {die}
sub DELETE   {die}
sub CLEAR    {die}
sub FIRSTKEY {die}
sub NEXTKEY  {die}

tie %N => __PACKAGE__;

__END__

=pod

=head1 NAME

Lingua::EN::Numbers::Easy - Hash access to Lingua::EN::Numbers objects.

=head1 SYNOPSIS

    use Lingua::EN::Numbers::Easy;

    print "$N{1} fish, $N{2} fish, blue fish, red fish";
                         # one fish, two fish, blue fish, red fish.

=head1 DESCRIPTION

C<Lingua::EN::Numbers> is a module that translates numbers to English 
words. Unfortunally, it has an object oriented interface, which makes
it hard to interpolate them in strings. C<Lingua::EN::Numbers::Easy>
translates numbers to words using a tied hash, which can be interpolated.

By default, C<Lingua::EN::Numbers::Easy> exports a hash C<%N> to the
importing package. This can be changed by giving 
C<< use Lingua::EN::Numbers::Easy >> an argument - this argument is the
name of the hash that will be used instead:

    use Lingua::EN::Numbers::Easy qw /%nums/;

would use C<%nums> as the tied hash.

See also the C<Lingua::EN::Numbers> man page.

C<Lingua::EN::Numbers::Easy> caches results - numbers will only be
translated once.

Any other operation on the exported hash than fetches will throw an exception.

=head2 History

This module was created at the end of the 20th century, when 
C<< Lingua::EN::Numbers >> has a clunky, OO interface.
Nowadays, C<< Lingua::EN::Numbers >> has procedural interface as 
well, lessening the need for C<< Lingua::EN::Numbers::Easy >>.

Furthermore, C<< Lingua::EN::Numbers >> no longer supports different
I<< British >> and I<< American >> modes. Therefore, the support
for the modes has been dropped in C<< Lingua::EN::Numbers >> as well.

As for 2014, C<< Lingua::EN::Numbers >> does not have an OO interface
anymore, just a procedurial one. There's probably no need for
C<< Lingua::EN::Numbers::Easy >> anymore, and the reason it was
created is now completely gone.

=head1 AUTHOR

This package was written by Abigail, 
L<< mailto:lingua-en-numbers-easy@abigail.be >>

=head1 COPYRIGHT and LICENSE

This package is copyright 1999 - 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
