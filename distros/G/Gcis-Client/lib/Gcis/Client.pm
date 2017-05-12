package Gcis::Client;
use Mojo::UserAgent;
use Mojo::Base -base;
use Mojo::Log;
use JSON::XS;
use YAML::XS qw/LoadFile/;
use Path::Class qw/file/;
use Data::Dumper;
use Time::HiRes qw/sleep/;
use v5.14;

our $VERSION = '0.12';

has url      => 'http://localhost:3000';
has 'key';
has 'error';
has 'delay' => $ENV{GCIS_API_DELAY};
has ua => sub {
  my $c = shift;
  state $ua;
  return $ua if $ua;
  $ua = Mojo::UserAgent->new();
  $ua->on(
    start => sub {
      my ($ua, $tx) = @_;
      $tx->req->headers->header($c->auth_hdr) if $c->auth_hdr;
      $tx->req->headers->header(Accept => $c->accept);
    }
  );
  $ua->max_redirects(5);
  $ua;
};
has logger   => sub { state $log  ||= Mojo::Log->new(); };
has json     => sub { state $json ||= JSON::XS->new(); };
has accept   => "application/json";
has 'tx';

sub auth_hdr { ($a = shift->key) ? ("Authorization" => "Basic $a") : () }

sub get {
    my $s = shift;
    my $path = shift or die "missing path";
    my $params = shift;
    if (defined($s->delay)) {
        $s->logger->debug("sleeping for ".$s->delay.'s');
        sleep $s->delay;
    }
    my $url;
    if ($params) {
        $url = Mojo::URL->new($s->url);
        $url->path($path);
        $url->query(%$params);
    } else {
        $url = Mojo::URL->new($s->url.$path);
    }
    my $tx = $s->ua->get($url);
    $s->tx($tx);
    my $res = $tx->success;
    unless ($res) {
        if ($tx->res->code && $tx->res->code == 404) {
            # $s->logger->debug("not found : $path");
            $s->error("not found : $path");
            return;
        }
        $s->error($tx->error->{message});
        $s->logger->error($tx->error->{message});
        return;
    };
    my $json = $res->json or do {
        $s->logger->debug("no json from $path : ".$res->to_string);
        $s->error("No JSON returned from $path : ".$res->to_string);
        return;
    };
    return wantarray && ref($json) eq 'ARRAY' ? @$json : $json;
}

sub post {
    my $s = shift;
    my $path = shift or Carp::confess "missing path";
    my $data = shift;
    my $tx = $s->ua->post($s->url."$path" => json => $data );
    $s->tx($tx);
    my $res = $tx->success or do {
        $s->logger->error("got an error $path : ".Dumper($tx->error->{message}).$tx->res->body);
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}

sub delete {
    my $s = shift;
    my $path = shift;
    my $payload = shift;
    my $tx = $s->ua->delete($s->url."$path", ( $payload ? (json => $payload) : () ) );
    $s->tx($tx);
    my $res = $tx->success;
    unless ($res) {
        if ($tx->res->code && $tx->res->code == 404) {
            $s->error("not found : $path");
            return;
        }
        $s->error($tx->error->{message});
        $s->logger->error($tx->error->{message});
        return;
    };
    return $res->body;
}

sub put_file {
    my $s = shift;
    my $path = shift;
    my $file = shift;
    my $data = file($file)->slurp;
    my $tx = $s->ua->put($s->url."$path" => $data );
    $s->tx($tx);
    my $res = $tx->success or do {
        $s->error(join "\n",$tx->error->{message},$tx->res->body);
        $s->logger->error($path." : ".$tx->error->{message});
        $s->logger->error($tx->res->body);
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}

sub add_file_url {
    my $s = shift;
    my $gcid = shift;
    my $args = shift;
    my $path = $gcid;
    $path =~ s[/([^/]+)$][/files/$1];
    $s->post($path => $args);
}

sub post_quiet {
    my $s = shift;
    my $path = shift;
    my $data = shift;
    my $tx = $s->ua->post($s->url."$path" => json => $data );
    $s->tx($tx);
    my $res = $tx->success or do {
        $s->logger->error("$path : ".$tx->error.$tx->res->body) unless $tx->res->code == 404;
        return;
    };
    return unless $res;
    my $json = $res->json or return $res->body;
    return $res->json;
}

sub find_credentials {
    my $s = shift;
    my $home = $ENV{HOME};
    die "need url to find credentials" unless $s->url;
    my $conf_file = "$home/etc/Gcis.conf";
    -e $conf_file or die "Missing $conf_file";
    my $conf = LoadFile($conf_file);
    my @found = grep { $_->{url} eq $s->url } @$conf;
    die "Multiple matches for ".$s->url." in $conf_file." if @found > 1;
    die "No matches for ".$s->url." in $conf_file." if @found < 1;
    my $key = $found[0]->{key} or die "no key for ".$s->url." in $conf_file";
    $s->logger->info("Loaded configuration from $conf_file");
    $s->key($key);
    return $s;
}

sub login {
    my $c = shift;
    my $got = $c->get('/login') or return;
    $c->get('/login')->{login} eq 'ok' or return;
    return $c;
}

sub use_env {
    my $c = shift;
    my $url = $ENV{GCIS_API_URL} or die "please set GCIS_API_URL";
    $c->url($url);
    return $c;
}

sub get_chapter_map {
    my $c = shift;
    my $report = shift or die "no report";
    my $all = $c->get("/report/$report/chapter?all=1") or die $c->url.' : '.$c->error;
    my %map = map { $_->{number} // $_->{identifier} => $_->{identifier} } @$all;
    return wantarray ? %map : \%map;
}

sub tables {
    my $c = shift;
    my %a = @_;
    my $report = $a{report} or die "no report";
    if (my $chapter_number = $a{chapter_number}) {
        $c->{_chapter_map}->{$report} //= $c->get_chapter_map($report);
        $a{chapter} = $c->{_chapter_map}->{$report}->{$chapter_number};
    }
    my $tables;
    if (my $chapter = $a{chapter}) {
        $tables = $c->get("/report/$report/chapter/$chapter/table?all=1") or die $c->error;
    } else {
        $tables = $c->get("/report/$report/table?all=1") or die $c->error;
    }
    return wantarray ? @$tables : $tables;
}

sub figures {
    my $c = shift;
    my %a = @_;
    my $report = $a{report} or die "no report";
    if (my $chapter_number = $a{chapter_number}) {
        $c->{_chapter_map}->{$report} //= $c->get_chapter_map($report);
        $a{chapter} = $c->{_chapter_map}->{$report}->{$chapter_number};
    }
    my $figures;
    if (my $chapter = $a{chapter}) {
        $figures = $c->get("/report/$report/chapter/$chapter/figure?all=1") or die $c->error;
    } else {
        $figures = $c->get("/report/$report/figure?all=1") or die $c->error;
    }
    return wantarray ? @$figures : $figures;
}

sub findings {
    my $c = shift;
    my %a = @_;
    my $report = $a{report} or die "no report";
    if (my $chapter_number = $a{chapter_number}) {
        $c->{_chapter_map}->{$report} //= $c->get_chapter_map($report);
        $a{chapter} = $c->{_chapter_map}->{$report}->{$chapter_number};
    }
    my $findings;
    if (my $chapter = $a{chapter}) {
        $findings = $c->get("/report/$report/chapter/$chapter/finding?all=1") or die $c->error;
    } else {
        $findings = $c->get("/report/$report/finding?all=1") or die $c->error;
    }
    return wantarray ? @$findings : $findings;
}

sub get_form {
    my $c = shift;
    my $obj = shift;
    my $uri = $obj->{uri} or die "no uri in ".Dumper($obj);
    if ($uri =~ m[/article]) {
        $uri =~ s[article][article/form/update];
    } else {
        # The last backslash becomes /form/update
        $uri =~ s[/([^/]+)$][/form/update/$1];
    }
    return $c->get($uri);
}

sub connect {
    my $class = shift;
    my %args = @_;

    my $url = $args{url} or die "missing url";
    my $c = $class->new;
    $c->url($url);
    $c->find_credentials->login or die "Failed to log in to $url";
    return $c;
}

1;

__END__

=head1 NAME

Gcis::Client -- Perl client for interacting with the Global Change Information System

=head1 SYNOPSIS

    use Gcis::Client;

    my $c = Gcis::Client->new(url => 'http://data.globalchange.gov');
    print $c->get('/report');

    my $c = Gcis::Client->connect(url => $ARGV[0]);
    $c->post(
      '/report',
      {
        identifier       => 'my-new-report',
        title            => "awesome report",
        frequency        => "1 year",
        summary          => "this is a great report",
        report_type_identifier => "report",
        publication_year => '2000',
        url              => "http://example.com/report.pdf",
      }
    ) or die $c->error;

    # Add a chapter
    $c->post(
        "/report/my-new-report/chapter",
        {
            report_identifier => "my-new-report",
            identifier        => "my-chapter-identifier",
            title             => "Some Title",
            number            => 12,
            sort_key          => 100,
            doi               => '10.1234/567',
            url               => 'http://example.com/report',
        }
    ) or die $c->error;

    my $c = Gcis::Client->new
        ->url('http://data.globalchange.gov')
        ->logger($logger)
        ->find_credentials
        ->login;

=head1 DESCRIPTION

This is a simple client for the GCIS API, based on L<Mojo::UserAgent>.

=head1 ATTRIBUTES

=head2 delay

A delay between requests.

=head2 url

The base url for the API.

=head2 key

An access key for the API.

=head2 error

An error from the most recent reqeust.

=head2 ua

The Mojo::UserAgent object.

=head2 logger

A logger (defaults to a Mojo::Log object).

=head2 accept

An accept header to send with every request (defaults to "application/json");

=head2 tx

The Mojo::Transaction object from the most recent request.

=cut

=head1 METHODS

=head2 connect

    my $c = Gcis::Client->connect(url => $url);

Shorthand for Gcis::Client->new->url($url)->find_credentials->login or die "Failed to log in to $url";

=head2 find_credentials

Matches a URL with one in the configuration file.  See CONFIGURATION below.

=head2 login

Verify that a get request to /login succeeds.

Returns the client object if and only if it succeeds.

    $c->login;

=head2 get_chapter_map

Get a map from chapter number to identifer.

    my $identifier = $c->get_chapter_map('nca3')->{1}

=head2 use_env

Get the URL from the GCIS_API_URL environment variable.
Also get an optional delay (in seconds) from GCIS_API_DELAY.

    $c->use_env;

=head2 get

Get a URL, requesting JSON, converting an arrayref to an array if called in an array context.
An optional second parameter may be a hash which is converted into a query string.

    $gcis->get('/report');
    $gcis->get('/report', {report_type => 'assessment'});
    $gcis->get('/report?report_type=assessment');

=head2 delete

Delete a record, optionally replacing it with another record.

    $gcis->delete('/person/1234');
    $gcis->delete('/person/1234', { replacement => "/person/7899" });

=head2 add_file_url

Add a file using its URL.

    $c->add_file_url($gcid => {
        file_url => $file_url,
        landing_page => $landing_page
    });

=head2 put_file

PUT a local file to a remote destination.

    $g->put_file($destination, $source) or die $g->error;

    $path is the destination API path, like /report/files/nca2100/highres.pdf
    $source is the local file, e.g. /tmp/nca2100.pdf

=head1 CONFIGURATION

Credentials can be stored in a YAML file called ~/etc/Gcis.conf.
This contains URLs and keys, in this format :

    - url      : http://data-stage.globalchange.gov
      userinfo : me@example.com:298015f752d99e789056ef826a7db7afc38a8bbd6e3e23b3
      key      : M2FiLTg2N2QtYjhiZTVhM5ZWEtYjNkM5ZWEtYjNkMS00LTgS00LTg2N2QtYZDFhzQyNGUxCg==

    - url      : http://data.globalchange.gov
      userinfo : username:pass
      key      : key

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::Log>

=cut
