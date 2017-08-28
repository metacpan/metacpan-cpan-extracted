package MYDan::Collector::Stat::Output;

use strict;
use warnings;
use Carp;
use POSIX;
use File::Spec;
use FindBin qw( $RealBin );
use Digest::MD5;
use MYDan::Collector::Util;

our $path = "$RealBin/../exec";

sub co
{
    my ( $this, @output, @stat, %output ) = @_;

    push @stat, [ 'OUTPUT', 'stdout', 'md5sum', 'exit' ];

    map{ $output{$1} = 1 if $_ =~ /^\{OUTPUT\}\{([^}]+)\}/ }@output;

    for my $output ( keys %output )
    {
        my $todo = $output;

        if( $output =~ /^(.+)::(\w{32})::$/ )
        {
            my ( $cmd, $md5, $sudo ) = ( $1, $2 );
            $sudo = $1 if $cmd =~ s/^(\w+)://;

            if ( $cmd !~ /^\// )
            {
                unless( $path ) { warn "[WARN]undef path for exec.\n"; next; }
                $cmd = File::Spec->join( $path, $cmd );
            }

            unless ( $cmd ){ warn"[WARN]no command defined on $output.\n"; next; }
            unless ( -x $cmd ){ warn"[WARN]$cmd is not an executable file.\n"; next; }

            my $filemd5 = MYDan::Collector::Util::qx( "md5sum '$cmd'" );
            unless( $filemd5 =~ /^(\w{32})\s+$cmd$/ )
            {
                warn"[WARN]get $cmd md5 fail.\n";next;
            }
            $filemd5 = $1;

            if( $md5 ne $filemd5 )
            {
                warn"[WARN] $output MD5 comparison failed <> $filemd5\n";next;
            }

            $todo = $sudo ? "sudo -u $sudo $cmd" : $cmd;
        }

        my $stdout = MYDan::Collector::Util::qx( "$todo 2>&1" );
        my $exit = $? == -1 ? -1 : $? >> 8;
	my $md5sum = Digest::MD5->new()->add( $stdout ||'' )->hexdigest();
        push @stat, [ $output, $stdout, $md5sum, $exit ];
    }

    return \@stat;
}

1;
