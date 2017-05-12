package Dist::Surveyor::Inquiry;
$Dist::Surveyor::Inquiry::VERSION = '0.016';
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

=head1 NAME

Dist::Surveyor::Inquiry - Handling the meta-cpan API access for Dist::Surveyor

=head1 VERSION

version 0.016

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

my $ua = HTTP::Tiny->new(
    agent => $0,
    timeout => 10,
    keep_alive => 1, 
);

require Exporter;
our @ISA = qw{Exporter};
our @EXPORT = qw{
    get_candidate_cpan_dist_releases
    get_candidate_cpan_dist_releases_fallback
    get_module_versions_in_release
    get_release_info
};

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
http://api.metacpan.org/v0/release/$author/$release
(but not information on the files inside the module)

Dies on HTTP error, and warns on empty response.

=cut

sub get_release_info {
    my ($author, $release) = @_;
    $metacpan_calls++;
    my $response = $ua->get("http://api.metacpan.org/v0/release/$author/$release");
    die "$response->{status} $response->{reason}" unless $response->{success};
    my $release_data = decode_json $response->{content};
    if (!$release_data) {
        warn "Can't find release details for $author/$release - SKIPPED!\n";
        return; # XXX could fake some of $release_data instead
    }
    return $release_data;
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
        {"term" => {"file.module.name" => $module }},
        (@$version_qual > 1 ? { "or" => $version_qual } : $version_qual->[0]),
    );
    push @and_quals, {"term" => {"file.stat.size" => $file_size }}
        if $file_size;

    # XXX doesn't cope with odd cases like 
    # http://explorer.metacpan.org/?url=/module/MLEHMANN/common-sense-3.4/sense.pm.PL
    $metacpan_calls++;

    my $query = {
        "size" => $metacpan_size,
        "query" =>  { "filtered" => {
            "filter" => {"and" => \@and_quals },
            "query" => {"match_all" => {}},
        }},
        "fields" => [qw(
            release _parent author version version_numified file.module.version 
            file.module.version_numified date stat.mtime distribution file.path
            )]
    };

    my $response = $ua->post(
        'http://api.metacpan.org/v0/file', {
            headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
            content => JSON->new->utf8->canonical->encode($query),
        }
    );
    die "$response->{status} $response->{reason}" unless $response->{success};
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
        (@$version_qual > 1 ? { "or" => $version_qual } : $version_qual->[0]),
    );

    # XXX doesn't cope with odd cases like 
    $metacpan_calls++;
    my $query = {
        "size" => $metacpan_size,
        "query" =>  { "filtered" => {
            "filter" => {"and" => \@and_quals },
            "query" => {"match_all" => {}},
        }},
        "fields" => [qw(
            release _parent author version version_numified file.module.version 
            file.module.version_numified date stat.mtime distribution file.path)]
    };
    my $response = $ua->post(
        'http://api.metacpan.org/v0/file', {
            headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
            content => JSON->new->utf8->canonical->encode($query),
        }
    );
    die "$response->{status} $response->{reason}" unless $response->{success};
    return _process_response("get_candidate_cpan_dist_releases_fallback($module, $version)", $response);
}

sub _prepare_version_query {
    my ($is_fallback, $version) = @_;
    $version = 0 if not defined $version; # XXX
    my ($v_key, $num_key) = 
        $is_fallback 
        ? qw{ version version_numified } 
        : qw{ file.module.version file.module.version_numified };

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

    my $results = decode_json $response->{content};

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
            "query" =>  { "filtered" => {
                "filter" => {"and" => [
                    {"term" => {"release" => $release }},
                    {"term" => {"author" => $author }},
                    {"term" => {"mime" => "text/x-script.perl-module"}},
                ]},
                "query" => {"match_all" => {}},
            }},
            "fields" => ["path","name","_source.module", "_source.stat.size"],
        }; 
        my $response = $ua->post(
            'http://api.metacpan.org/v0/file', {
                headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
                content => JSON->new->utf8->canonical->encode($query),
            }
        );
        die "$response->{status} $response->{reason}" unless $response->{success};
        decode_json $response->{content};
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

        my $size = $hit->{fields}{"_source.stat.size"};
        # files can contain more than one package ('module')
        my $rel_mods = $hit->{fields}{"_source.module"} || [];
        for my $mod (@$rel_mods) { # actually packages in the file

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
