package Dist::Surveyor::Inquiry;

use strict;
use warnings;
use Memoize; # core
use FindBin;
use Fcntl qw(:DEFAULT :flock); # core
use Dist::Surveyor::DB_File; # internal
use HTTP::Tiny;
use JSON::MaybeXS qw(JSON decode_json);
use Scalar::Util qw(looks_like_number); # core
use Data::Dumper;
use version;

our $VERSION = '0.021';

=head1 NAME

Dist::Surveyor::Inquiry - Handling the meta-cpan API access for Dist::Surveyor

=head1 DESCRIPTION

There are a few things that needed to be known in this module:

=over

=item *

$metacpan_size - internally defined global to limit the maximum size of 
every API call

=item *

$metacpan_calls - internally defined global counting how many API call happen.

=item *

This module checks $::DEBUG and $::VERBOSE for obvious proposes.

=item *

For initating cache-on-disk, call Dist::Surveyor::Inquiry->perma_cache()
(this should be usually done, except in testing environment)

=back

=cut

# We have to limit the number of results when using MetaCPAN::API.
# We can'r make it too large as it hurts the server (it preallocates)
# but need to make it large enough for worst case distros (eg eBay-API).
# TODO: switching to the ElasticSearch module, with cursor support, will
# probably avoid the need for this. Else we could dynamically adjust.
our $metacpan_size = 2500;
our $metacpan_calls = 0;

our ($DEBUG, $VERBOSE);
*DEBUG = \$::DEBUG;
*VERBOSE = \$::VERBOSE;

require Exporter;
our @ISA = qw{Exporter};
our @EXPORT = qw{
    get_candidate_cpan_dist_releases
    get_candidate_cpan_dist_releases_fallback
    get_module_versions_in_release
    get_release_info
};

my $agent_string = "dist_surveyor/$VERSION";

my ($ua, $wget, $curl);
if (HTTP::Tiny->can_ssl) {
    $ua = HTTP::Tiny->new(
        agent => $agent_string,
        timeout => 10,
        keep_alive => 1, 
    );
} else { # for fatpacking support
    require File::Which;
    require IPC::System::Simple;
    $wget = File::Which::which('wget');
    $curl = File::Which::which('curl');
}

sub _https_request {
    my ($method, $url, $headers, $content) = @_;
    $headers ||= {};
    $method = uc($method || 'GET');
    if (defined $ua) {
        my %options;
        $options{headers} = $headers if %$headers;
        $options{content} = $content if defined $content;
        my $response = $ua->request($method, $url, \%options);
        unless ($response->{success}) {
            die "Transport error: $response->{content}\n" if $response->{status} == 599;
            die "HTTP error: $response->{status} $response->{reason}\n";
        }
        return $response->{content};
    } elsif (defined $wget) {
        my @args = ('-q', '-O', '-', '-U', $agent_string, '-T', 10, '--method', $method);
        push @args, '--header', "$_: $headers->{$_}" for keys %$headers;
        push @args, '--body-data', $content if defined $content;
        return IPC::System::Simple::capturex($wget, @args, $url);
    } elsif (defined $curl) {
        my @args = ('-s', '-S', '-L', '-A', $agent_string, '--connect-timeout', 10, '-X', $method);
        push @args, '-H', "$_: $headers->{$_}" for keys %$headers;
        push @args, '--data-raw', $content if defined $content;
        return IPC::System::Simple::capturex($curl, @args, $url);
    } else {
        die "None of IO::Socket::SSL, wget, or curl are available; cannot make HTTPS requests.";
    }
}

# caching via persistent memoize

my %memoize_cache;
my $locking_file;

=head1 CLASS METHODS

=head2 Dist::Surveyor::Inquiry->perma_cache()

Enable caching to disk of all the MetaCPAN API requests.
This cache can grew to be quite big - 40MB is one case, but it worth it,
as if you will need to run this program again, it will run much faster.

=cut

sub perma_cache {
    my $class = shift;
    my $db_generation = 3; # XXX increment on incompatible change
    my $pname = $FindBin::Script;
    $pname =~ s/\..*$//;
    my $memoize_file = "$pname-$db_generation.db";
    open $locking_file, ">", "$memoize_file.lock" 
        or die "Unable to open lock file: $!";
    flock ($locking_file, LOCK_EX) || die "flock: $!";
    tie %memoize_cache => 'Dist::Surveyor::DB_File', $memoize_file, O_CREAT|O_RDWR, 0640
        or die "Unable to use persistent cache: $!";
}

my @memoize_subs = qw(
    get_candidate_cpan_dist_releases
    get_candidate_cpan_dist_releases_fallback
    get_module_versions_in_release
    get_release_info
);
for my $subname (@memoize_subs) {
    my %memoize_args = (
        SCALAR_CACHE => [ HASH => \%memoize_cache ],
        LIST_CACHE   => 'FAULT',
        NORMALIZER   => sub { return join("\034", $subname, @_) }
    );
    memoize($subname, %memoize_args);
}

=head1 FUNCTIONS

=head2 get_release_info($author, $release)

Receive release info, such as:

    get_release_info('SEMUELF', 'Dist-Surveyor-0.009')

Returns a hashref containing all that release meta information, returned by
C<https://fastapi.metacpan.org/v1/release/$author/$release>
(but not information on the files inside the module)

Dies on HTTP error, and warns on empty response.

=cut

sub get_release_info {
    my ($author, $release) = @_;
    $metacpan_calls++;
    my $response = _https_request(GET => "https://fastapi.metacpan.org/v1/release/$author/$release");
    my $release_data = decode_json $response;
    if (!$release_data or !$release_data->{release}) {
        warn "Can't find release details for $author/$release - SKIPPED!\n";
        return; # XXX could fake some of $release_data instead
    }
    return $release_data->{release};
}

=head2 get_candidate_cpan_dist_releases($module, $version, $file_size)

Return a hashref containing all the releases that contain this module 
(with the specific version and file size combination)

The keys are the release name (i.e. 'Dist-Surveyor-0.009') and the value
is a hashref containing release information and file information:

    'Dist-Surveyor-0.009' => {
        # release information
        'date' => '2013-02-20T06:48:35.000Z',
        'version' => '0.009',
        'author' => 'SEMUELF',
        'version_numified' => '0.009',
        'release' => 'Dist-Surveyor-0.009',
        'distribution' => 'Dist-Surveyor',
        'version_obj' => <version object 0.009>,

        # File information
        'path' => 'lib/Dist/Surveyor/DB_File.pm',
        'stat.mtime' => 1361342736,
        'module.version' => '0.009'
        'module.version_numified' => '0.009',
    }

=cut

sub get_candidate_cpan_dist_releases {
    my ($module, $version, $file_size) = @_;
    my $funcstr = "get_candidate_cpan_dist_releases($module, $version, $file_size)";

    my $version_qual = _prepare_version_query(0, $version);

    my @and_quals = (
        {"term" => {"module.name" => $module }},
        (@$version_qual > 1 ? { "bool" => { "should" => $version_qual } } : $version_qual->[0]),
    );
    push @and_quals, {"term" => {"stat.size" => $file_size }}
        if $file_size;

    # XXX doesn't cope with odd cases like 
    # http://explorer.metacpan.org/?url=/module/MLEHMANN/common-sense-3.4/sense.pm.PL
    $metacpan_calls++;

    my $query = {
        "size" => $metacpan_size,
        "query" =>  { "bool" => {
            "filter" => \@and_quals,
        }},
        "fields" => [qw(
            release _parent author version version_numified module.version 
            module.version_numified date stat.mtime distribution path
            )]
    };

    my $response = _https_request(POST => 'https://fastapi.metacpan.org/v1/file',
        { 'Content-Type' => 'application/json;charset=UTF-8' },
        JSON->new->utf8->canonical->encode($query),
    );
    return _process_response($funcstr, $response);
}

=head2 get_candidate_cpan_dist_releases_fallback($module, $version)

Similar to get_candidate_cpan_dist_releases, but getting called when 
get_candidate_cpan_dist_releases fails for find matching file and release.

Maybe the file was tempared somehow, so the file size does not match anymore.

=cut

sub get_candidate_cpan_dist_releases_fallback {
    my ($module, $version) = @_;

    # fallback to look for distro of the same name as the module
    # for odd cases like
    # http://explorer.metacpan.org/?url=/module/MLEHMANN/common-sense-3.4/sense.pm.PL
    (my $distname = $module) =~ s/::/-/g;

    my $version_qual = _prepare_version_query(1, $version);

    my @and_quals = (
        {"term" => {"distribution" => $distname }},
        (@$version_qual > 1 ? { "bool" => { "should" => $version_qual } } : $version_qual->[0]),
    );

    # XXX doesn't cope with odd cases like 
    $metacpan_calls++;
    my $query = {
        "size" => $metacpan_size,
        "query" =>  { "bool" => {
            "filter" => \@and_quals,
        }},
        "fields" => [qw(
            release _parent author version version_numified module.version 
            module.version_numified date stat.mtime distribution path)]
    };
    my $response = _https_request(POST => 'https://fastapi.metacpan.org/v1/file',
        { 'Content-Type' => 'application/json;charset=UTF-8' },
        JSON->new->utf8->canonical->encode($query),
    );
    return _process_response("get_candidate_cpan_dist_releases_fallback($module, $version)", $response);
}

sub _prepare_version_query {
    my ($is_fallback, $version) = @_;
    $version = 0 if not defined $version; # XXX
    my ($v_key, $num_key) = 
        $is_fallback 
        ? qw{ version version_numified } 
        : qw{ module.version module.version_numified };

    # timbunce: So, the current situation is that: version_numified is a float
    # holding version->parse($raw_version)->numify, and version is a string
    # also holding version->parse($raw_version)->numify at the moment, and
    # that'll change to ->stringify at some point. Is that right now? 
    # mo: yes, I already patched the indexer, so new releases are already
    # indexed ok, but for older ones I need to reindex cpan
    my $v = (ref $version && $version->isa('version')) ? $version : version->parse($version);
    my %v = map { $_ => 1 } "$version", $v->stringify, $v->numify;
    my @version_qual;
    push @version_qual, { term => { $v_key => $_ } }
        for keys %v;
    push @version_qual, { term => { $num_key => $_ }}
        for grep { looks_like_number($_) } keys %v;
    return \@version_qual;
}

sub _process_response {
    my ($funcname, $response) = @_;

    my $results = decode_json $response;

    my $hits = $results->{hits}{hits};
    die "$funcname: too many results (>$metacpan_size)"
        if @$hits >= $metacpan_size;
    warn "$funcname: ".Dumper($results)
        if grep { not $_->{fields}{release} } @$hits; # XXX temp, seen once but not since

    # filter out perl-like releases
    @$hits = 
        grep { $_->{fields}{path} !~ m!^(?:t|xt|tests?|inc|samples?|ex|examples?|bak|local-lib)\b! }
        grep { $_->{fields}{release} !~ /^(perl|ponie|parrot|kurila|SiePerl-)/ } 
        @$hits;

    for my $hit (@$hits) {
        $hit->{release_id} = delete $hit->{_parent};
        # add version_obj for convenience (will fail and be undef for releases like "0.08124-TRIAL")
        $hit->{fields}{version_obj} = eval { version->parse($hit->{fields}{version}) };
    }

    # we'll return { "Dist-Name-Version" => { details }, ... }
    my %dists = map { $_->{fields}{release} => $_->{fields} } @$hits;

    warn "$funcname: @{[ sort keys %dists ]}\n"
        if $VERBOSE;

    return \%dists;
}

=head2 get_module_versions_in_release($author, $release)

Receive release info, such as:

    get_module_versions_in_release('SEMUELF', 'Dist-Surveyor-0.009')

And returns a hashref, that contains one entry for each module that exists 
in the release. module information is the format:

    'Dist::Surveyor' => {
        'version' => '0.009',
        'name' => 'Dist::Surveyor',
        'path' => 'lib/Dist/Surveyor.pm',
        'size' => 43879
    },

this function can be called for all sorts of releases that are only vague 
possibilities and aren't actually installed, so generally it's quiet

=cut

sub get_module_versions_in_release {
    my ($author, $release) = @_;

    $metacpan_calls++;
    my $results = eval { 
        my $query = {
            "size" => $metacpan_size,
            "query" =>  { "bool" => {
                "filter" => [
                    {"term" => {"release" => $release }},
                    {"term" => {"author" => $author }},
                    {"term" => {"mime" => "text/x-script.perl-module"}},
                ],
            }},
            "fields" => ["path","name","stat.size"],
            "inner_hits" => {"module" => {"path" => {"module" => {}}}},
        }; 
        my $response = _https_request(POST => 'https://fastapi.metacpan.org/v1/file',
            { 'Content-Type' => 'application/json;charset=UTF-8' },
            JSON->new->utf8->canonical->encode($query),
        );
        decode_json $response;
    };
    if (not $results) {
        warn "Failed get_module_versions_in_release for $author/$release: $@";
        return {};
    }
    my $hits = $results->{hits}{hits};
    die "get_module_versions_in_release($author, $release): too many results"
        if @$hits >= $metacpan_size;

    my %modules_in_release;
    for my $hit (@$hits) {
        my $path = $hit->{fields}{path};

        # XXX try to ignore files that won't get installed
        # XXX should use META noindex!
        if ($path =~ m!^(?:t|xt|tests?|inc|samples?|ex|examples?|bak|local-lib)\b!) {
            warn "$author/$release: ignored non-installed module $path\n"
                if $DEBUG;
            next;
        }

        my $size = $hit->{fields}{"stat.size"};
        # files can contain more than one package ('module')
        my $rel_mods = $hit->{inner_hits}{module}{hits}{hits} || [];
        for my $inner_hit (@$rel_mods) { # actually packages in the file
            my $mod = $inner_hit->{_source};

            # Some files may contain multiple packages. We want to ignore
            # all except the one that matches the name of the file.
            # We use a fairly loose (but still very effective) test because we
            # can't rely on $path including the full package name.
            (my $filebasename = $hit->{fields}{name}) =~ s/\.pm$//;
            if ($mod->{name} !~ m/\b$filebasename$/) {
                warn "$author/$release: ignored $mod->{name} in $path\n"
                    if $DEBUG;
                next;
            }

            # warn if package previously seen in this release
            # with a different version or file size
            if (my $prev = $modules_in_release{$mod->{name}}) {
                my $version_obj = eval { version->parse($mod->{version}) };
                die "$author/$release: $mod $mod->{version}: $@" if $@;

                if ($VERBOSE) {
                    # XXX could add a show-only-once cache here
                    my $msg = "$mod->{name} $mod->{version} ($size) seen in $path after $prev->{path} $prev->{version} ($prev->{size})";
                    warn "$release: $msg\n"
                        if ($version_obj != version->parse($prev->{version}) or $size != $prev->{size});
                }
            }

            # keep result small as Storable thawing this is major runtime cost
            # (specifically we avoid storing a version_obj here)
            $modules_in_release{$mod->{name}} = {
                name => $mod->{name},
                path => $path,
                version => $mod->{version},
                size => $size,
            };
        }
    }

    warn "\n$author/$release contains: @{[ map { qq($_->{name} $_->{version}) } values %modules_in_release ]}\n"
        if $DEBUG;

    return \%modules_in_release;
}

=head1 License, Copyright

Please see L<Dist::Surveyor> for details

=cut

1;
