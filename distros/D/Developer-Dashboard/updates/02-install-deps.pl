#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);

my ( $cpanm, undef, $which_exit ) = capture {
    system 'which', 'cpanm';
    return $? >> 8;
};
chomp $cpanm;

if ( $which_exit != 0 || !$cpanm ) {
    print "cpanm not found; skipping dependency refresh\n";
    exit 0;
}

print "Refreshing Perl dependencies with cpanm\n";
system $cpanm, '--notest', '--installdeps', '.';

my $exit_code = $? >> 8;
exit $exit_code;

__END__

=head1 NAME

02-install-deps.pl - refresh Perl dependencies for Developer Dashboard

=head1 DESCRIPTION

This update script looks for C<cpanm> and, when available, refreshes the
repository dependencies with C<cpanm --notest --installdeps .>.

=cut
