use strict;
use warnings;
use utf8;

package Pod::Weaver::PluginBundle::Author::TABULO;
our $VERSION = '1.000013';

use Pod::Weaver 4;
use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Elemental::Transformer::List 0.102000 ();  # - transform :list regions into =over/=back to save typing
use Pod::Elemental::PerlMunger 0.200001        ();  # - replace with comment support

use Pod::Weaver::Plugin::AppendPrepend ();          # - Merge append:FOO and prepend:FOO sections in POD
use Pod::Weaver::Plugin::Include       ();          # - Support for including sections of Pod from other files
use Pod::Weaver::Plugin::StopWords     ();          # - Dynamically add stopwords to your woven pod
use Pod::Weaver::Plugin::WikiDoc       ();          # - allow wikidoc-format regions to be translated during dialect phase

use Pod::Weaver::Section::Authors  ();              # - Add or replace an AUTHOR or AUTHORS section; similar to Pod::Weaver::Section::Authors
use Pod::Weaver::Section::ClassMopper     ();       # - Use Class::MOP introspection to make a couple sections.
use Pod::Weaver::Section::Collect       ();         # - a section that gathers up specific commands
use Pod::Weaver::Section::Contributors 0.008 ();    # - a section listing contributors
use Pod::Weaver::Section::ReplaceName   ();         # - Add or replace a NAME section with abstract.
use Pod::Weaver::Section::SeeAlso       ();         # - add a SEE ALSO pod section
use Pod::Weaver::Section::Support 1.001 ();         # - Add a SUPPORT section to your POD


## Roles / Classes
# use Pod::Weaver::Section::Requires ();            # - Add Pod::Weaver section with all used modules from package excluding listed ones
# use Pod::Weaver::Section::Consumes ();            # - Add a list of roles to your POD.
# use Pod::Weaver::Section::Extends ();             # - Add a list of parent classes to your POD.

## Add or Replace BOILERPLATE
# use Pod::Weaver::Section::ReplaceName();          # - Add or replace a NAME section with abstract.
# use Pod::Weaver::Section::ReplaceAuthors ();      # - Add or replace an AUTHOR or AUTHORS section; similar to Pod::Weaver::Section::Authors
# use Pod::Weaver::Section::ReplaceLegal();         # - Add or replace a COPYRIGHT AND LICENSE section.
# use Pod::Weaver::Section::ReplaceVersion();       # - Add or replace a VERSION section.

## Buildn se
# use Pod::Weaver::Section::Collect::FromOther ();  # - Import sections from other POD
# use Pod::Weaver::Section::CollectWithAutoDoc ();  # - Section to gather specific commands and add auto-generated documentation via Sub::Documentation.
# use Pod::Weaver::Section::CollectWithIntro ();    # - Preface pod collections; allows one to attach a prefix paragraph to the collected section/node.
# use Pod::Weaver::Section::CommentString ();       # - Add Pod::Weaver section with content extracted from comment with a keyword (like ABSTRACT for Name)
# use Pod::Weaver::Section::Template ();            # - add pod section from a Text::Template template

# use Pod::Weaver::Section::SourceGitHub();         #  - Add SOURCE pod section for a github repository
# use Pod::Weaver::Section::WarrantyDisclaimer();   # - Add a standard DISCLAIMER OF WARRANTY section (for your Perl module)

# use Sub::Documentation;
# use Sub::Documentation::Attributes;




sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

my $repo_intro = <<'END';
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
END

my $bugtracker_content = <<'END';
Please report any bugs or feature requests through the issue tracker
at {WEB}.
END


sub mvp_bundle_config {

    my @plugins;
    push @plugins, (
        [ "SingleEncoding", _exp('-SingleEncoding'), {} ],
        [ "WikiDoc",        _exp('-WikiDoc'),        {} ],
        [ "CorePrep",       _exp('@CorePrep'),       {} ],

        [ "AppendPrepend", _exp('-AppendPrepend'), {} ], # - Merge append:FOO and prepend:FOO sections in POD
        [ "Include",       _exp('-Include'),       {} ], # - Support for including sections of Pod from other files
        [ "StopWords",     _exp('-StopWords'),     {} ], # - Dynamically add stopwords to your woven pod
    );

    push @plugins, ( [ 'List' => _exp('-Transformer'), { transformer => 'List' } ], [ 'Verbatim' => _exp('-Transformer'), { transformer => 'Verbatim' } ], );

    push @plugins, map {
        $_->[2]{header} = uc $_->[0] if @$_;
        @$_ ? $_ : ()
    } (
        # Sections
        [ "Name",           _exp('ReplaceName'),    {} ],
        [ "Version",        _exp('Version'), {} ],
        [ "Prelude",        _exp('Region'),  { region_name => 'prelude' } ],

        [ "Foreword",       _exp('Generic'), {} ],
        [ "Synopsis",       _exp('Generic'), {} ],
        [ "Description",    _exp('Generic'), {} ],
        [ "Usage",          _exp('Generic'), {} ],
        [ "Overview",       _exp('Generic'), {} ],
        [ "Stability",      _exp('Generic'), {} ],

        [ 'Requirements',         _exp('Collect'),     { command => 'requires' } ],

        ## ClassMopper generates one or two sections (ATTRIBUTES / METHODS) from Class::MOP metadata.
        ## BUT... looks kinda horrible, like JavaDoc :-(
        [ 'Attributes',           _exp('ClassMopper'), { no_tagline => 1, skip_methods=>1, skip_attributes => 0 } ],
        [ 'Attributes*',          _exp('Collect'),     { command => 'attr'          } ], # name != Attributes (since ClassMopper generates that)
        [ 'Attributes (Class)',   _exp('Collect'),     { command => 'cattr'         } ],
        [ 'Attributes (Private)', _exp('Collect'),     { command => 'pattr'         } ],

        [ 'Constructors',         _exp('Collect'),     { command => 'constructor'   } ],
        [ 'Methods',              _exp('Collect'),     { command => 'method'        } ],
        [ 'Methods (Class)',      _exp('Collect'),     { command => 'cmethod'       } ],
        [ 'Methods (Object)',     _exp('Collect'),     { command => 'omethod'       } ],
        [ 'Singletons',           _exp('Collect'),     { command => 'singleton'     } ],

        [ 'Functions',            _exp('Collect'),     { command => 'func'          } ],

        [ 'Commands',             _exp('Collect'),     { command => 'cmd'           } ],
        [ 'Options',              _exp('Collect'),     { command => 'opt'           } ],
        [ 'Tags',                 _exp('Collect'),     { command => 'tag'           } ],

        [ 'Types',                _exp('Collect'),     { command => 'type'          } ],
        [ 'Constants',            _exp('Collect'),     { command => 'const'         } ],
        [ 'Variables',            _exp('Collect'),     { command => 'var'           } ],

        [ 'Caveats',              _exp('Collect'),     { command => 'caveat'        } ],
        [ 'See Also',             _exp('Collect'),     { command => 'see'           } ],

        [ "Leftovers" => _exp('Leftovers'), {} ],
        [ "postlude"  => _exp('Region'),    { region_name => 'postlude' } ],
        [ "Authors"   => _exp('Authors'),   {} ],
        [
            "Support" => _exp('Support'), {
                perldoc            => 0,
                websites           => 'none',
                bugs               => 'metadata',
                bugs_content       => $bugtracker_content,
                repository_link    => 'both',
                repository_content => $repo_intro
            }
        ],
        [ 'Contributors' => _exp('Contributors'), { ':version' => '0.008' } ],
        [ "Legal", _exp('Legal'), {} ],

    );

    # [TAU]: Refactored prefixing down here.
    $_->[0] = '@Author/TABULO/' . $_->[0] for (@plugins);

    return @plugins;
}

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Pod::Weaver::PluginBundle::Author::TABULO - TABULO's bundle for Pod::Weaver (providing a default config for his distros)

=head1 VERSION

version 1.000013

=head1 FOREWORD

[TABULO]: This module started out as a copy of @DAGOLDEN's, including its documentation, copied and re-adapted below.

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-WikiDoc]

  [Generic / FOREWORD]

  [@Default]

  [Generic / USAGE]
  [Generic / OVERVIEW]
  [Generic / STABILITY]

  [Collect / REQUIREMENTS]
  command = requires

  [Collect / CONSTRUCTORS]
  command = constructor

  [ClassMopper / ATTRIBUTES]
  no_tagline = 1
  skip_methods = 1
  skip_attributes = 0

  [Support]
  ...

  [Contributors]

  [-Transformer]
  transformer = List

=head1 USAGE

This PluginBundle is used automatically with the C<@Author::TABULO> L<Dist::Zilla>
plugin bundle.

It also has region collectors for:

=over 4

=item *

requires

=item *

constructor

=item *

attr

=item *

method

=item *

func

=back

=for Pod::Coverage mvp_bundle_config

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::PluginBundle::DAGOLDEN>

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::Plugin::WikiDoc>

=item *

L<Pod::Weaver::Plugin::ClassMopper>

=item *

L<Pod::Elemental::Transformer::List>

=item *

L<Pod::Weaver::Section::Contributors>

=item *

L<Pod::Weaver::Section::Support>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=back

=begin notes




=end notes

# Some PLUGIN possibilities (found on CPAN) include :
#
# Pod::Weaver::Section::*
#   * AllowOverride       - Allow POD to override a Pod::Weaver-provided
#   * Collect::FromOther  - Import sections from other POD
#   * CommentString       - Add Pod::Weaver section with content extracted from comment with specified key
#   * Bugs::DefaultRT     - Add a BUGS section to refer to bugtracker (or RT as default)
#   * GenerateSection     - add pod section from an interpolated piece of text
#   * ReplaceName         - Add or replace a NAME section with abstract.
#   * SeeAlso             - add a SEE ALSO pod section. Also supports #SEEALSO comments (preferable).
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
#                             WARNING: Seems to be a bit esoteric.
#   * SortSections          - Sort POD sections
#  .* StopWords             - Dynamically add stopwords to your woven pod. XXX: Staying away from this, as it adds lines on top of the module.
#  .* WikiDoc               - allow wikidoc-format regions to be translated during dialect phase

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: TABULO's bundle for Pod::Weaver (providing a default config for his distros)
# COPYRIGHT


