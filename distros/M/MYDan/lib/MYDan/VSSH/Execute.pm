package MYDan::VSSH::Execute;

use strict;
use warnings;

use MYDan::Agent::Client;
use MYDan::Util::OptConf;

use MYDan::Node;
use YAML::XS;
use MYDan::Util::MIO::SSH;
use MYDan::Util::Pass;

our $dan = 1;
our $pass;

$|++;

our %o; BEGIN{ %o = MYDan::Util::OptConf->load()->dump('agent'); };
sub new
{
    my ( $class, %self ) =  @_;
    bless \%self, ref $class || $class;
}

sub run
{
    my ( $this, %run ) = @_;
 
    if( $dan )
    {
        my %query = ( code => 'exec', argv => [ $run{cmd} ], map{ $_ => $run{$_} }qw( user sudo ) );

        my $client = MYDan::Agent::Client->new( @{$this->{node}} );
        return $client->run( %o, %run, query => \%query, verbose => 1 );
    }
    else
    {
        $pass = +{ MYDan::Util::Pass->new()->pass( $this->{node} => $run{user} )}unless defined $pass;
        tie my @input, 'Tie::File', my $input = "/tmp/mssh.".time.".$$";
        @input = ( $run{sudo} ? ( "sudo su - '$run{sudo}' || exit 1" ) : (), $run{cmd}, 'echo --- $?' );

        my ( %result, %re )= MYDan::Util::MIO::SSH->new( map{ $_ => [] }@{$this->{node}} )
            ->run( %run, pass => $pass, input => $input );

        unlink $input;

        while( my ( $type, $result ) = each %result )
        {
            map{ my $t = $_; map{ $re{$_} .= $t } @{$result->{$t}};}keys %$result;
        }
        return %re;
    }
}

1;
