package MYDan::Collector::Stat::Exec;

use strict;
use warnings;
use Carp;
use POSIX;
use File::Spec;
use FindBin qw( $RealBin );
use MYDan::Collector::Util;

our $path = "$RealBin/../exec";

sub co
{
    my ( $this, @exec, @stat, %exec ) = @_;

    push @stat, [ 'EXEC', 'exit', 'stdout' ];

    map{ $exec{$1} = 1 if $_ =~ /^\{EXEC\}\{([^}]+)\}/ }@exec;

    for my $exec ( keys %exec )
    {
        my $todo = $exec;

        if( $exec =~ /^(.+)::(\w{32})::$/ )
        {
            my ( $cmd, $md5, $sudo ) = ( $1, $2 );
            $sudo = $1 if $cmd =~ s/^(\w+)://;

            if ( $cmd !~ /^\// )
            {
                unless( $path ) { warn "[WARN]undef path for exec.\n"; next; }
                $cmd = File::Spec->join( $path, $cmd );
            }

            unless ( $cmd ){ warn"[WARN]no command defined on $exec.\n"; next; }
            unless ( -x $cmd ){ warn"[WARN]$cmd is not an executable file.\n"; next; }
           
            my $filemd5 = MYDan::Collector::Util::qx( "md5sum '$cmd'" );
            unless( $filemd5 =~ /^(\w{32})\s+$cmd$/ )
            {
                warn"[WARN]get $cmd md5 fail.\n";next;
            }
            $filemd5 = $1;

            if( $md5 ne $filemd5 )
            {
                warn"[WARN] $exec MD5 comparison failed <> $filemd5\n";next;
            }

            $todo = $sudo ? "sudo -u $sudo $cmd" : $cmd;
        }

        push @stat, [ $exec, MYDan::Collector::Util::system_qx( $todo ) ];
    }

    return \@stat;
}

1;
