package MColPro::CollectConf;

=head1 NAME

MColPro::Collect::Conf - parse collect configuration

=cut

use strict;
use warnings;

use Carp;
use YAML::XS;
use MColPro::Util::TimeHelper;
use MColPro::Util::Serial qw( deepcopy );

our @PARAM = qw( target plugin type interval timeout );

sub new
{
    my ( $class, $conf ) = splice @_;

    confess "undefined config" unless $conf;
    $conf = readlink $conf if -l $conf;

    my $error = "invalid config $conf";
    confess "$error: not a regular file" unless -f $conf;

    eval { $conf = YAML::XS::LoadFile( $conf ) };

    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $conf ne 'HASH';

    my $self = bless $conf, ref $class || $class;

    $self->check();

    return $self;
}

sub parse
{
    my ( $this, @targets ) = @_;
    my $target = $this->{target};

    for my $t ( @$target )
    {
        if( $t->{range} )
        {
            my $range = delete $t->{range};
            map
            {
                my %t = %$t;
                $t{range} = $_;
                $t{type} = $this->{type};
                push @targets, deepcopy( \%t );
            } @$range;
        }
        else
        {
            $t->{type} = $this->{type};
            push @targets, deepcopy( $t );
        }
    }

    return \@targets;
}

sub check
{
    my $self = shift;
    map { die "$_ not defined" if ! $self->{$_} } @PARAM;
    $self->{interval} = MColPro::Util::TimeHelper::rel2sec( $self->{interval} );
    $self->{timeout} = MColPro::Util::TimeHelper::rel2sec( $self->{timeout} );
}

1;
