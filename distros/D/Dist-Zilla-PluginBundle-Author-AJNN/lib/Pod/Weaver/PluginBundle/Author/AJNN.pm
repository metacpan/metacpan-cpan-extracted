use 5.026;
use warnings;

package Pod::Weaver::PluginBundle::Author::AJNN;
# ABSTRACT: AJNN Pod::Weaver configuration
$Pod::Weaver::PluginBundle::Author::AJNN::VERSION = '0.07';

use Pod::Weaver 4.009;
use Pod::Weaver::Config::Assembler;

use Pod::Weaver::PluginBundle::Author::AJNN::Author;
use Pod::Weaver::PluginBundle::Author::AJNN::License;


sub _exp {
	my ( $moniker ) = @_;
	return Pod::Weaver::Config::Assembler->expand_package( $moniker );
}


sub mvp_bundle_config {
	return (
		[ '@AJNN/CorePrep',       _exp('@CorePrep'), {} ],
		[ '@AJNN/SingleEncoding', _exp('-SingleEncoding'), {} ],
		[ '@AJNN/Name',           _exp('Name'), {} ],
		[ '@AJNN/Version',        _exp('Version'), {} ],
		
		[ '@AJNN/Leftovers',      _exp('Leftovers'), {} ],
		
		[ '@AJNN/Author',  __PACKAGE__ . '::Author', {} ],
		[ '@AJNN/Contributors', _exp('Contributors'), {} ],
		
		[ '@AJNN/License', __PACKAGE__ . '::License', {} ],
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::AJNN - AJNN Pod::Weaver configuration

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 package Dist::Zilla::PluginBundle::Author::AJNN;
 
 use Pod::Weaver::PluginBundle::Author::AJNN;
 
 use Moose;
 with 'Dist::Zilla::Role::PluginBundle::Easy';
 
 sub configure {
   shift->add_plugins(
     ...,
     [ 'PodWeaver' => { config_plugin => '@Author::AJNN' } ],
   );
 }

or in F<dist.ini>:

 [PodWeaver]
 config_plugin = @Author::AJNN

=head1 DESCRIPTION

This is the configuration I use for L<Dist::Zilla::Plugin::PodWeaver>.
Most likely you don't want or need to read this.

=head1 EQUIVALENT INI CONFIG

This plugin bundle is nearly equivalent to the following C<weaver.ini> config:

 [@CorePrep]
 [-SingleEncoding]
 [Name]
 [Version]
 
 [Leftovers]
 
 [@Author::AJNN::Author]
 [Contributors]
 
 [@Author::AJNN::License]

=head1 BUGS

This configuration is hacked together specifically for AJNN's needs.
It has not been designed with extensibility or reusability in mind.
No forward or backward compatibility should be expected.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::AJNN>

L<Pod::Weaver::PluginBundle::Author::AJNN::Author>

L<Pod::Weaver::PluginBundle::Author::AJNN::License>

L<Pod::Weaver::PluginBundle::Default>

L<Dist::Zilla::Plugin::PodWeaver>

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
