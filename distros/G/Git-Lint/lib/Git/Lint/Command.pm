package Git::Lint::Command;

use strict;
use warnings;

use Capture::Tiny;

our $VERSION = '0.010';

sub run {
    my $command = shift;

    my ( $stdout, $stderr, $exit ) = Capture::Tiny::capture {
        system( @{$command} );
    };

    chomp($stderr);

    return ( $stdout, $stderr, $exit );
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Command - run commands

=head1 SYNOPSIS

 use Git::Lint::Command;
 my ($stdout, $stderr, $exit) = Git::Lint::Command::run(\@git_config_cmd);

=head1 DESCRIPTION

C<Git::Lint::Command> runs commands and returns output.

=head1 SUBROUTINES

=over

=item run

Runs the passed command and returns the output from STDOUT, STDERR, and the exit code.

=back

=cut
