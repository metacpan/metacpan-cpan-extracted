package Locale::TextDomain::UTF8;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01'; # VERSION

use Encode             ();
use Locale::Messages   ();

$ENV{OUTPUT_CHARSET} = 'UTF-8';
sub import {
    my ($class, $textdomain, @search_dirs) = @_;

    my $pkg = caller;

    eval qq[package $pkg; use Locale::TextDomain \$textdomain, \@search_dirs;];
    die $@ if $@;
    Locale::Messages::bind_textdomain_filter(
        $textdomain, \&Encode::decode_utf8);
}

1;
# ABSTRACT: Shortcut to use Locale::TextDomain and decoding to UTF8

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::TextDomain::UTF8 - Shortcut to use Locale::TextDomain and decoding to UTF8

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Instead of:

 use Locale::TextDomain 'Some-TextDomain';

you now say:

 use Locale::TextDomain::UTF8 'Some-TextDomain';

=head1 DESCRIPTION

 use Locale::TextDomain::UTF8 'Some-TextDomain'

is equivalent to:

 use Locale::TextDomain 'Some-TextDomain';
 use Locale::Messages qw(bind_textdomain_filter);
 use Encode;
 BEGIN {
     $ENV{OUTPUT_CHARSET} = 'UTF-8';
     bind_textdomain_filter 'Some-TextDomain' => \&Encode::decode_utf8;
 }

it's just more convenient, especially if you have to do it for each textdomain.

Why would you want this? To ensure that strings returned by the C<__()>, et al
functions are UTF8-encoded Perl strings. For example, if you want to pass the
strings to L<Unicode::GCString>. For more details, see the Perl Advent article
mentioned in the SEE ALSO section.

=head1 SEE ALSO

L<Locale::TextDomain>

L<Locale::Messages>

L<http://www.perladvent.org/2013/2013-12-09.html>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-TextDomain-UTF8>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Locale-TextDomain-UTF8>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-TextDomain-UTF8>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
