package Lemonldap::NG::Common::Conf::Serializer;

use strict;
use utf8;
use Encode;
use JSON;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.0.12';

BEGIN {
    *Lemonldap::NG::Common::Conf::normalize      = \&normalize;
    *Lemonldap::NG::Common::Conf::unnormalize    = \&unnormalize;
    *Lemonldap::NG::Common::Conf::serialize      = \&serialize;
    *Lemonldap::NG::Common::Conf::unserialize    = \&unserialize;
    *Lemonldap::NG::Common::Conf::oldUnserialize = \&oldUnserialize;
}

## @method string normalize(string value)
# Change quotes, spaces and line breaks
# @param value Input value
# @return normalized string
sub normalize {
    my ( $self, $value ) = @_;

    # trim white spaces
    $value =~ s/^\s*(.*?)\s*$/$1/;

    # Convert carriage returns (\r) and line feeds (\n)
    $value =~ s/\r/%0D/g;
    $value =~ s/\n/%0A/g;

    # Convert simple quotes
    $value =~ s/'/&#39;/g;

    # Surround with simple quotes
    $value = "'$value'" unless ( $self->{noQuotes} );

    return $value;
}

## @method string unnormalize(string value)
# Revert quotes, spaces and line breaks
# @param value Input value
# @return unnormalized string
sub unnormalize {
    my ( $self, $value ) = @_;

    # Convert simple quotes
    $value =~ s/&#?39;/'/g;

    # Convert carriage returns (\r) and line feeds (\n)
    $value =~ s/%0D/\r/g;
    $value =~ s/%0A/\n/g;

    # Keep number as numbers
    $value += 0 if ( $value =~ /^(?:0|(?:\-[0-9]|[1-9])[0-9]*)(?:\.[0-9]+)?$/ );

    return $value;
}

## @method hashref serialize(hashref conf)
# Parse configuration and convert it into fields
# @param conf Configuration
# @return fields
sub serialize {
    my ( $self, $conf ) = @_;
    my $fields;

    # Parse configuration
    foreach my $k ( keys %$conf ) {
        my $v = $conf->{$k};

        # 1.Hash ref
        if ( ref($v) ) {
            $fields->{$k} = to_json($v);
        }
        else {
            $fields->{$k} = $v;
        }
    }

    return $fields;
}

## @method hashref unserialize(hashref fields)
# Convert fields into configuration
# @param fields Fields
# @return configuration
sub unserialize {
    my ( $self, $fields ) = @_;
    my $conf;

    # Parse fields
    foreach my $k ( keys %$fields ) {
        my $v = $fields->{$k};
        if ( $k =~ $hashParameters ) {
            unless ( utf8::is_utf8($v) ) {
                $v = encode( 'UTF-8', $v );
            }
            $conf->{$k} = (
                $v =~ /./
                ? eval { from_json( $v, { allow_nonref => 1 } ) }
                : {}
            );
            if ($@) {
                $Lemonldap::NG::Common::Conf::msg .=
                  "Unable to decode $k, switching to old format.\n";
                return $self->oldUnserialize($fields);
            }
        }
        elsif ( $k =~ $arrayParameters ) {
            unless ( utf8::is_utf8($v) ) {
                $v = encode( 'UTF-8', $v );
            }
            $conf->{$k} = (
                $v =~ /./
                ? eval { from_json( $v, { allow_nonref => 1 } ) }
                : {}
            );
            if ($@) {
                $Lemonldap::NG::Common::Conf::msg .=
                  "Unable to decode $k, switching to old format.\n";
                return $self->oldUnserialize($fields);
            }
        }
        else {
            $conf->{$k} = $v;
        }
    }
    return $conf;
}

sub oldUnserialize {
    my ( $self, $fields ) = @_;
    my $conf;

    # Parse fields
    while ( my ( $k, $v ) = each(%$fields) ) {

        # Remove surrounding quotes
        $v =~ s/^'(.*)'$/$1/s;

        # Manage hashes

        if ( $k =~ $hashParameters and $v ||= {} and not ref($v) ) {
            $conf->{$k} = {};

            # Value should be a Data::Dumper, else this is an old-old format
            if ( defined($v) and $v !~ /^\$/ ) {

                $Lemonldap::NG::Common::Conf::msg .=
" Warning: configuration is in old format, you've to migrate!";

                eval { require Storable; require MIME::Base64; };
                if ($@) {
                    $Lemonldap::NG::Common::Conf::msg .= " Error: $@";
                    return 0;
                }
                $conf->{$k} = Storable::thaw( MIME::Base64::decode_base64($v) );
            }

            # Convert Data::Dumper
            else {
                my $data;
                $v =~ s/^\$([_a-zA-Z][_a-zA-Z0-9]*) *=/\$data =/;
                $v = $self->unnormalize($v);

                # Evaluate expression
                eval $v;

                if ($@) {
                    $Lemonldap::NG::Common::Conf::msg .=
                      " Error: cannot read configuration key $k: $@";
                }

                # Store value in configuration object
                $conf->{$k} = $data;
            }
        }

        # Other fields type
        else {
            $conf->{$k} = $self->unnormalize($v);
        }
    }

    return $conf;
}

1;
__END__
