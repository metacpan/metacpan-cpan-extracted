#!/usr/bin/perl -w

use strict;
use Embedix::DB;
use Getopt::Long;
use Pod::Usage;

# getopt
my %opt;
GetOptions (
    \%opt,
    "help|h",
    "database|d=s",
    "distro=s",
    "board=s",
);

my $distro = $opt{distro} || "Embedix 1.2";
my $board  = $opt{board}  || "generic";

# help
pod2usage(-verbose => 1, -output => \*STDOUT) if (defined $opt{help});

# init
my $dbname = $opt{database} || 'embedix';

my $edb = Embedix::DB->new (
    backend => 'Pg',
    source  => [
        "dbi:Pg:dbname=$dbname", undef, undef,
        { AutoCommit => 0 }
    ],
);
$edb->workOnDistro(name => $distro, board => $board);

# clone
foreach (@ARGV) {
    eval { $edb->cloneDistro(board => $_) };
    print "$_ ";
    print "not " if ($@);
    print "ok\n";
}

exit 0;

__END__

=head1 NAME

edb_clone.pl - clone the nodes of a distribution

=head1 SYNOPSIS

edb_clone.pl [OPTION]... [CLONE]...

=head1 OPTIONS

=over 4

=item --help | -h

Print this help message

=item --database

defaults to "embedix".  Specify the database to use.

=item --distro distro

defaults to "Embedix 1.2".  Specify the distro to clone.

=item --board base_board

defaults to "generic".  Specify the board to clone.

=back

=cut
