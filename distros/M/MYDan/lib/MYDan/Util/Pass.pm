package MYDan::Util::Pass;

=head1 NAME

MYDan::Util::Pass

=head1 SYNOPSIS

 use MYDan::Util::Pass;

 /path/pass
 ---
 'host{1~10}': 
    user1: pass1
    user2: pass2 
    default: pass
 default:
    u1: p1
    u2: p2
    default: p

 my $pass = MYDan::Util::Pass->new( conf => '/path/pass' );
 my $pass = MYDan::Util::Pass->new( conf => '/path/pass', range => $range );

 my %pass = $pass->pass( [ 'host1', 'host2' ] ); 
 %pass
   host1: +{ user1 => pass1, user2 => pass2 },
   host2: +{ user1 => pass1, user2 => pass2 },

 my %pass = $pass->pass( [ 'host1', 'host2' ] => 'user1' ); 
 %pass
   host1: pass1
   host2: pass1

 my %pass = $pass->pass( 'host1', 'host2' ); 
 %pass
   host1: [ user1, pass1 ]
   host2: [ user2, pass2 ]

=cut

use strict;
use warnings;

use Carp;
use YAML::XS;
use MYDan::Node;
use MYDan::Util::OptConf;

sub new
{
    my ( $class, %self ) = @_;

    $self{conf} ||= MYDan::Util::OptConf->load()->dump( 'util' )->{conf} .'/pass';
    $self{range} ||= MYDan::Node->new( MYDan::Util::OptConf->load()->dump( 'range' ) );

    my $conf = eval{ YAML::XS::Dump YAML::XS::LoadFile $self{conf} };
    confess "error $self{conf}:$@" if $@;

    map{ $conf =~ s/\$ENV\{$_\}/$ENV{$_}/g; }keys %ENV;
    $self{pass} =  eval{ YAML::XS::Load $conf };

    die "load conf fail:$@" if $@;

    bless \%self, ref $class || $class;
}

sub pass
{
    my ( $this, @param, $node, $user ) = @_;

    ( $node, $user ) = ref $param[0] ? @param : ( [ @param ], 0 );

    my %node = map{ $_ => 1 }@$node;
    my ( $pass, $range, %pass ) = @$this{qw( pass range )};

    while ( my ( $n, $p ) = each %$pass )
    {
        map{ $pass{$_} = $p || $pass->{default} }
            grep{ $node{$_} }$range->load( $n )->list();
    }
    
    map{ $pass{$_} ||= $pass->{default} || +{} }@$node;

    return %pass unless defined $user;

    return map{
        $_ => defined $pass{$_}{$user} ? $pass{$_}{$user} : $pass{$_}{default}
    }keys %pass if $user;

    for my $node ( keys %pass )
    {
        my $default = delete $pass{$node}{default};
        my ( $u ) = sort keys %{$pass{$node}};
        $pass{$node} = $u ? [ $u, $pass{$node}{$u} ]
            : $default ? [ undef, $default ] : [];
    }
    
    return %pass;
}

1;
