package MYDan::VSSH;

use strict;
use warnings;
use MYDan::VSSH::Execute;
use MYDan::VSSH::Comp;
use MYDan::VSSH::History;
use MYDan::VSSH::Print;

$|++;

our %RUN = ( max => 128, timeout => 300 );

sub new
{
    my ( $class, %self ) =  @_;

    $self{config} = +{};

    bless \%self, ref $class || $class;
}

sub run
{
    my ( $this, %run, %busy ) = ( shift, %RUN, @_ );
 
    my $history = MYDan::VSSH::History->new();
    my $execute = MYDan::VSSH::Execute->new( node => $this->{node} );
    my $print = MYDan::VSSH::Print->new();
    $print->welcome();

    my $c = scalar @{$this->{node}};
    while ( 1 )
    {
	next unless my $cmd = $this->_comp( $c, @run{qw( user sudo )} );
        exit if $cmd eq 'exit' || $cmd eq 'quit' ||  $cmd eq 'logout';
   
        my %result = $execute->run( %run, cmd => $cmd );
        $print->result( %result );

        $history->push( $cmd );
    }
}

sub _comp
{
    my ( $self, $c ) = splice @_, 0, 2;
    my $tc = MYDan::VSSH::Comp->new(
        'clear'  => qr/\cl/,
        'reverse'  => qr/\cr/,
        'wipe'  => qr/\cw/,
         prompt => sprintf( "%s ($c)sh#", join( ':', grep{$_}@_)|| 'mydan' ),
         choices => [ ],
         up       => qr/\x1b\[[A]/,
         down     => qr/\x1b\[[B]/,
         left     => qr/\x1b\[[D]/,
         right    => qr/\x1b\[[C]/,
         quit     => qr/[\cc]/,
    );
    my ( $cmd, $danger ) = $tc->complete();
    return $cmd unless $danger;
    while( 1 )
    {
        print "$cmd [y/n]:";
        my $in = <STDIN>;
        next unless $in;
        return $cmd if $in eq "y\n";
        return undef if $in eq "n\n";
    }
}

1;
