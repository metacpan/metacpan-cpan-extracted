use strict;
use warnings;
package Pod::Weaver::PluginBundle::MITHALDU;
our $VERSION = '1.151340'; # VERSION

use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Elemental::Transformer::List 0.101620 ();
use Pod::Weaver::Section::Support 1.001 ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

my $repo_intro = <<'END';
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
END

my $bugtracker_content = <<'END';
Please report any bugs or feature requests through the issue tracker
at {WEB}.
You will be notified automatically of any progress on your issue.
END

sub mvp_bundle_config {
  my @plugins;
  push @plugins, (
    [ '@MITHALDU/WikiDoc',     _exp('-WikiDoc'), {} ],
    [ '@MITHALDU/CorePrep',    _exp('@CorePrep'), {} ],
    [ '@MITHALDU/Name',        _exp('Name'),      {} ],
    [ '@MITHALDU/Version',     _exp('Version'),   {} ],

    [ '@MITHALDU/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@MITHALDU/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@MITHALDU/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@MITHALDU/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],

    [ '@MITHALDU/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],
  );

  for my $plugin (
    [ 'Attributes', _exp('Collect'), { command => 'attr'   } ],
    [ 'Methods',    _exp('Collect'), { command => 'method' } ],
    [ 'Functions',  _exp('Collect'), { command => 'func'   } ],
  ) {
    $plugin->[2]{header} = uc $plugin->[0];
    push @plugins, $plugin;
  }

  push @plugins, (
    [ '@MITHALDU/Leftovers', _exp('Leftovers'), {} ],
    [ '@MITHALDU/postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@MITHALDU/Support',   _exp('Support'),
      {
        perldoc => 0,
        websites => 'none',
        bugs => 'metadata',
        bugs_content => $bugtracker_content,
        repository_link => 'both',
        repository_content => $repo_intro
      }
    ],
    [ '@MITHALDU/Authors',   _exp('Authors'),   {} ],
    [ '@MITHALDU/Legal',     _exp('Legal'),     {} ],
    [ '@MITHALDU/List',      _exp('-Transformer'), { 'transformer' => 'List' } ],
  );

  return @plugins;
}

# ABSTRACT: MITHALDU's default Pod::Weaver config
#
# This file is part of Dist-Zilla-PluginBundle-MITHALDU
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::MITHALDU - MITHALDU's default Pod::Weaver config

=head1 VERSION

version 1.151340

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle.  It is roughly equivalent to the
following weaver.ini:

   [-WikiDoc]
 
   [@Default]
 
   [Support]
   perldoc = 0
   websites = none
   bugs = metadata
   bugs_content = ... stuff (web only, email omitted) ...
   repository_link = both
   repository_content = ... stuff ...
 
   [-Transformer]
   transfomer = List

=for Pod::Coverage mvp_bundle_config

=head1 USAGE

This PluginBundle is used automatically with the CE<lt>@MITHALDUE<gt> L<Dist::Zilla>
plugin bundle.

=head1 SEE ALSO

=over

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::Plugin::WikiDoc>

=item *

L<Pod::Elemental::Transformer::List>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=back

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Christian Walde <mithaldu@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
