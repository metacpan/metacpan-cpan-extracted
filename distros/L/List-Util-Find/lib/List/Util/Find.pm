package List::Util::Find;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-16'; # DATE
our $DIST = 'List-Util-Find'; # DIST
our $VERSION = '0.005'; # VERSION

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

This document describes version 0.005 of List::Util::Find (from Perl distribution List-Util-Find), released on 2023-09-16.

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
sure non-numeric scalars don't match when C<$num> is zero. It is equivalent to
something like:

 use List::Util qw(first);
 use Scalar::Util qw(looks_like_number);
 defined(first { defined && looks_like_number($_) && $_ == $num } @list);

except it does not use any module.

=head2 hasstr

Usage:

 hasstr $str, ...

Like C<< grep { $_ eq $num } ... >> except: 1) it short-circuits (exits early as
soon as an item is found); 2) it makes sure C<undef> does not match empty
string. It is equivalent to something like:

 use List::Util qw(first);
 defined(first { defined && $_ eq $str } @list);

except it does not use any module.

=head1 FAQ

=head2 How about hasundef, hasref, hasarrayref, ...?

They are trivial enough:

 first { !defined } @list;
 first { ref $_ } @list;
 first { ref $_ eq 'ARRAY' } @list;
 # and so on

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-Find>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-Find>.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-Find>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
