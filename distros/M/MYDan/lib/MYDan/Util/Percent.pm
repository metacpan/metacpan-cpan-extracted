package MYDan::Util::Percent;
use strict;
use warnings;

$|++;

sub new
{
    my $class = shift;
    bless +{ size => shift, count => 0, time => 0, speed => '0/s', len => 0, prompt => (shift||''), pcb => shift }, 
        ref $class || $class;
}

sub renew
{
    my $this = shift;
    $this->{size} = shift;
    return $this;
}

sub add
{
    my $this = shift;
    my $add = shift||1;
    $this->{len} = $this->{len}  + $add;
    my $time = int time;
    if( $time eq $this->{time} )
    {
        $this->{count} += $add;
    }
    else
    {
        $this->{speed} = _human(( $this->{count} + $add )/( $time - $this->{time} ));
        $this->{time} = $time;
        $this->{count} = 0;
    }
    return $this;
}

sub print
{
    my ( $this, $prompt ) = @_;
    my ( $size, $len, $pcb ) = @$this{qw( size len pcb )};
    $prompt ||= $this->{prompt};
    my $p = $size ? sprintf( "%d", $len*100/$size ) : 0;
    $p = 100 if $p >100;

    my $percent = "$prompt $p% ". _human( $len ) ."/".($size ? _human( $size ) : 'unkown' ).' '.$this->{speed}.'/s';
    if( $pcb )
    {
        &$pcb( "$percent" );
    }
    else
    {
        print "\r$percent".' ' x 20;
        print "\n" if $p==100;
    }

    return $this;
}

sub _human
{
    my $c = shift;
    return '1' if $c <= 1;
    if( $c > 1073741824 )
    {
        $c = sprintf "%.1fG", $c / 1073741824;
    }
    elsif( $c > 1048576 )
    {
        $c = sprintf "%.1fM", $c / 1048576;
    }
    elsif( $c > 1024 )
    {
        $c = sprintf "%.1fK", $c / 1024;
    }
    
    return $c;
}

1;
__END__
