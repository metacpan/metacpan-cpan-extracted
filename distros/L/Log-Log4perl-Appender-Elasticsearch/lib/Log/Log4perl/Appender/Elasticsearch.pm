package Log::Log4perl::Appender::Elasticsearch;
use version();
$Log::Log4perl::Appender::Elasticsearch::VERSION = version->parse("0.09");

use strict;
use warnings;
our @ISA = qw(Log::Log4perl::Appender);

use Carp;
use HTTP::Headers();
use HTTP::Request();
use JSON;
use LWP::UserAgent();
use Log::Log4perl;
use MIME::Base64;
use URI;

=head1 NAME

Log::Log4perl::Appender::Elasticsearch - implements appending to Elasticsearch

=head1 DESCRIPTION

This is a simple appender for writing log entries to Elasticsearch via L<Index API|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/docs-index_.html>.

L<Log::Log4perl::Appender::Elasticsearch::Bulk> does the same task by using L<Bulk API|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/docs-bulk.html>.

=head1 VERSION

Version 0.09

=cut

=head1 SYNOPSIS

    use Log::Log4perl;

    Log::Log4perl->init(\<<'HERE');
    log4perl.logger=DEBUG, ES

    log4perl.appender.ES = Log::Log4perl::Appender::Elasticsearch
    log4perl.appender.ES.layout = Log::Log4perl::Layout::NoopLayout

    log4perl.appender.ES.body.level = %p
    log4perl.appender.ES.body.module = %M
    log4perl.appender.ES.body.line = %L

    log4perl.appender.ES.nodes = localhost:9200
    log4perl.appender.ES.index = log4perl
    log4perl.appender.ES.type = entry

    log4perl.appender.ES.use_https = 0
    log4perl.appender.ES.user_agent.timeout = 5

    log4perl.appender.ES.headers.User-Agent = foo
    HERE

    Log::Log4perl::get_logger()->info("OK");

    # look up:
    # curl -XPOST 'http://localhost:9200/log4perl/_search' -d \
    # '{"query": {"query_string": {"query": "level:INFO AND message:OK"}}}'
    # ...
    #         "_source": {
    #           "module": "main::__ANON__",
    #           "line": "60",
    #           "level": "INFO",
    #           "message": "OK"
    #        }


=head1 OPTIONS

=over 4

=item

nodes

a comma separeted list of nodes. The message will be sent to the next node only if previous request failed

=item

index

The name of the elasticsearch index the message will be stored in.

=item

type

The name of the type in given index the message belongs to.

=item

use_https

0|1 global https setting for all nodes

the individual https setting possible too:

C<log4perl.appender.ES.nodes = https://user:password@node1:9200,localhost:9200>

=item

user_agent

LWP::UserAgent parameters

C<log4perl.appender.ES.user_agent.timeout = 5>

=item

headers

HTTP::Headers parameters

C<log4perl.appender.ES.headers.User-Agent = foo>

=back

=cut

sub new {
    my ($proto, %p) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;

    $self->_init(%p);
    return $self;
} ## end sub new

sub index {
    my ($self, $index) = @_;
    if (defined $index) {
        $self->{_index} = $index;
    }

    return $self->{_index};
} ## end sub index

sub type {
    my ($self, $type) = @_;
    if (defined $type) {
        $self->{_type} = $type;
    }

    return $self->{_type};
} ## end sub type

sub log {
    my ($self, %p) = @_;
    $self->_send_request($self->_to_json($self->_prepare_body(%p)));
}

sub _init {
    my ($self, %p) = @_;

    defined($p{nodes})
        || Carp::croak('Log4perl: nodes not set in ', __PACKAGE__);

    my $use_https = delete($p{use_https});
    foreach (split ',', delete($p{nodes})) {
        (my $node = $_) =~ s/^\s+|\s+$//g;
        unless ($node =~ m{^http(s)?://}) {
            $node = ($use_https ? 'https://' : 'http://') . $node;
        }

        my $uri = URI->new($node);
        push @{ $self->{_nodes} }, $uri;
    } ## end foreach (split ',', delete(...))

    foreach my $k (qw/index type/) {
        my $v = delete($p{$k});
        $v || Carp::croak("Log4perl: $k not set in ", __PACKAGE__);
        $self->$k($v);
    }

    my $b = delete($p{body});
    scalar(keys %{$b})
        || Carp::croak('Log4perl: body not set in ', __PACKAGE__);

    foreach my $k (keys %{$b}) {
        $k eq 'message' && Carp::croak(
            "Log4perl: choose an other key name instead $k. The key $k is used to store the logging message ",
            __PACKAGE__
        );
        $self->{_body}{$k} = Log::Log4perl::Layout::PatternLayout->new(
            { ConversionPattern => { value => $b->{$k} } });
    } ## end foreach my $k (keys %{$b})

    my $h = delete($p{headers});
    $self->{_headers} = HTTP::Headers->new(%{$h});

    my $up = delete($p{user_agent});
    $self->{_user_agent} = LWP::UserAgent->new(%{$up});

    foreach my $k (keys %p) {
        $self->{$k} = $p{$k};
    }
} ## end sub _init

sub _send_request {
    my ($self, $data, $suffix) = @_;
    my @nodes = @{ $self->{_nodes} };
    my (@errors, $ok);
    do {
        my $node = shift @nodes;
        my $uri  = $self->_uri($node, $suffix);
        my $req  = $self->_request($uri, $data);

        my $resp = $self->{_user_agent}->request($req);
        $ok = $resp->is_success;
        if (!$ok) {
            push @errors, join ': ', $uri, $resp->status_line;
        }
    } while (!$ok && scalar(@nodes));

    $ok || Carp::croak('coud not send log the message to any node: ',
        join '; ', @errors);
} ## end sub _send_request

sub _uri {
    my ($self, $node, $suffix) = @_;
    my $uri = $node->clone;
    $uri->path(join '', $uri->path,
        join('/', $self->{_index}, $self->{_type}, $suffix ? $suffix : ''));

    return $uri;
} ## end sub _uri

sub _headers {
    my ($self, $uri) = @_;
    my $h = $self->{_headers}->clone;
    $h->header('Content-Type' => 'application/json');

    my $ui = $uri->userinfo;
    if ($ui) {
        my $auth = MIME::Base64::encode_base64($ui);
        chomp $auth;
        $h->header(Authorization => "Basic $auth");
    }

    return $h;
} ## end sub _headers

sub _request {
    my ($self, $uri, $data) = @_;

    return HTTP::Request->new(
        POST => $uri,
        $self->_headers($uri),
        $data
    );
} ## end sub _request

sub _prepare_body {
    my ($self, %p) = @_;

    my $b = {};
    foreach my $k (keys %{ $self->{_body} }) {
        my $v
            = $self->{_body}{$k}
            ->render($p{message}, $p{log4p_category}, $p{log4p_level},
            5 + $Log::Log4perl::caller_depth,
            );

        $b->{$k} = $v;
    } ## end foreach my $k (keys %{ $self...})

    $b->{message} = $p{message};

    return $b;
} ## end sub _prepare_body

sub _to_json {
    my ($self, $o) = @_;
    return JSON::encode_json($o);
}

1;    # End of Log::Log4perl::Appender::Elasticsearch
__END__

=head1 AUTHOR

Alexei Pastuchov C<< <palik at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/p-alik/Log-Log4perl-Appender-Elasticsearch.git>

=head1 LICENSE AND COPYRIGHT

Copyright 2014, 2015 by Alexei Pastuchov E<lt>palik at cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
