#-----------------------------------------------------------------
# Dist::Zilla::Plugin::Pod2Html
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer in the POD.
#
# ABSTRACT: create CSS-rich HTML pages from the POD-aware files
# PODNAME: Dist::Zilla::Plugin::Pod2Html
#-----------------------------------------------------------------
use warnings;
use strict;
package Dist::Zilla::Plugin::Pod2Html;
our $VERSION = '0.1.2'; # VERSION

use Moose;
use Moose::Autobox;
use PPI;
use File::Basename;
use File::Spec;
use Pod::Simple::HTML;
use Encode qw( encode );
use Dist::Zilla::File::InMemory;

with ('Dist::Zilla::Role::InstallTool',          # will be done after PodWeaver
      'Dist::Zilla::Role::FileFinderUser' => {   # where to take input files from
          default_finders => [ ':InstallModules', ':ExecFiles' ],
      },
    );

sub mvp_multivalue_args { return qw( ignore ) }

# ------------------------------------------------------------------
# Where to create HTML output files.
# ------------------------------------------------------------------
has dir => (
    is      => 'ro',
    isa     => 'Str',
    default => 'docs',
);

# ------------------------------------------------------------------
# Which input files to ignore.
# ------------------------------------------------------------------
has ignore => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

# ------------------------------------------------------------------
# Return $file if it could be an input file for us. Otherwise return
# undef. (Partly taken from Dzill::Zilla::Plugin::MinimumPerl)
# ------------------------------------------------------------------
sub is_interesting_file {
    my ($self, $file) = @_;

    return       if $file->name    =~ m{^corpus/};
    return       if $file->name    =~ m{\.t$}i;
    return       if @{ $self->ignore->grep ( sub { $_ eq $file->name } )} > 0;
    return $file if $file->name    =~ m{\.(?:pm|pl)$}i;
    return $file if $file->content =~ m{^#!(?:.*)perl(?:$|\s)};
    return;
}

# ------------------------------------------------------------------
# The main job
# ------------------------------------------------------------------
sub setup_installer {
    my ($self, $arg) = @_;

    $self->log_debug ("Attribute DIR:    " . $self->dir);
    $self->log_debug ("Attribute IGNORE: " . join (" | ", @{ $self->ignore }));

    my $result_count = 0;
    my $files = $self->found_files;
    foreach my $file (@$files) {
        next unless $self->is_interesting_file ($file);
        my $content = $file->content;
        my $document = PPI::Document->new (\$content);
        if ($document) {
            # does it contain any POD?
            if ($document->find_any ('PPI::Token::Pod')) {
                my $new_file = Dist::Zilla::File::InMemory->new ({
                    content => $self->pod2html ($file),
                    name    => $self->output_filename ($file),
                                                                 });
                $self->add_file ($new_file);
                $result_count++;
            }
        }
    }
    $self->log("$result_count documentation files created in '" . $self->dir . "'");
    return;
}

# ------------------------------------------------------------------
# Create and return a suitable name for the output file for the given
# input $file.
# ------------------------------------------------------------------
sub output_filename {
    my ($self, $file) = @_;

    my ($basename, $path, $suffix) = fileparse ($file->name, qr{\.[^.]*});
    $path =~ s{^(lib|bin)[/\\]}{};
    $path =~ s{[/\\]}{-}g;
    return File::Spec->catfile (
        $self->dir,
        "$path$basename.html"
        );
}

# ------------------------------------------------------------------
# Convert the content of the $file to the HTML output, and return it.
# ------------------------------------------------------------------
sub pod2html {
    my ($self, $file) = @_;

    # CSS-style to be added to the resulting files
    my $style = $self->get_css_style();

    # make the POD to HTML conversion
    my $result;
    my $parser = Pod::Simple::HTML->new;
    $parser->index (1);
    $parser->html_css ("\n$style\n");
    $parser->output_string (\$result);
    $parser->parse_string_document ($file->content);

    # ...and perhaps encode it
    if (defined $parser->{encoding}) {
        return encode ($parser->{encoding} , $result);
     } else {
         return $result;
     }
}

# ------------------------------------------------------------------
# Return a string containing CSS-style to be added to the resulting
# HTML files. It is read from the <DATA> section of this module
# (unless a subclass overwrites this method).
# ------------------------------------------------------------------
my $Style;  # global (we can read <DATA> only once)
sub get_css_style {
    my $self = shift;
    unless ($Style) {
        my @style = <DATA>;
        $Style = join ("", @style);
    }
    return $Style;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;




=pod

=head1 NAME

Dist::Zilla::Plugin::Pod2Html - create CSS-rich HTML pages from the POD-aware files

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    # dist.ini
    [Pod2Html]

    # or
    [Pod2Html]
    dir = my_docs   ; where to create HTML files

    # or
    [Pod2Html]
    ignore = bin/myscript1   ; what input file to ignore
    ignore = bin/myscript2   ; another input to ignore

=head1 DESCRIPTION

This plugin generates HTML pages from the POD files and puts them into
the distribution in a separate directory (not as a tree of files but
flatten). The created HTML pages have the same (or, at least, similar)
style as the modules' documentation shown at CPAN.

It creates HTML pages from all files in the C<lib> and C<bin>
directory that contain a POD section and that have C<.pm> or C<.pl>
extension or that have the word C<perl> in their first line. The
plugin is run after other plugins that may munge files and create the
POD sections (such as I<PodWeaver>).

=head1 ATTRIBUTES

All attributes are optional.

=head3 dir

This attribute changes the destination of the generated HTML files. It
is a directory (or even a path) relative to the distribution root
directory. Default value is C<docs>. For example:

    [Pod2Html]
    dir = docs/html

=head3 ignore

This attribute allows to ignore some input files that would be
otherwise converted to HTML. Its value is a file name that should be
ignored (relative to the distribution root directory). By default no
(appropriate) files are ignored. The attribute can be repeated if you
wish to ignore more files. For example:

    [Pod2Html]
    ignore = lib/My/Sample.pm
    ignore = bin/obscure-script

=head1 SUBCLASSING

New plugins can be created by subclassing this plugin. The subclass
may consider to overwrite following methods:

=head3 is_interesting_file ($file)

The method decides (by returning something or undef) whether the given
file should be a candidate for the conversion to the HTML. The
parameter is a blessed object with the C<Dist::Zilla::Role::File>
role.

=head3 pod2html ($file)

This method does the conversion to the HTML (using module
C<Pod::Simple::HTML>). It gets an input file (a blessed object with
the C<Dist::Zilla::Role::File> role) and it should return a converted
content. By overwriting this method a new plugin can make any
conversion, to anything.

=head3 get_css_style

It returns a string containing CSS-style definitions. The string will
be used in the C<head> section of the created HTML file. See its
default value in the I<__DATA__> section of this module.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
<style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
BODY {
  background: white;
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}

A:link, A:visited {
  background: transparent;
  color: #006699;
}

A[href="#POD_ERRORS"] {
  background: transparent;
  color: #FF0000;
}

DIV {
  border-width: 0;
}

DT {
  margin-top: 1em;
  margin-left: 1em;
}

.pod { margin-right: 20ex; }

.pod PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding: 1em;
  white-space: pre;
}

.pod H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}

.pod H1 A { text-decoration: none; }
.pod H2 A { text-decoration: none; }
.pod H3 A { text-decoration: none; }
.pod H4 A { text-decoration: none; }

.pod H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}

.pod H3      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-style: italic;
}

.pod H4      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-weight: normal;
}

.pod IMG     {
  vertical-align: top;
}

.pod .toc A  {
  text-decoration: none;
}

.pod .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}

  /*]]>*/-->
</style>
