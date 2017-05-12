package Pod::Weaver::PluginBundle::Author::BBYRD;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.06'; # VERSION
# ABSTRACT: Pod::Weaver Author Bundle for BBYRD

use sanity;

use Pod::Weaver 3.101635; # fixed ABSTRACT scanning
use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Weaver::Section::Availability ();
use Pod::Elemental::Transformer::List 0.101620 ();
use Pod::Weaver::Section::Support 1.001        ();
use Pod::Weaver::Section::Contributors ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

### TODO: Consider a simplified version of this a la DZIL:R:PB:Merged?
sub mvp_bundle_config {
   my @plugins;
   push @plugins, (
      # [-SingleEncoding]
      # [-WikiDoc]
      # [@CorePrep]
      #
      # [Name]

      [ '@Author::BBYRD/SingleEncoding', _exp('-SingleEncoding'), {} ],
      [ '@Author::BBYRD/WikiDoc',        _exp('-WikiDoc'),        {} ],
      [ '@Author::BBYRD/CorePrep',       _exp('@CorePrep'),       {} ],
      [ '@Author::BBYRD/Name',           _exp('Name'),            {} ],

      # [Region / prelude]
      #
      # [Generic / SYNOPSIS]
      # [Generic / DESCRIPTION]
      # [Generic / OVERVIEW]

      [ '@Author::BBYRD/Prelude',     _exp('Region'),  { region_name => 'prelude' } ],
      [ '@Author::BBYRD/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS' } ],
      [ '@Author::BBYRD/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
      [ '@Author::BBYRD/Overview',    _exp('Generic'), { header      => 'OVERVIEW' } ],
   );

   foreach my $plugin (
      # [Collect / ATTRIBUTES]
      # command = attr
      #
      # [Collect / METHODS]
      # command = method
      #
      # [Collect / FUNCTIONS]
      # command = func

      [ 'Attributes',   _exp('Collect'), { command => 'attr' } ],
      [ 'Methods',      _exp('Collect'), { command => 'method' } ],
      [ 'Functions',    _exp('Collect'), { command => 'func' } ],
     )
   {
       $plugin->[2]{header} = uc $plugin->[0];
       push @plugins, $plugin;
   }

   push @plugins, (
      # [Leftovers]
      #
      # [Region / postlude]
      #
      # [Availability]

      [ '@Author::BBYRD/Leftovers',    _exp('Leftovers'),    {} ],
      [ '@Author::BBYRD/postlude',     _exp('Region'),       { region_name => 'postlude' } ],
      [ '@Author::BBYRD/Availability', _exp('Availability'), {} ],

      # [Support]
      # perldoc = 0
      # websites = none
      # repository_link = none
      # bugs = metadata
      # bugs_content = Please report any bugs or feature requests via {WEB}.
      # irc = irc.perl.org, #distzilla, SineSwiper

      [ '@Author::BBYRD/Support', _exp('Support'), {
         perldoc            => 0,
         websites           => 'none',
         repository_link    => 'none',
         bugs               => 'metadata',
         bugs_content       => 'Please report any bugs or feature requests via {WEB}.',
         ### XXX: Use a DZIL stash to store the IRC channel? ###
         irc                => 'irc.perl.org, SineSwiper',
      } ],

      # [Authors]
      # [Contributors]
      # [Legal]
      #
      # [-Transformer]
      # transformer = List

      [ '@Author::BBYRD/Authors',      _exp('Authors'),      {} ],
      [ '@Author::BBYRD/Contributors', _exp('Contributors'), {} ],
      [ '@Author::BBYRD/Legal',        _exp('Legal'),        {} ],
      [ '@Author::BBYRD/List',         _exp('-Transformer'), { 'transformer' => 'List' } ],
   );

   return @plugins;
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::BBYRD - Pod::Weaver Author Bundle for BBYRD

=head1 SYNOPSIS

    ; Very similar to...
 
    [-SingleEncoding]
    [-WikiDoc]
    [@CorePrep]
 
    [Name]
 
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
 
    [Leftovers]
 
    [Region / postlude]
 
    [Availability]
    [Support]
    perldoc = 0
    websites = none
    repository_link = none
    bugs = metadata
    bugs_content = Please report any bugs or feature requests via {WEB}.
    irc = irc.perl.org, SineSwiper
 
    [Authors]
    [Contributors]
    [Legal]
 
    [-Transformer]
    transformer = List
 
    ; PodWeaver deps
    ; authordep Pod::Weaver::Plugin::WikiDoc
    ; authordep Pod::Weaver::Section::Availability
    ; authordep Pod::Weaver::Section::Support
    ; authordep Pod::Elemental::Transformer::List

=head1 DESCRIPTION

Like the DZIL one, this is a personalized Author bundle for my Pod::Weaver
configuration.

=head1 NAMING SCHEME

I'm a strong believer in structured order in the chaos that is the CPAN
namespace.  There's enough cruft in CPAN, with all of the forked modules,
legacy stuff that should have been removed 10 years ago, and confusion over
which modules are available vs. which ones actually work.  (Which all stem
from the same base problem, so I'm almost repeating myself...)

Like I said, I hate writing these personalized modules on CPAN.  I even bantered
around the idea of using L<MetaCPAN's author JSON input|https://github.com/SineSwiper/Dist-Zilla-PluginBundle-BeLike-You/blob/master/BeLike-You.pod>
to store the plugin data.  However, keeping the Author plugins separated from the
real PluginBundles is a step in the right direction.  See
L<KENTNL's comments on the Author namespace|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>
for more information.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Author-BBYRD>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::BBYRD/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
