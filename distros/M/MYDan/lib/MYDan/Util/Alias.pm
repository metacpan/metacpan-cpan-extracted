package MYDan::Util::Alias;
use strict;
use warnings;
use Carp;
use YAML::XS;
use MYDan;

sub new
{
    my $class = shift;

    my $conf = eval{ YAML::XS::LoadFile "$MYDan::PATH/etc/alias" };
    die "load alias fail: $@" if $@;

    bless $conf, ref $class || $class;
}

sub alias
{
    my ( $this, $k, $v ) = @_;

    if( defined $k && defined $v )
    {
        $this->{$k} = $v;
        eval{ YAML::XS::DumpFile "$MYDan::PATH/etc/alias", $this };
        die "save alias fail:$@" if $@;
    }
    elsif( defined $k )
    {
        return $this->{$k};
    }
    else { return %$this; }

}

sub unalias
{
    my ( $this, $k ) = @_;

    delete $this->{$k};

    eval{ YAML::XS::DumpFile "$MYDan::PATH/etc/alias", $this };
    die "save alias fail:$@" if $@;
}

1;
__END__
