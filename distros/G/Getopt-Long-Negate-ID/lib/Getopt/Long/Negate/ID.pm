package Getopt::Long::Negate::ID;

our $DATE = '2016-08-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(negations_for_option);

sub negations_for_option {
    my $word = shift;

    if    ($word =~ /\Atak[_-](.+)/  ) { return ("$1") }
    elsif ($word =~ /\Atidak[_-](.+)/) { return ("$1") }
    elsif ($word =~ /\Abukan[_-](.+)/) { return ("$1") }

    elsif ($word =~ /\Adengan([_-].+)/) { return ("tanpa$1") }
    elsif ($word =~ /\Atanpa([_-].+)/)  { return ("dengan$1") }

    elsif ($word =~ /\Aadalah([_-].+)/) { return ("bukan$1") }
    elsif ($word =~ /\Aialah([_-].+)/)  { return ("bukan$1") }

    elsif ($word =~ /\Amatikan([_-].+)/)  { return ("hidupkan$1") }
    elsif ($word =~ /\Apadamkan([_-].+)/) { return ("nyalakan$1") }
    elsif ($word =~ /\Ahidupkan([_-].+)/) { return ("matikan$1") }
    elsif ($word =~ /\Anyalakan([_-].+)/) { return ("padamkan$1") }

    elsif ($word =~ /\Aizinkan([_-].+)/)     { return ("larang$1") }
    elsif ($word =~ /\Aijinkan([_-].+)/)     { return ("larang$1") }
    elsif ($word =~ /\Abolehkan([_-].+)/)    { return ("larang$1") }
    elsif ($word =~ /\Aperbolehkan([_-].+)/) { return ("larang$1") }
    elsif ($word =~ /\Alarang([_-].+)/)      { return ("izinkan$1") }

    else {
        # default
        return ("tak-$word");
    }
}

1;
# ABSTRACT: Better negation of boolean option names (Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::Negate::ID - Better negation of boolean option names (Indonesian)

=head1 VERSION

This document describes version 0.001 of Getopt::Long::Negate::ID (from Perl distribution Getopt-Long-Negate-ID), released on 2016-08-07.

=head1 SYNOPSIS

 use Getopt::Long::Negate::ID qw(negations_for_option);

 @negs = negations_for_option('foo');       # ('tak-foo')
 @negs = negations_for_option('tak-foo');   # ('foo')
 @negs = negations_for_option('tidak-foo'); # ('foo')
 @negs = negations_for_option('bukan-foo'); # ('foo')

 @negs = negations_for_option('dengan-foo'); # ('tanpa-foo')
 @negs = negations_for_option('tanpa-foo');  # ('dengan-foo')

 @negs = negations_for_option('adalah-foo');  # ('bukan-foo')
 @negs = negations_for_option('ialah-foo');   # ('bukan-foo')

 @negs = negations_for_option('matikan-foo');  # ('hidupkan-foo')
 @negs = negations_for_option('padamkan-foo'); # ('hidupkan-foo')
 @negs = negations_for_option('hidupkan-foo'); # ('matikan-foo')
 @negs = negations_for_option('nyalakan-foo'); # ('matikan-foo')

 @negs = negations_for_option('izinkan-foo');     # ('larang-foo')
 @negs = negations_for_option('ijinkan-foo');     # ('larang-foo')
 @negs = negations_for_option('bolehkan-foo');    # ('larang-foo')
 @negs = negations_for_option('perbolehkan-foo'); # ('larang-foo')
 @negs = negations_for_option('larang-foo');      # ('izinkan-foo')

=head1 DESCRIPTION

This is the Indonesian equivalent for L<Getopt::Long::Negate::EN>.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 negations_for_option($str) => list

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-Negate-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-Negate-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-Negate-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::Negate::EN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
