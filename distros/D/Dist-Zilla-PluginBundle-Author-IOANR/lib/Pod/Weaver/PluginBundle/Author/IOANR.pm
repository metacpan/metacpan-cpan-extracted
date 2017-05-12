package Pod::Weaver::PluginBundle::Author::IOANR;
$Pod::Weaver::PluginBundle::Author::IOANR::VERSION = '1.162691';
# ABSTRACT: Weave the POD for a IOANR dist

use Moose;
use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        ['@Author::IOANR/CorePrep', _exp('@CorePrep'), {}],
        ['@Author::IOANR/SingleEncoding', _exp('-SingleEncoding'), {}],
        [
            '@Author::IOANR/EnsureUniqueSections',
            _exp('-EnsureUniqueSections'),
            {}
        ],
        [
            '@Author::IOANR/List', _exp('-Transformer'),
            {'transformer' => 'List'}
        ],
        ['@Author::IOANR/StopWords', _exp('-StopWords'), {}],

        ['@Author::IOANR/Name',    _exp('Name'),    {}],
        ['@Author::IOANR/Version', _exp('Version'), {}],

        ['@Author::IOANR/Prelude', _exp('Region'), {region_name => 'prelude'}],

        ['@Author::IOANR/Synopsis', _exp('Generic'), {header => 'SYNOPSIS'}],
        [
            '@Author::IOANR/Description', _exp('Generic'),
            {header => 'DESCRIPTION'}
        ],
        ['@Author::IOANR/Overview', _exp('Generic'), {header => 'OVERVIEW'}],
        ['@Author::IOANR/Usage',    _exp('Generic'), {header => 'USAGE'}],
    );

    for my $plugin (
        ['Attributes', _exp('Collect'), {command => 'attr'}],
        ['Methods',    _exp('Collect'), {command => 'method'}],
        ['Functions',  _exp('Collect'), {command => 'func'}],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins, (
        ['@Author::IOANR/Leftovers', _exp('Leftovers'), {}],
        [
            '@Author::IOANR/postlude', _exp('Region'),
            {region_name => 'postlude'}
        ],
        ['@Author::IOANR/BugsAndLimitations', _exp('BugsAndLimitations'), {}],
        ['@Author::IOANR/Availability',       _exp('Availability'),       {}],
        ['@Author::IOANR/SourceGitHub',       _exp('SourceGitHub'),       {}],
        ['@Author::IOANR/Authors',            _exp('Authors'),            {}],
        ['@Author::IOANR/Legal',              _exp('Legal'),              {}],
        ['@Author::IOANR/WarrantyDisclaimer', _exp('WarrantyDisclaimer'), {}],

    );

    return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Pod::Weaver::PluginBundle::Author::IOANR - Weave the POD for a IOANR dist

=head1 VERSION

version 1.162691

=head1 SEE ALSO

Originally based on L<Pod::Weaver::PluginBundle::NRR>, though I'm sure I copied
it from somewhere else who copied from that one.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-IOANR/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::IOANR/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR>
and may be cloned from L<git://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
