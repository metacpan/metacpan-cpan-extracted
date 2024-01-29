#!/usr/bin/env perl
use v5.20;
use Feature::Compat::Class;
use feature 'signatures';

# PODNAME: create_release.pl - Helper script to create a GitHub Release
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
        if ($self->get_config_filename() ne 'dist.ini'){
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

    method get_identity($org = '') {
        my @fields = ("login", "token");
        my %identity = Config::Identity->load_check($org, \@fields);
        die "Unable to load github token from ~/.$org-identity or ~/.$org"
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
        my $setting = "remote." . $remote_name . ".url";
        $self->log("Release will be created using $setting\n");
        my $git = Git::Wrapper->new('./');
        my @url;
        use Try::Tiny;
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
        $basename =~ s/.git//;
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
        print "Version: ", $version, "\n";
    }

    method get_version {
        my $git = Git::Wrapper->new('./');

        my @tags;
        use Try::Tiny;
        try {
            @tags = $git->RUN(
                                'for-each-ref',
                                'refs/tags/*',
                                '--sort=-taggerdate',
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

    method _sign_notes ($notes) {
        if ($self->get_sign()) {
            use Module::Signature qw/ $SIGNATURE $Preamble /;
            use File::Temp qw/ tempfile /;
            my $fh;
            ($fh, $SIGNATURE) = tempfile();
            $Preamble = '';
            my $signed;
            if (my $version = Module::Signature::_has_gpg()) {
                $signed = Module::Signature::_sign_gpg($SIGNATURE, $notes, $version);
            }
            elsif (eval {require Crypt::OpenPGP; 1}) {
                $signed = Module::Signature::_sign_crypt_openpgp($SIGNATURE, $notes);
            }
            use File::Slurper qw/ read_text /;
            print "tmpfiel: $SIGNATURE\n";
            $notes = read_text($SIGNATURE) if $signed;
            unlink $SIGNATURE;
        }
        return $notes;
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
               @tags = $git->RUN('for-each-ref', 'refs/tags/*', '--sort=-taggerdate', '--count=2', '--format=%(refname:short)');
        }
        catch {
            $self->log("Unable to get the last two tags from git");
            #FIXME this is pretty much a failure but we will at least return something
            return $self->{add_checksum} ? $self->_as_code($self->get_checksum($filename)) :
                    $self->_as_code($filename);
        };

        my $changes = CPAN::Changes->load($notes_file);
        my $notes = $changes->release($tags[0])->serialize();
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
        $text = $self->_sign_notes($text);
        return '```' . "\n" . $text . "\n" . '```' if $notes_as_code;
        return $text;
    }


    method log ($log) {
        print $log, "\n";
    }
}

use Getopt::Long;
my $prod    = 0;
my $trial  = 0;
my $draft   = 1;
my $configfile='dist.ini';
my $version;

GetOptions ("draft"     => \$draft,
            "prod"      => \$prod,
            "trial"   => \$trial,
            "configfile=s"  => \$configfile,
            "version=s"   => \$version)
or die("Error in command line arguments --draft or --prod are supported\n");

# Load the Dist::Zilla file
my $config      = Config::INI::Reader->read_file($configfile);
# Obtain the GitHub::CreateRelease attributes
my $attributes  = $config->{'GitHub::CreateRelease'};

my $release     = GitHub::Release->new(%{$attributes});

print "Trial: $prod\n";
print "Draft: $draft\n";
print "Config: $configfile\n";
print "Version: $version\n" if defined $version;
$release->set_trial($prod ? 0 : $prod);
$release->set_draft($draft);
$release->set_version($version);
$release->set_config_filename($configfile ? $configfile : '');

print "Trial: " . $release->get_trial() . "\n";
print "Draft: " . $release->get_draft() . "\n";
print "Version: " . $release->get_version() . "\n";

print "Dist-Name: ", $release->get_dist_filename($version), "\n";
print "File name: " , $release->get_config_filename($configfile) ,"\n" if $configfile;
$release->set_filename($release->get_dist_filename($release->get_version()));
$release->create_release( );

__END__

=pod

=encoding UTF-8

=head1 NAME

create_release.pl - Helper script to create a GitHub Release

=head1 VERSION

version 0.0007

=head1 AUTHOR

Timothy Legge

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Timothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
