use 5.014;  # because we use the 'non-destructive substitution' feature (s///r)
use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::TABULO; # git description: v0.197-45-g838f7b1
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: A plugin bundle for distributions built by TABULO
# BASED_ON: Dist::Zilla::PluginBundle::Author::ETHER
# KEYWORDS: author bundle distribution tool

our $VERSION = '0.198';
# AUTHORITY

use Data::Printer;                          # For DEBUG. TODO: Comment this out for a normal release.
use Scalar::Util                            qw(refaddr reftype);
use Scalar::Does                              -constants, does => { -as => 'it_does' };
use List::Util 1.45                         qw(first all any none pairs pairgrep unpairs uniq);
use List::MoreUtils                         qw(arrayify);
use Hash::MoreUtils                         qw(slice_grep);



use Dist::Zilla::PluginBundle::Author::TABULO::Config qw(configuration detect_settings);
use Dist::Zilla::Util;
use Module::Runtime qw(require_module use_module);
use Devel::CheckBin 'can_run';
use Path::Tiny;
use CPAN::Meta::Requirements;
use Term::ANSIColor 'colored';
eval { +require Win32::Console::ANSI } if $^O eq 'MSWin32';
use Config;


# multivalue aliases. name =>  [ @aliases ]
our %PINFO = (
  commit_files_from_release   => { multivalue =>1, aka => 'commit_file_from_release',   },
  copy_files_from_release     => { multivalue =>1, aka => 'copy_file_from_release',     },
  installers                  => { multivalue =>1, aka => 'installer',                  },
  never_gather                => { multivalue =>1, aka => 'do_not_gather',              },
  spellcheck_dirs             => { multivalue =>1, aka => 'spellcheck_dir',             },
  stopwords                   => { multivalue =>1, aka => 'stopword',                   },
);

use vars (
  '%PINFO',         # Will be looked up by mhs_dictionnary() -- which is a general purpose 'has-munger'
  '%PROPS',         # Will be populated by mhs_dictionnary() -- which is a general purpose 'has-munger'
  '%mungers',
);


use Banal::Util::Mini           qw( hash_access   inverse_dict  maybe_kv  peek
                                    tidy_arrayify sanitize_env_var_name   suffixed );
use Banal::Dist::Util::Pause    qw(pause_config);
use Banal::Moosy::Mungers       qw(mhs_dictionary mhs_lazy_ro  mhs_fallbacks);
BEGIN {
  %mungers = (
    haz       => [  sub {; mhs_lazy_ro() }             ],
    haz_bool  => [  sub {; mhs_lazy_ro(isa=>'Bool') }  ],
    haz_int   => [  sub {; mhs_lazy_ro(isa=>'Int') }   ],
    haz_str   => [  sub {; mhs_lazy_ro(isa=>'Str') }   ],
    haz_strs  => [  sub {; mhs_lazy_ro(isa=>'ArrayRef[Str]', traits=>['Array'] ) }  ],
    haz_hash  => [  sub {; mhs_lazy_ro(isa=>'HashRef',       traits=>['Hash']  ) }  ],
  );
  push @{$mungers{$_}},(
                          sub {; mhs_dictionary( src=> \%PINFO) },
                          sub {; mhs_fallbacks()                  },
#                          sub {; mhs_dictionary( dest=>\%PROPS)   },
                        )  for (sort keys %mungers)
}



# satisfy requirements by the consumed banal role : ..::Role::PluginBundle::Easier
sub _extra_args;
sub payload;

#use Types::Standard;
#use Type::Utils qw(enum subtype where class_type);
use Moose::Util::TypeConstraints qw(enum subtype where class_type);
use Moose;
use MooseX::MungeHas { %mungers };
with  ( 'Banal::Dist::Zilla::Role::PluginBundle::Easier',
        'Banal::Role::Fallback::Moo',
);
use namespace::autoclean;

# Forward subroutine declarations (as needed)
sub _msg;


# plural values (array-ref) expected
sub kvh_promote_mv(@) {
  my $fields = ref ($_[0]) eq 'ARRAY' ? shift : [];

  map {;
    my  ($k, $v)  = ($_->key, $_->value);   # 'pairs' come handy
    local %_ = (ref($v) eq 'HASH') ? (%$v) : ();
    my  @nv = tidy_arrayify( @_{@$fields} );  # We flatten a hash slice that gathers any existing values from any of the given fields
    ($k => [@nv] )
  } pairs @_
}

# Scalar values expected
sub kvh_promote(@) {
  my $fields = ref ($_[0]) eq 'ARRAY' ? shift : [];

  map {;
    my  ($k, $v)  = ($_->key, $_->value);   # 'pairs' come handy
    local %_ = (ref($v) eq 'HASH') ? (%$v) : ();
    my $nv = first { defined } @_{@$fields};
    ($_->key, $nv)
  } pairs @_
}


sub map_name_to_aliases(@) {
  kvh_promote_mv( [qw(aka alias aliases) ], @_ )
}

# multivalue aliases. name =>  [ @aliases ]
our %AKA        =  map_name_to_aliases (%PINFO);
our %AKA_MV     =  map_name_to_aliases slice_grep { $_{$_}->{multivalue} // 0 } (\%PINFO) ;
our %MV_ALIASES =  inverse_dict(%AKA);


# multivalue aliases
# our %MV_ALIASES = (
#   commit_file_from_release  => 'commit_files_from_release',
#   copy_file_from_release    => 'copy_files_from_release',
#   installer                 => 'installers',
#   do_not_gather             => 'never_gather',
#   spellcheck_dir            => 'spellcheck_dirs',
#   stopword                  => 'stopwords',
# );

# TABULO :
# DZIL wants us to declare multi-value INI parameters like below
# We declare both singular and plural forms for the same things to reduce hassle.
sub mvp_multivalue_args {
  map {;
    ($_, $_.'_implicit')
  } (%MV_ALIASES);
}


# our %MV_IMPLICIT  = map {; ($_->key . '_implicit' => $_->value . '_implicit' ) }
sub mvp_aliases         { +{ %MV_ALIASES } }


# plugins that use the network when they run
sub _network_plugins
{
    qw(
        PromptIfStale
        Test::Pod::LinkCheck
        Test::Pod::No404s
        Git::Remote::Check
        CheckPrereqsIndexed
        CheckIssues
        UploadToCPAN
        Git::Push
    );
}

#
# NOTE: 'haz' is our shorthand form of 'has' created with the help of 'MooseX::MungeHas' and some of our own craft.
#
# It reduces a lot of the noise, which also means you may immediately notice what is going on.

# The specific munger function we are using here 'mhs_lazy_ro_with_fallbacks' implies :
#   (is=>ro, lazy=1, initargs=>undef)
#
# Also, it will automatically create a 'default' subroutine  that will invoke the 'fallback' method (defined below for this class).
# In this particular case, our 'fallback' method will make use of Config settings, which supports author-specific default values,
# and falling back to global defaults if necessary. It also supports the notions of :
#   - a preffered default ('apriori' parameter), which will be tried before going into the fallbak mechanism described above.
#   - an ultimate default ('def' parameter), which will be used if the Config fallback mechanism could not find an applicable default setting.
#
# When present, the 'apriori/mid/def' parameters should be one of:
#   - a SCALAR value
#   _ a subroutine reference (which will be invoked to use its return value)
#   - An reference to an array
#
# Also, the fallback method also supports specifying a set of aliases (via 'aka' or 'alias' parameters)
#


haz_bool    airplane                      =>( def => 0,     );
haz_bool    fake_release                  =>( apriori => sub { $ENV{FAKE_RELEASE} }, def => 0, );
haz_bool    surgical_podweaver            =>( def => 0,     );
haz_bool    commit_copied                 =>( def => 1, );  # + by TABULO
haz_bool    verify_phases                 =>( def => 0, );  # + by TABULO
haz_bool    allow_insecure_operations     =>( def => 0, );  # + by TABULO
haz_bool    install_release_from_cpan     =>( def => 0, );  # + by TABULO


haz         server                        =>( def => 'github',  isa => enum([qw(github bitbucket gitmo p5sagit catagits none)]),);
haz_str     licence                       =>( def =>  sub { $_[0]->spelling eq 'GB'  ? 'LICENCE' : 'LICENSE' }, aka=>[qw( license) ], );
sub         license { shift->licence(@_) }
haz_str     max_target_perl               =>( def => '5.006',                     aka=>    'Test::MinimumVersion.max_target_perl',  );
haz_str     portability_options           =>( def => '',                          aka=>[qw( Portability.options   Test::Portability.options )],);
haz_str     spelling                      =>( def => 'US',  );     # + by TABULO
haz_str     static_install_mode           =>( def => 'no',                        aka =>   'StaticInstall.mode',  );
haz_str     weaver_config                 =>( def => sub { $_[0]->_bundle_ini_section_name }, );


# Changes file  handling
haz         nextrelease_entry_columns     =>( def => 10,        isa => subtype('Int', where { $_ > 0 && $_ < 20 }),
  aka=>[qw( changes_version_columns
)],);

haz_str     nextrelease_entry_time_zone  =>( def =>'UTC',
  aka=>[qw( changes_version_time_zone
            changes_version_timezone
            nextrelease_entry_timezone
            NextRelease.time_zone
)],);

haz_str     nextrelease_entry_format     =>(
  def=>sub {; '%-' . ($_[0]->nextrelease_entry_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T'     },
  aka=>[qw( changes_version_format
            NextRelease.format )], );

# $VERSION management
haz_bool    bump_version_global           =>( def => 1,
  aka=>[qw( BumpVersionAfterRelease.global
            BumpVersionAfterRelease::Transitional.global )],); # + by TABULO

haz_str     fallback_version_provider     =>( def => 'Git::NextVersion',
  aka=>    'RewriteVersion::Transitional.fallback_version_provider',  );

haz_bool    rewrite_version_global        =>( def => 1,
  aka=>[qw( RewriteVersion.global
            RewriteVersion::Transitional.global ) ],);  # + by TABULO

haz_str     version_regexp                =>( def => '^v([\d._]+)(-TRIAL)?$',
  aka=>[qw( RewriteVersion::Transitional.version_regexp
            Git::NextVersion.version_regexp )], );


# VCS options, added by TABULO [ 2018-01-16 ]
haz_str     tag_format                    => (  def => 'v%v',           aka => 'Git::Tag.tag_format',     );
haz_str     tag_message                   => (  def => 'v%v%t',         aka => 'Git::Tag.tag_message',    );
haz_str     release_snapshot_commit_msg   => (  def => '%N-%v%t%n%n%c', );

# Git information (normally detected automatically).  + by TABULO [ 2018-01-16 ]
haz_str     git_remote                    => ( def => 'origin',  );
haz_str     git_branch                    => ( def => 'master',  );
haz_str     git_remote_branch             => ( def => sub {;  shift->git_branch // 'master' }, );

# Boolean switches for VCS (git, etc) checks,. + by TABULO [ 2018-06-24 ]
haz_bool    check_vcs                     =>( );
haz_bool    check_vcs_more                =>( def => sub {;  $_[0]->check_vcs //  !($_[0]->fake_release // 0) },   );

# The below are UNDOCUMENTED for the moment:
haz_bool    check_vcs_clean               =>( def => sub {;  $_[0]->check_vcs // 1 },                              );
haz_bool    check_vcs_clean_initial       =>( def => sub {;  $_[0]->check_vcs_clean // 1 },                        );
haz_bool    check_vcs_clean_after_tests   =>( def => sub {;  $_[0]->check_vcs_clean // 1 },                        );

haz_bool    check_vcs_merge_conflicts     =>( def => sub {;  $_[0]->check_vcs_more // 1 },                         );
haz_bool    check_vcs_correct_branch      =>( def => sub {;  $_[0]->check_vcs_more // 1 },                         );
haz_bool    check_vcs_remote_branch       =>( def => sub {;  $_[0]->check_vcs_more // 1 },                         );

# NOTE: no support yet for depending on a specific version of an installer plugin --
# but [PromptIfStale] generally makes that unnecessary
haz_strs    commit_file_after_release     =>(
  sort      =>1,
  blankers  =>'none',
  def       => sub { [] },
  aka       => { commit_files_after_release => 'elements' },
);

haz_strs    copy_file_from_release        =>(
  sort      =>1,
  blankers  =>'none',
  def       => sub { [] },
  aka       => { copy_files_from_release => 'elements' },
);

haz_strs    do_not_gather                 =>(
  sort      =>1,
  blankers  =>'none',
  def       => sub { [] },
  aka       => { never_gather => 'elements' },
);  # + by TABULO

haz_strs    installer                     =>(
  blankers  =>'none',
  def       => sub { [] },
  aka       => { installers => 'elements' },
);

#sub         spellcheck_dir                    { $_[0]->spellcheck_dirs }
haz_strs    spellcheck_dirs                 =>( def => sub { [ qw(bin examples lib script t xt) ] },
                                                sort=>1, blankers=>'none',
  aka =>   'spellcheck_dir',
);


#sub         stopword                          { $_[0]->stopwords }
haz_strs    stopwords                       =>( def => sub { [qw(irc)] },
                                                sort=>1, blankers=>'none',
  aka =>   'stopword',
); # + by TABULO


around commit_files_after_release => sub {
    my $orig    = shift; my $self = shift;
    my $cpfr    = $self->copy_files_from_release;
    my @extras  = arrayify ($self->commit_copied ? $cpfr : [] );
    my $oresult = $self->$orig(@_);

    [ sort(uniq((grep { defined $_} arrayify( $oresult, @extras)))) ];
};


# Note: no support yet for depending on a specific version of the plugin --
# but [PromptIfStale] generally makes that unnecessary
haz_bool  _keen_on_static_install             =>( def => 0,             aka => 'keen_on_static_install',  );
haz_hash  _extra_args                         =>( def => sub { +{} },   aka => 'extra_args',              );


# The following attributes are NOT allowed to have AUTHOR SPECIFIC fallbacks
# 'author_specific => 0' allows us to avoid an infinte loop...
#   -- because the usual fallbacks include known_author_prefs which depend on 'authority' ...
haz_str   authority                           =>( def => 'cpan:TABULO', author_specific => 0, aka => 'Authority.authority', );
haz_bool  _no_author_specific_prefs           =>( def => 0,             author_specific => 0, aka => 'no_author_specific_preferences',);
haz_hash  _known_authors                      =>( def => sub { +{} },   author_specific => 0, aka => 'known_authors',        );


# The following attributes are NOT allowed to have FALLBACKS at all (because they provide the basis for the fallback mechanism)
haz_hash  _defaults                           =>( default => sub {  shift->_config('defaults') // {}  },                  );
haz_hash  _settings_detected                  =>( default => sub { +{ detect_settings(plugin_bundle => shift) } },        );
haz_hash  _settings                           =>( default => sub { shift->_config() //  +{} },  );
haz_hash  _author_specific_prefs              => (
  default => sub {
    my  $o = $_[0];
    ( $o->_no_author_specific_prefs ? +{} : hash_access( $o->_known_authors, $o->authority, 'prefs') ) // {}
  },
);

# The following attributes currently BYPASS the implicit FALLBACK mechanism (for lack of a simple way)
# haz_bool static_install_dry_run => (
#   default => sub {
#     my  $self = shift;
#     # only set x_static_install using auto mode for distributions where the authority is known to be 'keen on' static install (e.g. ETHER)
#     # (for all other distributions, set explicitly to on or off)
#     # Note that this is just the default; if a dist.ini changed these values, ConfigSlicer will apply it later
#     my $mode  = $self->static_install_mode;
#     my $keen  = $self->_keen_on_static_install // 0;
#     my  $r    = $self->_resolve( 'StaticInstall.dry_run', 'static_install_dry_run' );
#         $r    = undef    if (defined $r) && ($r eq '');
#         $r  //= (defined $mode) && ($mode eq 'auto') ? !$keen : undef;
#         $r  //= 0;
#     return $r;
#     },
# );

# The following attributes currently BYPASS the implicit FALLBACK mechanism (for lack of a simple way)
haz_bool static_install_dry_run => (
  def => sub {
    my  $self = shift;
    # only set x_static_install using auto mode for distributions where the authority is known to be 'keen on' static install (e.g. ETHER)
    # (for all other distributions, set explicitly to on or off)
    # Note that this is just the default; if a dist.ini changed these values, ConfigSlicer will apply it later
    !($self->_keen_on_static_install // 0);
    },
);


around static_install_dry_run => sub {
  my ($orig, $self) = (shift, shift);
  my $mode  = $self->static_install_mode // '';
  my $r     = $self->$orig(@_);
  $r        = ($mode eq 'auto') ? $r : 0;
  $r      //= 0;
};



# "PROTECTED" METHODS (OK to use/override in inherited classes)
sub _bundle_ini_section_name { $_[0]->_config('bundle', 'ini_section_name')  }
sub _pause_config { shift; pause_config(@_) } # return username, password from ~/.pause
sub _config { shift; configuration( @_) }       # Retrieve a setting, to ease sub-classing and such.

# Below are computed directly from settings and also possibly depend on state.
#   $detected : we try to auto-detect some defaults from the environment or the context
#   such as the repository 'server'
sub _fallback_settings  { # required by C<Banal::Role::Fallbacks>
    my $self  = shift;
    my %opt = %{ (ref($_[0]) eq 'HASH') ? shift : +{} };
       %opt = (%opt, @_);
    my (%res, @src);

    # %ENV hash wins over all of the others, unless we are asked not to include it in the bunch.
    unless ( $opt{'no_env'} ) {
      my $pfx   = $opt{env_key_prefix} // 'DZIL_';
      $res{source_opts}{refaddr \%ENV}{map_keys}  ||=  sub { map {; sanitize_env_var_name($pfx  . uc $_)  } @_ };
      push @src, \%ENV;
    }

    # Then comes the rest of them... Some of them (like payload) make sense only for OBJECT invocation, while others
    # may also make sense in a CLASS invocation context.
    push @src, $self->payload()                 if $opt{payload} && ref $self;
    push @src, $self->_author_specific_prefs()  if $opt{author_specific}; # depends on state.
    push @src, $self->_defaults                 if $opt{defaults} // $opt{generic};
    push @src, $self->_settings_detected()      if $opt{detected} // $opt{generic};
    push @src, $self->_settings()               if $opt{settings} // $opt{generic};

    $res{sources} = [ grep { defined } arrayify( @src ) ];

    return wantarray ? (%res) : \%res;
}



sub BUILD
{
    my $self = shift;

    # say STDERR 'Here is my humble self : ' . np $self;

    if ($self->airplane)
    {
        warn _msg ( colored('building in airplane mode - plugins requiring the network are skipped, and releases are not permitted', 'yellow'));
        # doing this before running configure means we can be sure we update the removal list before
        # our _removed_plugins attribute is built.
        push @{ $self->payload->{ $self->plugin_remover_attribute } }, $self->_network_plugins;
    }
}



sub check
{
    my $self = shift;
    my @installers = tidy_arrayify( $self->installers );

    warn _msg 'no "bash" executable found; skipping Run::AfterBuild command to update .ackrc'
        if not $INC{'Test/More.pm'} and not $self->_detected_bash;

    # NOTE! since the working directory has not changed to $zilla->root yet,
    # if running this code via a different mechanism than dzil <command>, file
    # operations may be looking at the wrong directory! Take this into
    # consideration when running tests!

    my $has_xs = $self->_detected_xs;
    warn _msg 'XS-based distribution detected.' if $has_xs;
    die  _msg 'no Makefile.PL found in the repository root: this is not very nice for contributors!'
        if $has_xs and not -e 'Makefile.PL';

    # check for a bin/ that should probably be renamed to script/
    warn _msg colored('bin/ detected - should this be moved to script/, so its contents can be installed into $PATH?', 'bright_red')
        if -d 'bin' and grep { $_ eq 'ModuleBuildTiny' } $self->installers;

    warn _msg colored('You are using [ModuleBuild] as an installer, WTF?!', 'bright_red')
        if any { $_->isa('Dist::Zilla::Plugin::ModuleBuild') }
            map { Dist::Zilla::Util->expand_config_package_name($_) } @installers;

    # this is better than injecting a perl prereq for 5.008, to allow MBT to
    # become more 5.006-compatible in the future without forcing the distribution to be re-released.
    die _msg 'Module::Build::Tiny should not be used in distributions that are targeting perl 5.006!'
        if  any { /ModuleBuildTiny/ } @installers and ($self->max_target_perl // 0) < '5.008';

    warn _msg colored('.git is missing and META.json is present -- this looks like a CPAN download rather than a git repository. You should probably run '
            . (-f 'Build.PL' ? 'perl Build.PL; ./Build' : 'perl Makefile.PL; make') . ' instead of using dzil commands!', 'yellow')
        if not -d '.git' and -f 'META.json' and not $self->_plugin_removed('Git::GatherDir');

    my $server = $self->server // '';
    warn _msg colored(
      "server = '$server': recommend instead using server = github and GithubMeta.remote = '$server' with a read-only mirror", 'yellow')
        if $server ne 'github' and $server ne 'none';

    return $self;
}

sub configure
{
    my  $self = shift->check(@_);

    # some local variables for handier and faster access.
    my  $server                   = $self->server // '';
    my  $examples_finder_name     = $self->_bundle_ini_section_name . '/Examples';
    my  $licence                  = $self->license;
    my  $surgical                 = $self->surgical_podweaver;

    my  @copy_files_from_release  = tidy_arrayify ( $self->copy_files_from_release );
    my  @installers               = tidy_arrayify ( $self->installers );
    my  @never_gather             = tidy_arrayify ( $self->never_gather );
    my  @stopwords                = tidy_arrayify ( $self->stopwords );

    my  $static_install_mode      = $self->static_install_mode    // '';
    my  $static_install_dry_run   = $self->static_install_dry_run // 0;
    my  $v; # used in various places below in order to hold temporary values.

    my  $d; # $d is for DEBUGGING
    my  @d;

    # say STDERR 'Here is my humble self AGAIN (during configure) : ' . np $self;
    # say STDERR 'Stopwords are   : '   . np @stopwords;
    # say STDERR 'Installers are  : '  . np @installers;
    # say STDERR 'Server is       : '  . "'$server'";

    my @plugins = (

        # TAU : Just in case the name is not set in 'dist.ini'
        'NameFromDirectory',

        # VersionProvider
        # see [@Git::VersionManager]

        # BeforeBuild
        # [ 'EnsurePrereqsInstalled' ], # FIXME: use options to make this less annoying!
        [ 'PromptIfStale' => 'stale modules, build' => { phase => 'build', module => [ $self->meta->name ] } ],
        [ 'PromptIfStale' => 'stale modules, release' => { phase => 'release', check_all_plugins => 1, check_all_prereqs => 1 } ],

        # ExecFiles
        (-d ($self->payload->{'ExecDir.dir'} // 'script') || any { /^ExecDir\./ } keys %{ $self->payload })
            ? [ 'ExecDir'       => { dir => 'script' } ] : (),

        # Finders
        [ 'FileFinder::ByName'  => Examples => { dir => 'examples' } ],

        # Gather Files

        [ 'Git::GatherDir'      => { ':version' => '2.016',
                                      include_dotfiles => $self->_resolve(qw( Git::GatherDir.include_dot_files include_dot_files) ) // 1 ,
                                      @never_gather ? ( exclude_filename => \@never_gather) : ()
                                    } ],

        qw(MetaYAML MetaJSON Readme Manifest),
        [ 'License'             => { ':version' => '5.038', filename => $self->licence } ],
        [ 'GenerateFile::FromShareDir' => 'generate CONTRIBUTING' => { -dist => $self->_config('bundle', 'dist_name'), -filename => 'CONTRIBUTING', has_xs => $self->_detected_xs } ],
        [ 'InstallGuide'        => { ':version' => '1.200005' } ],

        [ 'Test::Compile'       => { ':version' => '2.039', bail_out_on_fail => 1, xt_mode => 1,
            script_finder => [qw(:PerlExecFiles ), $examples_finder_name   ] } ],
        [ 'Test::NoTabs'        => { ':version' => '0.08', finder => [qw(:InstallModules :ExecFiles), $examples_finder_name, qw(:TestFiles :ExtraTestFiles)] } ],
        [ 'Test::EOL'           => { ':version' => '0.17', finder => [qw(:InstallModules :ExecFiles), $examples_finder_name, qw(:TestFiles :ExtraTestFiles)] } ],
        'MetaTests',
        [ 'Test::CPAN::Changes' => { ':version' => '0.012' } ],
        'Test::ChangesHasContent',
        [ 'Test::MinimumVersion' => { ':version' => '2.000003', maybe_kv(max_target_perl => $self->max_target_perl) } ], # ETHER had 5.006
        [ 'PodSyntaxTests'      => { ':version' => '5.040' } ],
        [ 'PodCoverageTests'    => { ':version' => '5.040' } ],
        [ 'Test::PodSpelling'   => { ':version' => '2.006003',
                                     ( @stopwords ? ( stopwords => [ @stopwords ] ) : () ),
                                     directories => [qw(bin examples lib script t xt)] }
        ],

        #[Test::Pod::LinkCheck]     many outstanding bugs
        ($ENV{CONTINUOUS_INTEGRATION} ? () : [ 'Test::Pod::No404s' => { ':version' => '1.003' } ] ),
        [ 'Test::Kwalitee'      => { ':version' => '2.10', filename => 'xt/author/kwalitee.t' } ],
        [ 'MojibakeTests'       => { ':version' => '0.8' } ],
        [ 'Test::ReportPrereqs' => { ':version' => '0.022', verify_prereqs => 1,
            version_extractor => ( ( any { $_ ne 'MakeMaker' } @installers) ? 'Module::Metadata' : 'ExtUtils::MakeMaker' ),
            include => [ sort ( qw(autodie JSON::PP Sub::Name YAML), $self->_plugin_removed('PodCoverageTests') ? () : 'Pod::Coverage' ) ] } ],

        [ 'Test::Portability'   =>  { ':version' => '2.000007',
                                      # options => 'test_dos_length = 0, test_one_dot = 0',
                                      ( ($v = ($self->portability_options // ''))
                                         ? (options => $v)
                                         : ()
                                      )
                                    }],
        [ 'Test::CleanNamespaces' => { ':version' => '0.006' } ],


        # Munge Files
        [ 'Git::Describe'       => { ':version' => '0.004', on_package_line => 1 } ],
        [   # Weave POD ( possibly in a 'surgical' fashion)
            ($surgical ? 'SurgicalPodWeaver' : 'PodWeaver') => {
                $surgical ? () : ( ':version' => '4.005' ),
                -f 'weaver.ini' ? () : ( config_plugin => $self->weaver_config ),
                replacer => $self->_resolve(      ( $surgical ? qw( SurgicalPodWeaver.replacer ) : () ),
                                                qw( PodWeaver.replacer ), # checked in any case.
                                            ) // 'replace_with_comment',
                post_code_replacer => $self->_resolve(      ( $surgical ? qw( SurgicalPodWeaver.post_code_replacer ) : () ),
                                                qw( PodWeaver.post_code_replacer ), # checked in any case.
                                            ) // 'replace_with_nothing',
            }
        ],

        # Metadata
        ( $server =~ /^github$/i )  ? [ 'GithubMeta' => { ':version' => '0.54', homepage => 0, issues => 0 } ] : (),
        [ 'AutoMetaResources'   => { 'bugtracker.rt' => 1,
              ( $server !~ /^(github|custom|none)$/i )
            ? ( "repository.${server}" => ( $self->_resolve("server_amr_opts_${server}") // 1 ) )
            : ()
        } ],

        [ 'Authority'           => { ':version' => '1.009',
                                      authority => $self->authority,
                                      do_munging => ( $self->_resolve('Authority.do_munging') // 0 ),
                                      locate_comment => ( $self->_resolve('Authority.locate_comment') // 0 ),
                                    }
        ],
        [ 'MetaNoIndex'         =>  { directory =>  [ uniq ( qw(t xt), grep { -d } @{ $self->_resolve_mv('MetaNoIndex.directory') } ) ],
                                    },
        ],
        [ 'MetaProvides::Package' => { ':version' => '1.15000002', finder => ':InstallModules', meta_noindex => 1, inherit_version => 0, inherit_missing => 0 } ],
        'MetaConfig',
        [ 'Keywords'            => { ':version' => '0.004' } ],
        ($Config{default_inc_excludes_dot} ? [ 'UseUnsafeInc' => { dot_in_INC => 0 } ] : ()),
        # [Git::Contributors]
        # [StaticInstall]

        # Register Prereqs
        # (MakeMaker or other installer)
        [ 'AutoPrereqs'         => { ':version' => '5.038' } ],
        [ 'Prereqs::AuthorDeps' => { ':version' => '0.006', relation => 'suggests' } ],
        [ 'MinimumPerl'         => { ':version' => '1.006', configure_finder => ':NoFiles' } ],
        [ 'Prereqs' => pluginbundle_version => {
                '-phase' => 'develop', '-relationship' => 'recommends',
                $self->meta->name => $self->VERSION,
            } ],
        ($self->surgical_podweaver ? [ 'Prereqs' => pod_weaving => {
                '-phase' => 'develop', '-relationship' => 'suggests',
                'Dist::Zilla::Plugin::SurgicalPodWeaver' => 0
            } ] : ()),

        # Install Tool (some are also Test Runners)
        @installers,   # options are set lower down, via %extra_args

        # we prefer this to run after other Register Prereqs plugins
        [ 'Git::Contributors'   => { ':version' => '0.029', order_by => 'commits' } ],

        # must appear after installers; also note that MBT::*'s static tweak is consequently adjusted, later
        [ 'StaticInstall'       => { ':version' => '0.005', mode => $static_install_mode, dry_run => $static_install_dry_run } ],

        # Test Runners (load after installers to avoid a rebuild)
        [ 'RunExtraTests'       => { ':version' => '0.024' } ],

        # After Build
        'CheckSelfDependency',

          # Update '.ackrc' (TAU: actually, no longer needed since ack v2.16, ... So it defaults to doing nothing)
        ( $self->_detected_bash &&  ( $self->_resolve('update_ackrc_after_build') // 0 ) && ( $v = $self->_resolve('update_ackrc.cmd') ) ?
            [ 'Run::AfterBuild' => '.ackrc' => { ':version' => '0.038', quiet => 1, run => $v, } ]
            : ()
        ),
          # Update the '.latest' link
        ( ( $self->_resolve('update_latest_links_after_build') // 1 ) && ( $v = $self->_resolve('update_latest_links.eval') ) ?
            [ 'Run::AfterBuild'     => '.latest' => { ':version' => '0.041', quiet => 1, fatal_errors => 0, eval => $v, } ]
            : ()
        ),


        # Before Release
        [ 'CheckStrictVersion'  =>  { decimal_only  => ( $self->_resolve('CheckStrictVersion.decimal_only') // 1 ),
                                      tuple_only    => ( $self->_resolve('CheckStrictVersion.tuple_only')   // 0 ),
                                    }
        ],
        'CheckMetaResources',
        'EnsureLatestPerl',

        # if in airplane mode, allow our uncommitted dist.ini edit which sets 'airplane = 1'


        ( $self->check_vcs_clean_initial ?
            [ 'Git::Check'          => 'initial check' => { allow_dirty => [ $self->airplane ? 'dist.ini' : '' ] } ]
            : ()),


        ( $self->check_vcs_merge_conflicts  ?
            'Git::CheckFor::MergeConflicts'
            : ()),

        ( $self->check_vcs_correct_branch ?
            [ 'Git::CheckFor::CorrectBranch' => { ':version' => '0.004', release_branch => $self->git_branch } ]
            : ()),

        ( $self->check_vcs_remote_branch ?
                [ 'Git::Remote::Check'  => { branch => $self->git_branch, remote_branch => $self->git_remote_branch } ]
                : ()),


        # [ 'Git::CheckFor::CorrectBranch' => { ':version' => '0.004', release_branch => $self->git_branch } ],
        # [ 'Git::Remote::Check'  => { branch => $self->git_branch, remote_branch => $self->git_remote_branch } ],
        [ 'CheckPrereqsIndexed' => { ':version' => '0.019' } ],

        'TestRelease',

        ( $self->check_vcs_clean_after_tests ?
            [ 'Git::Check'          => 'after tests' => { allow_dirty => [''] } ]
            : ()),

        'CheckIssues',
        # (ConfirmRelease)

        # Releaser
        $self->fake_release
            ? do { warn _msg colored('FAKE_RELEASE set - not uploading to CPAN', 'yellow'); 'FakeRelease' }
            : 'UploadToCPAN',

        # After Release
        ( ($v=$self->licence)  && -e "$v" ?
            [ 'Run::AfterRelease' => "remove old $v" => { ':version' => '0.038', quiet => 1, eval => qq!unlink '$v'! } ]
            : ()),

        ( -e 'README.md' ?
            [ 'Run::AfterRelease' => 'remove old READMEs' => { ':version' => '0.038', quiet => 1, eval => q!unlink 'README.md'! } ]
            : ()),

        ( @copy_files_from_release ?
            [ 'CopyFilesFromRelease' => 'copy generated files' => { filename => [ @copy_files_from_release ] } ]
            : ()),

        [ 'ReadmeAnyFromPod'    => { ':version' => '0.142180', type => 'pod', location => 'root', phase => 'release' } ],
    );

    # method modifier will also apply default configs, compile develop prereqs
    $self->add_plugins(@plugins);

    # plugins to do with calculating, munging, incrementing versions
    my $rwt = 'RewriteVersion::Transitional'; # Just to shorten some lines below
    $self->add_bundle('@Git::VersionManager' => {
        $self->rewrite_version_global     ? ( "${rwt}.global"  => $self->rewrite_version_global ) : (),
        $self->fallback_version_provider  ? ( "${rwt}.fallback_version_provider"  => $self->fallback_version_provider ) : (),
        $self->version_regexp             ? ( "${rwt}.version_regexp"  => $self->version_regexp ) : (),

        # for first Git::Commit
        commit_files_after_release => [ arrayify($self->commit_files_after_release) ],

        # because of [Git::Check], only files copied from the release would be added -- there is nothing else
        # hanging around in the current directory
        'release snapshot.add_files_in' => ['.'],
        $self->release_snapshot_commit_msg  ? ( 'release snapshot.commit_msg'  => $self->release_snapshot_commit_msg  ) : (),

        $self->tag_format  ? ( 'Git::Tag.tag_format'  => $self->tag_format  ) : (),
        $self->tag_message ? ( 'Git::Tag.tag_message' => $self->tag_message ) : (),

        # if the caller set bump_only_matching_versions, then this global setting falls on the floor automatically
        # because the bundle uses the non-Transitional plugin in that case.
        $self->bump_version_global ? ( 'BumpVersionAfterRelease::Transitional.global' => $self->bump_version_global ) : (),

        'NextRelease.:version' => '5.033',
        # 'NextRelease.time_zone' => 'UTC',
        # 'NextRelease.format' => '%-' . ($self->changes_version_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
        'NextRelease.time_zone' => $self->nextrelease_entry_time_zone(),
        'NextRelease.format'    => $self->nextrelease_entry_format(),
    });

    $self->add_plugins(
        'Git::Push',
        $self->server eq 'github' ? [ 'GitHub::Update' => { ':version' => '0.40', metacpan => 1 } ] : (),
    );

    if ($self->allow_insecure_operations && $self->install_release_from_cpan) {
      # TAU : This is protected by an expression checking 'allow_insecure_operations' because what folows is
      # potentially quite insecure, since it would expose the author's PAUSE credentials
      # directly on the request URL (which would travel in cleartext even under 'https').

      # install with an author-specific URL from PAUSE, so cpanm-reporter knows where to submit the report
      # hopefully the file is available at this location soonish after release!
      my %pause = $self->_pause_config();
      say STDERR "PAUSE Config : " . np %pause;

      my ($user, $password) = @pause{qw(user password)};
      $self->add_plugins(
          [ 'Run::AfterRelease'   => 'install release' => { ':version' => '0.031', fatal_errors => 0, run => 'cpanm http://' . $user . ':' . $password . '@pause.perl.org/pub/PAUSE/authors/id/' . substr($user, 0, 1).'/'.substr($user,0,2).'/'.$user.'/%a' } ],
      ) if $user and $password;
    }

    # halt release after pre-release checks, but before ConfirmRelease
    $self->add_plugins('BlockRelease') if $self->airplane;

    $self->add_plugins(
        [ 'Run::AfterRelease'   => 'release complete' => { ':version' => '0.038', quiet => 1, eval => [ qq{print "release complete!\\xa"} ] } ],
        # listed late, to allow all other plugins which do BeforeRelease checks to run first.
        'ConfirmRelease',
    );

    # if ModuleBuildTiny(::*) is being used, disable its static option if
    # [StaticInstall] is being run with mode=off or dry_run=1
    if (($static_install_mode eq 'off' or $static_install_dry_run)
        and any { /^ModuleBuildTiny/ } @installers)
    {
        my $mbt = Dist::Zilla::Util->expand_config_package_name('ModuleBuildTiny');
        my $mbt_spec = first { $_->[1] =~ /^$mbt/ } @{ $self->plugins };

        $mbt_spec->[-1]{static} = 'no';
    }

    # ensure that additional optional plugins are declared in prereqs
    my $plugin_name = 'prereqs for ' . $self->_bundle_ini_section_name;
    $self->add_plugins(
        [ 'Prereqs' => $plugin_name =>
        { '-phase' => 'develop', '-relationship' => 'suggests',
          %{ $self->_develop_suggests_as_string_hash } } ]
    );

    # listed last, to be sure we run at the very end of each phase
    $self->add_plugins(
        [ 'VerifyPhases' => 'PHASE VERIFICATION' => { ':version' => '0.016' } ]
    ) if $self->verify_phases;
}





# PRIVATE UTILITY FUNCTIONS

# Message text builder to be used in error output (warn, die, ...)
sub _msg {
  state $pfx = configuration('bundle', 'msg_pfx');
  join ('', $pfx, @_, "\n")
}




__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::TABULO - A plugin bundle for distributions built by TABULO

=head1 VERSION

version 0.198

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::TABULO]

=head1 DESCRIPTION

=for stopwords TABULO DAGOLDEN ETHER KENTNL
=for stopwords GitHub
=for stopwords optimizations repo

This is the plug-in bundle that TABULO uses for his distributions whose starting
point was ETHER's.

It exists mostly because TABULO is very lazy and wants others to be using what
he's using if they want to be doing work on his modules, just like KENTNL
and many others, I suppose...

But since TABULO is probably even lazier than most folks; instead of starting his
bundle from scratch, he just shopped around to find a bundle that had the most
overlap with his taste or whatever; and then just slurped the whole thing,
even including its documentation which is what you see here and in the
related modules.:-)

Admittedly, the fact that TABULO was so late in migrating to dzil worked to his
advantage for this particular task at least, since by that time
the bold and the brave had already made delicious stuff!

Thank you ETHER!

Thank you, too, KENTNL and DAGOLDEN, as your plugin-bundles also seem to be quite
good sources of inspiration!

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

And now comes the rest of the documentation slurped right in from ETHER's GitHub
repo ... :-)

=head2 DESCRIPTION (at last)

This L<Dist::Zilla> plugin bundle is I<very approximately> equal to the
following F<dist.ini> (following the preamble), minus some optimizations:

    ;;; BeforeBuild
    [PromptIfStale / stale modules, build]
    phase = build
    module = Dist::Zilla::Plugin::Author::TABULO
    [PromptIfStale / stale modules, release]
    phase = release
    check_all_plugins = 1
    check_all_prereqs = 1


    ;;; ExecFiles
    [ExecDir]
    dir = script    ; only if script dir exists


    ;;; Finders
    [FileFinder::ByName / Examples]
    dir = examples


    ;;; Gather Files
    [Git::GatherDir]
    :version = 2.016
    exclude_filename = CONTRIBUTING
    exclude_filename = INSTALL
    exclude_filename = LICENCE
    exclude_filename = LICENSE
    exclude_filename = META.json
    exclude_filename = Makefile.PL
    exclude_filename = README.md
    exclude_filename = README.pod
    exclude_filename = TODO
    exclude_filename = cpanfile
    exclude_filename = inc/ExtUtils/MakeMaker/Dist/Zilla/Develop.pm
    exclude_filename = ppport.h

    [MetaYAML]
    [MetaJSON]
    [Readme]
    [Manifest]
    [License]
    :version = 5.038
    filename = LICENCE  ; for distributions where I have authority

    [GenerateFile::FromShareDir / generate CONTRIBUTING]
    -dist = Dist-Zilla-PluginBundle-Author-TABULO
    -filename = CONTRIBUTING
    has_xs = <dynamically-determined flag>
    [InstallGuide]
    :version = 1.200005

    [Test::Compile]
    :version = 2.039
    bail_out_on_fail = 1
    xt_mode = 1
    script_finder = :PerlExecFiles
    script_finder = Examples

    [Test::NoTabs]
    :version = 0.08
    finder = :InstallModules
    finder = :ExecFiles
    finder = Examples
    finder = :TestFiles
    finder = :ExtraTestFiles

    [Test::EOL]
    :version = 0.17
    finder = :InstallModules
    finder = :ExecFiles
    finder = Examples
    finder = :TestFiles
    finder = :ExtraTestFiles

    [MetaTests]
    [Test::CPAN::Changes]
    :version = 0.012
    [Test::ChangesHasContent]
    [Test::MinimumVersion]
    :version = 2.000003
    max_target_perl = 5.006
    [PodSyntaxTests]
    :version = 5.040
    [PodCoverageTests]
    :version = 5.040
    [Test::PodSpelling]
    :version = 2.006003
    stopwords = irc
    directory = examples
    directory = lib
    directory = script
    directory = t
    directory = xt

    ;[Test::Pod::LinkCheck]     many outstanding bugs
    [Test::Pod::No404s]
    :version = 1.003
    [Test::Kwalitee]
    :version = 2.10
    filename = xt/author/kwalitee.t
    [MojibakeTests]
    :version = 0.8
    [Test::ReportPrereqs]
    :version = 0.022
    verify_prereqs = 1
    version_extractor = Module::Metadata
    include = JSON::PP
    include = Pod::Coverage
    include = Sub::Name
    include = YAML
    include = autodie
    [Test::Portability]
    :version = 2.000007
    [Test::CleanNamespaces]
    :version = 0.006


    ;;; Munge Files
    [Git::Describe]
    :version = 0.004
    on_package_line = 1

    [PodWeaver] (or [SurgicalPodWeaver])
    :version = 4.005
    config_plugin = @Author::TABULO ; unless weaver.ini is present
    replacer = replace_with_comment
    post_code_replacer = replace_with_nothing


    ;;; Metadata
    [GithubMeta]    ; (if server = 'github' or omitted)
    :version = 0.54
    homepage = 0
    issues = 0

    [AutoMetaResources]
    bugtracker.rt = 1
    ; (plus repository.* = 1 if server = 'gitmo' or 'p5sagit')

    [Authority]
    :version = 1.009
    authority = cpan:TABULO
    do_munging = 0

    [MetaNoIndex]
    directory = corpus
    directory = demo
    directory = examples
    directory = fatlib
    directory = inc
    directory = local
    directory = perl5
    directory = share
    directory = t
    directory = xt

    [MetaProvides::Package]
    :version = 1.15000002
    finder = :InstallModules
    meta_noindex = 1
    inherit_version = 0
    inherit_missing = 0

    [MetaConfig]
    [Keywords]
    :version = 0.004

    ; if we are releasing with a new perl with -DDEFAULT_INC_EXCLUDES_DOT set
    [UseUnsafeInc]
    dot_in_INC = 0

    ;[Git::Contributors]    ; below
    ;[StaticInstall]        ; below


    ;;; Register Prereqs
    [AutoPrereqs]
    :version = 5.038
    [Prereqs::AuthorDeps]
    relation = suggests
    [MinimumPerl]
    :version = 1.006
    configure_finder = :NoFiles

    [Prereqs / prereqs for @Author::TABULO]
    -phase = develop
    -relationship = suggests
    ...all the plugins this bundle uses...

    [Prereqs / pluginbundle_version]
    -phase = develop
    -relationship = recommends
    Dist::Zilla::PluginBundle::Author::TABULO = <current installed version>


    ;;; Install Tool
    ; <specified installer(s)>

    [Git::Contributors]
    :version = 0.029
    order_by = commits

    [StaticInstall]
    :version = 0.005
    mode = auto
    dry_run = 1  ; only if authority is not ETHER


    ;;; Test Runner
    ; <specified installer(s)>
    [RunExtraTests]
    :version = 0.024
    default_jobs = 9


    ;;; After Build
    [CheckSelfDependency]

    [Run::AfterBuild / .ackrc]
    :version = 0.038
    quiet = 1
    run = bash -c "test -e .ackrc && grep -q -- '--ignore-dir=.latest' .ackrc || echo '--ignore-dir=.latest' >> .ackrc; if [[ `dirname '%d'` != .build ]]; then test -e .ackrc && grep -q -- '--ignore-dir=%d' .ackrc || echo '--ignore-dir=%d' >> .ackrc; fi"
    [Run::AfterBuild / .latest]
    :version = 0.041
    quiet = 1
    fatal_errors = 0
    eval = if ('%d' =~ /^%n-[.[:xdigit:]]+$/) { unlink '.latest'; symlink '%d', '.latest'; }


    ;;; Before Release
    [CheckStrictVersion]
    decimal_only = 1

    [CheckMetaResources]
    [EnsureLatestPerl]

    [Git::Check / initial check]
    allow_dirty =

    [Git::CheckFor::MergeConflicts]

    [Git::CheckFor::CorrectBranch]
    :version = 0.004
    release_branch = master

    [Git::Remote::Check]
    branch = master
    remote_branch = master

    [CheckPrereqsIndexed]
    :version = 0.019
    [TestRelease]
    [Git::Check / after tests]
    allow_dirty =
    [CheckIssues]
    ;(ConfirmRelease)


    ;;; Releaser
    [UploadToCPAN]


    ;;; AfterRelease
    [Run::AfterRelease / remove old LICENCE]    ; if switching from LICENCE -> LICENSE
    :version = 0.038
    quiet = 1
    eval = unlink 'LICENCE'

    [Run::AfterRelease / remove old LICENSE]    ; if switching from LICENSE -> LICENCE
    :version = 0.038
    quiet = 1
    eval = unlink 'LICENSE'

    [Run::AfterRelease / remove old READMEs]
    :version = 0.038
    quiet = 1
    eval = unlink 'README.md'

    [CopyFilesFromRelease / copy generated files]
    filename = CONTRIBUTING
    filename = INSTALL
    filename = LICENCE
    filename = LICENSE
    filename = ppport.h

    [ReadmeAnyFromPod]
    :version = 0.142180
    type = pod
    location = root
    phase = release

    ;;;;;; begin [@Git::VersionManager]

    ; this is actually a VersionProvider and FileMunger
    [RewriteVersion::Transitional]
    :version = 0.004
    global = 1
    fallback_version_provider = Git::NextVersion
    version_regexp = ^v([\d._]+)(-TRIAL)?$

    [CopyFilesFromRelease / copy Changes]
    filename = Changes

    [Git::Commit / release snapshot]
    :version = 2.020
    add_files_in = .
    allow_dirty = CONTRIBUTING
    allow_dirty = Changes
    allow_dirty = INSTALL
    allow_dirty = LICENCE
    allow_dirty = LICENSE
    allow_dirty = README.md
    allow_dirty = README.pod
    allow_dirty = ppport.h
    commit_msg = %N-%v%t%n%n%c

    [Git::Tag]
    tag_message = v%v%t

    [BumpVersionAfterRelease::Transitional]
    :version = 0.004
    global = 1

    [NextRelease]
    :version = 5.033
    time_zone = UTC
    format = %-8v  %{yyyy-MM-dd HH:mm:ss'Z'}d%{ (TRIAL RELEASE)}T

    [Git::Commit / post-release commit]
    :version = 2.020
    allow_dirty = Changes
    allow_dirty_match = ^lib/.*\.pm$
    commit_msg = increment $VERSION after %v release

    ;;;;;; end [@Git::VersionManager]

    [Git::Push]

    [GitHub::Update]    ; (if server = 'github' or omitted)
    :version = 0.40
    metacpan = 1

    [Run::AfterRelease / install release]
    :version = 0.031
    fatal_errors = 0
    run = cpanm http://URMOM:mysekritpassword@pause.perl.org/pub/PAUSE/authors/id/U/UR/URMOM/%a

    [Run::AfterRelease / release complete]
    :version = 0.038
    quiet = 1
    eval = print "release complete!\xa"

    ; listed late, to allow all other plugins which do BeforeRelease checks to run first.
    [ConfirmRelease]

    ; listed last, to be sure we run at the very end of each phase
    ; only performed if $ENV{USER} matches /^tabulo$/
    [VerifyPhases / PHASE VERIFICATION]
    :version = 0.015

=for Pod::Coverage configure mvp_multivalue_args

=for stopwords metacpan

The distribution's code is assumed to be hosted at L<github|http://github.com>;
L<RT|http://rt.cpan.org> is used as the issue tracker.
The home page in the metadata points to L<github|http://github.com>,
while the home page on L<github|http://github.com> is updated on release to
point to L<metacpan|http://metacpan.org>.
The version and other metadata is derived directly from the local git repository.

=head1 OPTIONS / OVERRIDES

=head2 version

Use C<< V=<version> >> in the shell to override the version of the distribution being built;
otherwise the version is incremented after each release, in the F<*.pm> files.

=head2 pod coverage

Subroutines can be considered "covered" for pod coverage tests by adding a
directive to pod (as many as you'd like),
as described in L<Pod::Coverage::TrustPod>:

    =for Pod::Coverage foo bar baz

=head2 spelling stopwords

=for stopwords Stopwords foo bar baz

Stopwords for spelling tests can be added by adding a directive to pod (as
many as you'd like), as described in L<Pod::Spell/ADDING STOPWORDS>:

    =for stopwords foo bar baz

It is also possible to use the [%PodWeaver] stash in 'dist.ini' to add stopwords, like so :
    [%PodWeaver]
    -StopWords.include = foo bar baz

Such words will be recognized by the C<[StopWords]|Pod::Weaver::Plugin::StopWords> plugin for C<Pod::Weaver>,
which will gather them at the top of your POD (since we set its 'gather' parameter).

See also L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling/stopwords>.

=head2 installer

=for stopwords ModuleBuildTiny

Available since 0.007.

The installer back-end(s) to use (can be specified more than once); defaults
to L<C<ModuleBuildTiny::Fallback>|Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>
and L<C<MakeMaker::Fallback>|Dist::Zilla::Plugin::MakeMaker::Fallback>
(which generates a F<Build.PL> for normal use with no-configure-requires
protection, and F<Makefile.PL> as a fallback, containing an upgrade warning).
For toolchain-grade modules, you should only use F<Makefile.PL>-generating installers.

You can select other backends (by plugin name, without the C<[]>), with the
C<installer> option, or C<none> if you are supplying your own, as a separate
plugin(s).

Encouraged choices are:

=over 4

=item *

C<< installer = ModuleBuildTiny >>

=item *

C<< installer = MakeMaker >>

=item *

C<< installer = MakeMaker::Fallback >> (when used in combination with ModuleBuildTiny)

=item *

C<< installer = =inc::Foo >> (if no configs are needed for this plugin; e.g. subclassed from L<[MakeMaker::Awesome]|Dist::Zilla::Plugin::MakeMaker::Awesome>)

=item *

C<< installer = none >> (if you are providing your own elsewhere in the file, with configs)

=back

=head2 server

Available since 0.019.

If provided, must be one of:

=over 4

=item *

C<github>

(default)
metadata and release plugins are tailored to L<github|http://github.com>.

=item *

C<gitmo>

metadata and release plugins are tailored to
L<gitmo@git.moose.perl.org|http://git.moose.perl.org>.

=item *

C<p5sagit>

metadata and release plugins are tailored to
L<p5sagit@git.shadowcat.co.uk|http://git.shadowcat.co.uk>.

=item *

C<catagits>

metadata and release plugins are tailored to
L<catagits@git.shadowcat.co.uk|http://git.shadowcat.co.uk>.

=item *

C<none>

no special configuration of metadata (relating to repositories etc) is done --
you'll need to provide this yourself.

=back

=head2 airplane

Available since 0.053.

A boolean option that, when set, removes the use of all plugins that use the
network (generally for comparing metadata against PAUSE, and querying the
remote git server), as well as blocking the use of the C<release> command.
Defaults to false; can also be set with the environment variable C<DZIL_AIRPLANE>.

=head2 copy_file_from_release

Available in this form since 0.076.

A file, to be present in the build, which is copied back to the source
repository at release time and committed to git. Can be used more than
once. Defaults to:
F<LICENCE>, F<LICENSE>, F<CONTRIBUTING>, F<Changes>, F<ppport.h>, F<INSTALL>;
defaults are appended to, rather than overwritten.

=head2 surgical_podweaver

=for stopwords PodWeaver SurgicalPodWeaver

Available since 0.051.

A boolean option that, when set, uses
L<[SurgicalPodWeaver]|Dist::Zilla::Plugin::SurgicalPodWeaver> instead of
L<[PodWeaver]|Dist::Zilla::Plugin::SurgicalPodWeaver>, but with all the same
options. Defaults to false.

=head2 changes_version_columns

Available since 0.076.

An integer that specifies how many columns (right-padded with whitespace) are
allocated in F<Changes> entries to the version string. Defaults to 10 in general (and 12 for TABULO).

=head2 licence (or license)

Available since 0.101.

A string that specifies the name to use for the license file.  Defaults to
C<LICENCE> for distributions where ETHER or any other known authors who prefer
C<LICENCE> have first-come permissions, or C<LICENSE> otherwise.
(The pod section for legal information is also adjusted appropriately.)

=head2 authority

Available since 0.117.

A string of the form C<cpan:PAUSEID> that references the PAUSE ID of the user who has primary ("first-come")
authority over the distribution and main module namespace. If not provided, it is extracted from the configuration
passed through to the L<[Authority]|Dist::Zilla::Plugin::Authority> plugin, and finally defaults to C<cpan:TABULO>.
It is presently used for setting C<x_authority> metadata and deciding which spelling is used for the F<LICENCE>
file (if the C<licence> configuration is not provided).

=head2 fake_release

=for stopwords UploadToCPAN FakeRelease

Available since 0.122.

A boolean option that, when set, removes L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN> from the plugin list
and replaces it with L<[FakeRelease]|Dist::Zilla::Plugin::FakeRelease>.
Defaults to false; can also be set with the environment variable C<FAKE_RELEASE>.

=for stopwords customization

=head2 other customization options

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
(Note that even though some overridden values are inspected in this class,
they are still overlaid on top of whatever this bundle eventually decides to
pass - so what is in the F<dist.ini> always trumps everything else.)

Plugins are not loaded until they are actually needed, so it is possible to
C<--force>-install this plugin bundle and C<-remove> some plugins that do not
install or are otherwise problematic.

If a F<weaver.ini> is present in the distribution, pod is woven using it;
otherwise, the behaviour is as with a F<weaver.ini> containing the single line
C<[@Author::TABULO]> (see L<Pod::Weaver::PluginBundle::Author::TABULO>).

=head1 NAMING SCHEME

=for stopwords KENTNL

This distribution follows best practices for author-oriented plugin bundles; for more information,
see L<KENTNL's distribution|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>.

=head1 ORIGINAL AUTHOR

This distribution is based on L<Dist::Zilla::PluginBundle::Author::ETHER> by :

Karen Etheridge L<cpan:ETHER>

Thank you ETHER!

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::PluginBundle::Author::TABULO>

=item *

L<Dist::Zilla::MintingProfile::Author::TABULO>

=item *

L<Dist::Zilla::PluginBundle::Git::VersionManager>

=item *

L<Dist::Zilla::PluginBundle::Author::ETHER> (original bundle by ETHER)

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Edward Betts Graham Knop Randy Stauner Roy Ivy III Сергей Романов Dave Rolsky

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Edward Betts <edward@4angle.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Roy Ivy III <rivy@cpan.org>

=item *

Сергей Романов <sromanov@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod


#endregion pod
