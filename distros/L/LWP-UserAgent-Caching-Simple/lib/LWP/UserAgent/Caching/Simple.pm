package LWP::UserAgent::Caching::Simple;

=head1 NAME

LWP::UserAgent::Caching::Simple - The first 'hard thing' made easy --- simple

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

use strict;
use warnings;

use parent 'LWP::UserAgent::Caching';
use HTTP::Request;

use CHI;
use JSON;

use parent 'Exporter';
our @EXPORT_OK = qw(get_from_json);

=head1 SYNOPSIS

    use LWP::UserAgent::Caching::Simple;
    
    my $ua = LWP::UserAgent::Caching::Simple->new;
    
    my $resp = $ua->get( 'http://example.com/cached?' );

and maybe even something quick:

    # use a built-in default User-Agent for quick one timers
    
    use LWP::UserAgent::Caching::Simple qw(get_from_json);
    
    my $hashref = get_from_json ( 'http://example.com/cached?' );


=head1 DESCRIPTION

This is a simplified version of L<LWP::UserAgent::Caching> with sensible
defaults and less options. For more control and more options, please use that
module.

=cut

sub _chi_cache {
    return CHI->new(
        driver          => 'File',
        root_dir        => '/tmp/LWP_UserAgent_Caching',
        file_extension  => '.cache',
    )
}

sub new {
    my ( $class) = @_;
    
    my $self = $class->SUPER::new(
        http_caching => {
            cache           => _chi_cache(),
        }
    );
    
    return $self
}

{
    my $ua;
    sub _default_useragent {
        $ua = __PACKAGE__->new() unless $ua;
        return $ua
    }
}

sub get_from_json {
    my $rqst = HTTP::Request->new(
        GET => $_[0],
        [ Accept => 'application/json' ]
    );
    my $resp = _default_useragent()->request($rqst);
    return from_json($resp->content()) if $resp->is_success;
    warn "HTTP Status message ${\$resp->code} [${\$resp->message}] GET $_[0]\n";
    return
    
}

=head1 METHODS

Since this is a subclass of L<LWP::UserAgent::Caching> it has it's methods, like
the following object methods:

=over

=item request

=item get

=item post

=item put

=item delete

=back

And to make life realy simple, when imported, one function

=over

=item get_from_json

this will simply make a GET request to a server, with the C<Accept> Header set
to C<application/json>. On succes, it will turn the returned json (as requested)
into a perl data structure. Otherwise it will be C<undef> and print a warning.

=back

=head1 CAVEATS

This is a super simplified way of making a straightforward request. It can
handle more complex requests as well, using

    my $resp = $ua->request($http_rqst);

which will give a full C<HTTP::Response> object back. The UserAgent is a full
subclass of the standard L<LWP::UserAgent>, and one can still change the setting
of that, like e.g. the C<< $ua->agent('SecretAgent/007') >>. But if you need
more control over your cache, you definitely need to fall back to
L<LWP::UserAgent::Caching>

=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA.nl> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 .. 2018 Theo van Hoesel.

=cut

1;
