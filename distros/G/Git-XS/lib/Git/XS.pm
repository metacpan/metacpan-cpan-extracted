##
# name:      Git::XS
# abstract:  Perl XS binding to libgit2
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.010;
use strict;
use warnings;
use Mo 0.30 ();
use XS::Object::Magic 0.04 ();

package Git::XS;
use Mo qw'default build required';

our $VERSION = '0.02';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub BUILD { shift->_build }

has repo => ( required => 1 );

sub init {
    my $self = shift;
    my $bare = (@_ and shift eq -bare) ? 1 : 0;
    croak("Invalid arguments passed to init") if @_;
    $self->_init($bare);
}

sub _repo_exists {
    my $self = shift;
    my $repo = shift;
    return -f "$repo/.git/conf" ? 1 : 0;
}

1;

=head1 SYNOPSIS

    use Git::XS;

    my $git = Git::XS->new(
        repo => "path/to/git/repo",
    );

    $git->init;
    
    print $git->status;

    $git->add('file.name');

    $git->commit(-m => 'It works');

    $git->fetch;

    $git->push('--all');

=head1 STATUS

WARNING: This module is still in the "proof of concept" phase. Come back
later.

So far new() and init() are working. Kind of.

Find me online if you have good ideas for this module.

=head1 DESCRIPTION

This module is a Perl binding to libgit2. It attempts to make a clean OO API
for dealing with git repositories from Perl. It should be very fast.

=head1 INSTALLATION

You can install this module like any other CPAN module, but you will need 2
programs in your PATH:

    git - to clone the libgit2 repository from GitHub
    cmake - to build libgit2

In the future, this module might use your system's copy of libgit2.

=head1 METHODS

=over

=item Git::XS->new(repo => $repo)

Create a new Git::XS object for dealing with a git repository.

=item $git->init([-bare])

Initialize a repo if it doesn't exist. You can pass '-bare' to create a bare
repo.
