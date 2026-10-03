package Test2::Require::Platform::OS::DOSOrDerivative;
use strict;
use warnings;

use base 'Test2::Require';

our $VERSION = '0.000160';

use English qw( -no_match_vars ) ;  # Avoids regex performance

my %PLATFORMS = (
    'dos'     => 'MS-DOS/PC-DOS',
    'os2'     => 'OS/2',
    'MSWin32' => 'Windows',
    'cygwin'  => 'Cygwin',
);

sub IS_PLATFORM {
    return 1 if exists $PLATFORMS{ $OSNAME };
    return 0;
}

sub skip {
    my $class = shift;

    if (IS_PLATFORM()) {
        return;
    } else {
        return (__PACKAGE__ =~ m/^Test2::(.*)$/msx)[0];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Require::Platform::OS::DOSOrDerivative - Only run a test if the current platform is a Unix.

=head1 DESCRIPTION

Some tests can only run in certain operating system or architectures.

This module automates the (admittedly trivial) work of checking
the operating system name.

=head1 SYNOPSIS

    use Test2::Require::Platform::OS::DOSOrDerivative;
    ...
    done_testing;

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<https://github.com/Test-More/Test2-Suite/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Mikko Koivunalho E<lt>mikkoi@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2024 Mikko Koivunalho E<lt>mikkoi@cpan.orgE<gt>.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
