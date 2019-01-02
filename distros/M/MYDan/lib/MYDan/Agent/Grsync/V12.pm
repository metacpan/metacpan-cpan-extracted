package MYDan::Agent::Grsync::V12;

=head1 NAME

MYDan::Util::Grsync::V1 - Replicate data via phased agent

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

    my %path = map { $_ => delete $o{$_} } qw( sp dp );
    $path{dp} ||= $path{sp};

    $MYDan::Agent::Mrsync::queryx = MYDan::Agent::Mrsync::queryx( 
	    node => [ keys %{$this->{proxy}} ], 
	    map{ $_ => $o{$_} }qw( user sudo )
    ) if delete $o{2};
    delete $o{1};

    my %failed;
    if( $task{sync} )
    {
        for my $sync ( @{$task{sync}} )
        {
	    next unless @{$sync->{dst}};
            delete $ENV{MYDanExtractFile};
            delete $ENV{MYDanExtractFileAim};
            my $mrsync = MYDan::Agent::Mrsync->new( %$sync, %path );
            map{ $failed{$_} = 1 } $mrsync->run( %o )->failed();
        }
    }

    my ( $load, $loadok );
    if( $task{load} )
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

    if( $task{dump} && ( $loadok || ! $task{load}) )
    {
        for ( 0 .. $o{retry} )
        {
            my %dump;
            my $id = -1;
            for my $todo ( @{$task{todo}} )
            {
                $id ++;
                next if $todo->{ok};

                my @dst = @{$todo->{dst}};
                my $i = int( rand time ) % @dst;
                my $dst = $dst[$i];
                $dump{$dst} = $id;
            }
            last unless keys %dump;
            my $argv = sub
            {
                delete $ENV{MYDanExtractFile};
                delete $ENV{MYDanExtractFileAim};

                my $code = File::Spec->join( $this->{agent}{argv}, shift );
                return -f $code && ( $code = do $code ) && ref $code eq 'CODE'
                    ? &$code( @_ ) : \@_;
            };

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
                $task{todo}[$dump{$_}]{ok} = $_ if $stat eq 'OK' 

            }keys %dump;
        }
    }

    unlink $load if $load && -f $load;

    if( $task{todo} )
    {
        for my $todo ( @{$task{todo}} )
        {
            if( $todo->{ok} )
            {
		my @dst = grep{ $_ ne $todo->{ok} }@{$todo->{dst}};
		next unless @dst;
                delete $ENV{MYDanExtractFile};
                delete $ENV{MYDanExtractFileAim};
                my $mrsync = MYDan::Agent::Mrsync->new( 
                    src => [ $todo->{ok} ], dst => \@dst, map{ $_ => $path{dp} }qw( sp dp ) );
                map{ $failed{$_} = 1 }$mrsync->run( %o )->failed();
            }
            else { map{ $failed{$_} = 1 }@{$todo->{dst}}; } 
        }
    }

    $this->{failed} = [ keys %failed ];
    return $this;
}

1;
