package Function::Fallback::CoreOrPP;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-03'; # DATE
our $DIST = 'Function-Fallback-CoreOrPP'; # DIST
our $VERSION = '0.090'; # VERSION

use 5.010001;
use strict;
use warnings;

our $USE_NONCORE_XS_FIRST = 1;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       clone
                       clone_list
                       unbless
                       uniq
               );

sub clone {
    my $data = shift;
    goto FALLBACK unless $USE_NONCORE_XS_FIRST;
    goto FALLBACK unless eval { require Data::Clone; 1 };

  STANDARD:
    return Data::Clone::clone($data);

  FALLBACK:
    require Clone::PP;
    return Clone::PP::clone($data);
}

sub clone_list {
    map { clone($_) } @_;
}

sub _unbless_fallback {
    my $ref = shift;

    my $r = ref($ref);
    # not a reference
    return $ref unless $r;

    # return if not a blessed ref
    my ($r2, $r3) = "$ref" =~ /(.+)=(.+?)\(/
        or return $ref;

    if ($r3 eq 'HASH') {
        return { %$ref };
    } elsif ($r3 eq 'ARRAY') {
        return [ @$ref ];
    } elsif ($r3 eq 'SCALAR') {
        return \( my $copy = ${$ref} );
    } elsif ($r3 eq 'CODE') {
        return sub { goto &$ref };
    } else {
        die "Can't handle $ref";
    }
}

sub unbless {
    my $ref = shift;

    goto FALLBACK unless $USE_NONCORE_XS_FIRST;
    goto FALLBACK unless eval { require Acme::Damn; 1 };

  STANDARD:
    return Acme::Damn::damn($ref);

  FALLBACK:
    return _unbless_fallback($ref);
}

sub uniq {
    goto FALLBACK unless $USE_NONCORE_XS_FIRST;
    goto FALLBACK unless eval { require List::MoreUtils; 1 };

  STANDARD:
    return List::MoreUtils::uniq(@_);

  FALLBACK:
    my %h;
    my @res;
    for (@_) {
        push @res, $_ unless $h{$_}++;
    }
    return @res;
}

1;
# ABSTRACT: Functions that use non-core XS module but provide pure-Perl/core fallback

__END__

=pod

=encoding UTF-8

=head1 NAME

Function::Fallback::CoreOrPP - Functions that use non-core XS module but provide pure-Perl/core fallback

=head1 VERSION

This document describes version 0.090 of Function::Fallback::CoreOrPP (from Perl distribution Function-Fallback-CoreOrPP), released on 2020-02-03.

=head1 SYNOPSIS

 use Function::Fallback::CoreOrPP qw(clone unbless uniq);

 my $clone = clone({blah=>1});
 my $unblessed = unbless($blessed_ref);
 my @uniq  = uniq(1, 3, 2, 1, 4);  # -> (1, 3, 2, 4)

=head1 DESCRIPTION

This module provides functions that use non-core XS modules (for best speed,
reliability, feature, etc) but falls back to those that use core XS or pure-Perl
modules when the non-core XS module is not available.

This module helps when you want to bootstrap your Perl application with a
portable, dependency-free Perl script. In a vanilla Perl installation (having
only core modules), you can use L<App::FatPacker> to include non-core pure-Perl
dependencies to your script.

=for Pod::Coverage ^()$

=head1 FUNCTIONS

=head2 clone($data) => $cloned

Try to use L<Data::Clone>'s C<clone>, but fall back to using L<Clone::PP>'s
C<clone>.

=head2 clone_list(@data) => @data

A shortcut for:

 return map {clone($_)} @data

=head2 unbless($ref) => $unblessed_ref

Try to use L<Acme::Damn>'s C<damn> to unbless a reference but fall back to
shallow copying.

NOTE: C<damn()> B<MODIFIES> the original reference. (XXX in the future an option
to clone the reference first will be provided), while shallow copying will
return a shallow copy.

NOTE: The shallow copy method currently only handles blessed
{scalar,array,hash}ref as those are the most common.

=head2 uniq(@ary) => @uniq_ary

Try to use L<List::MoreUtils>'s C<uniq>, but fall back to using slower,
pure-Perl implementation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Function-Fallback-CoreOrPP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Function-Fallback-CoreOrPP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Function-Fallback-CoreOrPP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Clone::Any> can also use multiple backends. I used to avoid it because
L<Storable>'s C<dclone> (which is used as the backend) did not support Regexp
objects out of the box until version 3.08. Plus must use deparse to handle
coderefs.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
