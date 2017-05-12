package Dist::Zilla::Plugin::OSPrereqs::NonPOSIX;

our $DATE = '2014-12-18'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perl::osnames;

use Moose;
extends 'Dist::Zilla::Plugin::OSPrereqs';

use namespace::autoclean;

sub BUILD {
    my $self = shift;

    my @os;
    {
        use experimental 'smartmatch';
        @os = sort(map {$_->[0]} grep {!("posix"~~@{$_->[1]})}
                       @$Perl::osnames::data);
    }

    $self->{prereq_os} = '~^('.join('|', map {quotemeta} @os).')$';
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: List prereqs for non-POSIX OSes

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OSPrereqs::NonPOSIX - List prereqs for non-POSIX OSes

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::OSPrereqs::NonPOSIX (from Perl distribution Dist-Zilla-Plugin-OSPrereqs-POSIX), released on 2014-12-18.

=head1 SYNOPSIS

In dist.ini:

 [OSPrereqs::NonPOSIX]
 Some::Module::That::Doesnt::Run::On::POSIX=0
 Another::Module=1.23

=head1 DESCRIPTION

This module is a subclass of L<Dist::Zilla::Plugin::OSPrereqs>. It is a shortcut
for doing:

 [OSPrereqs / ~^(MSWin32|...)$]
 ...

The list of non-POSIX-compliant operating systems is retrieved from
L<Perl::osnames>.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::OSPrereqs>

L<Perl::osnames>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-OSPrereqs-POSIX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-OSPrereqs-POSIX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OSPrereqs-POSIX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
