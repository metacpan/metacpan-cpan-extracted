package Test2::Deny::Platform::CI::GitHubCI;
use strict;
use warnings;

use base 'Test2::Require';

our $VERSION = '0.000160';

use English qw( -no_match_vars ) ;  # Avoids regex performance

require Test2::Require::Platform::CI::GitHubCI;

sub skip {
    my $class = shift;

    if (! Test2::Require::Platform::CI::GitHubCI::IS_PLATFORM()) {
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

Test2::Deny::Platform::CI::GitHubCI - Only run a test if the current platform is not GitHub CI.

=head1 DESCRIPTION

Some tests can only run in certain operating system, architectures or platforms.

=head1 SYNOPSIS

    use Test2::Deny::Platform::CI::GitHubCI;
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

Copyright 2025 Mikko Koivunalho E<lt>mikkoi@cpan.orgE<gt>.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
