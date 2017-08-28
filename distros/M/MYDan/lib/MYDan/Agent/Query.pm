package MYDan::Agent::Query;

=head1 NAME

MYDan::Agent::Query - MYDan::Agent query 

=head1 SYNOPSIS

 use MYDan::Agent::Query;

 my $query = MYDan::Agent::Query->dump( \%query ); ## scalar ready for transport

 my $code = MYDan::Agent::Query->load( $query );

 print $code->yaml();

 my $result = $code->run( code => '/code/dir', run => '/run/dir' );

=cut
use strict;
use warnings;

use Carp;
use POSIX;
use YAML::XS;
use File::Spec;
use File::Basename;
use Compress::Zlib;
use FindBin qw( $RealBin );
use MYDan::Agent::Auth;
use MYDan::Util::OptConf;
use MYDan::Util::ProcLock;

our $CA = 86400;

=head1 METHODS

=head3 dump( $query )

Returns a scalar dumped from input HASH.

=cut

our ( %o, @myip );
BEGIN{ 
    %o = MYDan::Util::OptConf->load()->dump( 'agent' );
    @myip = grep{ /\d/ }split /\s+/, `hostname -I 2>/dev/null;hostname 2>/dev/null`;
};

sub dump
{
    my ( $class, $query ) = splice @_;

    confess "invalid query" unless $query
        && ref $query eq 'HASH' && defined $query->{code};

    if( $o{'auth'} && $query->{code} !~ /^free\./ )
    {
        my ( $time, $user, $auth ) = ( time, $query->{user}, $o{'auth'} );

        if( $o{role} && $o{role} eq 'client' )
        {
            $auth = ( getpwnam $user )[7].'/.ssh';
            $query->{user} = $ENV{MYDan_username} if $ENV{MYDan_username};
        }

        die "user unkown" unless $user && $user =~ /^[A-Za-z_][\-A-Za-z0-9_\.]+$/;
        $query->{peri} = join '#', $time - $CA, $time + $CA;

        $query->{auth} = MYDan::Agent::Auth->new( 
            key => $auth
        )->sign( YAML::XS::Dump $query );
    }
    
    return Compress::Zlib::compress( YAML::XS::Dump $query );
}

=head3 load( $query )

Inverse of dump().

=cut
sub load
{
    my ( $class, $query, $yaml ) = splice @_;

    die "invalid $query\n" unless
        ( $yaml = Compress::Zlib::uncompress( $query ) )
        && eval { $query = YAML::XS::Load $yaml }
        && ref $query eq 'HASH' && $query->{code};

    idie( "code format error:$query->{code}\n" ) unless $query->{code} =~ /^[A-Za-z0-9_\.]+$/;

    if( $o{'auth'} && $query->{code} !~ /^free\./ )
    {
        my $auth = delete $query->{auth};

        idie( "auth fail\n" ) unless MYDan::Agent::Auth->new(
            pub => $o{'auth'}
        )->verify( $auth, YAML::XS::Dump $query );
        idie ( "peri undef\n" ) unless my $peri = delete $query->{peri};
        my @peri = split '#', $peri;
        idie( "peri fail\n" ) unless $peri[0] < time && time < $peri[1];
    }

    idie( "auth fail.access\n" ) if $query->{node} && 0 == grep { $query->{node}{$_} } @myip;

    bless { yaml => $yaml, query => $query }, ref $class || $class;
}

=head3 run( %path )

Run code in $path{code}. If code name is postfixed with '.mx',
run code in mutual exclusion mode.

=cut
sub run
{
    my ( $self, %path ) = @_;
    my $query = $self->{query};
    my ( $code, $sudo, $env ) = @$query{ qw( code sudo env ) };

    idie( "already running $code\n" ) if ( $code =~ /\.mx$/ ) && !
        MYDan::Util::ProcLock->new( File::Spec->join( $path{run}, $code ) )->lock();

    if ( ! $< && $sudo && $sudo ne ( getpwuid $< )[0] )
    {
        idie( "invalid sudo $sudo\n" ) unless my @pw = getpwnam $sudo;
        @pw = map { 0 + sprintf '%d', $_ } @pw[2,3];
        POSIX::setgid( $pw[1] ); ## setgid must preceed setuid
        POSIX::setuid( $pw[0] );
    }

    %ENV = ( %ENV, %$env ) if $env && ref $env eq 'HASH';
    map{ $ENV{"MYDan_$_"} = $query->{$_} }qw( user sudo );

    my $tmpfile = "/tmp/tmp.agent.$$";
    YAML::XS::DumpFile $tmpfile, $query;
    open STDIN, '<', "$tmpfile" or idie( "Can't open '$tmpfile': $!" );
    unlink $tmpfile;

    exec "$path{code}/$code";
}

=head3 yaml()

Return query in YAML.

=cut
sub yaml
{
    my $self = shift;
    return $self->{yaml};
}

sub idie
{
    my $info = shift;
    print "MYDan $info";die $info;
}

1;
