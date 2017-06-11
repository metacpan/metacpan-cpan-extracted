package Dist::Surveyor;

=head1 NAME

Dist::Surveyor - Survey installed modules and determine the specific distribution versions they came from

=head1 SYNOPSIS

    my $options = {
        opt_match => $opt_match,
        opt_perlver => $opt_perlver,
        opt_remnants => $opt_remnants,
        distro_key_mod_names => $distro_key_mod_names,
    };
    my @installed_releases = determine_installed_releases($options, \@libdirs);

=head1 DESCRIPTION

Surveys your huge ball of Perl modules, jammed together inside a directory,
and tells you exactly which module is installed there.

For quick start, and a fine example of this module usage, see L<dist_surveyor>.

This module have one exported function - determine_installed_releases

=cut

use strict;
use warnings;

use version;
use Carp; # core
use Data::Dumper; # core
use File::Find;  # core
use File::Spec; # core
use List::Util qw(max sum); # core
use Dist::Surveyor::Inquiry; # internal
use Module::CoreList;
use Module::Metadata;

our $VERSION = '0.019';

use constant ON_WIN32 => $^O eq 'MSWin32';
use constant ON_VMS   => $^O eq 'VMS';

if (ON_VMS) {
    require File::Spec::Unix;
}

our ($DEBUG, $VERBOSE);
*DEBUG = \$::DEBUG;
*VERBOSE = \$::VERBOSE;

require Exporter;
our @ISA = qw{Exporter};
our @EXPORT = qw{determine_installed_releases};

=head1 determine_installed_releases($options, $search_dirs)

$options includes:

=over

=item opt_match

A regex qr//. If exists, will ignore modules that doesn't match this regex

=item opt_perlver

Skip modules that are included as core in this Perl version

=item opt_remnants

If true, output will include old distribution versions that have left old modules behind

=item distro_key_mod_names

A hash-ref, with a list of irregular named releases. i.e. 'libwww-perl' => 'LWP'.

=back

$search_dirs is an array-ref containing the list of directories to survey.

Returns a list, where each element is a hashref representing one installed distibution.
This hashref is what MetaCPAN returns for C<https://fastapi.metacpan.org/v1/release/$author/$release>,
with two additional keys: 

=over

=item *

'url' - that same as 'download_url', but without the hostname. can be used to
download the file for your favorite mirror

=item *

'dist_data' - Hashref containing info about the release, i.e. percent_installed.
(fully installed releases will have '100.00')

=back

=cut

sub determine_installed_releases {
    my ($options, $search_dirs) = @_;
    $options->{opt_perlver} ||= version->parse( $] )->numify;

    my %installed_mod_info;

    warn "Finding modules in @$search_dirs\n";
    my ($installed_mod_files, $installed_meta) = find_installed_modules(@$search_dirs);

    # get the installed version of each installed module and related info
    warn "Finding candidate releases for the ".keys(%$installed_mod_files)." installed modules\n";
    foreach my $module ( sort keys %$installed_mod_files ) {
        my $mod_file = $installed_mod_files->{$module};

        if (my $opt_match = $options->{opt_match}) {
            if ($module !~ m/$opt_match/o) {
                delete $installed_mod_files->{$module};
                next;
            }
        }

        module_progress_indicator($module) unless $VERBOSE;
        my $mi = get_installed_mod_info($options, $module, $mod_file);
        $installed_mod_info{$module} = $mi if $mi;
    }


    # Map modules to dists using the accumulated %installed_mod_info info

    warn "*** Mapping modules to releases\n";

    my %best_dist;
    foreach my $mod ( sort keys %installed_mod_info ) {
        my $mi = $installed_mod_info{$mod};

        module_progress_indicator($mod) unless $VERBOSE;

        # find best match among the cpan releases that included this module
        my $ccdr = $installed_mod_info{$mod}{candidate_cpan_dist_releases}
            or next; # no candidates, warned about above (for mods with a version)

        my $best_dist_cache_key = join " ", sort keys %$ccdr;
        our %best_dist_cache;
        my $best = $best_dist_cache{$best_dist_cache_key}
            ||= pick_best_cpan_dist_release($ccdr, \%installed_mod_info);

        my $note = "";
        if ((@$best > 1) and $installed_meta->{perllocalpod}) { 
            # try using perllocal.pod to narrow the options, if there is one
            # XXX TODO move this logic into the per-candidate-distro loop below
            # it doesn't make much sense to be here at the per-module level
            my @in_perllocal = grep {
                my $distname = $_->{distribution};
                my ($v, $dist_mod_name) = perllocal_distro_mod_version(
                    $options->{distro_key_mod_names}, $distname, $installed_meta->{perllocalpod});
                warn "$dist_mod_name in perllocal.pod: ".($v ? "YES" : "NO")."\n"
                    if $DEBUG;
                $v;
            } @$best;
            if (@in_perllocal && @in_perllocal < @$best) {
                $note = sprintf "narrowed from %d via perllocal", scalar @$best;
                $best = \@in_perllocal;
            }
        }

        if (@$best > 1 or $note) { # note the poor match for this module
            # but not if there's no version (as that's common)
            my $best_desc = join " or ", map { $_->{release} } @$best;
            my $pct = sprintf "%.2f%%", $best->[0]{fraction_installed} * 100;
            warn "$mod $mi->{version} odd best match: $best_desc $note ($best->[0]{fraction_installed})\n"
                if $note or $VERBOSE or ($mi->{version} and $best->[0]{fraction_installed} < 0.3);
            # if the module has no version and multiple best matches
            # then it's unlikely make a useful contribution, so ignore it
            # XXX there's a risk that we'd ignore all the modules of a release
            # where none of the modules has a version, but that seems unlikely.
            next if not $mi->{version};
        }

        for my $dist (@$best) {
            # two level hash to make it easier to handle versions
            my $di = $best_dist{ $dist->{distribution} }{ $dist->{release} } ||= { dist => $dist };
            push @{ $di->{modules} }, $mi;
            $di->{or}{$_->{release}}++ for grep { $_ != $dist } @$best;
        }

    }

    warn "*** Refining releases\n";

    # $best_dist{ Foo }{ Foo-1.23 }{ dist=>$dist_struct, modules=>, or=>{ Foo-1.22 => $dist_struct } }

    my @installed_releases;    # Dist-Name => { ... }

    for my $distname ( sort keys %best_dist ) {
        my $releases = $best_dist{$distname};
        push @installed_releases, refine_releases($options, $distname, $releases);
    }

    # sorting into dependency order could be added later, maybe

    return @installed_releases;
}

sub refine_releases {
    my ($options, $distname, $releases) = @_;

    my @dist_by_version  = sort {
        $a->{dist}{version_obj}        <=> $b->{dist}{version_obj} or
        $a->{dist}{fraction_installed} <=> $b->{dist}{fraction_installed}
    } values %$releases;
    my @dist_by_fraction = sort {
        $a->{dist}{fraction_installed} <=> $b->{dist}{fraction_installed} or
        $a->{dist}{version_obj}        <=> $b->{dist}{version_obj}
    } values %$releases;
    
    my @remnant_dists  = @dist_by_version;
    my $installed_dist = pop @remnant_dists;

    # is the most recent candidate dist version also the one with the
    # highest fraction_installed?
    if ($dist_by_version[-1] == $dist_by_fraction[-1]) {
        # this is the common case: we'll assume that's installed and the
        # rest are remnants of earlier versions
    }
    elsif ($dist_by_fraction[-1]{dist}{fraction_installed} == 100) {
        warn "Unsure which $distname is installed from among @{[ keys %$releases ]}\n";
        @remnant_dists  = @dist_by_fraction;
        $installed_dist = pop @remnant_dists;
        warn "Selecting the one that apprears to be 100% installed\n";
    }
    else {
        # else grumble so the user knows to ponder the possibilities
        warn "Can't determine which $distname is installed from among @{[ keys %$releases ]}\n";
        warn Dumper([\@dist_by_version, \@dist_by_fraction]);
        warn "\tSelecting based on latest version\n";
    }

    if (@remnant_dists or $DEBUG) {
        warn "Distributions with remnants (chosen release is first):\n"
            unless our $dist_with_remnants_warning++;
        warn "@{[ map { $_->{dist}{release} } reverse @dist_by_fraction ]}\n"; 
        for ($installed_dist, @remnant_dists) {
            my $fi = $_->{dist}{fraction_installed};
            my $modules = $_->{modules};
            my $mv_desc = join(", ", map { "$_->{module} $_->{version}" } @$modules);
            warn sprintf "\t%s\t%s%% installed: %s\n",
                $_->{dist}{release},
                $_->{dist}{percent_installed},
                (@$modules > 4 ? "(".@$modules." modules)" : $mv_desc),
        }
    }

    my @installed_releases;
    # note ordering: remnants first
    for (($options->{opt_remnants} ? @remnant_dists : ()), $installed_dist) {
        my ($author, $release)
            = @{$_->{dist}}{qw(author release)};

        my $release_data = get_release_info($author, $release);
        next unless $release_data;
        
        # shortcuts
        (my $url = $release_data->{download_url}) =~ s{ .*? \b authors/ }{authors/}x;

        push @installed_releases, {
            # 
            %$release_data,
            # extra items mushed inhandy shortcuts
            url => $url,
            # raw data structures
            dist_data => $_->{dist},
        };
    }
    #die Dumper(\@installed_releases);
    return @installed_releases;
}

# for each installed module, get the list of releases that it exists in
# Parameters:
#   $options - uses only opt_perlver
#   $module - module name (i.e. 'Dist::Surveyor')
#   $mod_file - the location of this module on the filesystem
# Return:
#   undef if this module should be skipped
#   otherwise, a hashref containing:
#       file => $mod_file,
#       module => $module,
#       version => $mod_version,
#       version_obj => same as version, but as an object,
#       size => $mod_file_size,
#       # optional flags:
#       file_size_mismatch => 1,
#       cpan_dist_fallback => 1, # could not find this module/version on cpan,
#           # but found a release with that version, containing such module
#       version_not_on_cpan> 1, # can not find this file on CPAN.
#       # releases info
#       candidate_cpan_dist_releases => hashref,
#
#   candidate_cpan_dist_releases hashref contain a map of all the releases
#   that this module exists in. see get_candidate_cpan_dist_releases for more
#   info.
sub get_installed_mod_info {
    my ($options, $module, $mod_file) = @_;

    my $mod_version = do {
        # silence warnings about duplicate VERSION declarations
        # eg Catalyst::Controller::DBIC::API* 2.002001
        local $SIG{__WARN__} = sub { warn @_ if $_[0] !~ /already declared with version/ };
        my $mm = Module::Metadata->new_from_file($mod_file);
        $mm->version; # only one version for one package in file
    };
    $mod_version ||= 0; # XXX
    my $mod_file_size = -s $mod_file;

    # Eliminate modules that will be supplied by the target perl version
    if ( my $cv = $Module::CoreList::version{ $options->{opt_perlver} }->{$module} ) {
        $cv =~ s/ //g;
        if (version->parse($cv) >= version->parse($mod_version)) {
            warn "$module is core in perl $options->{opt_perlver} (lib: $mod_version, core: $cv) - skipped\n";
            return;
        }
    }

    my $mi = {
        file => $mod_file,
        module => $module,
        version => $mod_version,
        version_obj => version->parse($mod_version),
        size => $mod_file_size,
    };

    # ignore modules we know aren't indexed
    return $mi if $module =~ /^Moose::Meta::Method::Accessor::Native::/;

    # XXX could also consider file mtime: releases newer than the mtime
    # of the module file can't be the origin of that module file.
    # (assuming clocks and file times haven't been messed with)

    eval {
        my $ccdr = get_candidate_cpan_dist_releases($module, $mod_version, $mod_file_size);
        if (not %$ccdr) {
            $ccdr = get_candidate_cpan_dist_releases($module, $mod_version, 0);
            if (%$ccdr) {
                # probably either a local change/patch or installed direct from repo
                # but with a version number that matches a release
                warn "$module $mod_version on CPAN but with different file size (not $mod_file_size)\n"
                    if $mod_version or $VERBOSE;
                $mi->{file_size_mismatch}++;
            }
            elsif ($ccdr = get_candidate_cpan_dist_releases_fallback($module, $mod_version) and %$ccdr) {
                warn "$module $mod_version not on CPAN but assumed to be from @{[ sort keys %$ccdr ]}\n"
                    if $mod_version or $VERBOSE;
                $mi->{cpan_dist_fallback}++;
            }
            else {
                $mi->{version_not_on_cpan}++;
                # Possibly:
                # - a local change/patch or installed direct from repo
                #   with a version number that was never released.
                # - a private module never released on cpan.
                # - a build-time create module eg common/sense.pm.PL
                warn "$module $mod_version not found on CPAN\n"
                    if $mi->{version} # no version implies uninteresting
                    or $VERBOSE;
                # XXX could try finding the module with *any* version on cpan
                # to help with later advice. ie could select as candidates
                # the version above and the version below the number we have,
                # and set a flag to inform later logic.
            }
        }
        $mi->{candidate_cpan_dist_releases} = $ccdr if %$ccdr;
    };
    if ($@) {
        warn "Failed get_candidate_cpan_dist_releases($module, $mod_version, $mod_file_size): $@";
    }
    return $mi;
}

# pick_best_cpan_dist_release - memoized
# for each %$ccdr adds a fraction_installed based on %$installed_mod_info
# returns ref to array of %$ccdr values that have the max fraction_installed

sub pick_best_cpan_dist_release {
    my ($ccdr, $installed_mod_info) = @_;

    for my $release (sort keys %$ccdr) {
        my $release_info = $ccdr->{$release};
        $release_info->{fraction_installed}
            = dist_fraction_installed($release_info->{author}, $release, $installed_mod_info);
        $release_info->{percent_installed} # for informal use
            = sprintf "%.2f", $release_info->{fraction_installed} * 100;
    }

    my $max_fraction_installed = max( map { $_->{fraction_installed} } values %$ccdr );
    my @best = grep { $_->{fraction_installed} == $max_fraction_installed } values %$ccdr;

    return \@best;
}


# returns a number from 0 to 1 representing the fraction of the modules
# in a particular release match the coresponding modules in %$installed_mod_info
sub dist_fraction_installed {
    my ($author, $release, $installed_mod_info) = @_;

    my $tag = "$author/$release";
    my $mods_in_rel = get_module_versions_in_release($author, $release);
    my $mods_in_rel_count = keys %$mods_in_rel;
    my $mods_inst_count = sum( map {
        my $mi = $installed_mod_info->{ $_->{name} };
        # XXX we stash the version_obj into the mods_in_rel hash
        # (though with little/no caching effect with current setup)
        $_->{version_obj} ||= eval { version->parse($_->{version}) };
        my $hit = ($mi && $mi->{version_obj} == $_->{version_obj}) ? 1 : 0;
        # demote to a low-scoring partial match if the file size differs
        # XXX this isn't good as the effect varies with the number of modules
        $hit = 0.1 if $mi && $mi->{size} != $_->{size};
        warn sprintf "%s %s %s %s: %s\n", $tag, $_->{name}, $_->{version_obj}, $_->{size},
                ($hit == 1) ? "matches"
                    : ($mi) ? "differs ($mi->{version_obj}, $mi->{size})"
                    : "not installed",
            if $DEBUG;
        $hit;
    } values %$mods_in_rel) || 0;

    my $fraction_installed = ($mods_in_rel_count) ? $mods_inst_count/$mods_in_rel_count : 0;
    warn "$author/$release:\tfraction_installed $fraction_installed ($mods_inst_count/$mods_in_rel_count)\n"
        if $VERBOSE or !$mods_in_rel_count;

    return $fraction_installed;
}

sub get_file_mtime {
    my ($file) = @_;
    # try to find the time the file was 'installed'
    # by looking for the commit date in svn or git
    # else fallback to the file modification time
    return (stat($file))[9];
}


sub find_installed_modules {
    my (@dirs) = @_;

    ### File::Find uses follow_skip => 1 by default, which doesn't die
    ### on duplicates, unless they are directories or symlinks.
    ### Ticket #29796 shows this code dying on Alien::WxWidgets,
    ### which uses symlinks.
    ### File::Find doc says to use follow_skip => 2 to ignore duplicates
    ### so this will stop it from dying.
    my %find_args = ( follow_skip => 2 );

    ### File::Find uses lstat, which quietly becomes stat on win32
    ### it then uses -l _ which is not allowed by the statbuffer because
    ### you did a stat, not an lstat (duh!). so don't tell win32 to
    ### follow symlinks, as that will break badly
    # XXX disabled because we want the postprocess hook to work
    #$find_args{'follow_fast'} = 1 unless ON_WIN32;

    ### never use the @INC hooks to find installed versions of
    ### modules -- they're just there in case they're not on the
    ### perl install, but the user shouldn't trust them for *other*
    ### modules!
    ### XXX CPANPLUS::inc is now obsolete, remove the calls
    #local @INC = CPANPLUS::inc->original_inc;

    # sort @dirs to put longest first to make it easy to handle
    # elements that are within other elements (e.g., an archdir)
    my @dirs_ordered = sort { length $b <=> length $a } @dirs;

    my %seen_mod;
    my %dir_done;
    my %meta; # return metadata about the search
    for my $dir (@dirs_ordered) {
        next if $dir eq '.';

        ### not a directory after all
        ### may be coderef or some such
        next unless -d $dir;

        ### make sure to clean up the directories just in case,
        ### as we're making assumptions about the length
        ### This solves rt.cpan issue #19738

        ### John M. notes: On VMS cannonpath can not currently handle
        ### the $dir values that are in UNIX format.
        $dir = File::Spec->canonpath($dir) unless ON_VMS;

        ### have to use F::S::Unix on VMS, or things will break
        my $file_spec = ON_VMS ? 'File::Spec::Unix' : 'File::Spec';

        ### XXX in some cases File::Find can actually die!
        ### so be safe and wrap it in an eval.
        eval {
            File::Find::find(
                {   %find_args,
                    postprocess => sub {
                        $dir_done{$File::Find::dir}++;
                    },
                    wanted => sub {

                        unless (/\.pm$/i) {
                            # skip all dot-dirs (eg .git .svn)
                            $File::Find::prune = 1
                                if -d $File::Find::name and /^\.\w/;
                            # don't reenter a dir we've already done
                            $File::Find::prune = 1
                                if $dir_done{$File::Find::name};
                            # remember perllocal.pod if we see it
                            push @{$meta{perllocalpod}}, $File::Find::name
                                if $_ eq 'perllocal.pod';
                            return;
                        }
                        my $mod = $File::Find::name;

                        ### make sure it's in Unix format, as it
                        ### may be in VMS format on VMS;
                        $mod = VMS::Filespec::unixify($mod) if ON_VMS;

                        $mod = substr( $mod, length($dir) + 1, -3 );
                        $mod = join '::', $file_spec->splitdir($mod);

                        return if $seen_mod{$mod};
                        $seen_mod{$mod} = $File::Find::name;

                        ### ignore files that don't contain a matching package declaration
                        ### warn about those that do contain some kind of package declaration
                        #use File::Slurp;
                        #my $content = read_file($File::Find::name);
                        #unless ( $content =~ m/^ \s* package \s+ (\#.*\n\s*)? $mod \b/xm ) {
                        #warn "No 'package $mod' seen in $File::Find::name\n"
                        #if $VERBOSE && $content =~ /\b package \b/x;
                        #return;
                        #}

                    },
                },
                $dir
            );
            1;
        }
            or die "File::Find died: $@";

    }

    return (\%seen_mod, \%meta);
}


sub perllocal_distro_mod_version {
    my ($distro_key_mod_names, $distname, $perllocalpod) = @_;

    ( my $dist_mod_name = $distname ) =~ s/-/::/g;
    my $key_mod_name = $distro_key_mod_names->{$distname} || $dist_mod_name;

    our $perllocal_distro_mod_version;
    if (not $perllocal_distro_mod_version) { # initial setup
        warn "Only first perllocal.pod file will be processed: @$perllocalpod\n"
            if ref $perllocalpod eq 'ARRAY' and @$perllocalpod > 1;

        $perllocal_distro_mod_version = {};
        # extract data from perllocal.pod
        if (my $plp = shift @$perllocalpod) {
            # The VERSION isn't always the same as that in the distro file
            if (eval { require ExtUtils::Perllocal::Parser }) {
                my $p = ExtUtils::Perllocal::Parser->new;
                $perllocal_distro_mod_version = { map {
                    $_->name => $_->{data}{VERSION}
                } $p->parse_from_file($plp) };
                warn "Details of ".keys(%$perllocal_distro_mod_version)." distributions found in $plp\n";
            }
            else {
                warn "Wanted to use perllocal.pod but can't because ExtUtils::Perllocal::Parser isn't available\n";
            }
        }
        else {
            warn "No perllocal.pod found to aid disambiguation\n";
        }
    }

    return $perllocal_distro_mod_version->{$key_mod_name};
}


sub module_progress_indicator {
    my ($module) = @_;
    my $crnt = (split /::/, $module)[0];
    our $last ||= '';
    if ($last ne $crnt) {
        warn "\t$crnt...\n";
        $last = $crnt;
    }
}

=head1 OTHERS

This module checks $::DEBUG and $::VERBOSE for obvious proposes.

This module uses L<Dist::Surveyor::Inquiry> to communicate with MetaCPAN. 
Check that module's documentation for options and caching. 

You can use L<Dist::Surveyor::MakeCpan> to take the list of releases
and create a mini-cpan containing them.

=head1 AUTHOR

Written by Tim Bunce E<lt>Tim.Bunce@pobox.comE<gt> 

Maintained by Fomberg Shmuel E<lt>shmuelfomberg@gmail.comE<gt>, Dan Book E<lt>dbook@cpan.orgE<gt>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright 2011-2013 by Tim Bunce.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut

1;
