package MYDan::Util::Contact;
use strict;
use warnings;
use Carp;
use YAML::XS;

=head1 SYNOPSIS

 use MYDan::Util::Contact;
 my $contact = MYDan::Util::Contact->new();
 my $email = $contact->contact( 'user1' => 'email' );

=cut

use MYDan::Util::OptConf;
use MYDan::Oncall::Policy;



our ( %util, %oncall );
BEGIN{ 
    my $opt = MYDan::Util::OptConf->load();
    %util = $opt->dump( 'util' );
    %oncall = $opt->dump( 'oncall' );
};

sub new
{
    my ( $class, %this ) = @_;

    map{
        $this{$_} = eval{ YAML::XS::LoadFile "$util{conf}/$_" };
        die "load config error:$@" if $@;
    }qw( contact team );

    bless \%this, ref $class || $class;
}

sub contact
{
    my ( $this, $user, $type, $depth ) = @_;

    $depth ++;
    return () if $depth > 5;
    my %c;
    if ( $user =~ /(.+):(.+)/ )
    {
 
        my $time = time;
        my $who = MYDan::Oncall::Policy->new( "$oncall{data}/$1" )
           ->set( $time - MYDan::Oncall::HOUR, $time + MYDan::Oncall::HOUR )
           ->get( $time, $2 );
         map{ $c{$_} ++ }$this->contact( $who->{item}, $type, $depth )

       
    }
    elsif( $user =~ s/^@// )
    {
        return () unless my $user = $this->{team}{$user};
        map{  $c{$_} ++  }map{ $this->contact( $_, $type, $depth )}@$user;
    }
    else
    {
        return () unless my $c = $this->{contact}{$user}{$type};
        return $c;
    }
    return keys %c;
}

1;
