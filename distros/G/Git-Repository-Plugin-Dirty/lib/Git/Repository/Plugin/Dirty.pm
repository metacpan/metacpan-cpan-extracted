package Git::Repository::Plugin::Dirty;

use strict;
use warnings;

our $VERSION = '0.01';

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );

sub _keywords { return qw( is_dirty has_untracked has_unstaged_changes has_staged_changes diff_unstaged diff_staged current_branch ) }

sub is_dirty {
    my ( $git, %opts ) = @_;
    return 1 if $git->has_staged_changes() || $git->has_unstaged_changes();
    return 1 if $opts{untracked} && $git->has_untracked();
    return;
}

sub has_untracked {
    my ($git) = @_;
    my @untracked = map { my $l = $_; $l =~ s/^\?\? //; $l }
      grep { m/^\?\? / } $git->run( "status", "-u", "-s", "--porcelain" );
    return @untracked;
}

sub has_unstaged_changes {
    my ($git) = @_;
    eval { $git->run( "diff", "--quiet" ) };
    die $@ if $@ && ( $? == 128 || $? == 129 );
    return $?;
}

sub has_staged_changes {
    my ($git) = @_;
    eval { $git->run( "diff", "--quiet", "--cached" ) };
    die $@ if $@ && ( $? == 128 || $? == 129 );
    return $?;
}

sub diff_unstaged {
    my ( $git, $handler, $undocumented_cached_flag ) = @_;
    my @output;
    $handler ||= sub { my ( $self, $line ) = @_; push @output, $line; return 1; };

    my $diffcmd =
        $undocumented_cached_flag
      ? $git->command( 'diff', '--cached' )
      : $git->command('diff');
    my $diffout = $diffcmd->stdout;
    my $buffer;
    while ( $buffer = <$diffout> ) {
        last if !$handler->( $git, $buffer );
    }
    $diffcmd->close;

    return @output;
}

sub diff_staged {
    my ( $git, $handler ) = @_;
    @_ = ( $git, $handler, 1 );
    goto &diff_unstaged;
}

sub current_branch {
    my ($git) = @_;
    return $git->run(qw(rev-parse --abbrev-ref HEAD));
}

1;

__END__

=encoding utf8

=head1 NAME

Git::Repository::Plugin::Dirty - methods to inspect the dirtiness of a git repository

=head1 VERSION

This document describes Git::Repository::Plugin::Dirty version 0.01

=head1 SYNOPSIS

    use Git::Repository qw(Dirty);

    my $git = Git::Repository->new( { fatal => ["!0"], quiet => ( $verbose ? 0 : 1 ), } );

    if ($git->is_dirty) {
        if ($force) {
            …
        }
        else {
            die "Repo is dirty. Please commit or stash any staged or unstaged changes and try again.\n";
        }
    }

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=head2 $git->is_dirty()

Returns true if there are staged or unstaged changes.

=head2 $git->is_dirty(untracked => 1)

Also return true if there are untracked files.

=head2 $git->has_unstaged_changes()

Returns true if there are unstaged changes.

=head2 $git->has_staged_changes()

Returns true if there are staged changes.

=head2 $git->has_untracked()

Returns a list of untracked files.

=head2 $git->diff_unstaged()

Returns an array of lines making up the diff of unstaged changes.

=head2 $git->diff_unstaged(\&output_handler)

For each line of the unstaged changes diff this handler is called.

It is passed the git object and the line.

Returning true will continue to the next line.

Returning false will stop the command.


    $git->diff_staged(sub {
        my ($git,$line) = @_;

        if ($line =~ m/API_KEY:(.*)/) {
            my $api_key = $1;
            update_api_key_on_ci_boxes($api_key);
            return; # since we found what we where looking for we can stop
        }

        return 1; # keep going
    });

=head2 $git->diff_staged()

Returns an array of lines making up the diff of unstaged changes.

=head2 $git->diff_staged(\&output_handler)

Same as C<diff_staged()> but for staged changes.

=head2 $git->current_branch()

Returns the current branch. Useful for determining why a repo is dirty and what to do about it.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own. Any errors will be from the L<Git::Repository> objects.

=head1 CONFIGURATION AND ENVIRONMENT

Git::Repository::Plugin::Dirty requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Git::Repository::Plugin>

=head1 INCOMPATIBILITIES AND LIMITATIONS

None reported.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Git-Repository-Plugin-Dirty/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
