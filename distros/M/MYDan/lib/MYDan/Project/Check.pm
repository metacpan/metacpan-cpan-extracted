package MYDan::Project::Check;
use strict;
use warnings;
use Carp;
use YAML::XS;

use MYDan::Project::Check::Http;
use MYDan::Project::Check::Port;

sub new
{
    my ( $class, %self ) = @_;
    confess "conf undef.\n" unless $self{conf} && ref $self{conf} eq 'ARRAY';
    bless \%self, ref $class || $class;
}

sub check
{
    my ( $this, $i ) = ( shift, 0 );
    for my $conf ( @{$this->{conf}} )
    {
        $i++;
        eval{
            my $c = $conf->{addr} ? MYDan::Project::Check::Http->new( %$conf )
                                  : MYDan::Project::Check::Port->new( %$conf );
            $c->check();
        };
        die "[check]: $i fail: $@" if $@;
    }
}

1;

__END__
