#
# This file is part of Dist-Zilla-PluginBundle-MSCHOUT
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Pod::Weaver::PluginBundle::MSCHOUT;
$Pod::Weaver::PluginBundle::MSCHOUT::VERSION = '0.36';
# ABSTRACT: Pod::Weaver configuration the way MSCHOUT does it

# Dependencies
use Pod::Weaver::Section::SourceGitHub;
use Pod::Weaver::Section::BugsRT;

use Pod::Weaver::Config::Assembler;

use namespace::autoclean;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    return (
        [ '@Default/CorePrep', _exp('@CorePrep'), {} ],
        [ '@Default/Name',     _exp('Name'),      {} ],
        [ '@Default/Version',  _exp('Version'),   {} ],

        [ '@Default/prelude', _exp('Region'),  { region_name => 'prelude' } ],
        [ 'SYNOPSIS',         _exp('Generic'), {} ],
        [ 'DESCRIPTION',      _exp('Generic'), {} ],
        [ 'OVERVIEW',         _exp('Generic'), {} ],

        [ 'ATTRIBUTES', _exp('Collect'), { command => 'attr' } ],
        [ 'METHODS',    _exp('Collect'), { command => 'method' } ],
        [ 'FUNCTIONS',  _exp('Collect'), { command => 'func' } ],

        [ '@MSCHOUT/Leftovers', _exp('Leftovers'), {} ],

        # SOURCE section using GitHub.  If present in POD already, POD value
        # will be used.
        [ '@MSCHOUT/SourceGitHub', _exp('SourceGitHub'), {} ],
        [ 'AllowOverride/Source', _exp('AllowOverride'), {
                header_re      => '^SOURCE$',
                action         => 'replace',
                match_anywhere => 0
            }
        ],
        [ '@MSCHOUT/BugsRT',       _exp('BugsRT'),       {} ],

        [ '@MSCHOUT/postlude', _exp('Region'), { region_name => 'postlude' } ],

        # AUTHOR section. Will use POD section if present already
        [ '@MSCHOUT/Authors', _exp('Authors'), {} ],
        [ 'AllowOverride/Authors', _exp('AllowOverride'), {
                header_re      => '^AUTHORS?$',
                action         => 'replace',
                match_anywhere => 0
            }
        ],
        [ '@MSCHOUT/Legal',   _exp('Legal'),   {} ],
        [ '@MSCHOUT/List',    _exp('-Transformer'), { transformer => 'List' } ],
    );
}

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::MSCHOUT - Pod::Weaver configuration the way MSCHOUT does it

=head1 VERSION

version 0.36

=head1 DESCRIPTION

This is the L<Pod::Weaver> config I use for building my documentation.  I use
it with L<Dist::Zilla::PluginBundle::MSCHOUT>

=for Pod::Coverage mvp_bundle_config

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/dist-zilla-pluginbundle-mschout>
and may be cloned from L<git://github.com/mschout/dist-zilla-pluginbundle-mschout.git>

=head1 BUGS

Please report any bugs or feature requests to bug-dist-zilla-pluginbundle-mschout@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-MSCHOUT

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
