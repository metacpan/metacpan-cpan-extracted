package List::Util::Find;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-10'; # DATE
our $DIST = 'List-Util-Find'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       hasnum
                       hasstr
               );

sub hasnum {
    no warnings 'numeric';

    my $needle = shift;
    warn "hasnum(): needle is undefined" unless defined $needle;

    for (@_) {
        # TODO: handle Inf & -Inf (and NaN also?)
        next unless defined;
        next unless $needle == $_;
        if ($needle == 0) {
            # when needle == 0, we want to make sure that we don't match "foo"
            # as 0.
            return 1 if /\A\s*[+-]?(?:0|[1-9][0-9]*)\s*\z/s; # from isint()
            return 1 if /\A\s*[+-]?
                         (?: (?:0|[1-9][0-9]*)(\.[0-9]+)? | (\.[0-9]+) )
                         ([eE][+-]?[0-9]+)?\s*\z/sx && $1 || $2 || $3; # from isfloat()
            next;
        } else {
            return 1;
        }
    }
    0;
}

sub hasstr {
    my $needle = shift;

    warn "hasstr(): needle is undefined" unless defined $needle;

    for (@_) {
        return 1 if defined $_ && $needle eq $_;
    }
    0;
}

1;
# ABSTRACT: List utilities related to finding items

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::Find - List utilities related to finding items

=head1 VERSION

This document describes version 0.003 of List::Util::Find (from Perl distribution List-Util-Find), released on 2021-06-10.

=head1 SYNOPSIS

 use List::Util::Find qw(hasnum hasstr);

 my @ary = (1,3,"foo",7,2,"bar",10,"baz");

 if (hasnum 3, @ary) {
     ...
 }

 if (hasstr "baz", @ary) {
     ...
 }

=head1 DESCRIPTION

Experimental.

=head1 FUNCTIONS

Not exported by default but exportable.

=head2 hasnum

Usage:

 hasnum $num, ...

Like C<< grep { $_ == $num } ... >> except: 1) it short-circuits (exits early as
soon as an item is found); 2) it makes sure C<undef> does not match; 3) it makes
sure non-numeric scalars don't match when C<$num> is zero.

=head2 hasstr

Usage:

 hasstr $str, ...

Like C<< grep { $_ eq $num } ... >> except: 1) it short-circuits (exits early as
soon as an item is found); 2) it makes sure C<undef> does not match empty
string.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-Find>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-Find>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-Find>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
