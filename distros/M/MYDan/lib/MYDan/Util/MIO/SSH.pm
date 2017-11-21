package MYDan::Util::MIO::SSH;

=head1 NAME

MYDan::Util::MIO::SSH - Run multiple SSH commands in parallel.

=head1 SYNOPSIS
 
 use MYDan::Util::MIO::SSH;

 my @node = qw( host1 host2 ... );
 my @cmd = qw( uptime );

 my $ssh = MYDan::Util::MIO::SSH->new( map { $_ => \@cmd } @node );
 my $result = $ssh->run( max => 32, timeout => 300 );

 my $output = $result->{output};
 my $error = $result->{error};

=cut
use strict;
use warnings;

use Carp;
use Expect;
use Tie::File;
use Fcntl qw( :flock );
use POSIX qw( :sys_wait_h );
use FindBin qw( $Script );
use Authen::OATH;
use Convert::Base32 qw( decode_base32 ); 

use MYDan::Util::Alias;
use MYDan::Util::Hosts;
use MYDan::Util::Percent;
use MYDan::Util::Proxy;

use base qw( MYDan::Util::MIO );

our %RUN = %MYDan::Util::MIO::RUN;

our $SSH;
BEGIN{
    my $x = MYDan::Util::Alias->new()->alias( 'ssh' ) || 'ssh';
    $SSH = $x . ' -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -t';
};

local $| = 1;

sub new
{
    my $self = shift;
    $self->cmd( @_ );
}

=head1 METHODS

=head3 run( %param )

Run ssh commands in parallel.
The following parameters may be defined in I<%param>:

 max : ( default 128 ) number of commands in parallel.
 timeout : ( default 300 ) number of seconds allotted for each command.
 sudo : ( default no sudo ) remote sudo user
 user : ( default logname ) connect as user
 pass : password

=cut
sub run
{
    local $/ = "\n";

    my $self = shift;
    my @node = keys %$self;
    my ( $run, %run, %result, %busy ) = ( 1, %RUN, @_ );
    my ( $ext, $prompt ) = ( "$Script.$$", 'password:' );
    my ( $max, $timeout, $user, $sudo, $pass, $input ) =
        @run{ qw( max timeout user sudo pass input ) };

    my $percent =  MYDan::Util::Percent->new( scalar @node, 'run ..' );

    $SIG{INT} = $SIG{TERM} = sub
    {
        print STDERR "killed\n";
        $run = 0;
    };

    my %hosts = MYDan::Util::Hosts->new()->match( @node );
    my $p = MYDan::Util::Proxy->new( "$MYDan::PATH/etc/util/conf/proxy" );

    do
    {
        while ( @node && keys %busy < $max )
        {
            my $node = shift @node;
            my $cmd = $self->{$node};
            my $log = "/tmp/$node.$ext";

	    my %x = $p->search( $hosts{$node} );

            my $ssh = $user ? "$SSH -l $user $hosts{$node} " : "$SSH $hosts{$node} ";
	    $ssh.= " -o ProxyCommand='nc -X 5 -x $x{$hosts{$node}} %h %p' " if $x{$hosts{$node}};

            if( @$cmd )
            {
                $ssh .= join ' ',
                    $sudo ? map { "sudo -p '$prompt' -u $sudo $_" } @$cmd : @$cmd;
            }
            else { $ssh .= " < $input"; }

            if ( $run{noop} ) { warn "$ssh\n"; next }
            if ( my $pid = fork() ) { $busy{$pid} = [ $log, $node ]; next }
            
            my ( $exp, %expect ) = Expect->new();

	    if( $pass->{$node} && ref $pass->{$node} )
	    {
		%expect = %{$pass->{$node}};
                for( keys %expect )
		{
                    next unless $expect{$_} =~ /googlecode\s*:\s*(\w+)/;
		    $expect{$_} = Authen::OATH->new->totp(  decode_base32( $1 ));
		}
	    }
	    elsif( $pass->{$node} )
	    {
                $expect{assword} = $pass->{$node};
	    }

	    $exp->log_stdout(0); #disable output to stdion (password: )
            $exp->log_file( $log, 'w' );
	    warn "debug:$ssh\n" if $ENV{MYDan_DEBUG};
            if ( $exp->spawn( $ssh ) )
            {
                $exp->expect( $timeout, 
	        map{ my $v = $expect{$_};[ qr/$_/ => sub { $exp->send( "$v\n" ); exp_continue; } ] }keys %expect        
		);
            }
 
            exit 0;
        }

        for ( keys %busy )
        {
            my $pid = waitpid( -1, WNOHANG );
            next if $pid <= 0;

	    my $stat = $? >> 8;

            next unless my $data = delete $busy{$pid};

            $percent->add()->print();

            my ( $log, $node ) = @$data;
            tie my @log, 'Tie::File', $log;

            my @i = grep { $log[$_] =~ /$prompt/ } 0 .. $#log;
            splice @log, 0, $i[-1] + 1 if @i;

	    unless( $ENV{MYDan_DEBUG} )
	    {
	        @log = grep { $_ !~ m{Connection\ to.*?closed}xms } @log;
	        @log = grep { $_ !~ m{Warning: Permanently added .+ to the list of known hosts\.}m } @log;
                @log = grep { $_ !~ m{Pseudo-terminal will not be allocated because stdin is not a terminal\.}m } @log;
	        pop @log if @log && $log[-1] =~ /^Last login: .*\d+:\d+:\d+/;
            }

	    my $end = $input ? '' : "--- $stat\n";
            push @{ $result{output}{ join "\n", @log, $end } }, $node if @log;
            unlink $log;
        }
    }
    while $run && ( @node || %busy );

    kill 9, keys %busy;

    push @{ $result{output}{killed} }, map{ $busy{$_}[1]}keys %busy;
    push @{ $result{output}{norun} }, @node;

    unlink glob "/tmp/*.$ext";
    unlink $input if $input && -f $input;

    return wantarray ? %result : \%result;
}

1;
