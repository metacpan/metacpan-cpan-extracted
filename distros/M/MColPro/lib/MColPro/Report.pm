package MColPro::Report;

=head1 NAME

 MColPro::Report - Report warning to contacts

=cut

use warnings;
use strict;

use Carp;
use lib '/devops/tools/lib';
use Devops::Contacts;

sub new
{
    my ( $this, $conf, $sqlbase ) = @_;

    my %class;
    $class{mysql} = $sqlbase;
    $class{report} = $conf->{report};
    $class{email} = $conf->{email};
    $class{sms} = $conf->{sms};

    $class{contacts} = Devops::Contacts->new
    (
        db => '/devops/tools/var/contacts/contacts.db'
    );

    my $i = 0;
    map { $class{column}{$_} = $i++ }
        qw( id time name cluster node content receiver rid );
    bless \%class, ref $this || $this;
}

sub report
{
    my ( $this, $name, $param ) = @_;

    my ( $sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst )
        = localtime();
    $year += 1900;
    $mon  += 1;
    my $smstime = sprintf( "%d/%d %02d:%02d"
        , $day, $mon, $hour, $min );
    my $emailtime = sprintf( "%d-%02d-%02d %02d:%02d:%02d"
        , $year, $mon, $day, $hour, $min, $sec );

    while( my ( $cluster, $info ) = each %$param )
    {
        my $contacts = { mail => [], phone => [] };
        my @contacts;
        for my $item ( @{ $info->{contacts} } )
        {
            if( $item =~ /@/ )
            {
                push @{ $contacts->{mail} }, $item;
            }
            elsif( $item =~ /^\d{11}$/ )
            {
                push @{ $contacts->{phone} }, $item;
            }
            else
            {
                map
                {
                    /^\d{11}$/
                        ? push @{ $contacts->{phone} }, $_
                        : push @{ $contacts->{mail} }, $_
                } $this->{contacts}->get_addr( $item );
            }
        }

        ## Email report
        $this->{email}
        (
             subject => sprintf( '%s %s', $name, $cluster ),
             to      => $contacts->{mail},
             message => $emailtime.$info->{email},
        ) if $this->{email} && @{ $contacts->{mail} };

        for my $item ( @{ $info->{info} } )
        {
            ## SMS report
            $this->{sms}
            (
                 number  => $contacts->{phone},
                 message => sprintf( "%s: %s %s %s", 
                    $smstime, $cluster, $item->[0], $item->[1] ),
            ) if $this->{sms} && @{ $contacts->{phone} };

            $this->_savemsg
            ( 
                name => $name,
                cluster => $cluster,
                node => $item->[0],
                content => $item->[1],
                rid => $item->[2],
                receiver => join ',', @{ $info->{contacts} },
            );
        }
    }
}

sub _savemsg
{
    my ( $this, %param ) = @_;

    my @c = grep { $this->{column}{$_} > 1 } keys %{ $this->{column} };

    map { return unless defined $param{$_} } @c;

    $this->{mysql}->dbquery
    (
        sprintf( "INSERT INTO %s ( %s ) VALUES ( %s )", $this->{report}
            , ( join ',', @c )
            , ( join ',', map{"'$param{$_}'"} @c ) )
    );
}

1;

__END__
