package MYDan::Code;
use strict;
use warnings;

use MYDan::Code::Gitlab;
use MYDan::Code::SVN;

sub new 
{
    my ( $class, %self ) = splice @_;

    if( $self{conf} && ref $self{conf} eq 'ARRAY' )
    {
        for my $conf ( @{$self{conf}} )
        {
            next unless ( ! $self{name} ) || ( $self{name} && $conf->{name} && $self{name} eq $conf->{name} );
            if( $conf->{apiurl} )
            {
                push @{$self{code}}, MYDan::Code::Gitlab->new( %$conf ); 
            }
            else
            {
                push @{$self{code}}, MYDan::Code::SVN->new( %$conf );
            }
		}
    }

    bless \%self, ref $class || $class;
}

sub searchUser
{
    my ( $this, $user ) = @_;
    map { $_->searchUser( $user ); }@{$this->{code}};
    return $this;
}

sub getUsers
{
    my ( $this, %email ) = shift;
    map { %email = ( %email, $_->getUsers() ); }@{$this->{code}};

    return $this unless $this->{checkuser};

    my $i = 0;
    for my $email ( sort keys %email )
    {
        printf "[%i]: plugin.checkuser $email %s\n", ++$i, $this->{checkuser}->( $email );
    }

    return $this;
}

sub blockUser
{
    my ( $this, $user ) = @_;
    map { $_->blockUser( $user ); }@{$this->{code}};
    return $this;
}

sub unblockUser
{
    my ( $this, $user ) = @_;
    map { $_->unblockUser( $user ); }@{$this->{code}};
    return $this;
}

1;
