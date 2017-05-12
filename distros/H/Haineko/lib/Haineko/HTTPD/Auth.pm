package Haineko::HTTPD::Auth;
use feature ':5.10';
use strict;
use warnings;
use Try::Tiny;

our $PasswordDB = undef;

sub basic {
    my $class = shift;
    my $argvs = { @_ };

    return 0 unless exists $argvs->{'username'};
    return 0 unless exists $argvs->{'password'};

    my $passworddb = undef;
    my $credential = $PasswordDB // undef;
    my $exceptions = 0;

    if( not $credential ) {
        # Load username and password entries from a file
        return undef unless defined $ENV{'HAINEKO_ROOT'};
        $passworddb = sprintf( "%s/etc/password", $ENV{'HAINEKO_ROOT'} );
        $passworddb .= '-debug' if( not -f $passworddb && $ENV{'HAINEKO_DEBUG'} );
        return undef unless -f -r -s $passworddb;

        require Haineko::JSON;
        try {
            $credential = Haineko::JSON->loadfile( $passworddb );
        } catch {
            $exceptions = 1;
        };
    }

    return undef if $exceptions;
    return undef unless defined $credential;
    return undef unless keys %$credential;

    return 0 unless exists $credential->{ $argvs->{'username'} };

    my $password00 = $credential->{ $argvs->{'username'} } // undef;
    my $password01 = $argvs->{'password'};

    require Crypt::SaltedHash;
    return 1 if Crypt::SaltedHash->validate( $password00, $password01 );
    return 0;
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::HTTPD::Auth - Basic authentication at connecting Haineko server

=head1 DESCRIPTION

Haineko::HTTPD::Auth is an authenticator for Basic Authentication at connecting
Haineko server. It is called from Plack::MiddleWare::Auth::Basic in libexec/haineko.psgi.

=head1 SYNOPSIS

    use Haineko::HTTPD::Auth;
    use Haineko::JSON;
    $Haineko::HTTPD::Auth::PasswordDB = Haineko::JSON->loadfile('/path/to/password');
    builder {
        enable 'Auth::Basic', 'authenticator' => sub {
            my $u = shift;
            my $p = shift;
            return Haineko::HTTPD::Auth->basic( 'username' => $u, 'password' => $p );
        }
    };

=head1 CLASS METHODS

=head2 B<basic( I<%argvs> )>

basic() is a authenticator using $Haineko::HTTPD::Auth::PasswordDB.


=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
