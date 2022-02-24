package Lemonldap::NG::Manager::Conf::Diff;

use strict;
use Mouse;
use Lemonldap::NG::Manager::Conf::Parser;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.0.8';

*defaultValue = \&Lemonldap::NG::Manager::Conf::Parser::defaultValue;

sub diff {
    my ( $self, @conf ) = @_;
    my @res;
    my @keys = ( [ keys %{ $conf[0] } ], [ keys %{ $conf[1] } ] );
    while ( my $key = shift @{ $keys[0] } ) {
        if ( $key eq 'applicationList' ) {
            my @tmp = appListDiff( $self, $conf[0]->{$key}, $conf[1]->{$key} );
            for ( my $i = 0 ; $i < @tmp ; $i++ ) {
                $res[$i]->{$key} = $tmp[$i] if ( $tmp[$i] );
            }
        }
        elsif (
            $key =~ $hashParameters
            or ( ref( $conf[0]->{$key} ) and ref( $conf[0]->{$key} ) eq 'HASH' )
          )
        {
            if ( ref $conf[1]->{$key} ) {
                my @tmp =
                  diff( $self, $conf[0]->{$key}, $conf[1]->{$key}, 1 );
                for ( my $i = 0 ; $i < @tmp ; $i++ ) {
                    $res[$i]->{$key} = $tmp[$i] if ( $tmp[$i] );
                }
            }
            elsif ( ref( $conf[0]->{$key} ) and %{ $conf[0]->{$key} } ) {
                $res[0]->{$key} = $conf[0]->{$key} if ( %{ $conf[0]->{$key} } );
            }
        }
        elsif ( ref $conf[0]->{$key} eq 'ARRAY' ) {
            unless ( defined( $conf[1]->{$key} ) ) {
                $res[0]->{$key} = $conf[0]->{$key};
            }
            else {
                for ( my $i = 0 ; $i < @{ $conf[0]->{$key} } ; $i++ ) {
                    if ( defined $conf[1]->{$key}->[$i] ) {
                        if ( ref $conf[0]->{$key}->[$i] ) {

                            # TODO: array comp
                        }
                        elsif (
                            $conf[0]->{$key}->[$i] ne $conf[1]->{$key}->[$i] )
                        {
                            push @{ $res[0]->{$key} }, $conf[0]->{$key}->[$i];
                            push @{ $res[1]->{$key} }, $conf[1]->{$key}->[$i];
                        }
                    }
                    else {
                        push @{ $res[0]->{$key} }, $conf[0]->{$key}->[$i];
                    }
                }
                for (
                    my $i = @{ $conf[0]->{$key} } ;
                    $i < @{ $conf[1]->{$key} } ;
                    $i++
                  )
                {
                    push @{ $res[1]->{$key} }, $conf[1]->{$key}->[$i];
                }
            }
        }
        elsif ( exists $conf[1]->{$key} ) {
            if ( $conf[0]->{$key} ne $conf[1]->{$key} ) {
                $self->logger->debug( "Key $key has changed : "
                      . $conf[0]->{$key} . " -> "
                      . $conf[1]->{$key} );
                $res[0]->{$key} = $conf[0]->{$key};
                $res[1]->{$key} = $conf[1]->{$key};
            }
        }
        elsif (
            $conf[2]
            or (    defined( $conf[0]->{$key} )
                and defined( defaultValue( $self, $key ) )
                and $conf[0]->{$key} ne defaultValue( $self, $key ) )
          )
        {
            $res[0]->{$key} = $conf[0]->{$key} if ( defined $conf[0]->{$key} );
        }
        $keys[1] = [ grep { $_ ne $key } @{ $keys[1] } ];
    }
    while ( my $key = shift @{ $keys[1] } ) {
        next unless ( defined( $conf[1]->{$key} ) );
        next if ( $key =~ $hashParameters and not( %{ $conf[1]->{$key} } ) );
        if ( (
                not ref( $conf[1]->{$key} ) and not( (
                        defined defaultValue( $self, $key )
                        and $conf[1]->{$key} eq defaultValue( $self, $key )
                    )
                )
            )
            or ( ref( $conf[1]->{$key} ) eq 'HASH' and %{ $conf[1]->{$key} } )
          )
        {
            $res[1]->{$key} = $conf[1]->{$key};
        }
    }
    return @res;
}

sub appListDiff {
    my ( $self, @conf ) = @_;
    my @res;
    my @keys = (
        [ sort grep { $_ !~ /^(?:catname|type|order)$/ } keys %{ $conf[0] } ],
        [ sort grep { $_ !~ /^(?:catname|type|order)$/ } keys %{ $conf[1] } ]
    );
    while ( my $key = shift @{ $keys[0] } ) {

        # Checking for categories
        if ( $conf[0]->{$key}->{type} eq 'category' ) {
            my $cat   = $conf[0]->{$key}->{catname};
            my $found = undef;
            my ( @newK, @newC );
            for ( my $i = 0 ; $i < @{ $keys[1] } ; $i++ ) {
                if ( $conf[1]->{ $keys[1]->[$i] }->{catname} eq $cat ) {
                    $found = $i;
                }
                else {
                    push @newK, $keys[1]->[$i];
                }
            }

            # Same category found, checking for subnodes
            if ( defined $found ) {
                my @tmp = appListDiff(
                    $self,
                    $conf[0]->{$key},
                    $conf[1]->{ $keys[1]->[$found] }
                );
                for ( my $i = 0 ; $i < @tmp ; $i++ ) {
                    $res[$i]->{$cat} = $tmp[$i] if ( $tmp[$i] );
                }

                $keys[1] = \@newK;
            }

            # Category doesn't exists in new conf
            else {
                $res[0]->{$cat} = $conf[0]->{$key};
            }
        }

        # Checking for applications
        else {
            my $name = $conf[0]->{$key}->{options}->{name};

            # Searching for the same name in new conf
            my $found = undef;
            my ( @newK, @newC );
            for ( my $i = 0 ; $i < @{ $keys[1] } ; $i++ ) {
                if ( $conf[1]->{ $keys[1]->[$i] }->{options}->{name} eq $name )
                {
                    # Same name found, checking for diff in options
                    my $diff = 0;
                    foreach my $k (
                        keys %{ $conf[1]->{ $keys[1]->[$i] }->{options} } )
                    {
                        unless (
                            $conf[1]->{ $keys[1]->[$i] }->{options}->{$k} eq
                            $conf[0]->{$key}->{options}->{$k} )
                        {
                            $res[0]->{$name}->{options}->{$k} =
                              $conf[0]->{$key}->{options}->{$k};
                            $res[1]->{$name}->{options}->{$k} =
                              $conf[1]->{$key}->{options}->{$k};
                        }
                    }
                    $found = $i unless ($diff);
                }
                else {
                    push @newK, $keys[1]->[$i];
                }
            }
            if ( defined $found ) {
                $keys[1] = \@newK;
            }

            # Not found
            else {
                $res[0]->{$name} = $conf[0]->{$key};
            }
        }
    }

    while ( my $key = shift @{ $keys[1] } ) {
        my @tmp = _copyAppList( $self, $conf[1]->{$key} );
        $res[1]->{ $tmp[0] } = $tmp[1];
    }
    return @res;
}

sub _copyAppList {
    my ( $self, $conf ) = @_;
    my %res;
    if ( $conf->{type} eq 'category' ) {
        foreach ( grep { $_ !~ /^(?:catname|type|order)$/ } keys %$conf ) {
            my @tmp = _copyAppList( $self, $conf->{$_} );
            $res{ $tmp[0] } = $tmp[1];
        }
        $res{type}    = 'category';
        $res{catname} = $conf->{catname};
        return $conf->{catname} => \%res;
    }
    else {
        return $conf->{options}->{name} => $conf;
    }
}

1;
