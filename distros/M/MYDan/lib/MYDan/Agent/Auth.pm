package MYDan::Agent::Auth;

=head1 NAME

MYDan::Agent::Auth

=head1 SYNOPSIS

 use MYDan::Agent::Auth;

 my $sig = MYDan::Agent::Auth->new( key => /foo/ca/ )->sign( $mesg );

 MYDan::Agent::Auth->new( pub => /foo/ca/ )->verify( $sig, $mesg ); 


=cut
use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Basename;
use Crypt::PK::RSA;
use FindBin qw( $RealBin );

sub new
{
    my ( $class, $type, $auth, %self ) = @_;
    confess "invalid auth dir" unless $auth && -d $auth;

    $self{data} = +{};
    for my $file ( ( $self{user} && $type eq 'pub' ) ? ( "$auth/$self{user}.pub" ) : glob "$auth/*" )
    {
        next unless -f $file;
        $self{data}{ basename $file} = "$file.$type" if $file =~ s/\.$type$//;
    }

    bless \%self, ref $class || $class;
}

sub sign
{
    my ( $this, $mesg, %sig ) = splice @_, 0, 2;
    confess "no mesg"  unless $mesg;

    map 
    { 
        $sig{$_} = Crypt::PK::RSA->new( $this->{data}{$_} )->sign_message( $mesg );
    }keys %{$this->{data}};
    return wantarray ? %sig : \%sig;
}

sub verify
{
    my ( $this, $sig, $mesg ) = @_;
    if( my $user = $this->{user} )
    {
        return 0 unless $this->{data}{$user};
        map{
            return 1 if Crypt::PK::RSA->new( $this->{data}{$user} )->verify_message( $sig->{$_}, $mesg );
        }keys %$sig;
    } 
    else
    {
        for( keys %{$this->{data}} )
        { 
            next unless $sig->{$_};
            return 1 if Crypt::PK::RSA->new( $this->{data}{$_} )->verify_message( $sig->{$_}, $mesg );
        }
    }
    return 0;
}

1;
