package MYDan::Util::Progress;
use strict;
use warnings;

use Term::Size;

$|++;

sub new
{
    my $class = shift;
    my ( $size, $cols ) = ( 66, Term::Size::chars *STDOUT{IO} );

    $size = $cols if $size > $cols;
    my $rc = int ( $cols / $size );
    $size = int( $cols / $rc ) -1;

    bless +{ rc => $rc, size => $size -1, d => [] }, ref $class || $class;
}

sub load
{
    my ( $this, %data ) = @_;
    map{ 
        push @{$this->{d}}, $_ unless defined $this->{data}{$_};
        $this->{data}{$_} = $data{$_};
    }keys %data;

    return $this;
}

sub print
{
    my ( $this, $prompt ) = @_;

    system 'clear';

    my $i = 0;

    for my $k ( @{$this->{d}} )
    {
        $i ++;

        my $v = $k.":". ( $this->{data}{$k} ||'' );

        if( length $v > $this->{size} )
        {
            $v = substr $v, 0 ,$this->{size};
        }
        else
        {
            $v .= ' ' x ( $this->{size} - length $v );
        }

        print "$v|";
        print "\n" unless $i % $this->{rc};
    }
    return $this;
}

1;
__END__
