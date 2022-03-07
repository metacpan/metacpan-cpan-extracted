package Google::RestApi::Auth;

our $VERSION = '1.0.1';

use Google::RestApi::Setup;

sub params {{}}
sub headers {[]};

1;

__END__

=head1 NAME

Google::RestApi::Auth - Base class for authorization for Google Rest APIs

=head1 DESCRIPTION

Small base class that establishes the contract between RestApi and the
various possible authorization methods. If the auth class expects to be
able to add a param to each URL (outdated), it will be called via 'params'
when the time comes to add them to the calling URL. If the auth class
expects to add an authorization header, it will be called via 'headers'
to return the proper headers for that auth class.

The default behaviour is to return nothing for each, so the derived class
has to return at least something for one of them to be functional.
