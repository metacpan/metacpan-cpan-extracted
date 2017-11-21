package MYDan::Util::Percent;
use strict;
use warnings;

$|++;

sub new
{
    my $class = shift;
    bless +{ size => shift, len => 0, prompt => (shift||'') }, 
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
    $this->{len} = $this->{len}  + (shift||1);
    return $this;
}

sub print
{
    my ( $this, $prompt ) = @_;
    my ( $size, $len ) = @$this{qw( size len )};
    $prompt ||= $this->{prompt};
    my $p = $size ? sprintf( "%d", $len*100/$size ) : 0;
    $p = 100 if $p >100;
    print "\r$prompt $p% $len/".($size||'unkown').' ';
    print "\n" if $p==100;
    return $this;
}

1;
__END__
