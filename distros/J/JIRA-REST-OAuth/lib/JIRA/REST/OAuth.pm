package JIRA::REST::OAuth;

use base qw(JIRA::REST);

use 5.010;
use strict;
use warnings;
use utf8;

use Carp qw(croak);

use Net::OAuth();
use Net::OAuth::ProtectedResourceRequest();
use Crypt::OpenSSL::RSA();
use HTTP::Headers();
use URI();
use CGI();

our $VERSION = '1.04';

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args;
    if (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    # remove arguments for this subclass
    my @opts = qw( rsa_private_key oauth_token oauth_token_secret consumer_key );
    my %a;
    foreach my $opt (@opts) {
        croak __PACKAGE__.'::new requires argument '.$opt unless defined $args{$opt};
        $a{$opt} = delete $args{$opt};
    }

    # some sane defaults JIRA::REST
    $args{anonymous} = 1 unless exists $args{anonymous};

    my $url  = $args{url} if exists $args{url};
    my $self = $class->SUPER::new(\%args);
    $$self{url} = $url;

    # handle our options
    if (-e $a{rsa_private_key}) {
        open(my $fh, '<', $a{rsa_private_key}) or die "Unable to read $a{rsa_private_key}! $!";
        local $/ = undef;
        my $data = <$fh>;
        close($fh);

        $a{rsa_private_key} = Crypt::OpenSSL::RSA->new_private_key($data);
    }
    else {
        $a{rsa_private_key} = Crypt::OpenSSL::RSA->new_private_key($a{rsa_private_key});
    }

    foreach my $opt (@opts) {
        $$self{$opt} = delete $a{$opt};
    }

    return $self;
}

sub _generate_oauth_request
{
    my ($self, $method, $path, $query, $content, $headers) = @_;

    $path = $self->_build_path($path, $query);

    # handle headers
    if ($method =~ /^(?:PUT|POST)$/) {
        my $h;
        if ($headers) {
            eval { $h = $headers->clone(); } or do {
                $h = HTTP::Headers->new();
                $h->header(%$headers);
            };
        }
        else {
            $h = HTTP::Headers->new();
        }

        unless (length $h->content_type) {
            $h->content_type('application/json;charset=UTF-8');
        }
        unless (defined $h->header('Accept')) {
            $h->header('Accept', 'application/json');
        }
        $headers = $h;
    }

    # generate oauth request url
    my $url = $$self{url};
    $url =~ s/\/$//;
    $url .= $path;
    my %oauth_params = (
        request_url    => $url,
        request_method => $method,

        consumer_key     => $$self{consumer_key},
        consumer_secret  => 'ignore',
        signature_method => 'RSA-SHA1',
        protocol_version => Net::OAuth::PROTOCOL_VERSION_1_0,
        signature_key    => $$self{rsa_private_key},
        token            => $$self{oauth_token},
        token_secret     => $$self{oauth_token_secret},

        timestamp => time,
        nonce     => int(rand(2**32)),
    );
    if (defined $query) {
        $oauth_params{extra_params} = $query;
    }
    my $request = Net::OAuth::ProtectedResourceRequest->new(%oauth_params);
    $request->sign;

    # combine path and ouath request query stirings
    my %params;
    if ($path =~ /\?(.+)$/) {
        my $c = CGI->new($1);
        foreach my $param ($c->param) {
            $params{$param} = $c->param($param);
        }
    }

    # oauth query strings win
    %params = (%params, %{ $request->to_hash });

    # rebuild path
    $path =~ s/\?.+$//;
    $query = \%params;

    my @rv = ($path, $query);
    if ($method =~ /^(?:POST|PUT)$/) {
        @rv = ($path, $query, $content, { $headers->flatten() });
    }

    return @rv;
}

sub GET
{
    my $self = shift;
    return $self->SUPER::GET($self->_generate_oauth_request('GET', @_));
}

sub DELETE
{
    my $self = shift;
    return $self->SUPER::DELETE($self->_generate_oauth_request('DELETE', @_));
}

sub PUT
{
    my $self = shift;
    return $self->SUPER::PUT($self->_generate_oauth_request('PUT', @_));
}

sub POST
{
    my $self = shift;
    return $self->SUPER::POST($self->_generate_oauth_request('POST', @_));
}

1;

__END__

=head1 NAME

JIRA::REST::OAuth - Sub Class JIRA::REST providing OAuth 1.0 support.

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

Module is a sub-class of JIRA::REST, to provide OAuth support, no functionality 
differences between the two.

    use JIRA::REST::OAuth;
    my $jira = JIRA::REST::OAuth->new(
        {
            url                => 'https://jira.example.net',
            rsa_private_key    => '/path/to/private/key.pem',
            oauth_token        => '<oauth_token>',
            oauth_token_secret => '<oauth_token_secrete>',
            consumer_key       => '<key>',
        }
    );
    ...

=head1 EXPORT

None

=head1 AUTHOR

Adam R. Schobelock, C<< <schobes at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at 
L<https://github.com/schobes/JIRA-REST-OAuth/issues>.  I will be notified, and 
then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JIRA::REST::OAuth

You can also look for information at:

=over 4

=item * GitHub Repository

L<https://github.com/schobes/JIRA-REST-OAuth>

=item * GitHub Issue Tracker (report bugs here)

L<https://github.com/schobes/JIRA-REST-OAuth/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JIRA-REST-OAuth>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/JIRA-REST-OAuth>

=item * Search CPAN

L<https://metacpan.org/release/JIRA-REST-OAuth>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Adam R. Schobelock.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

