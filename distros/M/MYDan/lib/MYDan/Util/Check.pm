package MYDan::Util::Check;
use strict;
use warnings;

use MYDan::Util::Check::Proc;
use MYDan::Util::Check::Http;
use MYDan::Util::Check::Port;

$|++;

sub new
{
    my ( $class, $module ) = splice @_, 0, 2;

    if( $module && ( $module eq 'proc.num' || $module eq 'proc.time' ) )
    {
        $module =~ s/^proc.//;
        return  MYDan::Util::Check::Proc->new( $module, @_ );
    }
    return  MYDan::Util::Check::Http->new( @_ ) if $module && $module eq 'http.check';
    return  MYDan::Util::Check::Port->new( @_ ) if $module && $module eq 'net.port.listen';

    bless +{}, ref $class || $class;
}

sub check { die "not supported.\n"; }

1;
__END__
