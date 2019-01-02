package MYDan::Agent::Grsync::V4;

=head1 NAME

MYDan::Util::Grsync::V4 - Replicate data via phased agent

=cut

use base MYDan::Agent::Grsync;

use strict;
use warnings;

use Carp;
use YAML::XS;
use MYDan;
use MYDan::Agent::Mrsync;
use MYDan::Agent::Load;
use MYDan::Agent::Client;

sub run
{
    my ( $this, %o ) = @_;

    my %task = %{$this->{task}};
    map{ $task{$_} = +{} }qw( src dst );

    for my $n ( qw( sync todo ) )
    {
        next unless $task{$n} && ref $task{$n} eq 'ARRAY';
        map{ 
            map{$task{src}{$_} ++ }@{$_->{src}} if $_->{src};
            map{$task{dst}{$_} ++ }@{$_->{dst}} if $_->{dst};
        }@{$task{$n}};
    }

    my %path = map { $_ => delete $o{$_} } qw( sp dp );
    $path{dp} ||= $path{sp};

    my $argv = sub
    {
        delete $ENV{MYDanExtractFile};
        delete $ENV{MYDanExtractFileAim};

        my $code = File::Spec->join( $this->{agent}{argv}, shift );
        return -f $code && ( $code = do $code ) && ref $code eq 'CODE'
            ? &$code( @_ ) : \@_;
    };
 
    my ( $load, $loadok );
    $task{load} = [ keys %{$task{src}} ];
    if( @{$task{load}} )
    {
        my $path = "$MYDan::PATH/tmp";
        unless( -d $path ){ mkdir $path;chmod 0777, $path; }
        $path .= '/grsync.data.';
        for my $f ( grep{ -f } glob "$path*" )
        {
            my $t = ( stat $f )[9];
            unlink $f if $t && $t < time - 86400;
        }

        $load  = $path. Digest::MD5->new->add( time.$$ )->hexdigest;

        for ( 0 .. $o{retry} )
        {
            my $i = int( rand time ) % @{$task{load}};
            my $host = $task{load}[$i];
            print "$host => localhost: LOAD\n";

            delete $ENV{MYDanExtractFile};
            delete $ENV{MYDanExtractFileAim};
            eval{
                MYDan::Agent::Load->new(
                    node => $host,
                    sp => $path{sp}, dp => $load,
                )->run( %{$this->{agent}}, %o, 
                    ( defined $o{cc} ) ? () 
		            : ( 'chown' => undef, 'chmod' => undef ) 
		        );
 
            };

            my $stat = $@ ? "FAIL $@" : 'OK';
            print "$host <= localhost: $stat\n";
            if( $stat eq 'OK' )
            {
                $loadok = 1;
                last;
            }

        }
    }

    my %dump = %{$task{dst}};
    if( %dump && ( ( !%{$task{src}} ) ||  $loadok  ) )
    {
        for ( 0 .. $o{retry} )
        {
            last unless keys %dump;

	        my @argv;
    	    map{ push( @argv, "--$_", $o{$_} ) if defined $o{$_} }qw( chown chmod );
	        push( @argv, "--cc" ) if $o{cc};

            my %query = ( 
                code => 'dump',
                argv => &$argv( 'dump',$load || $path{sp} , '--path', $path{dp}, @argv ),
                 map{ $_ => $o{$_} }qw( user sudo ) 
            );

            map{ print "localhost => $_: DUMP\n" }keys %dump;
            my %result = MYDan::Agent::Client->new(
                keys %dump
            )->run( %{$this->{agent}}, %o, query => \%query );

            map{ 
                my $stat = $result{$_} && $result{$_} eq "ok\n--- 0\n" 
                    ? 'OK' : sprintf "Fail: %s", $result{$_} || 'error';
                print "$_ <= localhost: $stat\n";
                delete $dump{$_} if $stat eq 'OK' 
            }keys %dump;
        }
    }

    unlink $load if $load && -f $load;

    $this->{failed} = [ keys %dump ];
    return $this;
}

1;
