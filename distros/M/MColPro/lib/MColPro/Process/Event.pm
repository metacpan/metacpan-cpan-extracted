package MColPro::Process::Event;

=head1 NAME

 MColPro::Process::Event - parse process configuration

=cut

use strict;
use warnings;

use YAML::XS;
use Carp;

use MColPro::Util::TimeHelper;
use MColPro::Process::Policy;

sub new
{
    my ( $self, $file ) = @_;

    $file = eval { YAML::XS::LoadFile( $file ) };
    die "invaild conf: $@" unless $file && ref $file eq "ARRAY";

    bless &_parse( $file ), ref $self || $self;
}

sub _parse
{
    my ( $event_area ) = @_;
    my %namecheck;

    for my $event ( @$event_area )
    {
        confess "invaild conf" 
            unless $event->{name} && $event->{interval};

        confess sprintf( "name %s conflict", $event->{name} )
            if $namecheck{$event->{name}};
        $namecheck{$event->{name}} = 1;

        $event->{interval} = 
            MColPro::Util::TimeHelper::rel2sec( $event->{interval} );

        if( $event->{condition} )
        {
            while( my ( $column, $cond ) = each %{ $event->{condition} } )
            {
                if( $column eq 'label' )
                {
                    $event->{label} = &_label( $cond );
                    delete $event->{condition}{$column};
                    next;
                }

                $cond =~ s/\s//g;
                $event->{condition}{$column} = {};
                map 
                { 
                    if( $_ =~ /^-(.*)/ )
                    {
                        push @{ $event->{condition}{$column}{notin} }, $1
                            if $1;
                    }
                    else
                    {
                        push @{ $event->{condition}{$column}{in} }, $_
                    }
                } split ',', $cond;
            }
        }

        if( $event->{policy} )
        {
            while( my ( $c, $p ) = each %{ $event->{policy} } )
            {
                $event->{policy}->{$c} = MColPro::Process::Policy::parse( $p );
            }
        }
    }

    return $event_area;
}

sub _label
{
    my ( $label, %label ) = shift;

    $label =~ s/(\(|\))//g;
    map { $label{$_} = 1 } split /(&&|\|\|)/, $label;
    map
    {
        if( $_ ne "&&" && $_  ne "||" )
        {   
            s/(^\s+|\s+$)//;
            $label =~ s/$_/ \$label->{'$_'} /g;
        }   
    } keys %label;

    return $label;
}

1;
