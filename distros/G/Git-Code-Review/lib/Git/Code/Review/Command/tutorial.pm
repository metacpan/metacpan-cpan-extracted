# ABSTRACT: Show the Git::Code::Review::Tutorial
package Git::Code::Review::Command::tutorial;
use strict;
use warnings;

use Git::Code::Review -command;
use Git::Code::Review::Tutorial;
use Pod::Find qw( pod_where );
use Pod::Usage;

sub description {
    my $DESC = <<"    EOH";
    SYNOPSIS

        git-code-review tutorial

    DESCRIPTION

        Show the git-code-review tutorial.

    EXAMPLES

        git-code-review tutorial

    EOH
    $DESC =~ s/^[ ]{4}//mg;
    return $DESC;
}

sub execute {
    my ($cmd,$opt,$args) = @_;

    pod2usage( -verbose => 2, -input => pod_where( { -inc => 1 }, 'Git::Code::Review::Tutorial' ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Code::Review::Command::tutorial - Show the Git::Code::Review::Tutorial

=head1 VERSION

version 2.6

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
