package MYDan::Code::Gitlab;
use strict;
use warnings;

use GitLab::API::v4;

$|++;

sub new 
{
    my ( $class, %self ) = splice @_;
	map{ die "$_ undef" unless $self{$_} }qw( apiurl token name );

    $self{api} = GitLab::API::v4->new(
        url           => $self{apiurl},
        private_token => $self{token},
	);

	delete $self{user};
	$self{email} = +{};

    bless \%self, ref $class || $class;
}

sub searchUser
{
    my ( $this, $user ) = @_;
	$this->searchUserGroups( $user );
	$this->searchUserProjects( $user );
}

sub searchUserProjects
{
    my ( $this, $user ) = @_;
	return unless $this->_initUser( $user );

	my $pp = $this->{api}->sudo( $this->{user}{username} )
		->paginator( 'projects', +{ membership => 1 } );

    my ( $i, %groupowner ) = ( 0 );
	while( my $project = $pp->next() ) 
	{
		my ( $type, $typeid, @owner ) = map { $project->{namespace}{$_} }qw( kind id );

		my $m = $this->{api}->project_members( $project->{id} );
		for my $mm ( @$m )
		{
			next if $mm->{state} ne 'active' || $mm->{access_level} != 50;

			unless( $this->{email}{$mm->{id}} )
			{
				my $user = $this->{api}->user( $mm->{id} );
				$this->{email}{$mm->{id}} = $user->{email} || $mm->{username};
			}

			push @owner, $mm->{id};
		}

		my $bg = ( $type eq 'group' && $this->{groups}{$typeid} ) ? '@ByGroup' : '';

        if( ! @owner && $type eq 'group' && ! $bg )
        {
            if( defined $groupowner{$typeid} )
            {
                @owner = @{$groupowner{$typeid}};
            }
            else
            {
                my $m = $this->{api}->group_members( $typeid );
                for my $mm ( @$m )
                {
                    next if $mm->{state} ne 'active' || $mm->{access_level} != 50;
                    unless( $this->{email}{$mm->{id}} )
                    {
                        my $user = $this->{api}->user( $mm->{id} );
                        $this->{email}{$mm->{id}} = $user->{email} || $mm->{username};
                    }

                    push @owner, $mm->{id};
                    $groupowner{$typeid} = \@owner;
                }
            }
            $bg = '@GroupOwner';
        }

        $bg = '@Self' if ! @owner && !$bg && $project->{web_url} =~ /^$this->{user}{web_url}/;

        if( ! @owner && !$bg && $project->{owner}  && $project->{owner}{state} eq 'active' )
        {
            my $mm = $project->{owner};

			unless( $this->{email}{$mm->{id}} )
			{
				my $user = $this->{api}->user( $mm->{id} );
				$this->{email}{$mm->{id}} = $user->{email} || $mm->{username};
			}

			push @owner, $mm->{id};
            $bg = '@ProjectOwner';
        }

         $bg = 'NoFind' if ! @owner && !$bg;

		printf "[%i]: $this->{user}{email} $this->{name} project.$type $project->{web_url}\t%s $bg\n", ++$i, 
			join ' ', map{ "$this->{email}{$_}" }@owner;
	}

    return $this;
}

sub searchUserGroups
{
    my ( $this, $user ) = @_;

	return unless $this->_initUser( $user );

	my $i = 0;
	my $gp = $this->{api}->sudo( $this->{user}{username} )
		->paginator( 'groups', +{ min_access_level => 10 } );
	while ( my $group = $gp->next() ) 
	{
		$this->{groups}{$group->{id}}++;
		my @owner;
		my $m = $this->{api}->group_members( $group->{id} );
		for my $mm ( @$m )
		{
			next if $mm->{state} ne 'active' || $mm->{access_level} < 40;     

			unless( $this->{email}{$mm->{id}} )
			{
				my $user = $this->{api}->user( $mm->{id} );
				$this->{email}{$mm->{id}} = $user->{email} || $mm->{username};
			}

			push @owner, $mm->{id};
		}

		printf "[%i]: $this->{user}{email} $this->{name} group $group->{web_url}\t%s\n", ++$i, 
			join ' ', map{ "$this->{email}{$_}" }@owner;
	}

    return $this;
}


sub getUsers
{
    my ( $this, %email )= shift;

	my $i = 0;
    my $pp = $this->{api}->paginator( 'users' );
	while (my $user = $pp->next()) {
        $email{$user->{email}} ++ if $user->{state} eq 'active';
        printf "[%i]: $this->{name} $user->{email} $user->{state}\n", ++$i;
    }
    return %email;
}

sub blockUser
{
    my ( $this, $user ) = @_;
	return unless $this->_initUser( $user );

	print "$this->{name} lock user.email=$this->{user}{email} user.id=$this->{user}{id}\n";
	warn "block fail\n" unless $this->{api}->block_user( $this->{user}{id} );
}

sub unblockUser
{
    my ( $this, $user ) = @_;
	return unless $this->_initUser( $user );

	print "$this->{name} unlock user.email=$this->{user}{email} user.id=$this->{user}{id}\n";
	warn "unblock fail\n" unless $this->{api}->unblock_user( $this->{user}{id} );
}

sub _initUser
{
	my ( $this, $user ) = @_;

	return 1 if $this->{user};

	if( $user =~ /(.+)@/ )
	{

		my $u = $this->{api}->users( +{ username => $1 } );
        if( @$u )
        {
            $this->{user} = $u->[0];
            return 1;
        }

		my $userspage = $this->{api}->paginator( 'users' );
		while( my $u = $userspage->next() ) {
			$this->{email}{$u->{id}} = $u->{email} || $u->{username};
			if( $u->{email} eq $user )
			{
				$this->{user} = $u;
				return 1;
			}
		}
	}
	else
	{
		my $u = $this->{api}->users( +{ username => $user } );
		return 0 unless @$u;
		$this->{user} = $u->[0];
		return 1;
	}

	return 0;
}

1;
