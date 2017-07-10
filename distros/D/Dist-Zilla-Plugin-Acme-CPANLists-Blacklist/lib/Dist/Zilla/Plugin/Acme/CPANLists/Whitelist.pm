package Dist::Zilla::Plugin::Acme::CPANLists::Whitelist;

our $DATE = '2017-07-06'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::AfterBuild',
);

has author => (is=>'rw');
has module => (is=>'rw');

sub mvp_multivalue_args { qw(author module) }

sub after_build {}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Specify whitelist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANLists::Whitelist - Specify whitelist

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::Acme::CPANLists::Whitelist (from Perl distribution Dist-Zilla-Plugin-Acme-CPANLists-Blacklist), released on 2017-07-06.

=head1 SYNOPSIS

In your F<dist.ini>:

 [Acme::CPANLists::Blacklist]
 module_list=PERLANCAR::Modules I'm avoiding
 module_list=PERLANCAR::Test list

 [Acme::CPANLists::Whitelist]
 module=Log::Any

This means that if your dist specifies a prereq to C<Log::Any>, the Blacklist
plugin will not abort build even though the module is listed in one of the
blacklists.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists>

C<Acme::CPANLists::*> modules

L<Dist::Zilla::Plugin::Acme::CPANLists::Blacklist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
