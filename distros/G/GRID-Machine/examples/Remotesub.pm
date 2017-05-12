package GRID::Machine;
use strict;
use POSIX qw( uname );

sub maketest {
    my $dist = shift;

    my @remote_name = uname();

    die "File $dist was not found" unless -r $dist;
    system("tar xzf $dist") and die "Can't execute tar xzf $dist";

    my $dir = $dist;
    $dir =~ s{\.tar\.gz$}{};
    print "\n**********$dir**********\n";
    #chdir($dir);
    #print $ENV{PWD};
    system(<<"EOF") or die "Can't build Makefile";
      cd $dir
      perl Makefile.PL
EOF
}

1;

