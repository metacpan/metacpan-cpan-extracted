package GitTestUtils;
use warnings;
use strict;
use String::Random;
use base qw(Exporter);
our @EXPORT_OK = qw(create_repo mk_commit);

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);

sub create_repo {
    my $path = shift;;
    rmtree [ $path ] if -e $path;
    mkpath [ $path ] if ! -e $path;
    chdir $path;
    Git::command('init');
    return $path;
}

sub mk_commit {
    my ($re,$file,$line) = @_;
    open FH , ">>" , $file or die $!;
    print FH $line;
    close FH;
    $re->repo->command( 'add' , $file );
    $re->repo->command( 'commit' , $file , '-m' , "'Add $line'" );
}

1;
