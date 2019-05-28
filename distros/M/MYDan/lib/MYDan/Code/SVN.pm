package MYDan::Code::SVN;
use strict;
use warnings;

$|++;

sub new 
{
    my ( $class, %self ) = splice @_;
	map{ die "$_ undef" unless $self{$_} }qw( name path );
    die "path no array" unless ref $self{path} eq 'ARRAY';
    bless \%self, ref $class || $class;
}

sub searchUser
{
    my ( $this, $user ) = @_;

    unless( $user && $user =~ /^[a-zA-Z0-9\._\-]+@[a-zA-Z0-9\.]+$/ && $user !~ /^block__/ )
    {
        warn "user name format not support.\n";
        return;
    }


    my ( $i, $type ) = ( 0, '' );
    for my $path ( map{ glob $_ }@{$this->{path}} )
    {
        my @conf = `cat '$path'`;
        map{ $_ =~ s/[\r]*\n$// }@conf;

        $type = '';
        my @group;
        for my $conf ( @conf )
        {
            $conf =~ s/#.*//;

            if( $conf =~ /^\s*\[/ ) { $type = $conf; next; }

			next unless $conf =~ /$user/;

			if( $conf =~ /^$user\s*=\s*/ )
			{
				printf "[%i]: $user $this->{name} project $path $type $conf\n", ++$i;
			}
			elsif( $conf =~ /,$user\b/ || $conf =~ /=\s*$user\b/ )
			{
				if( $conf =~ /^(.*)=/ )
				{
					printf "[%i]: $user $this->{name} group $path $type $1\n", ++$i;
                    push @group, $1;
				}
			}
        }

        $type = '';
        for my $group ( @group )
        {
            for my $conf ( @conf )
            {
                $conf =~ s/#.*//;

                if( $conf =~ /^\[/ ) { $type = $conf; next; }

                next unless $conf =~ /$group/;

                if( $conf =~ /^\@$group\s*=\s*/ )
                {
                    printf "[%i]: $group $this->{name} bygroup $path $type $conf\n", ++$i;
                }
            }
        }
    }
}

sub getUsers
{
    my ( $this, %email )= shift;

    for my $path ( map{ glob $_ }@{$this->{path}} )
    {
        my @conf = `cat '$path'`;

        my ( $i, %print ) = ( 0 );

        for my $conf ( @conf )
        {
            $conf =~ s/#.*//;
            next unless my @g = $conf =~ /([a-zA-Z0-9\.\-_]+@[a-z]+\.[a-z]+)/g;
            map{
                my $p;
                if( $_ =~ /^block__(.+)$/ )
                {
                    $p = "$this->{name} $path $1 block";
                }
                else
                {
                    $p = "$this->{name} $path $_ active";
                    $email{$_} ++;
                }

                printf "[%i] $p\n", ++$i unless $print{$p};
                $print{$p} ++;
            }@g;
        }
    }
    return %email;
}

sub blockUser
{
    my ( $this, $user ) = @_;

    unless( $user && $user =~ /^[a-zA-Z0-9\._\-]+@[a-zA-Z0-9\.]+$/ && $user !~ /^block__/ )
    {
        warn "user name format not support.\n";
        return;
    }

    return if ! $user || ! @{$this->{path}};

    my $path = join ' ', @{$this->{path}};
    system "sed  -i 's/\\([=, ]\\)$user/\\1block__$user/g;s/^$user/block__$user/' $path";
}

sub unblockUser
{
    my ( $this, $user ) = @_;

    unless( $user && $user =~ /^[a-zA-Z0-9\._\-]+@[a-zA-Z0-9\.]+$/ && $user !~ /^block__/ )
    {
        warn "user name format not support.\n";
        return;
    }

    return if ! $user || ! @{$this->{path}};

    my $path = join ' ', @{$this->{path}};
    system "sed  -i 's/\\([=, ]\\)block__$user/\\1$user/g;s/^block__$user/$user/' $path";
}

1;
