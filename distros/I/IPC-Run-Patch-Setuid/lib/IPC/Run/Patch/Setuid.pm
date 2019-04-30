package IPC::Run::Patch::Setuid;

our $DATE = '2019-04-30'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;
use Log::ger;

use Module::Patch ();
use base qw(Module::Patch);

our %config;

my $p_do_kid_and_exit = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    defined $config{-euid} or die "Please specify -euid";

    if (defined $config{-egid}) {
        log_trace "Setting EGID to $config{-egid} ...";
        if ($config{-egid} =~ /\A[0-9]+\z/) {
            # a single number, let's set groups to only this group
            my $groups = $); my $num_groups = 1; $num_groups++ while $groups =~ / /g;
            my $target = join(" ", ($config{-egid}) x $num_groups);
            $) = $target;
            die "Failed setting \$) to '$target'" unless $) eq $target;
        } elsif ($config{-egid} =~ /\A[0-9]+( [0-9]+)+\z/) {
            $) = $config{-egid};
            die "Failed setting \$) to '$config{-egid}'"
                unless $) eq $config{-egid};
        } else {
            die "Invalid -egid '$config{-egid}', must be integer or ".
                "integers separated by space";
        }
    }

    log_trace "Setting EUID to $config{-euid} ...";
    if ($config{-euid} =~ /\A[0-9]+\z/) {
        $> = $config{-euid};
        die "Failed setting \$> to '$config{-euid}'"
            unless $> eq $config{-euid};
    } else {
        die "Invalid -euid, must be integer";
    }

    $ctx->{orig}->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -euid => {
                schema  => 'uint*',
                req => 1,
            },
            -egid => {
                summary => 'A GID or several GIDs separated by space',
                schema  => 'str*',
            },
        },
        patches => [
            {
                action => 'wrap',
                sub_name => '_do_kid_and_exit',
                code => $p_do_kid_and_exit,
            },
        ],
    };
}

1;
# ABSTRACT: Set EUID

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Run::Patch::Setuid - Set EUID

=head1 VERSION

This document describes version 0.003 of IPC::Run::Patch::Setuid (from Perl distribution IPC-Run-Patch-Setuid), released on 2019-04-30.

=head1 SYNOPSIS

 use IPC::Run::Patch::Setuid -euid => 1000;

=head1 DESCRIPTION

This patch sets EUID of the child process (C<< $> >>) to the specified ID after
forking.

=head1 CONFIGURATION

=head2 -euid

Unsigned integer.

=head2 -egid

String. Either a single GID or multiple GID separated by space.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/IPC-Run-Patch-Setuid>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-IPC-Run-Patch-Setuid>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-Run-Patch-Setuid>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<IPC::Run>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
