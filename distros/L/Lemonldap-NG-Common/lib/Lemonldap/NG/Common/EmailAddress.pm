package Lemonldap::NG::Common::EmailAddress;

use strict;
use Exporter;

our @ISA     = qw(Exporter);
our $VERSION = '2.0.0';

our @EXPORT_OK = qw(format_email);
our @EXPORT    = qw(format_email);

my $module;

BEGIN {
    eval {
        require Email::Address::XS;
        $module = 'Email::Address::XS';
    };
    if ($@) {
        eval {
            require Email::Address;
            $module = 'Email::Address';
        };
        die "Unable to find Email::Address, neither Email::Address::XS: $@"
          if ($@);
    }
}

sub format_email {
    my ( $name, $email ) = @_;
    my $obj = $module->new( $name, $email );
    return $obj->as_string;
}

1;
