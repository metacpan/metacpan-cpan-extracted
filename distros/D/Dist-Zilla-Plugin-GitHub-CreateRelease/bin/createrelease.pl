#!/usr/bin/env perl
use v5.20;
use Feature::Compat::Class;
use feature 'signatures';
our $VERSION = '0.0012'; # VERSION
# PODNAME: createrelease.pl
# ABSTRACT: Helper script to create a GitHub Release
use Config::INI::Reader;
use Pithub::Repos::Releases;
use Config::Identity;
use Git::Wrapper;
use Try::Tiny;
use File::Slurper qw( read_binary read_text );
use URI::Escape qw( uri_unescape );
use DDP;
use CPAN::Changes 0.500002;
use JSON::MaybeXS 1.004000;

class GitHub::Release {
    field $repo             :param //= '';
    field $hash_alg         :param //= 'sha256';
    field $org_id           :param //= 'github';
    field $branch           :param //= 'main';
    field $remote_name      :param //= 'upstream';
    field $title_template   :param //= 'Version RELEASE - TRIAL CPAN release';
    field $notes_as_code    :param //= 1;
    field $github_notes     :param //= 0;
    field $notes_from       :param //= 'SignReleaseNotes';
    field $notes_file       :param //= 'Release-VERSION';
    field $draft            :param //= 0;
    field $add_checksum     :param //= 1;
    field $trial            :param //= 0;
    field $filename         :param //= '';
    field $config_filename  :param //= 'dist.ini';
    field $version          :param //= undef;
    field $sign             :param //= 0;

    ADJUST {
        $draft          = $draft ? JSON::MaybeXS::true : JSON::MaybeXS::false;
        $trial          = $trial ? JSON::MaybeXS::true : JSON::MaybeXS::false;
        $github_notes   = $github_notes ? JSON::MaybeXS::true : JSON::MaybeXS::false;
    }

    method get_title {
        my $title = $title_template;
        my $trial = $trial ? 'Trial' : 'Official';
        $title =~ s/TRIAL/$trial/;
        my $version = $self->get_version();
        $title =~ s/RELEASE/$version/;
        return $title;
    }

    method get_branch {
        return $branch;
    }

    method get_config_filename {
        if (-f '.githubcreaterelease') {
            $config_filename = '.githubcreaterelease';
        }
        return $config_filename;
    }

    method set_config_filename ($name) {
        $config_filename = $name;
    }

    method get_dist_filename ($version) {
        return if ! defined $version;
        my $config      = Config::INI::Reader->read_file($self->get_config_filename());
        if ($self->get_config_filename() ne 'dist.ini'  && ! defined $config->{'_'}{name}){
            my $dist = Config::INI::Reader->read_file('dist.ini');
            $config->{'_'}{name} = $dist->{'_'}{name};
        }
        # Obtain the GitHub::CreateRelease attributes
        my $dist_name  = $config->{'_'}{name};
        my $filename = $dist_name . "-$version" . ($trial ? '-TRIAL' : '') . '.tar.gz';

        return $filename;
    }

    method set_filename ($name) {
        if ( -e $name ) {
            $filename = $name;
        } else {
            $self->log("$name does not exist");
        }
    }

    method get_sign () {
        my $config      = Config::INI::Reader->read_file($self->get_config_filename());
        $sign = $config->{'GitHub::CreateRelease'}{sign};
        return $sign;
    }

    method get_draft () {
        return $draft ? JSON::MaybeXS::true : JSON::MaybeXS::false;
    }

    method set_draft ($setting) {
        $draft = $setting ? JSON::MaybeXS::true : JSON::MaybeXS::false;
    }

    method get_trial () {
        return $trial ? JSON::MaybeXS::true : JSON::MaybeXS::false;
    }

    method set_trial ($setting) {
        $trial = $setting ? JSON::MaybeXS::true : JSON::MaybeXS::false;
    }

    method get_identity($org_id = '') {
        my @fields = ("login", "token");
        my %identity = Config::Identity->load_check($org_id, \@fields);
        die "Unable to load github token from ~/.$org_id-identity or ~/.$org_id"
            if (! defined $identity{token});
        return %identity;
    }

    method menu {
        my @items = @_;

        print "Enter the number of the git remote where you want to create a release:\n";
        print "Valid values are:\n";
        print "\n?: ";
        my $count = 0;
        foreach my $item( @items ) {
            $item =~ m/remote\.(.*)\.url/;
            printf "%d: %s\n", ++$count, $1;
        }

        print "\n?: ";

        while( my $line = <STDIN> ) {
            chomp $line;
            if ( $line =~ m/\d+/ && $line <= @items ) {
                return $line - 1;
            }
            print "\n?: ";
        }
    }

    method get_repo_name {
        my $git = Git::Wrapper->new('./');
        my @url;
        use Try::Tiny;
        try {
            @url = $git->RUN('config', '--get', 'branch.main.remote');
            $remote_name = $url[0];
        }
        catch {
            $self->log("Unable to find git \'branch.main.remote\' using git config --get branch.main.remote\n");
        };
        my $setting = "remote." . $remote_name . ".url";
        $self->log("Release will be created using $setting\n");
        try {
            @url = $git->RUN('config', '--get', $setting);
        }
        catch {
            $self->log("Unable to find git \'$setting\' using git config --get $setting\n");
            my @settings;
            try {
                @settings = $git->RUN('config', '--name-only', '--get-regexp', 'remote\..*\.url');
            }
            catch {
                $self->log("You do not seem to have any remote repositories defined'\n");
                $self->log("Run \'git config --name-only --get-regexp remote\..*\.url\' to review\n");
                return "";
            };
            my $number = $self->menu(@settings);
            try {
                @url = $git->RUN('config', '--get', $settings[$number]);
            }
            catch {
            $self->log("Unable to find git \'$settings[$number]\' using git config --get $settings[$number]\n");
            $self->log("You do not seem to have a remote repository set at: \'$settings[$number]\'\n");
            return "";
            };
        };

        #FIXME there must be a better way...
        my $basename = URI::Escape::uri_unescape( File::Basename::basename(URI->new( $url[0])->path));
        $basename =~ s/\.git$//;
        $self->log("Release will be created using $basename");

        return $basename;
    }

    method get_releases ($repo = '') {
        my %identity = $self->get_identity ($org_id);
        my $r = Pithub::Repos::Releases->new(
            user  => $identity{login},
            repo  => $self->get_repo_name(),
            #token => $identity{token},
        );
        use DDP;
        my $result = $r->list(
        );
        #p $result;
        print $result->count, "\n\n\n";
        use JSON::MaybeXS;
        my $json_with_args = JSON::MaybeXS->new(utf8 => 1);
        my $json = $json_with_args->decode_json($result->_json);
        #my $list = $result->list;
        print "==================================================\n";
        #my @content = $list->raw_content;
        #print $content[0], "\n";
        #print "==================================================\n";
        #foreach my $rel (@list) {
        #    p $rel;
        #    p $json;
        #
        #}

    }

    method create_release ($repo = '') {
        my %identity = $self->get_identity ($org_id);
        my $releases = Pithub::Repos::Releases->new(
            user  => $identity{login},
            repo  => $self->get_repo_name(),
            token => $identity{token},
        );

        require JSON::MaybeXS;
        my $response = $releases->create(
            data => {
            tag_name         => $self->get_version(),
            target_commitish => $branch,
            name             => $self->get_title(),
            body             => $self->get_notes(),
            draft            => $draft ? JSON::MaybeXS::true : JSON::MaybeXS::false,
            prerelease       => $trial ? JSON::MaybeXS::true : JSON::MaybeXS::false,
            generate_release_notes => $github_notes,
            }
        );

        die "Unable to create release for $identity{login}\\$releases->{repo}" if  ($response->code eq '404');
        #die "Validation failed, or the endpoint has been spammed." if  ($response->code eq '422');
        die "login or token invalid for the specified repository: $identity{login}\\$releases->{repo}\n"
            if  ($response->code eq '403');

        if ($response->code ne '201') {
            my $message = $response->raw_content();
            print "message", $message, "\n";
            $message =~ s/\n/ /gm;
            my $error_message  = decode_json $message;
            for my $error (@{$error_message->{errors}}) {
                print "Field: ", $error->{message}, " - ", $error->{code}, "\n";
            }
            die "See information at ", $error_message->{documentation_url}, "\n";
        }

        if (! defined $response->content->{id}) {
            die "Unable to create GitHub release\n";
        }
        $self->log("Release created at $releases->{repo} for $identity{login}");

        $filename = $self->get_dist_filename($self->get_version()) if ! $filename;

        my $release_results;
        if (! -e $filename) {
            use MetaCPAN::Client;
            my $mcpan  = MetaCPAN::Client->new();
            my $dist = Config::INI::Reader->read_file('dist.ini');
            $release_results = $mcpan->release(
            {
                all => [
                        {
                            distribution => $dist->{'_'}{name},
                        },
                    ]
            }
        );

        while ( my $release = $release_results->next ) {
            if ($release->{data}->{version} eq $self->get_version()) {
                use LWP::Simple;
                $filename = $release->{data}->{archive};
                getstore($release->{data}->{download_url}, $filename);

            }
        }
            die "Let's download the file from pause" if ( ! -e $filename);
        }
        my $cpan_tar  = File::Slurper::read_binary($filename);

        my $asset = $releases->assets->create(
                        release_id   => $response->content->{id},
                        name         => $filename,
                        data         => $cpan_tar,
                        content_type => 'application/gzip',
                    );

        my $tag = $self->get_version();
        if ($asset->code eq '201') {
            $self->log("CPAN archive appended to GitHub release: $tag");
        } else {
            $self->log("Unable to append CPAN archive GitHub release: $tag");
        }
    }

    method set_version ($ver){
        return if not defined $ver;
        $version = $ver;
    }

    method get_version {
        return $version if defined $version;

        my $git = Git::Wrapper->new('./');

        my @tags;
        use Try::Tiny;
        try {
            @tags = $git->RUN(
                                'for-each-ref',
                                'refs/tags/*',
                                '--sort=-version:refname',
                                '--count=1',
                                '--format=%(refname:short)'
                            );
        }
        catch {
            $self->log("Unable to get the current release's tag from git");
            #FIXME this is pretty much a failure
        };

        return $tags[0];
    }

    method get_notes {
        my $notes;
        if ($notes_from eq 'SignReleaseNotes' or $notes_from eq 'FromFile') {
            $notes = $self->get_notes_from_file($filename);
        } elsif ($notes_from eq 'ChangeLog') {
            $notes = $self->get_notes_from_changes($filename);
        } elsif ($notes_from eq 'GitHub::CreateRelease') {
            $notes = $self->generate_release_notes($filename);
        }

        die "Notes are undefined by get_notes" if (! defined $notes || $notes eq '');
        return $notes;
    }

    method generate_release_notes ($filename) {
        my $notes;

        return "" if (! $add_checksum);

        $notes = $self->get_checksum($filename);

        return $self->_as_code($notes);
    }

    method get_notes_from_changes {
        my $filename  = shift;

        my $git = Git::Wrapper->new('./');
        my @tags;
        try {
               @tags = $git->RUN('for-each-ref', 'refs/tags/*', '--sort=-version:refname', '--count=1', '--format=%(refname:short)');
        }
        catch {
            $self->log("Unable to get the last two tags from git");
            #FIXME this is pretty much a failure but we will at least return something
            return $self->{add_checksum} ? $self->_as_code($self->get_checksum($filename)) :
                    $self->_as_code($filename);
        };

        my $changes = CPAN::Changes->load($notes_file);
        my $notes = $changes->find_release($tags[0])->serialize();
        return $self->_as_code($notes) if (! $add_checksum);

        $notes .= "\n" . $self->get_checksum($filename);
        return $self->_as_code($notes);
    }

    method get_notes_from_file ($filename) {

        my $version   = $self->get_version();

        my $notes_file = $notes_file;
        $notes_file    =~ s/VERSION/$version/;

        my $notes     = File::Slurper::read_text($notes_file);

        return $self->_as_code($notes) if (! $add_checksum);

        return $self->_as_code($notes) if ($notes_from eq 'SignReleaseNotes');

        $notes .= $self->get_checksum($filename);

        return $self->_as_code($notes);

    }

    method get_checksum {
        my $filename = shift;

        use Digest::SHA;
        my $sha = Digest::SHA->new($hash_alg);
        my $digest;
        if ( -e $filename ) {
            open my $fh, '<:raw', $filename  or die "$filename: $!";
            $sha->addfile($fh);
            $digest = $sha->hexdigest;
        }

        my $checksum = uc($hash_alg) . " hash of CPAN release\n";
        $checksum .= "\n";
        $checksum .= "$digest *$filename\n";
        $checksum .= "\n";

        return $checksum;
    }

    method _as_code ($text) {
        return '```' . "\n" . $text . "\n" . '```' if $notes_as_code;
        return $text;
    }


    method log ($log) {
        print $log, "\n";
    }
}

use Getopt::Long;
my $trial      = 0;
my $nodraft    = 0;
my $configfile ='dist.ini';
my $version;

GetOptions ("no-draft"      => \$nodraft,
            "trial"         => \$trial,
            "configfile=s"  => \$configfile,
            "version=s"     => \$version)
or die("Error in command line arguments --configfile, --no-draft, --trial or --version are supported\n");

my $draft = $nodraft ? 0 : 1;
# Load the Dist::Zilla file
my $config      = Config::INI::Reader->read_file($configfile);
# Obtain the GitHub::CreateRelease attributes
my $attributes  = $config->{'GitHub::CreateRelease'};

my $release     = GitHub::Release->new(%{$attributes});

print "Trial: $trial\n";
print "Draft: $draft\n";
print "Config: $configfile\n";
print "Version: $version\n" if defined $version;
$release->set_trial($trial);
$release->set_draft($draft);
$release->set_version($version);
$release->set_config_filename($configfile ? $configfile : '');
print "Dist-Name: ", $release->get_dist_filename($version), "\n";
print "File name: " , $release->get_config_filename($configfile) ,"\n" if $configfile;
$release->set_filename($release->get_dist_filename($release->get_version()));
$release->create_release( );

__END__

=pod

=encoding UTF-8

=head1 NAME

createrelease.pl - Helper script to create a GitHub Release

=head1 VERSION

version 0.0012

=head1 SYNOPSIS

This script can be run from the root directory of your distribution, after
C<dzil release> has tagged and pushed the release:

It will allow you to create a "GitHub Release" for a version you specify
which is helpful if the Dist::Zilla plugin failed for some reason.

 createrelease.pl [options]

 Options:
   --no-draft             publish the release immediately (default: draft)
   --trial                mark the release as a trial (pre-)release
   --configfile FILE      configuration file to read (default: dist.ini)
   --version VERSION      version of the release

Examples:

 # Create a draft release for the most recent git tag
 createrelease.pl

 # Create a published release for a trial upload
 createrelease.pl --no-draft --trial

 # Create the release using a standalone configuration file
 createrelease.pl --configfile .githubcreaterelease --no-draft

 # Create the release for a specific version rather than the latest tag
 createrelease.pl --version 2.08

 # The same, for a trial release: --trial adds the -TRIAL suffix itself
 createrelease.pl --trial --version 2.08

=head1 DESCRIPTION

C<createrelease.pl> performs the same task as
L<Dist::Zilla::Plugin::GitHub::CreateRelease>, but as a standalone script
rather than as part of a C<dzil release> run.

It is intended to be run from the root directory of a distribution B<after>
the release has been built, tagged and pushed to GitHub.  It:

=over

=item 1

Reads the C<[GitHub::CreateRelease]> section of the configuration file
(F<dist.ini> by default) to obtain its settings.

=item 2

Determines the version of the release from the most recent git tag, unless
a version is given with C<--version>.

=item 3

Determines the GitHub repository from the URL of the git remote associated
with the current branch.  If the remote cannot be determined a menu of the
configured remotes is presented.

=item 4

Creates the GitHub Release using the GitHub API, with release notes obtained
according to the C<notes_from> setting.

=item 5

Attaches the CPAN release archive to the GitHub Release.  If the archive is
not present in the current directory it is downloaded from MetaCPAN.

=back

This is useful when the release was uploaded to CPAN but the GitHub Release
was not created - for example when the plugin was not yet configured, or when
the plugin failed after the distribution was uploaded.

=head1 OPTIONS

=over

=item B<--no-draft>

Publish the release immediately rather than creating it as a draft.

The release is created as a draft unless this option is given.  A draft
release is not visible until it is published via the GitHub web page.  Note
that the draft state is decided entirely by this option: the C<draft> setting
in the configuration file has no effect on this script.

In effect B<--draft> is the default option but it is not an option.

=item B<--trial>

Mark the release as a trial release.  The release is created as a GitHub
pre-release, C<TRIAL> in the C<title_template> is replaced with "Trial"
rather than "Official", and the archive that is attached to the release is
the C<-TRIAL> variant, for example F<Some-Dist-0.0010-TRIAL.tar.gz>.

=item B<--configfile> FILE

The configuration file to read the C<[GitHub::CreateRelease]> settings from.
It defaults to F<dist.ini>.  Note that F<dist.ini> is always read as well, in
order to obtain the name of the distribution.

=item B<--version> VERSION

The version of the release.  If it is not specified the most recently created
git tag is used instead.

The value is used everywhere the version of the release is needed: as the tag
the release points at, in the title of the release, in the name of the notes
file, and in the name of the CPAN archive that is attached.  It must therefore
match an existing tag in the repository.

Give the version on its own even for a trial release - C<--trial> appends the
C<-TRIAL> suffix to the name of the archive itself.

=back

=head1 CONFIGURATION

The script reads its settings from the C<[GitHub::CreateRelease]> section of
the configuration file, in the same format used by the plugin:

 name    = This-Distribution

 [GitHub::CreateRelease]
 branch = main                   ; default = main
 notes_as_code = 1               ; default = 1 (true)
 notes_from = ChangeLog          ; default = SignReleaseNotes
 notes_file = Changes            ; default = Release-VERSION
 github_notes = 0                ; default = 0 (false)
 hash_alg = sha256               ; default = sha256
 add_checksum = 1                ; default = 1 (true)
 org_id = some_id_identifier     ; default = github
 title_template = Version RELEASE - TRIAL CPAN release      ; this is the default

The settings have the same meaning as the attributes of the same name
documented in L<Dist::Zilla::Plugin::GitHub::CreateRelease>.  Only the
settings listed above, plus C<repo>, C<remote_name>, C<draft>, C<trial> and
C<sign>, are recognised by this script; any other setting in the section
causes it to fail on startup.

The C<draft> and C<trial> settings are always overridden by the command line
- use C<--no-draft> and C<--trial> to control them.

If a file named F<.githubcreaterelease> exists in the current directory it is
used as the configuration file in preference to the file given by
C<--configfile>.  This allows the settings to be kept separate from
F<dist.ini> - for example for a distribution that is not built with
Dist::Zilla.

=head1 RELEASE NOTES

The C<notes_from> setting determines where the body of the GitHub Release
comes from:

=over

=item SignReleaseNotes

Read from the file named by C<notes_file>, with C<VERSION> in the name
replaced by the version of the release.  The file is used as-is, since the
notes generated by L<Dist::Zilla::Plugin::SignReleaseNotes> already contain
the checksum of the archive.

=item FromFile

As above, but the checksum of the CPAN archive is appended when
C<add_checksum> is true.

=item ChangeLog

Read the entry for the release from the change log named by C<notes_file>
using L<CPAN::Changes>.  The checksum of the CPAN archive is appended when
C<add_checksum> is true.

=item GitHub::CreateRelease

Use only the checksum of the CPAN archive as the notes.

=back

When C<notes_as_code> is true the notes are wrapped in a GitHub markdown
code fence.

=head1 GITHUB API AUTHENTICATION

The script uses L<Config::Identity::GitHub> to obtain the GitHub API
credentials, and requires a file in your home directory named
F<.github-identity> containing:

 login github_username OR github_organization
 token github_....

The token must be a Personal Access Token with at least "Write" access to
"Contents" for the repository.  The C<org_id> setting selects a different
identity file, so that C<org_id = project> reads F<~/.project-identity> or
F<~/.project> instead.

An encrypted (F<.github-identity.asc>) identity file is supported and
recommended.  See L<Dist::Zilla::Plugin::GitHub::CreateRelease/"GITHUB API
AUTHENTICATION"> for the full details.

=head1 CAVEATS

Unless C<--version> is given, the version is taken from the git tag sorted by
tag date, so the tag for the release being published must be the most recently
created tag in the repository.  Use C<--version> to publish a release for any
older tag.

The owner of the repository is taken from the C<login> of the identity file,
so a repository owned by another user or organization needs an C<org_id>
identity whose login is that owner.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::GitHub::CreateRelease>

L<Dist::Zilla::Plugin::SignReleaseNotes>

L<Config::Identity::GitHub>

=head1 AUTHOR

Timothy Legge

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Timothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
