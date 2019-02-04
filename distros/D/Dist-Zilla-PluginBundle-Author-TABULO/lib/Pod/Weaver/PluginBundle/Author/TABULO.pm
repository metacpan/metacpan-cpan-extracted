use strict;
use warnings;
package Pod::Weaver::PluginBundle::Author::TABULO;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: A plugin bundle for pod woven for TABULO
# BASED_ON: Pod::Weaver::PluginBundle::Author::ETHER

our $VERSION = '0.198';
# AUTHORITY

use namespace::autoclean -also => ['_exp'];
use Pod::Weaver::Config::Assembler;
use Module::Runtime 'use_module';
use PadWalker 'peek_sub';

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

# This sub behaves somewhat like a Dist::Zilla pluginbundle's configure() -- it returns a list of strings or 1, 2
# or 3-element arrayrefs containing plugin specifications. The goal is to make this look as close to what
# weaver.ini looks like as possible.

# Some other possibilities (found on CPAN) include :
#
# Pod::Weaver::Section::*
#   * AllowOverride       - Allow POD to override a Pod::Weaver-provided
#   * Collect::FromOther  - Import sections from other POD
#   * CommentString       - Add Pod::Weaver section with content extracted from comment with specified key
#   * Bugs::DefaultRT     - Add a BUGS section to refer to bugtracker (or RT as default)
#   * GenerateSection     - add pod section from an interpolated piece of text
#   * ReplaceName         - Add or replace a NAME section with abstract.
#   * SeeAlso             - add a SEE ALSO pod section. Also supports #SEEALSO comments (preferrable).
#                           WARNING:  The 'SEE ALSO' section in your POD, if present,
#                                     should just be a list of links (one per line), without any POD commands.
#   * Template            - add pod section from a Text::Template template
#   * WarrantyDisclaimer  - Add a standard DISCLAIMER OF WARRANTY section (for your Perl module)
#
#   * Extends  - Add a list of parent classes to your POD.
#   * Consumes - Add a list of roles to your POD. WARNING: This one has some CAVEATS (refer to CPAN).
#   * Requires - Add Pod::Weaver section with all used modules from package excluding listed ones, e.g. :
#               [Requires]
#               ignore = base lib constant namespace::sweep
#
# Pod::Weaver::Plugin::*
#  .* AppendPrepend         - Merge append:FOO and prepend:FOO sections in POD
#  .* Include               - Support for including sections of Pod from other files
#  .* EnsureUniqueSections  - Ensure that POD has no duplicate section headers.
#                             NOTE: Setting strict=1 will disable smart detection of duplicates (plural forms, collapsed space, ...)
#   * Exec                  - include output of commands in your pod
#   * Run                   - Write Pod::Weaver::Plugin directly in 'weaver.ini'
#                             WARNING: Seems to be a bit exoteric.
#   * SortSections          - Sort POD sections
#  .* StopWords             - Dynamically add stopwords to your woven pod
#  .* WikiDoc               - allow wikidoc-format regions to be translated during dialect phase

sub configure
{
    my $self = shift;

    # ETHER says: I wouldn't have to do this ugliness if I could have some configuration values passed in from weaver.ini or
    # the [PodWeaver] plugin's use of config_plugin (where I could define a 'licence' option)
    my $podweaver_plugin = ${ peek_sub(\&Dist::Zilla::Plugin::PodWeaver::weaver)->{'$self'} };
    my $lic_plugin = $podweaver_plugin && $podweaver_plugin->zilla->plugin_named('@Author::TABULO/License');
    my $lic_filename = $lic_plugin ? $lic_plugin->filename : 'LICENSE'; # TAU: Changed default from 'LICENCE'

    return (
        # equivalent to [@CorePrep].  These are REQUIRED for anything to work.
        [ '-EnsurePod5' ],
        [ '-H1Nester' ],

          '-AppendPrepend',         #  + by TAU. Merge append:FOO and prepend:FOO sections in POD
          '-EnsureUniqueSections',  #  + by TAU. Ensure that POD has no duplicate section headers.
        [ '-Include'                    =>  { pod_path => 'lib:bin:script:scripts:docs/pod', insert_errors => 0 } ],  # + by TAU
          '-SingleEncoding',        #  Encoding defaults to UTF-8.
        # In addition to the below, other stopWords may be added in several places, such as the [%PodWeaver] stash in 'dist.ini'
        [ '-StopWords'                  =>  { gather=>1,   include   => [ stopwords() ] } ],
        [ '-Transformer'  => Verbatim   =>  { transformer => 'Verbatim' } ],
        [ '-Transformer'  => WikiDoc    =>  { transformer => 'WikiDoc'  } ],  # TAU : Added WikiDoc


        [ 'Region' => 'header' ],
          'Name',
          'Version',
        [ 'Region'  => 'prelude'      ],
        [ 'Generic' => 'SYNOPSIS'     ],
        [ 'Generic' => 'DESCRIPTION'  ],
        [ 'Generic' => 'OVERVIEW'     ],
        [ 'Collect' => 'ATTRIBUTES'           => { command => 'attr'    } ],
        # [ 'Collect' => 'ATTRIBUTES (PRIVATE)' => { command => 'pattr'   } ],
        [ 'Collect' => 'METHODS'              => { command => 'method'  } ],
        # [ 'Collect' => 'METHODS (PRIVATE)'    => { command => 'pmethod' } ],
        [ 'Collect' => 'FUNCTIONS'            => { command => 'func'    } ],
        # [ 'Collect' => 'FUNCTIONS (PRIVATE)'  => { command => 'pfunc'   } ],
        [ 'Collect' => 'TYPES'                => { command => 'type'    } ],

          'Leftovers',
        [ 'Region'  => 'postlude'     ],

        [ 'GenerateSection' => 'generate SUPPORT' => {
                title => 'SUPPORT',
                main_module_only => 0,
                text => [ support_section_text() ],
            },
        ],

        [ 'AllowOverride' => 'allow override SUPPORT' => {
               header_re => '^(SUPPORT|BUGS)\b',
               action => 'prepend',
               match_anywhere => 0,
            },
        ],

          'Authors',
        [ 'Contributors' => { ':version' => '0.008' } ],
        [ 'Legal' => { ':version' => '4.011', header => 'COPYRIGHT AND ' . $lic_filename } ],
          'WarrantyDisclaimer', # + by TABULO
        [ 'Region' => 'footer' ],
    );
}


#--------------------------------------
sub stopwords {

#pod =for COMMENT
#pod
#pod NOTE: See C<Pod::Wordlist> for a list of stopwords that are already taken into account
#pod automatically by L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling/stopwords>.
#pod
#pod =cut

  (

  # Frequently mentioned proper names
  qw ( bitbucket BitBucket CPAN irc GitHub metacpan ),

  # Frequently mentioned Perl module names (without the '::')
  qw ( FakeRelease ModuleBuildTiny PodWeaver SurgicalPodWeaver UploadToCPAN),

  # Common idioms found in Perl docuentation
  qw ( foo foobar bar baz ),

  # Frequently mentioned authors
  qw ( DAGOLDEN ETHER TABULO KENTNL ),

  # Some made-up words or americanisms that TABULO likes to use anyway
  qw ( customization customizations stopword stopwords repo submodule optimization optimizations),

  # Some words that are somehow not known to the spell-checker
  qw (
    MERCHANTABILITY
  ),
)
}

#--------------------------------------
sub support_section_text {  # [TAU] : Note that this is actualy a template.
#--------------------------------------
  return <<'SUPPORT',
{{ join("\n\n",
($bugtracker_email && $bugtracker_email =~ /rt\.cpan\.org/)
? "Bugs may be submitted through L<the RT bug tracker|$bugtracker_web>\n(or L<$bugtracker_email|mailto:$bugtracker_email>)."
: $bugtracker_web
? "bugs may be submitted through L<$bugtracker_web>."
: (),

$distmeta->{resources}{x_MailingList} ? 'There is also a mailing list available for users of this distribution, at' . "\nL<" . $distmeta->{resources}{x_MailingList} . '>.' : (),

$distmeta->{resources}{x_IRC}
? 'There is also an irc channel available for users of this distribution, at' . "\nL<"
. do {
# try to extract the channel
if (my ($network, $channel) = ($distmeta->{resources}{x_IRC} =~ m!(?:://)?(\w+(?:\.\w+)*)/?(#\w+)!)) {
    'C<' . $channel . '> on C<' . $network . '>|' . $distmeta->{resources}{x_IRC}
}
else {
    $distmeta->{resources}{x_IRC}
}
}
. '>.'
: (),

(($distmeta->{x_authority} // '') eq 'cpan:ETHER')    # Disabled for TABULO because I am not active on IRC, but ETHER can still use this profile:-)
? "I am also usually active on irc, as 'ether' at C<irc.perl.org>."
: (),
) }}
SUPPORT
}

sub mvp_bundle_config {
    my $self = shift || __PACKAGE__;

    return map {
        $self->_expand_config($_)
    } $self->configure;
}


my $prefix;
sub _prefix {
    my $self = shift;
    return $prefix if defined $prefix;
    ($prefix = (ref($self) || $self)) =~ s/^Pod::Weaver::PluginBundle:://;
    $prefix;
}

sub _expand_config
{
    my ($self, $this_spec) = @_;

    die 'undefined config' if not $this_spec;
    die 'unrecognized config format: ' . ref($this_spec) if ref($this_spec) and ref($this_spec) ne 'ARRAY';

    my ($name, $class, $payload);

    if (not ref $this_spec)
    {
        ($name, $class, $payload) = ($this_spec, _exp($this_spec), {});
    }
    elsif (@$this_spec == 1)
    {
        ($name, $class, $payload) = ($this_spec->[0], _exp($this_spec->[0]), {});
    }
    elsif (@$this_spec == 2)
    {
        $name = ref $this_spec->[1] ? $this_spec->[0] : $this_spec->[1];
        $class = _exp(ref $this_spec->[1] ? $this_spec->[0] : $this_spec->[0]);
        $payload = ref $this_spec->[1] ? $this_spec->[1] : {};
    }
    else
    {
        ($name, $class, $payload) = ($this_spec->[1], _exp($this_spec->[0]), $this_spec->[2]);
    }

    $name =~ s/^[@=-]//;

    # Region plugins have the custom plugin name moved to 'region_name' parameter,
    # because we don't want our bundle name to be part of the region name.
    if ($class eq _exp('Region'))
    {
        $name = $this_spec->[1];
        $payload = { region_name => $this_spec->[1], %$payload };
    }

    use_module($class, $payload->{':version'}) if $payload->{':version'};

    # prepend '@Author::TABULO/' to each class name,
    # except for Generic and Collect which are left alone.
    $name = '@' . $self->_prefix . '/' . $name
        if $class ne _exp('Generic') and $class ne _exp('Collect');

    return [ $name => $class => $payload ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::TABULO - A plugin bundle for pod woven for TABULO

=head1 VERSION

version 0.198

=head1 SYNOPSIS

In your F<weaver.ini>:

    [@Author::TABULO]

Or in your F<dist.ini>

    [PodWeaver]
    config_plugin = @Author::TABULO

It is also used automatically when your F<dist.ini> contains:

    [@Author::TABULO]
    :version = 0.094    ; or any higher version

=head1 DESCRIPTION

=begin COMMENT




=end COMMENT

NOTE: See C<Pod::Wordlist> for a list of stopwords that are already taken into account
automatically by L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling/stopwords>.

=for stopwords TABULO ETHER
=for stopwords GitHub
=for stopwords optimizations repo

This is a L<Pod::Weaver> plugin bundle used for TABULO's distributions.
Like his dzil plugin-bundle, the starting point of this profile was ETHER's.

And since TABULO initially forked the whole thing from ETHER's,
most of the documentation you see here actually come from her originally, ...

Thank you ETHER!

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

=head2 DESCRIPTION (at last)

This L<Pod::Weaver> plugin bundle is I<approximately> equal to the
following F<weaver.ini>, minus some optimizations:

    [-EnsurePod5]
    [-H1Nester]

    [-AppendPrepend]

    [-EnsureUniqueSections]

    [-Include]
    insert_errors = 0
    pod_path = lib:bin:script:scripts:docs/pod

    [-SingleEncoding]

    [-StopWords]
    gather = 1
    include = CPAN
    include = DZIL
    include = GITHUB
    include = MERCHANTABILITY
    ; include = ... (a bunch of other stopwords for the spell-checker, too many to list here)

    [-Transformer / List]
    transformer = List

    [-Transformer / Verbatim]
    transformer = Verbatim

    [-Transformer / WikiDoc]
    transformer = WikiDoc

    [Region / header]
    [Name]
    [Version]

    [Region / prelude]

    [Generic / SYNOPSIS]
    [Generic / DESCRIPTION]
    [Generic / OVERVIEW]

    [Collect / ATTRIBUTES]
    command = attr

    [Collect / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = func

    [Collect / TYPES]
    command = type

    [Leftovers]

    [Region / postlude]

    [GenerateSection / generate SUPPORT]
    title = SUPPORT
    main_module_only = 0
    text = <template>
    [AllowOverride / allow override SUPPORT]
    header_re = ^(SUPPORT|BUGS)
    action = prepend
    match_anywhere = 0

    [Authors]
    [Contributors]
    :version = 0.008

    [Legal]
    :version = 4.011
    header = COPYRIGHT AND <licence filename>

    [WarrantyDisclaimer]

    [Region / footer]

This is also equivalent (other than section ordering) to:

    [-AppendPrepend]

    [-EnsureUniqueSections]

    [-Include]
    insert_errors = 0
    pod_path = lib:bin:script:scripts:docs/pod

    [-StopWords]
    gather = 1
    include = CPAN
    include = DZIL
    include = GITHUB
    include = MERCHANTABILITY
    ; include = ... (a bunch of other stopwords for the spell-checker, too many to list here)

    [-Transformer / List]
    transformer = List

    [-Transformer / Verbatim]
    transformer = Verbatim

    [-Transformer / WikiDoc]  ; Added by TABULO
    transformer = WikiDoc

    [Region / header]
    [@Default]

    [Collect / TYPES]
    command = type

    [GenerateSection / generate SUPPORT]
    title = SUPPORT
    main_module_only = 0
    text = <template>
    [AllowOverride / allow override SUPPORT]
    header_re = ^(SUPPORT|BUGS)
    action = prepend
    match_anywhere = 0

    [Contributors]
    :version = 0.008

    [WarrantyDisclaimer]

    [Region / footer]

=head1 OPTIONS

None at this time. (The bundle is never instantiated, so this doesn't seem to
be possible without updates to L<Pod::Weaver>.)

=head1 OVERRIDING A SPECIFIC SECTION

This F<weaver.ini> will let you use a custom C<COPYRIGHT AND LICENCE> section and still use the plugin bundle:

    [@Author::TABULO]
    [AllowOverride / OverrideLegal]
    header_re = ^COPYRIGHT
    match_anywhere = 1

=head1 ADDING STOPWORDS FOR SPELLING TESTS

As noted in L<Dist::Zilla::PluginBundle::Author::TABULO>, stopwords for
spelling tests can be added by adding a directive to pod:

    =for stopwords foo bar baz

However, if the stopword appears in the module's abstract, it is moved to the
C<NAME> section, which will be above your stopword directive. You can handle
this by declaring the stopword in the special C<header> section, which will be
woven ahead of everything else:

    =for :header
    =for stopwords foo bar baz

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::PluginBundle::Default>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::PluginBundle::Author::TABULO>

=item *

L<Dist::Zilla::MintingProfile::Author::TABULO>

=item *

L<Pod::Weaver::PluginBundle::Author::ETHER> (the original bundle of ETHER)

=back

=head1 NAMING SCHEME

=for stopwords KENTNL

This distribution follows best practices for author-oriented plugin bundles; for more information,
see L<KENTNL's distribution|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>.

=head1 ORIGINAL AUTHOR

=for stopwords ETHER

This distribution is based on L<Pod::Weaver::PluginBundle::Author::ETHER> by :

Karen Etheridge L<cpan:ETHER>

Thank you ETHER!

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
