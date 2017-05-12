use strict;
use warnings;

package Pod::Weaver::PluginBundle::ARJONES;
{
  $Pod::Weaver::PluginBundle::ARJONES::VERSION = '1.133200';
}

# ABSTRACT: ARJONES's default Pod::Weaver config

use Pod::Weaver::Section::Contributors 0.001 ();


use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }


sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        [ '@ARJONES/CorePrep', _exp('@CorePrep'), {} ],
        [ '@ARJONES/Name',     _exp('Name'),      {} ],
        [ '@ARJONES/Version',  _exp('Version'),   {} ],

        [ '@ARJONES/Prelude',  _exp('Region'),  { region_name => 'prelude' } ],
        [ '@ARJONES/Synopsis', _exp('Generic'), { header      => 'SYNOPSIS' } ],
        [
            '@ARJONES/Description', _exp('Generic'), { header => 'DESCRIPTION' }
        ],
        [ '@ARJONES/Overview', _exp('Generic'), { header => 'OVERVIEW' } ],

        [ '@ARJONES/Stability', _exp('Generic'), { header => 'STABILITY' } ],
        [ '@ARJONES/Events',    _exp('Generic'), { header => 'EVENTS' } ],
    );

    for my $plugin (
        [ 'Attributes', _exp('Collect'), { command => 'attr' } ],
        [ 'Methods',    _exp('Collect'), { command => 'method' } ],
        [ 'Functions',  _exp('Collect'), { command => 'func' } ],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins,
      (
        [ '@ARJONES/SingleEncoding',  _exp('-SingleEncoding'), {} ],
        [ '@ARJONES/Leftovers', _exp('Leftovers'), {} ],
        [ '@ARJONES/postlude', _exp('Region'),  { region_name => 'postlude' } ],
        [ '@ARJONES/Authors',  _exp('Authors'), {} ],
        [ '@ARJONES/Contributors', _exp('Contributors'), {} ],
        [ '@ARJONES/Legal',        _exp('Legal'),        {} ],
        [ '@ARJONES/List', _exp('-Transformer'), { 'transformer' => 'List' } ],
      );

    return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::ARJONES - ARJONES's default Pod::Weaver config

=head1 VERSION

version 1.133200

=head1 DESCRIPTION

This is the default Pod::Weaver config that ARJONES uses. Roughly equivalent to:

=over 4

=item *

C<@Default>

=item *

C<-Transformer> with L<Pod::Elemental::Transformer::List>

=back

Heavily based on L<Pod::Weaver::PluginBundle::RJBS>.

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
