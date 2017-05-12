package Lemonldap::NG::Handler::API;

use Exporter 'import';

our $VERSION = '1.9.1';
our ( %EXPORT_TAGS, @EXPORT_OK, @EXPORT );
our $mode;

BEGIN {
    %EXPORT_TAGS = (
        httpCodes => [
            qw( MP OK REDIRECT HTTP_UNAUTHORIZED FORBIDDEN DONE DECLINED SERVER_ERROR AUTH_REQUIRED MAINTENANCE )
        ],
        functions => [
            qw( &hostname &remote_ip &uri &uri_with_args
              &unparsed_uri &args &method &header_in )
        ]
    );
    push( @EXPORT_OK, @{ $EXPORT_TAGS{$_} } ) foreach ( keys %EXPORT_TAGS );
    $EXPORT_TAGS{all} = \@EXPORT_OK;

    if ( exists $ENV{MOD_PERL} ) {
        if ( $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 ) {
            eval 'use constant MP => 2;';
        }
        else {
            eval 'use constant MP => 1;';
        }
    }
    else {
        eval 'use constant MP => 0;';
    }

}

sub AUTOLOAD {
    my $func = $AUTOLOAD;
    $func =~ s/^.*:://;

    # Launch appropriate specific API function:
    # - Apache (modperl 2),
    # - Apache (modperl1),
    # - Nginx
    if ( !$mode or $func eq 'newRequest' ) {

        #print STDERR "FONCTION $func\n";
        #for ( my $i = 0 ; $i < 7 ; $i++ ) {
        #    print STDERR "    $i: " . ( caller($i) )[0] . "\n";
        #}
        $mode =
          (
            ( caller(1) )[0] =~
              /^Lemonldap::NG::Handler::(?:Nginx|PSGI::Server)$/
              or ( caller(6)
                and ( caller(6) )[0] =~
                /^Lemonldap::NG::Handler::(?:Nginx|PSGI::Server)$/ )
          ) ? 'PSGI/Server'
          : (
            ( caller(0) )[0] =~ /^Lemonldap::NG::Handler::PSGI/
              or (
                (
                        ( caller(6) )[0]
                    and ( ( caller(6) )[0] =~ /^Lemonldap::NG::Handler::PSGI/ )
                )
              )
          ) ? 'PSGI'
          : ( $ENV{GATEWAY_INTERFACE}
              and !( ref $_[1] eq 'Apache2::RequestRec' ) ) ? 'CGI'
          : ( MP == 2 )        ? 'ApacheMP2'
          : ( MP == 1 )        ? 'ApacheMP1'
          : $main::{'nginx::'} ? 'ExperimentalNginx'
          :                      'CGI';
        unless ( $INC{"Lemonldap/NG/Handler/API/$mode.pm"} ) {
            $mode =~ s#/#::#g;
            eval
"use Lemonldap::NG::Handler::API::$mode (':httpCodes', ':functions');";
            die $@ if ($@);
        }
        $mode =~ s#/#::#g;
    }
    shift;
    return "Lemonldap::NG::Handler::API::${mode}"->${func}(@_);
}

1;
