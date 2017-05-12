package Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes;
$Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes::VERSION = '0.110';
# ABSTRACT: Generate valid CPAN::Changes Changelogs from git

use v5.10.1;
use Moose;
use Moose::Util::TypeConstraints;
use Class::Load 'try_load_class';
use CPAN::Changes::Release;
use CPAN::Changes 0.400002;
use DateTime;
use Encode;
use Git::Wrapper;

with qw/
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::FileGatherer
  Dist::Zilla::Role::Git::Repo
  /;

subtype 'CoercedRegexpRef' => as 'RegexpRef';

coerce 'CoercedRegexpRef' => from 'Str' => via {qr/$_[0]/};


has group_by_author => ( is => 'ro', isa => 'Bool', default => 0);


has show_author_email => ( is => 'ro', isa => 'Bool', default => 0);


has show_author => ( is => 'ro', isa => 'Bool', default => 1);


has tag_regexp => (
    is      => 'ro',
    isa     => 'CoercedRegexpRef',
    coerce  => 1,
    default => 'v?(\d+\.\d+(_\d+)?)'
);


has file_name => (is => 'ro', isa => 'Str', default => 'Changes');


has preamble => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Str',
    default => sub { 'Changelog for ' . $_[0]->zilla->name },
);


has copy_to_root => (is => 'ro', isa => 'Bool', default => 1);


has edit_changelog => (is => 'ro', isa => 'Bool', default => 0);

has _changes => (is => 'ro', lazy_build => 1, isa => 'CPAN::Changes');
has _last_release => (is => 'ro', lazy_build => 1, isa => 'Maybe[version]');
has _tags => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

has _git => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Git::Wrapper',
    default => sub { Git::Wrapper->new('.') },
);

has _git_can_mailmap => (
    is      => 'ro',
    lazy    => 1,
    isa     => 'Bool',
    default => sub {
        my ($gv) = $_[0]->git->version =~ /(\d+\.\d+\.\d+)/;
        $gv //= 0;
        return version->parse($gv) < '1.8.2' ? 0 : 1;
    },
);

sub BUILDARGS {
    my %args = %{$_[1]};

    if (exists $args{tag_regexp}) {
        if ($args{tag_regexp} eq 'semantic') {
            $args{tag_regexp} = 'v?(\d+\.\d+\.\d+)';
        } elsif ($args{tag_regexp} eq 'decimal') {
            $args{tag_regexp} = 'v?(\d+\.\d+)$';
        }
    }

    return \%args;
}

sub _build__changes {
    my $self = shift;

    my $changes;
    my @args = (preamble => $self->preamble);

    if (-f $self->file_name) {
        $self->logger->log_debug('Starting from an existing changelog');
        $changes = CPAN::Changes->load($self->file_name, @args);
    } else {
        $self->logger->log_debug('Creating full changelog');

        # TODO maybe. If Changelog is new and this is the first release,
        # first entry should just be "First release"
        $changes = CPAN::Changes->new(@args);
    }

    return $changes;
}

sub _build__last_release {
    my $self = shift;

    my @releases = $self->_changes->releases;
    if (scalar @releases > 1) {
        my $last_release = version->parse($releases[-1]->version);
        $self->logger->log("Last release in changelog: $last_release");

        if (version->parse($self->zilla->version) == $last_release) {
            $last_release = $releases[-2]->version;
            $self->logger->log(
                "Last release is *this* release, using $last_release as last");
        }
        $last_release =~ $self->tag_regexp;
        if (!defined $1) {
            $self->logger->log_fatal(
                "Last release $last_release does not match tag_regexp");
        }
        return version->parse($1);
    }
    return;
}

sub gather_files {
    my $self = shift;

    $self->_get_tags;
    $self->_get_changes;

    my $content = $self->_changes->serialize;

    $self->log('Editing changelogs is disabled') if $ENV{NO_EDIT_CHANGES};

    if ($self->edit_changelog && !$ENV{NO_EDIT_CHANGES}) {
        if (try_load_class('Proc::InvokeEditor')) {
            my $edited_content = Proc::InvokeEditor->edit($content);
            my $new_changes    = CPAN::Changes->load_string($edited_content);
            $content = $new_changes->serialize;
        } else {
            $self->log(
                'Proc::InvokeEditor needs to be installed for editing changelogs'
            );
        }
    }

    my $file = Dist::Zilla::File::InMemory->new({
        content => $content,
        name    => $self->file_name,
    });

    $self->add_file($file);
}

# Will copy the the changelog into the root folder if C<copy_to_root> is enabled.
sub after_build {
    my ($self, $args) = @_;

    return unless $self->copy_to_root;

    my $build_file = $args->{build_root}->child($self->file_name);

    my $root_file = $self->zilla->root->child($self->file_name);
    $self->log_debug("Copying changes file from $build_file to $root_file");
    if (!-e $build_file) {
        $self->logger->log_fatal("Where is the changelog?");
    }
    $build_file->copy($root_file);

    return;
}

sub _get_tags {
    my $self = shift;
    $self->logger->log_debug(
        'Searching for tags matching ' . $self->tag_regexp);
    foreach my $tag ($self->_git->RUN('tag')) {
        next unless $tag =~ $self->tag_regexp;
        push @{$self->_tags}, $tag;
    }

    push @{$self->_tags}, 'HEAD';
    return;
}

sub _git_log {
    my ($self, $revs) = @_;

    # easier to read than just writing the string directly
    my $format = {
        author  => '%aN',
        date    => '%at',
        email   => '<%aE>',
        subject => '%s',
    };

    # commit has to come first
    my $format_str = 'commit:%H%n';
    while (my ($attr, $esc) = each %$format) {
        $format_str .= "$attr:$esc%n";
    }
    $format_str .= '<END COMMIT>%n';

    my $log_opts = {
        no_color => 1,
        format   => $format_str,
    };

    if ($self->_git_can_mailmap and $self->show_author) {
        $self->logger->log_debug('Using git mailmap');
        $log_opts->{'use-mailmap'} = 1;
    }

    my @out = $self->_git->RUN(
        log => $log_opts,
        $revs
    );

    my $commits;
    my $cur_commit;
    while (my $line = shift @out) {
        if ($line eq '<END COMMIT>') {
            $cur_commit = undef;
            shift @out;
            next;
        }

        if ($line =~ /^commit:(\w+)$/) {
            $cur_commit = $1;
            $commits->{$cur_commit}->{id} = $cur_commit;
            next;
        } elsif (!$cur_commit) {
            die 'Failed to parse commit id';
        }

        if ($line =~ /^(\w+):(.+)$/) {
            die 'WTF? Not currently in a commit?' if !$cur_commit;
            $commits->{$cur_commit}->{$1} = $2;
            next;
        }
    }

    if (!defined $commits) {
        $self->logger->log_debug("No commits found for $revs");
        return [{
                subject => "No changes found"
            }];
    }

    return [sort { $b->{date} <=> $a->{date} } values %$commits];
}

sub _get_release_date {
    my ($self, $tag) = @_;

    # TODO configurable date formats
    if ($tag eq 'HEAD') {
        return DateTime->now->iso8601;
    }

    # XXX 'max-count' => '1' doesn't work with Git::Wrapper, it becomes
    # just '--max-count'. File a bug!
    my @out = $self->_git->RUN(log => {format => '%ct', 1 => 1}, $tag);
    my $dt = DateTime->from_epoch(epoch => $out[0]);
    return $dt->iso8601;
}

sub _get_changes {
    my $self     = shift;
    my $last_tag = $self->_last_release;

    foreach my $tag (@{$self->_tags}) {
        my $rev = $last_tag ? "$last_tag..$tag" : $tag;
        $last_tag = $tag;

        my $version;
        if ($tag eq 'HEAD') {
            $version = $self->zilla->version;
        } else {
            $tag =~ $self->tag_regexp;
            if (!$1) {
                die sprintf
                  'Failed to get a match from tag_regexp: [%s] vs [%s]',
                  $version, $self->tag_regexp;
            }
            $version = $1;
        }

        $self->logger->log_debug("Tag $tag == Version $version");
        if ($self->_last_release) {
            if ($self->_last_release > version->parse($version)) {
                $self->logger->log_debug("Skipping previous release $version");
                next;
            } elsif ($self->_last_release == version->parse($version)) {
                $self->logger->log_debug("Skipping release $version");
                next;

            }
        }

        $self->logger->log_debug("Getting commits for $rev");
        my $commits = $self->_git_log($rev);

        my $release = CPAN::Changes::Release->new(
            version => $version,
            date    => $self->_get_release_date($tag),
        );

        my %seen;
        foreach my $commit (@$commits) {

            # TODO strip extra spaces and newlines
            # TODO convert * lists

            # weed out dupes
            chomp $commit->{subject};
            next if exists $seen{$commit->{subject}};
            $seen{$commit->{subject}} = 1;

            # ignore the auto-commits
            next if $commit->{subject} eq $tag;
            next if $commit->{subject} =~ /^Release /;
            next if $commit->{subject} =~ /^Merge (pull|branch)/;

            unless (utf8::is_utf8($commit->{subject})) {
                $commit->{subject} = Encode::decode_utf8($commit->{subject});
            }

            if ($self->show_author && exists $commit->{author}) {
                my $author = $commit->{author};

                if ($self->show_author_email) {
                    $author .= ' ' . $commit->{email};
                }

                unless (utf8::is_utf8($author)) {
                    $author = Encode::decode_utf8($author);
                }

                if ($self->group_by_author) {
                    my $group = $author;
                    $release->add_changes({group => $group},
                        $commit->{subject});
                } else {
                    $release->add_changes($commit->{subject} . " ($author)");
                }
            } else {
                $release->add_changes($commit->{subject});
            }
        }

        $self->_changes->add_release($release);
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers Alexandr Retout Shantanu Tim Tuomas Voss Bell Bhadoria Ciornii
Doug Hare Jakob Jormola Lisa

=head1 NAME

Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes - Generate valid CPAN::Changes Changelogs from git

=head1 VERSION

version 0.110

=head1 SYNOPSIS

 [ChangelogFromGit::CPAN::Changes]
 ; All options from [ChangelogFromGit] plus
 group_by_author       = 1 ; default 0
 show_author_email     = 1 ; default 0
 show_author           = 0 ; default 1
 edit_changelog        = 1 ; default 0

=head1 ATTRIBUTES

=head2 group_by_author

Whether to group commit messages by their author. This is the only way previous
versions did it. Defaults to no, and [ Anne Author ] is appended to the commit
message.

Defaults to off.

=head2 show_author_email

Author email is probably just noise for most people, but turn this on if you
want to show it [ Anne Author <anne@author.com> ]

Defaults to off.

=head2 show_author

Whether to show authors at all. Turning this off also
turns off grouping by author and author emails.

Defaults to on.

=head2 C<tag_regexp>

A regexp string which will be used to match git tags to find releases. If your
release tags are not compliant with L<CPAN::Changes::Spec>, you can use a
capture group. It will be used as the version in place of the full tag name.

Also takes C<semantic>, which becomes C<qr{^v?(\d+\.\d+\.\d+)$}>, and
C<decimal>, which becomes C<qr{^v?(\d+\.\d+)$}>.

Defaults to 'decimal'

=head2 C<file_name>

The name of the changelog file.

Defaults to 'Changes'.

=head2 C<preamble>

Block of text at the beginning of the changelog.

Defaults to 'Changelog for $dist_name'

=head2 C<copy_to_root>

When true, the generated changelog will be copied into the root folder where it
can be committed (possiby automatically by L<Dist::Zilla::Plugin::Git::Commit>)

Defaults to true.

=head2 C<edit_changelog>

When true, the generated changelog will be opened in an editor to allow manual
editing.

Defaults to false.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/issues>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes>
and may be cloned from L<git://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
