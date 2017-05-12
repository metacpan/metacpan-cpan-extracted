#!/usr/bin/perl -w

# to prevent future headaches, and to show I'm disciplined
use strict;

# for benchmarking
use Benchmark;

# for loading ECD data from files
use Embedix::ECD;

# for adding ECD data to a database
use Embedix::DB;

# for command line args
use Getopt::Long;

# for objectified filehandles
use IO::File;

# for the help message
use Pod::Usage;

# for globals
use vars qw($fucked_up $log_fh $err_fh);

$fucked_up = undef;

# header
sub print_header {
    my $format = '%7s|%7s|%7s|%7s| %s' . "\n";
    printf $log_fh ($format, 'bytes', 'usr', 'sys', 'cpu', 'ecd');
    print $log_fh '-' x 78;
    print $log_fh "\n";
}

# stats in beppu-readable form
sub print_entry {
    my $time     = shift;
    my $filename = shift;
    my $comment  = ($fucked_up) 
        ? "$filename (" . substr($fucked_up, 0, 3) . ")" 
        : $filename;
    my $size     = (stat($filename))[7];
    my $format   = '%7s|%7.2f|%7.2f|%7.2f| %s' . "\n";

    if ($fucked_up) {
        print $err_fh "$fucked_up\n";
        $fucked_up = undef;
    }

    printf $log_fh (
        $format, 
        $size, 
        $time->[1], 
        $time->[2],
        $time->[1] + $time->[2],
        $comment
    );
}

# return a closure that will add an ECD to the database
sub updater {
    my %opt = @_;
    my $filename = $opt{filename};
    my $edb      = $opt{edb};

    return sub {
        my $ecd;
        my $size = (stat($filename))[7];
        printf $err_fh ("> %7d $filename\n", $size, $filename);

        eval { $ecd = Embedix::ECD->newFromFile($filename) };
        if ($@) {
            $fucked_up = "ECD failure: $@";
            return;
        }
        unless ($ecd->hasChildren) {
            $fucked_up = "ECD failure: ECD is empty";
            return;
        }

        eval { $edb->updateDistro(ecd => $ecd) };
        if ($@) {
            $fucked_up = "EDB failure: $@";
            return;
        }
    }
}

# return a filehandle
sub fh_for_file {
    my $filename = shift;
    my $fh = IO::File->new("> $filename");
    $fh->autoflush(1);
    return $fh;
}



# XXX the fun begins here XXX



# get options
my %opt;
GetOptions (
    \%opt,
    "help|h",
    "database|d=s",
    "distro=s",
    "board=s",
    "log=s",
    "errorlog=s",
    "sizelimit=i",
);

pod2usage(-verbose => 1, -output => \*STDOUT) if (defined $opt{help});

my $dbname    = $opt{database}  || 'embedix';
my $distro    = $opt{distro}    || 'Embedix 1.2';
my $board     = $opt{board}     || 'generic';
my $sizelimit = $opt{sizelimit} || 0;
$log_fh = $opt{'log'} 
    ? fh_for_file($opt{'log'}) 
    : *STDOUT;
$err_fh = $opt{errorlog}
    ? fh_for_file($opt{errorlog})
    : *STDERR;


# init database
my $edb = Embedix::DB->new (
    backend => 'Pg',
    source  => [
        "dbi:Pg:dbname=$dbname", undef, undef,
        { AutoCommit => 0 }
    ],
);

eval { $edb->workOnDistro(name => $distro, board => $board) };
if ($@) {
    $edb->addDistro(name => $distro, board => $board);
    $edb->workOnDistro(name => $distro, board => $board);
}


# insert and update like a madman
print_header;
foreach (@ARGV) {
    if ($sizelimit) {
        my $filesize = (stat($_))[7];
        if ($filesize > $sizelimit) {
            printf $err_fh (
                "> %7d $_ is too big\n", 
                $filesize,
                $_,
            );
            next;
        }
    }
    my $t = timeit(1, updater(edb => $edb, filename => $_));
    print_entry($t, $_);
}

exit 0;

__END__

=head1 NAME

edb_populate.pl - benchmarks insertion of ECD data into database

=head1 SYNOPSIS

syntax

    edb_populate.pl [OPTION]... [FILE]...

=head1 DESCRIPTION

this is a general overview of what I do

=head1 OPTIONS

=over 4

=item --database dbname

defaults to 'embedix' if none is given

=item --log filename

defaults to STDOUT

=item --errorlog filename

defaults to STDERR.  I recommend specifying at least this one, because
the output looks bad if mixed in on a tty w/ the normal --log output.

=item --distro name_of_distribution

defaults to "Embedix 1.2"  This is where the name of the distribution
you're working with should be specified.

=item --board hardware

defaults to "generic".  This is where the name of the platform you're
working with should be specified.  (ex. 'ppc', 'mpc8260adsp', 'sh4',
'i386');

=item --sizelimit bytes

This will reject an ECD if it is greater than the specified amount of
bytes.  Until I make myself a faster parser, I need this for practical 
reasons.

=back

=head1 REQUIRES

a lot of modules, the most important of which is Embedix::DB::Pg

=head1 SEE ALSO

stuff that relates to me

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=cut

# $Id: edb_populate.pl,v 1.4 2001/02/08 10:32:37 beppu Exp $
