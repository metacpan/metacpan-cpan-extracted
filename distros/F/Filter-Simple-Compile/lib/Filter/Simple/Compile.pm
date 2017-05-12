package Filter::Simple::Compile;
$Filter::Simple::Compile::VERSION = '0.02';

use strict;
use warnings;
use 5.006;
use Module::Compile 0.17 ();

sub import {
    my $class = shift;
    my $code = shift;
    my $pkg = caller;

    no strict 'refs';

    push @{"$pkg\::ISA"} => 'Module::Compile';
    *{"$pkg\::FILTER"} = \&FILTER;

    ($code and ref($code) eq 'CODE') or return;
    _setup_filter($pkg, $code);
}

sub unimport {
    my $pkg = caller;

    no strict 'refs';
    *{"$pkg\::pmc_use_means_no"} = sub { 1 };

    goto &{$_[0]->can('import')};
}

sub FILTER (&) {
    my $pkg = caller;
    my $code = shift;

    _setup_filter($pkg, $code);
}

sub _setup_filter {
    my ($pkg, $code) = @_;

    no strict 'refs';
    *{"$pkg\::pmc_compile"} = sub {
        local $_;
        (undef, $_, undef) = @_;
        $code->();
        return $_;
    };
}

1;

__END__

=head1 NAME

Filter::Simple::Compile - Drop-in replacement to Filter::Simple

=head1 SYNOPSIS

Drop-in replacement for L<Filter::Simple>:

    package MyFilter;
    use Filter::Simple::Compile;
    FILTER { ... };

This way also works:

    use Filter::Simple::Compile sub { ... };

=head1 DESCRIPTION

This module lets you write B<Module::Compile> extensions that
are compatible with B<Filter::Simple>'s API.

Additionally, C<no Filter::Simple::Compile> does the same thing
as C<use Filter::Simple::Compile>, except the meaning for C<use>
and C<no> will be reversed for your filter:

    package MyFilter;
    no Filter::Simple::Compile sub { ... }

    # "no MyFilter" begins filtering
    # "use MyFilter" terminates it

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.  Additionally,
when this software is distributed with B<Perl Kit, Version 5>, you may also
redistribute it and/or modify it under the same terms as Perl itself.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
