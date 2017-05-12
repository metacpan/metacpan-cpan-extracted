package MyBuilder;
use base 'Module::Build';
use warnings;
use strict;

use autodie;

use Math::Matrix::MaybeGSL 0.005;
use Data::Dumper;

sub ACTION_code {
    my $self = shift;

    die "Can not find share dir..." unless -d "share";

    $self->SUPER::ACTION_code;

    $self->dispatch("prepare_features")
      if ! -f "share/features.lst" || -M "share/features.lst" > -M "data/features.dmp";

    $self->dispatch("prepare_classes")
      if ! -f "share/classes.lst"  || -M "share/classes.lst"  > -M "data/classes.dmp";

    $self->dispatch("prepare_thetas")
      if ! -f "share/theta-01.dat" || -M "share/theta-01.dat" > -M "data/thetas.dat";

}

sub ACTION_prepare_thetas {
    my $self = shift;

    print STDERR "Munging some data...";

    open my $fh, "<", "data/thetas.dat";

    # skip comments
    my $line = <$fh>;
    $line = <$fh> while $line =~ /^\s*#/;

    # first line is the number of layers
    chomp(my $nr_layers = $line);

    # then we have the arch
    my @arch;
    for (1..$nr_layers) {
        chomp($line = <$fh>);
        $arch[$_] = $line;
    }

    ## Load and save matrices
    for my $l (1 .. $nr_layers-1) {
        my $m = Matrix->new($arch[$l+1], $arch[$l]+1);
        for my $c (1 .. $arch[$l]+1) {
            for my $r (1 .. $arch[$l+1]) {
                chomp($line = <$fh>);
                $m->assign($r, $c, $line);
            }

            print STDERR "." unless $c % 100;  ## show some progress
        }
        $m->write(sprintf("share/theta-%02d.dat", $l));
    }

    print STDERR "done\n";
}

sub ACTION_prepare_classes {
    my $self = shift;

    open my $fh, "<:utf8", "data/classes.lst";

    my $classes;
    ### We expect them to be ordered, consecutive, starting at 1
    while (<$fh>) {
        chomp;
        my ($id, $class) = split /\s+/;
        push @$classes, $class;
    }

    close $fh;

    open $fh, ">:utf8", "share/classes.dmp";
    print $fh "use utf8;\n";
    print $fh Dumper($classes);
    close $fh;

}

sub ACTION_prepare_features {
    my $self = shift;

    open my $fh, "<:utf8", "data/features.lst";

    my $features;
    while (<$fh>) {
        chomp;
        push @$features, $_;
    }

    close $fh;

    open $fh, ">:utf8", "share/features.dmp";
    print $fh "use utf8;\n";
    print $fh Dumper($features);
    close $fh;
}




1;
