package MColPro::Process::Policy;

=head1 NAME

 MColPro::Process::Policy - parse report policy

=cut

use strict;
use warnings;

use YAML::XS;
use POSIX qw( INT_MAX );
use Carp;
use DynGig::Range::String;

sub parse
{
    my $policy = shift;
    my %policy;

    confess "invaild policy conf" unless $policy && ref $policy eq 'ARRAY';

    map
    {
        if( $_->{count} )
        {
            my $count = $_->{count};
            $count =~ s/\s//g;
            my ( $due, $step ) = split ':', $count;
            confess "invaild policy conf" unless $due;
            $step ||= 1;
            my ( $start, $end ) = split '-', $due;
            confess "invaild policy conf" unless $start && $end;
            $_->{count} = [ $start + 0, $end eq '*' ? INT_MAX : $end + 0 ];
            $_->{step} = $step + 0;
        }
        else
        {
            $_->{count} = [ 0, INT_MAX ];
            $_->{step} = 1;
        }

        if( $_->{reciver} )
        {
            my $reciver = $_->{reciver};
            $reciver =~ s/\s//g;
            $_->{reciver} = [ split ',', $reciver ];
        }
        else
        {
            $_->{reciver} = [];
        }

        if( $_->{time} )
        {
            if( $_->{time} =~ /(\d{1,2}:\d{2}~\d{1,2}:\d{2})({\d~\d})?/ )
            {
                $_->{time} = {};

                for my $t ( split '~', $1 )
                {
                    $t = '0'.$t if $t =~ /^\d{1}:/;
                    push @{ $_->{time}{hm} }, $t;
                }
                $_->{time}{hm} = [ sort @{ $_->{time}{hm} } ];

                if( defined $2 )
                {
                    my @week = DynGig::Range::String->expand( $2 );
                    croak "invaild policy time config" unless @week;
                    for my $t ( @week )
                    {
                        croak "invaild policy time config" if $t !~ /[0-6]/;
                        $_->{time}{wday}{$t} = 1;
                    }
                }
                else
                {
                    $_->{time}{wday} = map { $_ => 1 } ( 0..6 );
                }
            }
            else
            {
                confess "invaild policy time range";
            }
        }

        push @{ $policy{stair} }, $_;
    } @$policy;

    return \%policy;
}

1;
