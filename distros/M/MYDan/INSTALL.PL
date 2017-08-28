use strict;
use warnings;
use FindBin qw( $Bin $RealBin );
use Tie::File;

exit 0 unless $ENV{dan} || $ENV{box};

my @p = split /\//, $RealBin; pop @p;

die "path no in mydan" unless $p[-1] eq 'mydan';

my $mydan = join '/', @p;


my $perl = $ENV{PERL_PATH} || $^X;
my $cpan = $perl;$cpan =~ s/perl$/cpan/;
$cpan = $ENV{cpan} unless -f $cpan;
die "no find cpan" unless -f $cpan;

sub mysystem
{
    my $cmd = shift;
    die "$cmd fail:$!" if system $cmd;
}

sub repl
{
    my $type = shift;
    for my $file ( `find $type -type f` )
    {
        chomp $file;
        tie my ( @file ), 'Tie::File', $file;
    
        next unless @file && $file[0] =~ /#![^#]*perl(.*$)/o;
        $file[0] = "#!$perl$1";
        warn "$file\n";
        untie @file;
    }
}

sub insl
{
   
    print '#' x 30, " check module ", '#' x 30, "\n";
   
    map{
        $_ =~ s/'//g;
        if( system "$perl -e \"use $_\" >/dev/null 2>&1" )
        {
            print "install $_\n";
            mysystem( "$cpan install $_" );
        }
        else { print "$_=> ok.\n"; }
        print '-' x 74, "\n";
    }@_;
    
}

if( $ENV{dan} )
{
    mysystem "rsync -a dan/ dan.i/";
    repl( 'dan.i' );
    mysystem "rsync -a dan.i/ '$mydan/dan/'";

    my %m;
    tie my ( @file ), 'Tie::File', 'Makefile.PL';
    map{ $m{$1} = 1 if $_ =~ /\s+'?([:\w]+)'? => [\d\.]+/ }@file;
    untie @file;

    insl( keys %m );   
}

if( $ENV{box} )
{

    mysystem "rsync -a box/ box.i/";
    mysystem "rsync -a dan/node/ box.i/node/";
    map { mysystem "rsync -a dan/tools/$_ box.i/tools/" } qw(range mcmd mssh expect vssh go mrsync);
    
    my %sed = (
        'box.i/tools/vssh' => [ 'MYDan::VSSH::Execute::dan=1', 'MYDan::VSSH::Execute::dan=0' ],
        'box.i/tools/mrsync' => [ 'MYDan::Agent::Mrsync', 'MYDan::Util::Mrsync' ],
    );

    while( my ( $f, $s ) = each %sed )
    {
        tie my ( @file ), 'Tie::File', $f;
        map{ s/$s->[0]/$s->[1]/g }@file;
        untie @file;
    }

    repl( 'box.i' );
    mysystem "rsync -a box.i/ '$mydan/box/'";

    unless( $ENV{dan} )
    {
         my %m;
         tie my ( @file ), 'Tie::File', 'Makefile.PL';
         map{ $m{$1} = 1 if $_ =~ /\s+'?([:\w]+)'? => [\d\.]+,\s*#box/ }@file;
         untie @file;

         insl( keys %m );
    }
}

mysystem( "rsync -av def/ ../" ) if $ENV{def};

exit 0;
