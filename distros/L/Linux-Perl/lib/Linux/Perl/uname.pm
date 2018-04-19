package Linux::Perl::uname;

=encoding utf-8

=head1 NAME

Linux::Perl::uname

=head1 SYNOPSIS

    my @parts = Linux::Perl::uname->uname();

    my @parts = Linux::Perl::uname::x86_64->uname();

=head1 DESCRIPTION

This module returns the list of strings from the C<uname> system call.
See C<man 2 uname> for the specifics of what that means.

=cut

use strict;
use warnings;

use Call::Context;
use Linux::Perl;

use constant BUFFER_SIZE => 257 * 6;

sub uname {
    my ($class) = @_;

    Call::Context::must_be_list();

    if (!$class->can('NR_uname')) {
        require Linux::Perl::ArchLoader;
        $class = Linux::Perl::ArchLoader::get_arch_module($class);
    }

    my $buf = ("\0" x BUFFER_SIZE);
    Linux::Perl::call( $class->NR_uname(), $buf );

    return split m<\0+>, $buf;
}

1;
