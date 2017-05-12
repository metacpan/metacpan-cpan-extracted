package DocSet;

$VERSION = '0.19';

=head1 NAME

DocSet - documentation projects builder in HTML, PS and PDF formats

=head1 SYNOPSIS

  docset_build [options] base_full_path relative_to_base_config_file_location

Options:

  -h    this help
  -v    verbose
  -i    podify pseudo-pod items (s/^* /=item */)
  -s    create the splitted html version (not implemented)
  -t    create tar.gz (not implemented)
  -p    generate PS file
  -d    generate PDF file
  -f    force a complete rebuild
  -a    print available hypertext anchors (not implemented)
  -l    perform L<> links validation in pod docs
  -e    slides mode (for presentations) (not implemented)
  -m    executed from Makefile (forces rebuild,
				no PS/PDF file,
				no tgz archive!)

=head1 DESCRIPTION

This package builds a docset from sources in different formats. The
generated documents can be all nicely interlinked and to have the same
look and feel.

Currently it knows to handle input formats:

* POD
* HTML

and knows to generate:

* HTML
* PS
* PDF

=head2  Modification control

Each output mode maintains its own cache (per docset) which is used
when certain source documents weren't modified since last build and
the build is running in a non-force-rebuild mode.

=head2 Definitions:

* Chapter is a single document (file).

* Link is an URL

* Docset is a collection of docsets, chapters and links.

=head2 Application Specific Features

=over

=item 1

META: not ported yet!

Generate a split version HTML, creating html file for each pod
section, and having everything interlinked of course. This version is
used best for the search.

=item 1

Complete the POD on the fly from the files in POD format. This is used
to ease the generating of the presentations slides, so one can use
C<*> instead of a long =over/=item/.../=item/=back strings. The rest
is done as before. Take a look at the special version of the html2ps
format to generate nice slides in I<conf/html2ps-slides.conf>.

=item 1

If you turn the slides mode on, it automatically turns the C<-i> (C<*>
bullets preprocessing) mode and does a page break before each =head
tag.

=back

=head2 Examples

The package includes two fully working examples in the I<examples/>
directory.

=over

=item site

This example demonstrates a shrinked version of perl.apache.org (which
is genrated entirely by DocSet), with many docs removed or reduced to
the mininumum. There are still quite a lot of documents left so you
can see the big picture. Read I<examples/site/README> for more
information.

=item presentation

This example demonstrates how to build presentations handouts and
slides using DocSet. Read I<examples/presentation/README> for more
information.

=back

=head2 Look-n-Feel Customization

You can customise the look and feel of the ouput by adjusting the
templates in the directory I<examples/site/tmpl/custom>.

You can change look and feel of the PS (PDF) versions by modifying
I<examples/site/conf/html2ps.conf>.  Be careful that if your
documentation that you want to put in one PS or PDF file is very big
and you tell html2ps to put the TOC at the beginning you will need
lots of memory because it won't write a single byte to the disk before
it gets all the HTML markup converted to PS.


=head1 CONFIGURATION

All you have to prepare is a single config file that you then pass as
an argument to C<docset_build>:

  % docset_build [options] base_full_path relative_to_base_config_file_location

Every directory in the source tree may have a configuration file,
which designates a docset's root. See the I<config> files for
examples. Usually the file in the root (I<examples/site/src>) sets
operational directories and other arguments, which you don't have to
repeat in sub-docsets. You want to redefine the build attributes in
nested docsets if you want to override certain configuration
attributes. Modify these files to suit your documentation project
layout.

Note that the smart I<examples/site/bin/build> script automatically
locates your project's directory, so you can move your project around
filesystem without changing anything. So you really build with:

  % bin/build [options]

I<examples/site/README> explains the layout of the directories.

C<DocSet::Config> manpage explains the layout of the configuration
file.

=head1 Extending

Read the other manpages for more information about how to extend
Docset.

=head1 PREREQUISITES

The following are the optional prerequisites:

=over 4

=item * ps2pdf

Needed to generate the PDF version.

=item * Storable

Available from CPAN (http://cpan.org/) and is a part of the core Perl
distribution of the Perl 5.8.0 and higher.

Allows source modification control, so if you modify only one file you
will not have to rebuild everything to get the updated HTML/PS/PDF
files.

=back

=head1 SUPPORT

Notice that this tool relies on two tools (C<ps2pdf> and C<html2ps>)
which I don't support, since I didn't write them. So if you have any
problem first make sure that it's not a problem of these tools.

Note that while C<html2ps> is included in this distribution, it's
written in the old style Perl, so if you have patches send them along,
but I won't try to fix/modify this code otherwise. For more info see:
http://www.tdb.uu.se/~jan/html2ps.html

=head1 BUGS

Huh? Probably many...

=head1 QUESTIONS

Questions can be asked at the template-docset mailing list. For
mailing list archives and subscription information please see:
http://template-toolkit.org/mailman/listinfo/template-docset

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=head1 SEE ALSO

perl(1), Pod::POM(3), Pod::HTML(3), html2ps(1), ps2pod(1), Storable(3)

=head1 COPYRIGHT

This program is distributed under the Artistic License, like the Perl
itself.

=cut
