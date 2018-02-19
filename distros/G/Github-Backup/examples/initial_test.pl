use warnings;
use strict;

use Data::Dumper;
use Git::Repository;
use File::Copy qw(move);
use File::Path qw(rmtree);
use LWP::UserAgent;
use Pithub;

if (! $ENV{TOKEN}){
    die "\$ENV{TOKEN} must be set with your Github API token.\n";
}

my $user = 'stevieb9';
my $token = $ENV{TOKEN};
my $bak = 'backups';
my $stg = 'backups.stg';

$ENV{http_proxy} = 'http://10.0.0.4:80';
$ENV{https_proxy} = 'http://10.0.0.4:80';

my $ua = LWP::UserAgent->new;
$ua->env_proxy;

my $gh = Pithub->new(
    ua => $ua,
    user => $user,
    token => $token
);

my $result = $gh->repos->list(user => $user);

my @repos;

while (my $row = $result->next){
    push @repos, $row->{name};
}

# prepare the staging dir

if (-d $stg){
    rmtree $stg or die $!;
    mkdir $stg or die $!;
}

for (@repos){

    my $content = $gh->repos()
              ->get(user => $user, repo => $_)
              ->content;

    if (! exists $content->{parent}){
        print "backing up $content->{full_name}...\n";

        Git::Repository->run(
            clone => $content->{clone_url} => "$stg/$content->{name}",
            { quiet => 1}
        );
    }
}

# move staging into the backup dir

if (-d $bak){
    rmtree $bak or die $!;
}

move $stg, $bak or die $!;
