use utf8;
package Dist::Zilla::Plugin::Git::PushInitial;
BEGIN {
  $Dist::Zilla::Plugin::Git::PushInitial::AUTHORITY = 'cpan:RKITOVER';
}
{
  $Dist::Zilla::Plugin::Git::PushInitial::VERSION = '0.02';
}

use 5.008001;
use Moose;
use MooseX::Types::Moose qw/Str Undef/;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use Try::Tiny;

with 'Dist::Zilla::Role::AfterMint';

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::PushInitial - do initial git push from your minting profile

=head1 SYNOPSIS

In your profile.ini:

    [Git::Init]

    [GitHub::Create]
    repo   = {{ lc $dist->name }}
    prompt = 1

    [Git::PushInitial]
    remote = origin # default

=head1 DESCRIPTION

This module is only of interest to authors of L<Dist::Zilla> minting profiles.

After minting a new dist with L<Git::Init|Dist::Zilla::Plugin::Git::Init> and
setting remote information with e.g.
L<GitHub::Create|Dist::Zilla::Plugin::GitHub::Create>, if C<push.default> is
not configured or set at the default value (C<tracking>), or an older git is
being used, it is necessary to create the branch on the remote before a simple
C<git push>, done by e.g. L<Git::Push|Dist::Zilla::Plugin::Git::Push> will work
on C<dzil release>.

Using this plugin in your minting profile should save the users of your minting
profile the step of doing a manual push, regardless of their git config. They
can just commit and do a C<dzil release>, assuming they are using
L<Git::Push|Dist::Zilla::Plugin::Git::Push> in their dist.ini.

It runs this command:

    git push <remote> <current-branch>

remote defaults to 'origin' but can be specified as a parameter to this plugin.

=head1 PARAMETERS

=head2 remote

The remote to push to, default is C<origin>.

=cut

has remote => (is => 'ro', isa => Str|Undef, default => 'origin');

sub after_mint {
    my ($self, $opts) = @_;

    my $root = $opts->{mint_root};

    if (not -e catdir($root, '.git')) {
        $self->log('Not a git repo, bailing out');
        return;
    }

    my $git = Git::Wrapper->new($root);

    my (@remotes) = try { $git->remote };

    if (not (grep $_ eq $self->remote, @remotes)) {
        $self->log("Remote '".$self->remote."' does not exist, bailing out");
        return;
    }

    my ($branch) = try {
        $git->rev_parse({ abbrev_ref => 1, symbolic_full_name => 1 }, 'HEAD')
    };

    if (not $branch) {
        $self->log('No branch found, bailing out');
        return;
    }

    my $error;

    my $pushed = try {
        $git->push($self->remote, $branch); 1;
    }
    catch {
        $error = $_; 0;
    };

    if (not $pushed) {
        $self->log("Error pushing branch '$branch': $error");
        return;
    }

    $self->log("Pushed '$branch' to '".$self->remote."' successfully.");
}

=head1 SEE ALSO

=over 4

=item * L<Minting Profiles Tutorial|http://dzil.org/tutorial/minting-profile.html>

=item * L<Dist::Zilla::Plugin::Git::Init>

=item * L<Dist::Zilla::Plugin::GitHub::Create>

=item * L<Dist::Zilla::Plugin::Git::Push>

=item * L<Dist::Zilla::MintingProfile::Author::Caelum>

=back

=head1 ACKNOWLEDGEMENTS

Some code/ideas stolen from Alessandro Ghedini's
L<Dist::Zilla::Plugin::GitHub::Create>.

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=cut

__PACKAGE__; # End of Dist::Zilla::Plugin::Git::PushInitial
