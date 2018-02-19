package Github::Backup;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Git::Repository;
use File::Copy;
use File::Path;
use JSON;
use LWP::UserAgent;
use Moo;
use Pithub;

use namespace::clean;

our $VERSION = '1.02';

# external

has api_user => (
    is => 'rw',
);
has _clean => (
    # used to clean up test backup directories
    is => 'rw',
);
has dir => (
    is => 'rw',
);
has forks => (
    is => 'rw',
);
has token => (
    is => 'rw',
);
has proxy => (
    is => 'rw',
);
has user => (
    is => 'rw',
);

# internal

has gh => (
    # Pithub object
    is => 'rw',
);
has stg => (
    # staging dir
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;

    if (! $self->token){
        $self->token($ENV{GITHUB_TOKEN}) if $ENV{GITHUB_TOKEN};
    }

    for ($self->api_user, $self->token, $self->dir){
        if (! $_){
            croak "When instantiating an object, the 'api_user', 'token' and " .
                  "'dir' parameters are mandatory...\n";
        }
    }

    my $ua = LWP::UserAgent->new;

    if ($self->proxy){
        $ENV{http_proxy} = $self->proxy;
        $ENV{https_proxy} = $self->proxy;

        $ua->env_proxy;
    }

    my $gh = Pithub->new(
        ua => $ua,
        user => $self->api_user,
        token => $self->token
    );

    $self->stg($self->dir . '.stg');
    $self->gh($gh);

    $self->user($self->api_user) if ! defined $self->user;

    if (-d $self->stg){
        rmtree $self->stg or die "can't remove the old staging directory...$!";
    }

    mkdir $self->stg or die "can't create the backup staging directory...$!\n";

}
sub repos {
    my ($self) = @_;

    my $repo_list = $self->gh->repos->list(user => $self->user);

    my @repos;

    while (my $repo = $repo_list->next){
        push @repos, $repo;
    }

    for my $repo (@repos){

        my $stg = $self->stg . "/$repo->{name}";

        if (! $self->forks){
            if (! exists $repo->{parent}){
                Git::Repository->run(
                    clone => $repo->{clone_url} => $stg,
                    {quiet => 1}
                );
            }
        }
        else {
             Git::Repository->run(
                clone => $repo->{clone_url} => $stg,
                { quiet => 1 }
            );
        }
    }
}
sub issues {
    my ($self) = @_;

    mkdir $self->stg . "/issues" or die "can't create the 'issues' dir: $!";

    my $repo_list = $self->gh->repos->list(user => $self->user);

    while (my $repo = $repo_list->next){
        my $issue_list = $self->gh->issues->list(
            user => $self->user,
            repo => $repo->{name}
        );

        my $issue_dir = $self->stg . "/issues/$repo->{name}";


        my $dir_created = 0;

        while (my $issue = $issue_list->next){
            if (! $dir_created) {
                mkdir $issue_dir or die $!;
                $dir_created = 1;
            }
            open my $fh, '>', "$issue_dir/$issue->{id}"
                or die "can't create the issue file";

            print $fh encode_json $issue;
        }
    }
}
sub DESTROY {
    my $self = shift;

    if ($self->dir && -d $self->dir) {
        rmtree $self->dir or die "can't remove the old backup directory: $!";
    }

    if ($self->stg && -d $self->stg) {
        move $self->stg,
            $self->dir or die "can't rename the staging directory: $!";
    }

    if ($self->dir && -d $self->dir && $self->_clean) {
        # we're in testing mode, clean everything up
        rmtree $self->dir
            or die "can't remove the test backup directory...$!";
    }
}

1;
__END__

=head1 NAME

Github::Backup - Back up your Github repositories and/or issues locally

=head1 SYNOPSIS

    github_backup \
        --user stevieb9 \
        --token 003e12e0780025889f8da286d89d144323c20c1ff7 \
        --dir /home/steve/github_backup \
        --repos \
        --issues

    # You can store the token in an environment variable as opposed to sending
    # it on the command line

    export GITHUB_TOKEN=003e12e0780025889f8da286d89d144323c20c1ff7

    github_backup -u stevieb9 -d ~/github_backup -r

=head1 DESCRIPTION

The cloud is a wonderful thing, but things do happen. Use this distribution to
back up all of your Github repositories and/or issues to your local machine for
both assurance of data accessibility due to outage, data loss, or just simply
off-line use.

=head1 COMMAND LINE USAGE

=head2 -u | --user

Mandatory: Your Github username.

=head2 -t | --token

Mandatory: Your Github API token. If you wish to not include this on the
command line, you can put the token into the C<GITHUB_TOKEN> environment
variable.

=head2 -d | --dir

Mandatory: The backup directory where your repositories and/or issues will be
stored. The format of the directory structure will be as follows:

    backup_dir/
        - issues/
            - repo1/
                - issue_id_x
                - issue_id_y
            - repo2/
                - issue_id_a
        - repo1/
            - repository data
        - repo2/
            - repository data

The repositories are stored as found on Github. The issues are stored in JSON
format.

=head2 -r | --repos

Optional: Back up all of your repositories found on Github.

Note that either C<--repos> or C<--issues> must be sent in.

=head2 -i | --issues

Optional: Back up all of your issues across all of your Github repositories.

Note that either C<--issues> or C<--repos> must be sent in.

=head2 -p | --proxy

Optional: Send in a proxy in the format C<https://proxy.example.com:PORT> and
we'll use this to do our fetching.

=head2 -h | --help

Display the usage information page.

=head1 MODULE METHODS

=head2 new

Instantiates and returns a new L<Github::Backup> object.

Parameters:

=head3 api_user

Mandatory, String: Your Github username.

=head3 token

Mandatory, String: Your Github API token. Note that if you do not wish to store
this in code, you can put it into the C<GITHUB_TOKEN> environment variable,
and we'll read it in from there instead.

=head3 dir

Mandatory, String: The directory that you wish to store your downloaded Github
information to.

=head3 proxy

Optional, String: Send in a proxy in the format
C<https://proxy.example.com:PORT> and we'll use this to do our fetching.

=head2 repos

Takes no parameters. Backs up all of your Github repositories, and stores them
in the specified backup directory.

=head2 issues

Takes no parameters. Backs up all of your Github issues. Stores them per-repo
within the C</backup_dir/issues> directory.

=head1 FUTURE DIRECTION

- Slowly, I will add new functionality such as backing up *all* Github data, as
well as provide the ability to restore to Github the various items.

- Add more tests. Usually I don't release a distribution with such few tests,
but in this case I have. I digress.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017,2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

