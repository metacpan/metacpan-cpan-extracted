package Kubernetes::REST::Kubeconfig;
# ABSTRACT: Parse kubeconfig files and create Kubernetes::REST instances
our $VERSION = '1.107';
use Moo;
use Carp qw(croak);
use Config ();
use YAML::XS ();
use Path::Tiny qw(path);
use MIME::Base64 qw(decode_base64);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::AuthTokenFile;
use namespace::clean;


has kubeconfig_path => (
    is => 'ro',
    default => sub { $_[0]->_default_kubeconfig_path },
);


sub _default_kubeconfig_path {
    my $self = shift;
    return $ENV{KUBECONFIG} if defined $ENV{KUBECONFIG} and length $ENV{KUBECONFIG};
    return undef unless defined $ENV{HOME} and length $ENV{HOME};
    return "$ENV{HOME}/.kube/config";
}

my $PATH_SEP = $Config::Config{path_sep} || ':';

has kubeconfig_paths => (
    is => 'lazy',
    init_arg => undef,
    builder => sub {
        my $self = shift;
        my $path = $self->kubeconfig_path;
        return [] unless defined $path;
        my @entries = ref $path eq 'ARRAY' ? @$path : split /\Q$PATH_SEP\E/, $path, -1;
        return [ grep { defined and length } @entries ];
    },
);


has context_name => (
    is => 'ro',
    predicate => 1,
);


has refresh_token_files => (
    is => 'ro',
    default => sub { 1 },
);


has _config => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my @configs;
        for my $path (@{ $self->kubeconfig_paths }) {
            # A file the list names but that is not there is not an error, the
            # same way it is not one for kubectl.
            next unless -f $path;
            my $config = YAML::XS::LoadFile($path);
            next unless ref $config eq 'HASH';
            # While the file is being read is the only place where its own
            # directory is still known: the merge below keeps whole entries but
            # not where they came from, and with several files merged that
            # directory differs per entry.
            push @configs, $self->_resolve_file_references($config, $path);
        }
        return undef unless @configs;
        return $self->_merge_configs(@configs);
    },
);

# The file references a kubeconfig entry can hold, per section: the key of the
# entry body, and the fields in it that name a file. The *-data twins hold
# base64 content rather than a path and are none of this code's business, and
# neither is an exec plugin's command, which is looked up in PATH.
my %FILE_REFERENCES = (
    clusters => { body => 'cluster', fields => ['certificate-authority'] },
    users    => { body => 'user',    fields => [qw(client-certificate client-key tokenFile)] },
);

sub _resolve_file_references {
    my ($self, $config, $file) = @_;

    # Absolute, so the result survives a later chdir - the file itself may well
    # have been named relatively.
    my $dir = path($file)->absolute->parent;

    for my $section (sort keys %FILE_REFERENCES) {
        my $spec = $FILE_REFERENCES{$section};
        for my $entry (@{ $config->{$section} // [] }) {
            next unless ref $entry eq 'HASH';
            my $body = $entry->{ $spec->{body} };
            next unless ref $body eq 'HASH';
            for my $field (@{ $spec->{fields} }) {
                my $value = $body->{$field};
                next unless defined $value and !ref $value and length $value;
                next if path($value)->is_absolute;
                $body->{$field} = $dir->child($value)->stringify;
            }
        }
    }

    return $config;
}

# The sections keyed by name, which are unioned; everything else is a plain
# top-level key taken from the first file that has it.
my @NAMED_SECTIONS = qw(clusters contexts users);
my %IS_NAMED_SECTION = map { $_ => 1 } @NAMED_SECTIONS;

sub _merge_configs {
    my ($self, @configs) = @_;

    my (%merged, %seen);
    for my $config (@configs) {
        for my $section (@NAMED_SECTIONS) {
            for my $entry (@{ $config->{$section} // [] }) {
                next unless ref $entry eq 'HASH' and defined $entry->{name};
                next if $seen{$section}{ $entry->{name} }++;
                push @{ $merged{$section} }, $entry;
            }
        }
        for my $key (grep { !$IS_NAMED_SECTION{$_} } keys %$config) {
            next if exists $merged{$key};
            my $value = $config->{$key};
            next unless defined $value;
            next if !ref $value and !length $value;
            $merged{$key} = $value;
        }
    }

    return \%merged;
}

sub _not_found_error {
    my $self = shift;
    my $paths = $self->kubeconfig_paths;
    return 'Kubeconfig not found: ' . join($PATH_SEP, @$paths) if @$paths;
    return 'Kubeconfig not found: neither KUBECONFIG nor HOME is set';
}

sub current_context_name {
    my $self = shift;


    return $self->context_name if $self->has_context_name;
    my $config = $self->_config
        or croak $self->_not_found_error;
    return $config->{'current-context'};
}

sub contexts {
    my $self = shift;


    my $config = $self->_config
        or croak $self->_not_found_error;
    return [ map { $_->{name} } @{$config->{contexts} // []} ];
}

sub _find_by_name {
    my ($self, $list, $name) = @_;
    for my $item (@{$list // []}) {
        return $item if $item->{name} eq $name;
    }
    return undef;
}

sub context {
    my ($self, $name) = @_;


    my $config = $self->_config
        or croak $self->_not_found_error;
    $name //= $self->current_context_name;
    my $ctx = $self->_find_by_name($config->{contexts}, $name)
        or croak "Context not found: $name";
    return $ctx->{context};
}

sub cluster {
    my ($self, $name) = @_;


    my $config = $self->_config
        or croak $self->_not_found_error;
    my $cluster = $self->_find_by_name($config->{clusters}, $name)
        or croak "Cluster not found: $name";
    return $cluster->{cluster};
}

sub user {
    my ($self, $name) = @_;


    my $config = $self->_config
        or croak $self->_not_found_error;
    my $user = $self->_find_by_name($config->{users}, $name)
        or croak "User not found: $name";
    return $user->{user};
}

sub _resolve_cert {
    my ($self, $hash, $key) = @_;

    my $data_key = "${key}-data";
    if (my $data = $hash->{$data_key}) {
        return (pem => decode_base64($data));
    }

    if (my $file = $hash->{$key}) {
        return (file => $file);
    }

    return ();
}

sub api {
    my ($self, $context_name) = @_;


    # If no kubeconfig, try in-cluster
    unless ($self->_config) {
        return $self->_in_cluster_api
            // croak $self->_not_found_error . " and not running in-cluster";
    }

    $context_name //= $self->current_context_name;
    my $ctx = $self->context($context_name);
    my $cluster = $self->cluster($ctx->{cluster});
    my $user = $self->user($ctx->{user});

    # Build server config
    my %server = (
        endpoint => $cluster->{server},
    );

    if (my %ca = $self->_resolve_cert($cluster, 'certificate-authority')) {
        $server{ $ca{pem} ? 'ssl_ca_pem' : 'ssl_ca_file' } = $ca{pem} // $ca{file};
    }

    if ($cluster->{'insecure-skip-tls-verify'}) {
        $server{ssl_verify_server} = 0;
    } else {
        $server{ssl_verify_server} = 1;
    }

    if (my %cert = $self->_resolve_cert($user, 'client-certificate')) {
        $server{ $cert{pem} ? 'ssl_cert_pem' : 'ssl_cert_file' } = $cert{pem} // $cert{file};
    }

    if (my %key = $self->_resolve_cert($user, 'client-key')) {
        $server{ $key{pem} ? 'ssl_key_pem' : 'ssl_key_file' } = $key{pem} // $key{file};
    }

    # Build credentials
    my $credentials;
    if (my $token = $user->{token}) {
        $credentials = Kubernetes::REST::AuthToken->new(token => $token);
    } elsif (my $token_file = $user->{tokenFile}) {
        $credentials = $self->_token_file_credential(
            $token_file, "tokenFile of user '$ctx->{user}'"
        );
    } elsif (my $exec = $user->{exec}) {
        $credentials = $self->_exec_credential($exec);
    } else {
        # No token auth, might be using client certs only
        $credentials = Kubernetes::REST::AuthToken->new(token => '');
    }

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(%server),
        credentials => $credentials,
    );
}

# Credentials for a file holding a bearer token: a user's tokenFile, or the
# service account token mounted into a pod. Both are written by something else
# - the kubelet, a login helper - and both are rotated under a running process,
# so both get credentials that notice.
sub _token_file_credential {
    my ($self, $file, $what) = @_;

    return Kubernetes::REST::AuthTokenFile->new(
        file => $file,
        description => $what,
        refresh => $self->refresh_token_files ? 1 : 0,
    );
}

sub _exec_credential {
    my ($self, $exec) = @_;

    my $cmd = $exec->{command};
    my @args = @{$exec->{args} // []};

    # Set up environment
    local %ENV = %ENV;
    for my $env (@{$exec->{env} // []}) {
        $ENV{$env->{name}} = $env->{value};
    }

    my $output = `$cmd @args`;
    croak "exec credential command failed: $cmd" if $?;

    my $cred = YAML::XS::Load($output);
    my $token = $cred->{status}{token}
        or croak "exec credential did not return token";

    return Kubernetes::REST::AuthToken->new(token => $token);
}

my $SA_TOKEN = '/var/run/secrets/kubernetes.io/serviceaccount/token';
my $SA_CA    = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt';

sub _in_cluster_api {
    my ($self) = @_;
    return undef unless -f $SA_TOKEN;

    my $host = $ENV{KUBERNETES_SERVICE_HOST} // 'kubernetes.default.svc';
    my $port = $ENV{KUBERNETES_SERVICE_PORT} // '443';

    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(
            endpoint          => "https://$host:$port",
            ssl_ca_file       => $SA_CA,
            ssl_verify_server => 1,
        ),
        credentials => $self->_token_file_credential(
            $SA_TOKEN, 'service account token'
        ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Kubeconfig - Parse kubeconfig files and create Kubernetes::REST instances

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    use Kubernetes::REST::Kubeconfig;

    # Use default kubeconfig and current context
    my $kc = Kubernetes::REST::Kubeconfig->new;
    my $api = $kc->api;

    # Specify kubeconfig and context
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/path/to/kubeconfig',
        context_name => 'my-cluster',
    );

    # Several kubeconfigs, merged the way kubectl merges $KUBECONFIG
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/etc/kube/base:/home/me/.kube/extra',
    );
    my $kc = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => [ '/etc/kube/base', '/home/me/.kube/extra' ],
    );

    # List available contexts
    my $contexts = $kc->contexts;

    # Get API for specific context
    my $api = $kc->api('production');

    # Inside a Kubernetes pod: no kubeconfig needed, auto-detects service account
    my $api = Kubernetes::REST::Kubeconfig->new->api;

=head1 DESCRIPTION

Parses Kubernetes kubeconfig files (typically C<~/.kube/config>) and creates configured L<Kubernetes::REST> instances.

Several kubeconfig files can be given at once - as the C<:>-separated list
C<kubectl> expects in C<KUBECONFIG>, or as an arrayref - and are merged into
one configuration the way C<kubectl> merges them. See L</MERGING>.

When no kubeconfig file is found, automatically falls back to in-cluster
authentication using the pod's service account token.

Supports:

=over 4

=item * Multiple clusters and contexts

=item * Merging several kubeconfig files, C<kubectl>-style

=item * Token authentication, inline or from a C<tokenFile>

=item * Client certificate authentication

=item * Inline certificate data (base64 encoded)

=item * External certificate files

=item * Exec-based credential plugins

=item * In-cluster service account auto-detection

=back

=head2 kubeconfig_path

Path to the kubeconfig file: a single path, a C<$Config{path_sep}>-separated
list of paths (C<:> on Unix, C<;> on Win32), or an arrayref of paths. A list is
merged as described in L</MERGING>; a single path behaves exactly as it always
has.

Defaults to the C<KUBECONFIG> environment variable if it is set and not empty,
otherwise to C<~/.kube/config>. With neither C<KUBECONFIG> nor C<HOME> set
there is no path to guess, and the default is C<undef>: L</api> then goes
straight to in-cluster authentication, and every method that needs a file
croaks naming the two missing variables instead of reaching for C</.kube/config>.

The split list, without empty entries, is L</kubeconfig_paths>.

=head2 kubeconfig_paths

Arrayref of the individual kubeconfig paths L</kubeconfig_path> names, in the
order they are merged, with empty entries removed. Derived from
C<kubeconfig_path> and not settable on its own. Empty when neither
C<KUBECONFIG> nor C<HOME> is set.

The paths are not checked for existence here - see L</MERGING> for what happens
to entries that are not there.

=head2 context_name

Optional. The context name to use. If not specified, uses the current-context from the kubeconfig.

=head2 refresh_token_files

Whether a token that comes from a file - a user's C<tokenFile>, or the service
account token of the in-cluster fallback - is re-read when the file changes.
True by default; see L</TOKEN FILES AND ROTATION>.

Set it to false and such a token is read once, when L</api> builds the client,
and never again, which is what this module did before it could refresh.

    my $kc = Kubernetes::REST::Kubeconfig->new(refresh_token_files => 0);

It reaches every client this object builds. A caller who wants it per client
can build a second C<Kubernetes::REST::Kubeconfig> - they are cheap, and the
kubeconfig is only read when a client is actually built.

=head2 current_context_name

    my $name = $kc->current_context_name;

Returns the current context name (either from C<context_name> attribute or from the kubeconfig's C<current-context>). With several kubeconfig files merged, C<current-context> is the one from the first file that sets it.

=head2 contexts

    my $contexts = $kc->contexts;

Returns an arrayref of all available context names from the kubeconfig, or from every merged kubeconfig.

=head2 context

    my $ctx = $kc->context;
    my $ctx = $kc->context('production');

Look up a context entry by name and return its C<context> hashref (with C<cluster>, C<user>, and optional C<namespace> keys). Defaults to C<current_context_name> when C<$name> is omitted. Croaks if the context is not found.

=head2 cluster

    my $cluster = $kc->cluster('prod-cluster');

Look up a cluster entry by name and return its C<cluster> hashref (with keys such as C<server>, C<certificate-authority>/C<certificate-authority-data>, and C<insecure-skip-tls-verify>). Croaks if the cluster is not found.

=head2 user

    my $user = $kc->user('token-user');

Look up a user entry by name and return its C<user> hashref (with keys such as C<token>, C<client-certificate>/C<client-certificate-data>, C<client-key>/C<client-key-data>, or C<exec>). Croaks if the user is not found.

=head2 api

    my $api = $kc->api;
    my $api = $kc->api('production');

Create a L<Kubernetes::REST> instance (with a L<Kubernetes::REST::Server> built from the cluster entry and credentials built from the user entry) configured from the kubeconfig. If C<$context_name> is provided, uses that context; otherwise uses the current context.

Certificate and key material can come from either an inline base64 C<*-data> field or a plain file-path field in the kubeconfig. Inline data is decoded and passed to L<Kubernetes::REST::Server> as an in-memory PEM string (C<ssl_ca_pem>/C<ssl_cert_pem>/C<ssl_key_pem>) rather than written to a temporary file, so the returned L<Kubernetes::REST> instance keeps working after this C<Kubernetes::REST::Kubeconfig> object is garbage-collected. A file path is passed on as C<ssl_ca_file>/C<ssl_cert_file>/C<ssl_key_file>, absolute: a relative one is resolved against the directory of the kubeconfig that defined the entry, see L</MERGING>.

User authentication is resolved in this order: a plain C<token> field; a C<tokenFile>, whose content is the bearer token; an C<exec> block (kubectl's exec-credential-plugin mechanism, used for e.g. cloud IAM auth), which runs the configured C<command> (with C<args> and any C<env> entries applied to the child process) and reads C<status.token> from its output (parsed as YAML, which also accepts the JSON that real exec plugins emit); otherwise an empty token, for setups that authenticate via client certificate alone.

That order is C<kubectl>'s. An inline C<token> wins over a C<tokenFile> - client-go's C<getUserIdentificationPartialConfig> reads the file only when there is no inline token - and either of them wins over an C<exec> block, which C<kubectl> skips whenever a request already carries an C<Authorization> header. An C<exec> plugin is therefore not run at all when the user also has a token or a token file.

A C<tokenFile> that cannot be read, or that holds nothing but whitespace, is a fatal error naming the user and the file. It is deliberately not a fall-through to the next mechanism: a kubeconfig saying where its token lives is a statement about how this user authenticates, and quietly carrying on would produce a 401 from the cluster with nothing pointing at the file. Leading and trailing whitespace is stripped - such files almost always end in a newline, and a newline in an C<Authorization> header does not reach the server as intended.

A C<tokenFile> is handed to L<Kubernetes::REST> as a L<Kubernetes::REST::AuthTokenFile>, which reads the file again when it changes, so a rotated token is picked up without rebuilding the client. The in-cluster service account token works the same way. See L</TOKEN FILES AND ROTATION>, and L</refresh_token_files> to turn it off.

Falls back to in-cluster service account authentication when no kubeconfig
file is found - none of the merged paths exists, or there is no path at all
because neither C<KUBECONFIG> nor C<HOME> is set - and the pod has a mounted
token at
C</var/run/secrets/kubernetes.io/serviceaccount/token>. In that case the API
server address comes from the C<KUBERNETES_SERVICE_HOST>/C<KUBERNETES_SERVICE_PORT>
environment variables (defaulting to C<kubernetes.default.svc:443>), and the
cluster CA is read from C</var/run/secrets/kubernetes.io/serviceaccount/ca.crt>.

=head1 MERGING

C<KUBECONFIG> is a C<PATH>-style list of kubeconfig files, not a single path -
C<:>-separated everywhere except on Win32, where it is C<;>-separated, the same
separator Perl reports in C<$Config{path_sep}>. C<kubectl> merges every file in
that list into one configuration, and so does this module:

=over 4

=item * Clusters, contexts and users are unioned by name. The B<first> file
that defines a given name wins; later definitions of that same name are
discarded, they do not overwrite fields.

=item * C<current-context> comes from the first file in the list that sets one,
as does every other top-level key (C<apiVersion>, C<kind>, C<preferences>).

=item * Entries that name a file that does not exist are skipped silently,
which is what C<kubectl> does - a list assembled by a shell profile or by
C<direnv> routinely mentions files that are not there. So are empty entries, so
C</a::/b> and a trailing C<:> are harmless.

=item * Relative entries in the list itself are resolved against the current
working directory.

=back

If no file in the list exists, the configuration is empty and L</api> falls
back to in-cluster authentication exactly as it does for a single missing file.

=head2 Relative paths inside a kubeconfig

The file references an entry holds - C<certificate-authority> on a cluster,
C<client-certificate>, C<client-key> and C<tokenFile> on a user - are resolved
against the directory of the kubeconfig file that defines that entry, the way
C<kubectl> resolves them, and not against the current working directory.

With several files merged that directory is a property of the entry, not of the
configuration: a cluster that won from F</a/config> resolves its CA against
F</a> even when the current context came from F</b/config>. Resolution
therefore happens as each file is read, before anything is merged, so what
L</cluster>, L</user> and L</api> hand back are absolute paths that keep
pointing at the same file after a C<chdir>.

An absolute reference is passed through untouched, and so is the inline base64
of the C<*-data> fields, which names no file. A leading C<~> is not expanded -
it is an ordinary directory name, exactly as it is for C<kubectl>, and resolves
like any other relative path. An C<exec> plugin's C<command> is not a file
reference in this sense either: it is looked up in C<PATH> and is left alone.

=head1 TOKEN FILES AND ROTATION

Kubernetes rotates the files a token can come from. The kubelet replaces a
projected service account token well before it expires, and a client that read
the file once at startup would go on sending a token that has stopped being
valid while a good one sits in the file next to it.

A token that comes from a file - a user's C<tokenFile>, or the service account
token of the in-cluster fallback - is therefore not handed over as a fixed
string. L</api> builds a L<Kubernetes::REST::AuthTokenFile>, which reads the
file again whenever it has changed. There is no timer and no interval to
configure: the trigger is the file itself, and a client picks up a new token on
the first request after the rotation.

What "changed" means, and what it costs, is
L<Kubernetes::REST::AuthTokenFile/token>: one C<stat> per request, comparing
inode, size and modification time, so the C<..data> symlink swap the kubelet
performs is seen as the different file it is. A read that fails after a
successful one - the file gone for a moment mid-rotation - keeps the last good
token rather than breaking the client. Only the first read, when the client is
built, is fatal.

Set L</refresh_token_files> to false to switch this off. The token is then read
exactly once, when C<api()> builds the client, and never again: no C<stat> per
request, and the client stops working when that token expires, until something
builds it anew.

An inline C<token> in the kubeconfig is unaffected either way - there is no
file to watch, and it is used exactly as it is written.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Server> - Server configuration

=item * L<Kubernetes::REST::AuthToken> - Authentication credentials

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
