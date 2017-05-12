package Devel::REPL::Profile::TSIBLEY;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Moose;
use namespace::autoclean;

extends 'Devel::REPL::Profile::Default';

sub plugins {
    my @default = $_[0]->SUPER::plugins;
    return (
        grep { not /^(DDS|ReadLineHistory)$/ } @default,
        "DDP",
        "ReadLineHistory::WithoutExpansion",
    );
}

sub apply_profile {
    my ($self, $repl) = @_;

    # The past is the key to the present.
    $ENV{PERLREPL_HISTLEN} = 10_000;

    $repl->load_plugin($_) for $self->plugins;

    # Turn off green slime from Colors plugin
    $repl->normal_color("reset");
}

1;
__END__

=encoding utf-8

=head1 NAME

Devel::REPL::Profile::TSIBLEY - TSIBLEY's personal Devel::REPL profile

=head1 SYNOPSIS

    # in your shell's rc file
    export DEVEL_REPL_PROFILE=TSIBLEY

    # per-invocation
    re.pl --profile TSIBLEY

=head1 DESCRIPTION

Devel::REPL::Profile::TSIBLEY is based on the L<default
profile|Devel::REPL::Profile::Default> with the following differences:

=over

=item * History expansion via C<!> is disabled

=item * L<Data::Printer> is used instead of L<Data::Dumper::Streamer> (via L<Devel::REPL::Plugin::DDP>)

=back

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Devel::REPL>

=cut
