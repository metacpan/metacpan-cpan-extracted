package Dist::Zilla::PluginBundle::AVAR;
our $AUTHORITY = 'cpan:AVAR';
$Dist::Zilla::PluginBundle::AVAR::VERSION = '0.35';
use 5.10.0;
use Moose;

with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git 1.102810;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::ReadmeFromPod;
use Dist::Zilla::Plugin::MakeMaker::Awesome;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Authority;
use Dist::Zilla::Plugin::InstallRelease;
use Try::Tiny;
use Git::Wrapper ();
use Dist::Zilla::Chrome::Term ();
use Dist::Zilla::Dist::Builder ();
use Dist::Zilla::App ();

sub bundle_config {
    my ($self, $section) = @_;

    my $args        = $section->{payload};

    my $zilla       = $self->_get_zilla;

    my $dist        = $args->{dist} // $zilla->name || die "You must supply a dist =, it's equivalent to what you supply as name =";

    my $ldist       = lc $dist;

    my $git = Git::Wrapper->new('.');

    my $github_user = $args->{github_user} // try { ($git->config('github.user'))[0] } || $ENV{GITHUB_USER} || 'avar';

    my $cpan_id = try { $zilla->stash_named('%PAUSE')->username };

    my $authority   = $args->{authority} // ($cpan_id ? "cpan:$cpan_id" : 'cpan:AVAR');
    my $no_Authority = $args->{no_Authority} // 1;
    my $no_a_pre    = $args->{no_AutoPrereq} // 0;
    my $use_mm      = $args->{use_MakeMaker} // 1;
    my $use_ct      = $args->{use_CompileTests} // $args->{use_TestCompile} // 1;
    my $bugtracker  = $args->{bugtracker}  // 'rt';
    my $homepage    = $args->{homepage};
    warn "AVAR: Upgrade to new format" if $args->{repository};
    my $repository_url  = $args->{repository_url};
    my $repository_web  = $args->{repository_web};
    my $nextrelease_format = $args->{nextrelease_format} // '%-2v %{yyyy-MM-dd HH:mm:ss}d',
    my $tag_message = $args->{git_tag_message};
    my $version_regexp = $args->{git_version_regexp};

    my $install_command = $args->{install_command};

    my ($tracker, $tracker_mailto);
    my $page;
    my ($repo_url, $repo_web);

    if ($bugtracker eq 'github') {
        $tracker = "http://github.com/$github_user/$ldist/issues";
    } elsif ($bugtracker eq 'rt') {
        $tracker = "https://rt.cpan.org/Public/Dist/Display.html?Name=$dist";
        $tracker_mailto = sprintf 'bug-%s@rt.cpan.org', $dist;
    } else {
        $tracker = $bugtracker;
    }


    unless ($repository_url) {
        $repo_web = "http://github.com/$github_user/$ldist";
        $repo_url = "git://github.com/$github_user/$ldist.git";
    } else {
        $repo_web = $repository_web;
        $repo_url = $repository_url;
    }

    unless (defined $homepage) {
        $page = "http://metacpan.org/release/$dist";
    } else {
        $page = $homepage;
    }

    my @plugins = Dist::Zilla::PluginBundle::Filter->bundle_config({
        name    => $section->{name} . '/@Classic',
        payload => {
            bundle => '@Classic',
            remove => [
                # Don't add a =head1 VERSION
                'PodVersion',
                # This will inevitably whine about completely reasonable stuff
                'PodCoverageTests',
                # Use my MakeMaker
                'MakeMaker',
                # Use the use_begin argument to PkgVersion
                'PkgVersion',
            ],
        },
    });

    my $prefix = 'Dist::Zilla::Plugin::';
    my @extra = map {[ "$section->{name}/$_->[0]" => "$prefix$_->[0]" => $_->[1] ]}
    (
        [
            'PkgVersion' => {
                use_begin => 1,
            },
        ],
        [
            'Git::NextVersion' => {
                first_version => '0.01',
                ($version_regexp
                ? (version_regexp => $version_regexp)
                : (version_regexp => '^(\d.*)$')),
            }
        ],
        ($no_a_pre
         ? ()
         : ([ AutoPrereqs  => { } ])),
        [ MetaJSON     => { } ],
        [
            MetaNoIndex => {
                # Ignore these if they're there
                directory => [ map { -d $_ ? $_ : () } qw( inc t xt utils example examples ) ],
            }
        ],
        # Produce README from lib/
        [ ReadmeFromPod => {} ],
        [
            MetaResources => {
                homepage => $page,
                'bugtracker.web' => $tracker,
                'bugtracker.mailto' => $tracker_mailto,
                'repository.type' => 'git',
                'repository.url' => $repo_url,
                'repository.web' => $repo_web,
                license => 'http://dev.perl.org/licenses/',
            }

        ],
        ($no_Authority
         ? ()
         : (
             [
                 Authority => {
                     authority   => $authority,
                     do_metadata => 1,
                 }
             ]
          )
        ),
        # Bump the Changlog
        [
            NextRelease => {
                format => $nextrelease_format,
            }
        ],
        # install a copy for ourselves when releasing
        ($install_command ? ([
            InstallRelease => {
                install_command => $install_command,
            }
        ]) : ()),

        # Maybe use MakeMaker, maybe not
        ($use_mm
         ? ([ MakeMaker  => { } ])
         : ()),

        # Maybe CompileTests
        ($use_ct
         ? ([ 'Test::Compile'  => { } ])
         : ()),
    );
    push @plugins, @extra;

    push @plugins, Dist::Zilla::PluginBundle::Git->bundle_config({
        name    => "$section->{name}/\@Git",
        payload => {
            tag_format => '%v',
            ($tag_message
             ? (tag_message => $tag_message)
             : ()),
        },
    });

    # remove empty entries, Config::MVP crashes on them

    foreach my $p (@plugins) {
        my ($name, $package, $payload) = @$p;

        while (my ($k, $v) = each %$payload) {
            if (!$v || (ref $v eq 'ARRAY' && !@$v) || (ref $v eq 'HASH' && !%$v)) {
                delete $payload->{$k};
            }
        }
    }

    return @plugins;
}

sub _get_zilla {
    no warnings 'redefine';
    # avoid recursive loop
    local *Dist::Zilla::PluginBundle::AVAR::bundle_config = sub { };

    my $chrome = Dist::Zilla::Chrome::Term->new;

    # this sucks
    local *Dist::Zilla::App::chrome = sub { $chrome };

    return Dist::Zilla::Dist::Builder->from_config({
        dist_root => '.',
        chrome    => $chrome,
        _global_stashes => Dist::Zilla::App->new->_build_global_stashes,
    });
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Dist::Zilla::PluginBundle::AVAR - Use L<Dist::Zilla> like AVAR does

=head1 DESCRIPTION

This is the plugin bundle that AVAR uses. Use it as:

    [@AVAR]
    ;; same as `name' earlier in the dist.ini (optional, detected from $dzil->name)
    dist = MyDist
    ;; If you're not avar (will be read from "git config github.user" or $ENV{GITHUB_USER} by default)
    github_user = imposter
    ;; Bugtracker github or rt, default is rt
    bugtracker = rt
    ;; custom homepage/repository, defaults to metacpan page and github repository lc($dist->name)
    homepage = http://example.com
    repository = http://git.example.com/repo.git
    ;; use various stuff or not
    no_AutoPrereq = 1 ; evil for this module
    use_MakeMaker = 0 ; If using e.g. MakeMaker::Awesome instead
    use_TestCompile = 0 ; I have my own compile tests here..
    ;; cpan:YOUR_CPAN_ID is the default authority, read from "dzil setup" entry for PAUSE
    ; authority = cpan:AVAR
    no_Authority = 0 ; If want to use the authority module (previously the default)
    ;; if you want to install your dist after release (set $ENV{PERL_CPANM_OPTS} if you need --sudo or --mirror etc.)
    ;; default is OFF
    install_command = cpanm .

It's equivalent to:

    [@Filter]
    bundle = @Classic
    remove = PodVersion
    remove = PodCoverageTests
    
    [Git::NextVersion]
    [AutoPrereqs]
    [MetaJSON]

    [MetaNoIndex]
    ;; Only added if these directories exist
    directory = inc
    directory = t
    directory = xt
    directory = utils
    directory = example
    directory = examples
    
    [ReadmeFromPod]

    [MetaResources]
    ;; $github_user is 'avar' by default, $lc_dist is lc($dist)
    homepage   = http://search.cpan.org/dist/$dist/
    bugtracker.mailto = bug-$dist@rt.cpan.org
    bugtracker.web = https://rt.cpan.org/Public/Dist/Display.html?Name=$dist
    repository.web = http://github.com/$github_user/$lc_dist
    repository.url = git://github.com/$github_user/$lc_dist.git
    repository.type = git
    license    = http://dev.perl.org/licenses/

    [Authority]
    authority   = cpan:AVAR
    do_metadata = 1
    
    [NextRelease]
    format = %-2v %{yyyy-MM-dd HH:mm:ss}d
    
    [@Git]
    tag_format = %v
    version_regexp = '^(\d.*)$'
    first_version = '0.01'

    [InstallRelease]
    install_command = cpanm .

If you'd like a minting profile (to create new modules with all the
boilerplate) for this PluginBundle, check out:
L<Dist::Zilla::MintingProfile::Author::Caelum>.

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla>

=item * L<Dist::Zilla::PluginBundle::Git>

=item * L<Dist::Zilla::MintingProfile::Author::Caelum>

=back

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2023 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
    
=cut
