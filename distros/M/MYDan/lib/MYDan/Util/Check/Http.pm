package MYDan::Util::Check::Http;
use strict;
use warnings;
use LWP::UserAgent;

$|++;

sub new
{
    my ( $class, $method, $url, $type, @condition ) = @_;

    die "not supported.\n" unless $method && ( $method eq 'get' || $method eq 'post' );
    die "not supported.\n" unless $type && ( $type eq 'code' || $type eq 'grep' );

    die "format error.\n" unless @condition;

    bless +{ method => $method, url => $url, type => $type, condition => \@condition },
        ref $class || $class;
}

sub check
{
    my ( $this, %run )= @_;

    my ( $method, $url, $type, $condition ) = @$this{qw( method url type condition )};

    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    $ua->timeout( 10 );

    my $res = $method eq 'get' ? $ua->get( $url ) : $ua->post( $url );

    if( $type eq 'code' )
    {
        my $code = $res->code();
        print "$method $url code:$code\n";
        return ( grep{ $code eq $_ }@$condition ) ? 0 : 1;
    }
    else
    {
        unless( $res->is_success )
		{
			print "$method $url fail\n"; 
            return 1;
		}
        my $content = $res->content;
        $content = '' unless defined $content;
        print "$method $url: $content\n" if $run{debug};

        return ( grep{ $content =~ /$_/ }@$condition ) ? 0 : 1;
    }

	return 1;
}

1;
__END__
