package MYDan::Util::FileUpdate;

=head1 NAME

MYDan::Util::FileUpdate

=head1 SYNOPSIS

 use MYDan::Util::FileUpdate;

 MYDan::Util::FileUpdate->new( output => '/path/file', interval => 3600, url => 'https://xxx' )->run();

=cut

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use File::Temp;

sub new
{
    my ( $class, %self ) = @_;
    map{ die "$_ undef" unless $self{$_} }qw( url output );
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

    my ( $url, $output ) = @$this{qw( url output )};
    return unless my $c = uaget( $url );

    my $TEMP = File::Temp->new();
    print $TEMP $c;
    system "mv '$TEMP->filename' '$output'";
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
