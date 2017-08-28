package MYDan::Project::Check::Http;
use strict;
use warnings;
use Carp;
use Encode;

use LWP::UserAgent;

#  addr: http://localhost/stat
#  check: 'ok'
#  type: post # type: get  default 
#  data: a=1&b=2
#  Host: abc.org

sub new
{
    my ( $class, %self ) = @_;
    $self{check} ||='';
    map{ 
        confess "$_ undef.\n" unless defined $self{$_};
        Encode::_utf8_off( $self{$_} );
    }qw( addr check );
    my %opt = $self{addr} =~ /^https/ ? ( ssl_opts => { verify_hostname => 0 } ) :();

    $self{ua} = my $ua = LWP::UserAgent->new( %opt );
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    $ua->timeout( 10 );
    $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache', Host => $self{Host} );

    $self{type} ||= 'get';

    bless \%self, ref $class || $class;
}

sub check
{
    my $this = shift;
    my ( $ua, $addr, $check, $data, $type ) = @$this{qw( ua addr check data type )};

    my $res = $type eq 'post'
       ? $ua->post( $addr, $data ? ( Content => $data ) : () )
       : $ua->get( $addr ); 
    
    my $content = $res->is_success ? $res->content : die "$addr not success\n";
    print "$content\n" if $ENV{NS_DEBUG};

   ( defined $content ) && ( $check eq '' || $content =~ /$check/ )
       ? print "$addr <> $check :OK\n"
       : die "$addr <> $check :FAIL\n";

    return 1;
}

1;
__END__
