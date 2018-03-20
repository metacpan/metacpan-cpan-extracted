package MYDan::Bootstrap::ProcUpdate;

=head1 NAME

MYDan::Bootstrap::ProcUpdate

=head1 SYNOPSIS

 use MYDan::Bootstrap::ProcUpdate;

 MYDan::Bootstrap::ProcUpdate->new( exec => /path/, interval => 3600, url => 'https://xxx' )->run();

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

    map{ die "$_ undef" unless $self{$_} }qw( url exec );

    die "noexec" unless -e $self{exec};

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

    my ( $url, $exec ) = @$this{qw( url exec )};
    return unless my $key = uaget( $url );

    my ( %d, %dd, $ddd ); 
    for( split /\n/, $key )
    {
        my ( $md5, $url, $name );

        unless( ( $md5, $url ) = $_ =~ /^([a-zA-Z0-9]{32}):(http.+)$/ )
        {
             $ddd = 1; next;
        }

        $dd{ $name = basename $url } = 1;

        next if -e "$exec/$name";
        next unless my $c = uaget( $url );

        my $TEMP = File::Temp->new();
        print $TEMP $c;
        seek $TEMP, 0, 0;
        my $tmd5 = Digest::MD5->new()->addfile( $TEMP )->hexdigest();

        next unless lc( $md5 ) eq lc( $tmd5 );
        chmod 0700, $TEMP->filename;
        system "mv '$TEMP->filename' '$exec/$name'";
    }

    return if $ddd;

    map{ $d{ basename $_ } = 1 }glob "$exec/*";
    map{ delete $dd{$_} if delete $d{$_} }keys %dd;
    return if keys %dd;
    map{ unlink "$exec/$_" }keys %d;
    
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
