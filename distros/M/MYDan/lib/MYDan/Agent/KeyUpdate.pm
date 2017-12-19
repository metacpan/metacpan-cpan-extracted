package MYDan::Agent::KeyUpdate;

=head1 NAME

MYDan::Agent::KeyUpdate

=head1 SYNOPSIS

 use MYDan::Agent::KeyUpdate;

 MYDan::Agent::Auth->new( auth => /path/, interval => 3600, url => 'https://xxx' )->run();

=cut

use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Basename;
use LWP::UserAgent;
use File::Temp;
use Digest::MD5;

sub new
{
    my ( $class, %self ) = @_;

    map{ die "$_ undef" unless $self{$_} }qw( url auth );

    die "noauth" unless -e $self{auth};

    bless \%self, ref $class || $class;
}

sub run
{
    my $this = shift;

    $this->update();

    return unless my $interval = $this->{interval};

    sleep int 3 + rand $interval;

    while(1)
    {
        $this->update();
        sleep $interval;
    }

    return 0;
}

sub update
{
    my $this = shift;

    print "update ...\n";

    my ( $url, $auth ) = @$this{qw( url auth )};
    return unless my $key = uaget( $url );

    my ( %d, %dd, $ddd ); 
    for( split /\n/, $key )
    {
        my ( $md5, $url, $name );

        unless( ( $md5, $url ) = $_ =~ /^([a-zA-Z0-9]{32}):(http.*\.pub)$/ )
        {
             $ddd = 1; next;
        }

        $dd{ $name = basename $url } = 1;

        next if -e "$auth/$name";
        next unless my $c = uaget( $url );

        my $TEMP = File::Temp->new();
        print $TEMP $c;
        seek $TEMP, 0, 0;
        my $tmd5 = Digest::MD5->new()->addfile( $TEMP )->hexdigest();

        next unless lc( $md5 ) eq lc( $tmd5 );
        rename $TEMP->filename, "$auth/$name";
    }

    return if $ddd;

    map{ $d{ basename $_ } = 1 }glob "$auth/*.pub";
    map{ delete $dd{$_} if delete $d{$_} }keys %dd;
    return if keys %dd;
    map{ unlink "$auth/$_" }keys %d;
    
}

sub uaget
{
    my $url = shift;

    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    $ua->timeout( 10 );

    my $res = $ua->get( $url );
    my $code = $res->code();
    warn "get $url code: $code\n" unless $code == 200;
    return $res->is_success ? $res->content : undef;
}

1;
