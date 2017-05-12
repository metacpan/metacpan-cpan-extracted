package Git::Hook::PostReceive;
$Git::Hook::PostReceive::VERSION = '0.3';
use warnings;
use strict;
use v5.14;
use feature "switch";

#ABSTRACT: Parses git commit information in post-receive hook scripts
use Cwd;
use File::Basename;
use Encode;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { utf8 => $args{utf8} ? 1 : 0, }, $class;
    $self;
}

sub read_stdin {
    my $self = shift;
    my @lines = @_ ? map { split "\n" } @_ : <>;
    my @branches;

    foreach my $line (@lines) {
        chomp $line;
        my $payload = $self->run( split /\s+/, $line );
        if (wantarray) {
            push @branches, $payload;
        }
        else {
            return $payload;
        }
    }
    return wantarray ? @branches : ();
}

sub _git_cmd {
    my $self = shift;
    my @args = qw(git);
    push @args, "--git-dir=" . $self->{git_dir}     if $self->{git_dir};
    push @args, "--work-tree=" . $self->{work_tree} if $self->{work_tree};
    return @args;
}

sub detect_action {
    my ( $self, $before, $after ) = @_;
    chomp $before;
    chomp $after;
    if ( $before ne '0000000000000000000000000000000000000000' ) {
        $before = qx(@{[ $self->_git_cmd() ]} rev-parse $before);
    }
    else {
        return { created => $before };
    }
    if ( $after ne '0000000000000000000000000000000000000000' ) {
        $after = qx(@{[ $self->_git_cmd() ]} rev-parse $after);
    }
    else {
        return { deleted => $after };
    }
    return { pushed => [ $before, $after ] };
}

sub get_repo {
    my $self = shift;
    return $self->{git_dir}   if $self->{git_dir};
    return $self->{work_tree} if $self->{work_tree};
    return getcwd();
}

sub run {
    my ( $self, $before, $after, $ref ) = @_;

    return unless $before and $after and $ref;

    my ( $created, $deleted ) = ( 0, 0 );
    if ( $before ne '0000000000000000000000000000000000000000' ) {
        $before = qx(@{[ $self->_git_cmd() ]} rev-parse $before);
        chomp $before;
    }
    else {
        $created = 1;
    }

    if ( $after ne '0000000000000000000000000000000000000000' ) {
        $after = qx(@{[ $self->_git_cmd() ]} rev-parse $after);
        chomp $after;
    }
    else {
        $deleted = 1;
    }

    return {
        before     => $before,
        after      => $after,
        repository => $self->get_repo(),
        ref        => $ref,
        created    => $created,
        deleted    => $deleted,
        commits    => [ $self->get_commits( $before, $after ) ]

            # head_commit => ... # ?
    };
}

sub get_commits {
    my ( $self, $before, $after ) = @_;

    my $log_string;

    if (   $before ne '0000000000000000000000000000000000000000'
        && $after ne '0000000000000000000000000000000000000000' )
    {
        $log_string = qx(@{[ $self->_git_cmd() ]} rev-list $before...$after);
    }
    elsif ( $after ne '0000000000000000000000000000000000000000' ) {
        $log_string = qx(@{[ $self->_git_cmd() ]} rev-list $after);
    }

    return () unless $log_string;

    return reverse map { $self->commit_info($_) } split /\n/, $log_string;
}

sub commit_info {
    my ( $self, $hash ) = @_;

    my $commit
        = qx{@{[ $self->_git_cmd() ]} show --format=fuller --date=iso --name-status $hash};
    $commit = decode( 'utf8', $commit ) if $self->{utf8};

    my @lines = split /\n/, $commit;

    my $info = {
        added    => [],
        removed  => [],
        modified => [] };

    for my $line (@lines) {
        $_ = $line;
        if (m{^commit (.*)$}i) {
            $info->{id} = $1;
        }
        elsif (m{^author:\s+(.*?)\s<(.*?)>}i) {
            $info->{author} = { name => $1, email => $2 };
        }
        elsif (m{^commit:\s+(.*?)\s<(.*?)>}i) {
            $info->{commiter} = { name => $1, email => $2 };
        }
        elsif (m{^authordate:\s+(.*)$}i) {
            $info->{timestamp} = $1;
            $info->{timestamp} =~ s/ /T/;
            $info->{timestamp} =~ s/ ([+-])(\d\d)(\d\d)/$1$2:$3/;
        }
        elsif (m{^merge: (\w+)\s+(\w+)}i) {
            $info->{merge} = { parent1 => $1, parent2 => $2 };
        }
        elsif (m{^A\t(.+)}) {
            push @{ $info->{added} }, $1;
        }
        elsif (m{^D\t(.+)}) {
            push @{ $info->{removed} }, $1;
        }
        elsif (m{^M\t(.+)}) {
            push @{ $info->{modified} }, $1;
        }
        elsif (m{^    (.*)}) {
            $info->{message} .= $1 . "\n";
        }
    }
    chomp $info->{message};
    return $info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Hook::PostReceive - Parses git commit information in post-receive hook scripts

=head1 VERSION

version 0.3

=head1 SYNOPSIS

    # hooks/post-receive
    use Git::Hook::PostReceive;

    my @branches = Git::Hook::PostReceive->new->read_stdin;
    foreach my $payload (@branches) {

        $payload->{before};
        $payload->{after};

        for my $commit (@{ $payload->{commits} } ) {
            $commit->{id};
            $commit->{author}->{name};
            $commit->{author}->{email};
            $commit->{message};
            $commit->{date};
        }
    }

    # hooks/post-receive to send web hooks like GitHub
    use Git::Hook::PostReceive 0.2;
    use LWP::UserAgent;
    use JSON;

    my $ua = LWP::UserAgent->new;
    for (Git::Hook::PostReceive->new( utf8 => 1 )->read_stdin) {
        $ua->post( "http://example.org/webhook", { 'payload' => to_json($_) } );
    }

=head1 DESCRIPTION

Git::Hook::PostReceive parses git commit information in post-receive hook script.

All you need to do is pass each STDIN string to Git::Hook::PostReceive,
then it returns the commit payload for the particular branch.

This module does not use any non-core dependencies, so you can also
copy it to a location of your choice and directly include it.

To run the hook on an arbitrary git repository, set the C<GIT_WORK_TREE>
environment variable.

=head2 payload format

The payload format returned by method C<read_stdin> or C<run> is compatible with
L<https://help.github.com/articles/post-receive-hooks|GitHub Post-Receive Hooks>
with some minor differences:

    {
        before  => $commit_hash_before,
        after   => $commit_hash_after,
        ref     => $ref,
        created => $whether_new_branch,      # 1|0 in contrast to true|false
        deleted => $whether_branch_removed,  # 1|0 in contrast to true|false
        commits => [
            id        => $hash,
            message   => $message,
            timestamp => $date,
            author    => {
                email => $email,
                name  => $name
            },
            commiter  => {
                email => $email,
                name  => $name
            },
            added     => [@added_paths],
            removed   => [@deleted_paths],
            modified  => [@modified_paths],
        ],
        repository => $directory,           # in contrast to detailed object
    }

C<before> is set to <0000000000000000000000000000000000000000> and C<created>
is set to C<1> (C<0> otherwise) when a new branch has been pushed. C<after> is
set to <0000000000000000000000000000000000000000> and C<deleted> is set to C<1>
(C<0> otherwise) when a branch has been deleted.

=head1 CONFIGURATION

=over 4

=item utf8

Git does not know about character encodings, so the payload will consists of
raw byte strings by default.  Setting this configuration value to a true value
will decode all payload fields as UTF8 to get Unicode strings.

=back

=head1 METHODS

=head2 read_stdin( [ @lines ] )

Read one or more lines as passed to a git post-receive hook. One can pass
arrays of lines or strings that are split by newlines. Lines are read from
STDIN by default.

=head2 run( $before, $after, $ref )

Return a payload for the commits between C<$before> and C<$after> at branch
C<$ref>. Returns undef on failure.

=head2 detect_action($before, $after)

This function detects the action of the receiving commits and return the action
name with the related commit hash in a hashref.

C<0000000000> at the head means "branch created".

C<0000000000> at the end means "branch deleted".

Otherwise it means "commits pushed".

=head2 SEE ALSO

L<Git::Repository>, L<Plack::App::GitHub::WebHook>

=head1 CONTRIBUTORS

=over 4

=item *

Jakob Voss <voss@gbv.de>

=item *

Yo-An Lin <cornelius@cpan.org>

=back

=head1 AUTHOR

Yo-An Lin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yo-An Lin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
