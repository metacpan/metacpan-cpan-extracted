package Google::CloudTasks::Client;

use Mouse;
use WWW::Google::Cloud::Auth::ServiceAccount;
use LWP::UserAgent;
use HTTP::Request;
use URI;
use URI::QueryParam;
use JSON::XS;

our $VERSION = "0.01";

has base_url => (
    is => 'ro',
    isa => 'Str',
    default => 'https://cloudtasks.googleapis.com/',
);

has version => (
    is => 'ro',
    isa => 'Str',
    default => 'v2',
);

has credentials_path => (
    is => 'ro',
    isa => 'Str'
);

has auth => (
    is => 'ro',
    lazy_build => 1,
);

has ua => (
    is => 'ro',
    lazy => 1,
    default => sub { LWP::UserAgent->new() },
);

has is_debug => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

no Mouse;

__PACKAGE__->meta->make_immutable;

sub _build_auth {
    my ($self) = @_;

    if (!$self->credentials_path) {
        die "attribute 'credentials_path' is required";
    }
    my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
        credentials_path => $self->credentials_path,
    );
    return $auth;
}

sub request {
    my ($self, $method, $path, $content) = @_;

    my $url = $self->base_url . $self->version . '/' . $path;
    my $req = HTTP::Request->new($method, $url);
    $req->header('Content-Type' => 'application/json; charset=utf8');
    $req->header('Authorization' => 'Bearer ' . $self->auth->get_token);
    if ($content) {
        my $encoded_body = encode_json($content);
        $req->header('Content-Length' => length($encoded_body));
        $req->content($encoded_body);
    }

    if ($self->is_debug) {
        use Data::Dumper;
        print "Request : " . Dumper($req);
    }

    my $res = $self->ua->request($req);

    if ($res->is_success) {
        return decode_json($res->content);
    }
    else {
        die "Fail: " . $res->content;
    }
}

sub request_get {
    my ($self, $path) = @_;
    return $self->request(GET => $path);
}

sub request_post {
    my ($self, $path, $content) = @_;
    $content //= {};
    return $self->request(POST => $path, $content);
}

sub request_delete {
    my ($self, $path) = @_;
    return $self->request(DELETE => $path);
}

sub request_patch {
    my ($self, $path, $content) = @_;
    return $self->request(PATCH => $path, $content);
}

sub _make_query_param {
    my ($args, @keys) = @_;

    my $u = URI->new();
    for (@keys) {
        if (defined $args->{$_}) {
            $u->query_param($_ => $args->{$_});
        }
    }

    return $u->query ? '?' . $u->query : '';
}

sub get_location {
    my ($self, $name) = @_;
    my $path = $name;

    return $self->request_get($path);
}

sub list_locations {
    my ($self, $name, $opts) = @_;
    my $path = $name . '/locations';
    $path .= _make_query_param($opts, qw/filter pageSize pageToken/);

    return $self->request_get($path);
}

sub create_queue {
    my ($self, $parent, $queue) = @_;
    my $path = $parent . '/queues';

    return $self->request_post($path, $queue);
}

sub delete_queue {
    my ($self, $name) = @_;
    my $path = $name;

    return $self->request_delete($path);
}

sub get_iam_policy_queue {
    my ($self, $resource) = @_;
    my $path = $resource . ':getIamPolicy';

    return $self->request_post($path);
}

sub set_iam_policy_queue {
    my ($self, $resource, $policy) = @_;
    my $path = $resource . ':setIamPolicy';

    return $self->request_post($path, { policy => $policy });
}

sub list_queues {
    my ($self, $parent, $opts) = @_;
    my $path = $parent . '/queues';
    $path .= _make_query_param($opts, qw/filter pageSize pageToken/);

    return $self->request_get($path);
}

sub get_queue {
    my ($self, $name) = @_;
    my $path = $name;

    return $self->request_get($path);
}

sub patch_queue {
    my ($self, $name, $queue, $opts) = @_;
    my $path = $name;
    $path .= _make_query_param($opts, qw/updateMask/);

    return $self->request_patch($path, $queue);
}

sub pause_queue {
    my ($self, $name) = @_;
    my $path = $name . ':pause';
    return $self->request_post($path);
}

sub purge_queue {
    my ($self, $name) = @_;
    my $path = $name . ':purge';
    return $self->request_post($path);
}

sub resume_queue {
    my ($self, $name) = @_;
    my $path = $name . ':resume';
    return $self->request_post($path);
}

sub test_iam_permissions {
    my ($self, $resource, $permissions) = @_;
    my $path = $resource . ':testIamPermissions';
    return $self->request_post($path, { permissions => $permissions });
}

sub create_task {
    my ($self, $parent, $task, $opts) = @_;
    my $path = $parent . '/tasks';

    my %param = (
        task => $task,
    );
    defined $opts->{responseView} and $param{responseView} = $opts->{responseView};

    return $self->request_post($path, \%param);
}

sub delete_task {
    my ($self, $name) = @_;
    my $path = $name;

    return $self->request_delete($path);
}

sub get_task {
    my ($self, $name, $opts) = @_;
    my $path = $name;

    $path .= _make_query_param($opts, qw/responseView/);

    return $self->request_get($path);
}

sub list_tasks {
    my ($self, $parent, $opts) = @_;
    my $path = $parent . '/tasks';

    $path .= _make_query_param($opts, qw/responseView pageSize pageToken/);

    return $self->request_get($path);
}

sub run_task {
    my ($self, $name, $opts) = @_;
    my $path = $name . ':run';

    my %param = ();
    defined $opts->{responseView} and $param{responseView} = $opts->{responseView};

    return $self->request_post($path, \%param);
}

1;
