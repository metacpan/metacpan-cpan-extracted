package MetaCPAN::Clients;
$MetaCPAN::Clients::VERSION = '0.05';
use strict;
use warnings;

=head1 NAME

MetaCPAN::Clients - Some useful stand-alone scripts to access L<MetaCPAN|http://metacpan.org/>

=head1 SYNOPSIS

Command-line tools:

 metacpan_meta.pl N [PAUSEID]
 metacpan_namespace.pl --module Module::Name
 metacpan_namespace.pl --distro Distro-Name  (or partial name)
 metacpan_impact.pl --distro Distribution-Name
 metacpan_reverse_dependencies.pl --distro Distro-Name
 metacpan_favorite.pl <token> <file>
 metacpan_old.pl
 metacpan_full_dependency_list.pl  Module::Name [more Module::Names]
 metacpan_dependency_tree.pl Module::Name

... or read the articles and check out L<MetaCPAN::API>.

=head1 DESCRIPTION

For an explanation of the L<metacpan_meta.pl> script see L<Fetching META data from Meta CPAN|http://perlmaven.com/fetching-meta-data-from-meta-cpan>.

For the L<metacpan_namespace.pl> see
L<List all the Perl modules and distributions in a name-space using Meta CPAN|http://perlmaven.com/list-all-the-perl-modules-and-distributions-in-a-namespace-using-meta-cpan>.

The L<metacpan_reverse_dependencies.pl> show the list of distributions that use the given distribution.
Code taken from L<Test::DependentModules> of Dave Rolsky.

The metacpan_favorite.pl was created by David Golden and it is explained in
L<How to mass-favorite modules on MetaCPAN|http://www.dagolden.com/index.php/2040/how-to-mass-favorite-modules-on-metacpan/>

The token is taken from L<https://api.metacpan.org/user> (assuming you are logged in) from the key B<access_token>,
B<token>. The input file contains lines of  "Distro-Name AUTHOR release" but it can work with "Distro-Name" alone too.


L<metacpan_dependency_tree.pl> was originally described in L<How to fetch the CPAN dependency
tree of a Perl module?|http://perlmaven.com/how-to-fetch-the-cpan-dependency-tree-of-a-perl-module>

=head1 RESULTS

Some results using these scripts show:

On December 28, 2012 we found that
L<17.4% of CPAN uploads have no license in the META files|http://blogs.perl.org/users/gabor_szabo/2012/12/174-of-cpan-uploads-have-no-license-in-the-meta-files.html>

On January 3, 2013 we found that
L<50% of the new CPAN uploads have a repository link|http://blogs.perl.org/users/gabor_szabo/2013/01/50-of-the-new-cpan-uploads-lack-a-repository-link.html>

On February 5, 2013 we found that still about 16.6% of the L<recent CPAN uploads|http://szabgab.com/license-and-repository-of-cpan-packages-201302.html>
have no license and 50% no repository link in their META files.

=head1 OTHER Examples

If you are interested in other examples using the L<MetaCPAN::API>, check out the
L<list of distributions using MetaCPAN::API|https://metacpan.org/requires/distribution/MetaCPAN-API>

=head1 AUTHOR

L<Gabor Szabo|http://szabgab.com/>

=head1 CONTRIBUTORS

L<David Golden|http://www.dagolden.com/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013- by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;

