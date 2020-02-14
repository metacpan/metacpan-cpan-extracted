package Git::Repository::Plugin::Diff;

use warnings;
use strict;

use 5.008_005;
our $VERSION = '0.01';

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );

use Carp qw/croak/;

use Git::Repository::Plugin::Diff::Hunk;

sub _keywords {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return qw( diff );
}

sub diff {
    my ( $repository, $file, $from_commit, $to_commit ) = @_;

    my $command =
      $repository->command( 'diff', $from_commit, $to_commit, $file );
    my @output = $command->final_output();

    my @hunks;

    # Parse the output.
    my $hunk;
    while (1) {
        my $line = shift @output;

        if ( !defined $line ) {    # eof
            push @hunks, $hunk if $hunk;
            last;
        }

        if ( !defined($hunk) and $line !~ /^\@\@/ ) {
            next;
        }

        if ( $line =~ /^@@/ ) {
            push @hunks, $hunk if $hunk;
            $hunk = Git::Repository::Plugin::Diff::Hunk->parse_header($line);
            next;
        }

        $hunk->add_line($line);
    }

    return @hunks;
}

1;
__END__

=encoding utf-8

=head1 NAME

Git::Repository::Plugin::Diff - Add diff method to L<Git::Repository>.

=head1 SYNOPSIS

    # Load the plugin.
    use Git::Repository 'Diff';

    my $repository = Git::Repository->new();

    # Get the git diff information.
    my @hunks = $repository->diff( $file, "HEAD", "HEAD~1" );
    my @other_hunks = $repository->diff( $file, "HEAD", "origin/master" );

    my $first_hunk = shift @hunks;
    _dump_diff($first_hunk);

    sub _dump_diff {
        my ($hunk) = @_;
        for my $l ($first_hunk->to_lines) {
            my ($line_num, $line_content) = @$l;
            print("+ $line_num: $line_content\n")
        }
        for my $l ($first_hunk->from_lines) {
            my ($line_num, $line_content) = @$l;
            print("- $line_num: $line_content\n")
        }
    }

=head1 DESCRIPTION

Git::Repository::Plugin::Diff adds diff method to L<Git::Repository>, which can be
used to determine diff between two commits/branches etc

=head2 diff()

Returns list of hunks diff for specified file. For specified commits (or branches).

    my @hunks = $repository->diff( $file, "HEAD", "HEAD~1" );

=head1 AUTHOR

d.tarasov E<lt>d.tarasov@corp.mail.ruE<gt>

=head1 COPYRIGHT

Copyright 2020- d.tarasov

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
