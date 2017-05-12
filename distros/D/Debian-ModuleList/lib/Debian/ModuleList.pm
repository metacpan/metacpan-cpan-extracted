package Debian::ModuleList;

use IPC::Open3;
use File::Temp qw/tempdir/;
use File::Spec;
use IO::All;

our $VERSION = '0.01';

sub list_modules {
    die("apt-file is not installed") if ( !-x "/usr/bin/apt-file" );

    my $out;
    my $dir = tempdir( CLEANUP => 1 );
    my $sources = File::Spec->catfile( $dir, "sources.list" );
    "deb http://ftp.us.debian.org/debian/ sid main contrib non-free\n" >
      io($sources);
    system( "apt-file", "-c", $dir, "-s", $sources, "update" );
    my $pid = open3(
        undef, $out,     undef, "apt-file", "-c", $dir,
        "-s",  $sources, "-x",  "search",   '.*\.pm$'
    );
    my @array;
    push @array, $_ while (<$out>);
    waitpid( $pid, 0 );

    foreach (@array) {
        chomp $_;
        my $index = index( $_, ": " );
        my ( $package, $file );
        $package = substr( $_, 0, $index );
        $file = substr( $_, $index + 2 );
        my $matching = "";
        foreach (@INC) {
            $_ .= "/" if ( !( $_ =~ /\/$/ ) );
            $matching = $_ if ( substr( $file, 0, length($_) ) eq $_ );
        }
        next if ( !length($matching) );
        my $module = $file;
        $module =~ s/$matching//;
        $module =~ s/\.pm$//;
        $module =~ s/\//::/g;
        push @list, $module;

        #  print "Package: " . $package . "\n";
        #  print "Module: " . $module . "\n";
    }

    my %hash;
    @hash{@list} = ();
    @list = sort keys %hash;

    return @list;

}

=head1 NAME

Debian::ModuleList - list the modules in Debian

=head1 DESCRIPTION

This requires apt-file to be installed.

    use Debian::ModuleList;
    my @list = Debian::ModuleList::list_modules();
=cut

1;
