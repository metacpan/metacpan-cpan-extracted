use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::MinimumVersionTests;
# ABSTRACT: Release tests for minimum required versions
our $VERSION = '2.000008'; # VERSION
use Moose;
extends 'Dist::Zilla::Plugin::Test::MinimumVersion';


before register_component => sub {
    warn '!!! [MinimumVersionTests] is deprecated and will be removed in a future release; replace it with [Test::MinimumVersion]';
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MinimumVersionTests - Release tests for minimum required versions

=head1 VERSION

version 2.000008

=for test_synopsis BEGIN { die "SKIP: Synopsis isn't Perl code" }

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::MinimumVersion]

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-MinimumVersion/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::MinimumVersion/>.

=head1 SOURCE

The development version is on github at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion/issues>.

=head1 AUTHORS

=over 4

=item *

Mike Doherty <doherty@cpan.org>

=item *

Marcel Grünauer <marcel@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
