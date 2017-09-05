use v5.24;

package Dist::Zilla::Plugin::LocalHTML;

# ABSTRACT: create CSS-rich HTML pages from the POD-aware files for local browsing

our $VERSION = 'v0.1.1';


use Moose::Autobox;
use PPI;
use File::Basename;
use File::Spec;
use Encode qw( encode );
use Dist::Zilla::File::InMemory;

use Moose;
use namespace::autoclean;
with(
    'Dist::Zilla::Role::InstallTool',    # will be done after PodWeaver
    'Dist::Zilla::Role::FileFinderUser' => {    # where to take input files from
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
);

sub mvp_multivalue_args { return qw( ignore local_prefix ) }

has dir => (
    is      => 'ro',
    isa     => 'Str',
    default => 'docs',
);

has local_prefix => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has pod2html_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Dist::Zilla::Plugin::LocalHTML::Pod2HTML',
);

has ignore => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

sub is_interesting_file {
    my ( $this, $file ) = @_;

    return       if $file->name =~ m{^corpus/};
    return       if $file->name =~ m{\.t$}i;
    return       if @{ $this->ignore->grep ( sub { $_ eq $file->name } ) } > 0;
    return $file if $file->name =~ m{\.(?:pm|pl)$}i;
    return $file if $file->content =~ m{^#!(?:.*)perl(?:$|\s)};
    return;
}

sub setup_installer {
    my ( $this, $arg ) = @_;

    $this->log_debug( "Attribute DIR:    " . $this->dir );
    $this->log_debug(
        "Attribute IGNORE: " . join( " | ", @{ $this->ignore } ) );

    my $result_count = 0;
    my $files        = $this->found_files;
    foreach my $file (@$files) {
        next unless $this->is_interesting_file($file);
        my $content  = $file->content;
        my $document = PPI::Document->new( \$content );
        if ($document) {

            # does it contain any POD?
            if ( $document->find_any('PPI::Token::Pod') ) {
                my $new_file = Dist::Zilla::File::InMemory->new(
                    {
                        content => $this->pod2html($file),
                        name    => $this->output_filename($file),
                    }
                );
                $this->add_file($new_file);
                $result_count++;
            }
        }
    }
    $this->log(
        "$result_count documentation files created in '" . $this->dir . "'" );
    return;
}

sub base_filename {
    my ( $this, $file ) = @_;

    my $file_name = ref($file) ? $file->name : $file;
    my ( $vol, $path, $basename ) = File::Spec->splitpath($file_name);
    $basename =~ s{(\.[^.]*)?$}{}n;
    $path = File::Spec->canonpath($path);
    my @dirs = File::Spec->splitdir($path);
    shift @dirs if @dirs && $dirs[0] =~ /^(lib|bin|scripts)$/n;
    return join( "-", @dirs, "$basename.html" );
}

sub output_filename {
    my ( $this, $file ) = @_;

    return File::Spec->catfile( $this->dir, $this->base_filename($file) );
}

sub pod2html {
    my ( $this, $file ) = @_;

    # CSS-style to be added to the resulting files
    my $style = $this->get_css_style();

    # make the POD to HTML conversion
    my $result;
    my $class = $this->pod2html_class;
    eval "require $class";
    die $@ if $@;
    my $parser = $class->new( callerPlugin => $this );
    $parser->index(1);
    $parser->html_css("\n$style\n");
    $parser->output_string( \$result );
    $parser->parse_string_document( $file->content );

    # ...and perhaps encode it
    if ( defined $parser->{encoding} ) {
        return encode( $parser->{encoding}, $result );
    }
    else {
        return $result;
    }
}

my $Style;    # global (we can read <DATA> only once)

sub get_css_style {
    my $this = shift;
    unless ($Style) {
        my @style = <DATA>;
        $Style = join( "", @style );
    }
    return $Style;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LocalHTML - create CSS-rich HTML pages from the POD-aware files for local browsing

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

    # dist.ini
    [LocalHTML]
    local_prefix = Dist::Zilla::
    local_preifx = MyProject\b
    dir = html_local   ; where to create HTML files
    ignore = bin/myscript1   ; what input file to ignore
    ignore = bin/myscript2   ; another input to ignore

=head1 DESCRIPTION

I<This plugin is based upon L<Dist::Zilla::Plugin::Pod2Html>. Check for more
info below.>

This plugin generates HTML pages from the POD files and puts them into
the distribution in a separate directory (not as a tree of files but
flatten). The created HTML pages have the same (or, at least, similar)
style as the modules' documentation shown at CPAN. They're also suitable for
local browsing meaning linking between pages is local to the file system meaning
that pages are browsable without any webserver or posting a module to CPAN.
This could be especially handy for developers using unicode in their docs as
sometimes it is not displayed correctly with perldoc – like on macOS systems.

It creates HTML pages from all files in the C<lib> and C<bin>
directory that contain a POD section and that have C<.pm> or C<.pl>
extension or that have the word C<perl> in their first line. The
plugin is run after other plugins that may munge files and create the
POD sections (such as I<PodWeaver>).

The plugin overrides Pod::Simple::HTML link generation. By distinguishing local
and remote links it generates either a simple reference to local filesystem, or
a reference to metacpan.org. Link is conisdered local if there is a corresponding
file for the original C<<L<>>> Pod tag. For example, of the following to links:

    L<Local::Project::Module>
    L<Local::Project::NoModule>

the first one is considered local if there is file
F<lib/Local/Project/Module.pm>; the second one would get linked to metacpan.org
if there is no file F<lib/Local/Project/NoModule.pm>.

Link type could additionally be determined by L</local_prefix> configuration
variable.

=head1 ATTRIBUTES

=head2 C<dir>

This attribute changes the destination of the generated HTML files. It
is a directory (or even a path) relative to the distribution root
directory. Default value is C<docs>. For example:

    [LocalHTML]
    dir = docs/html

=head2 C<local_prefix>

What modules to consider as local - i.e. part of the current project. Few
prefixes could be defined. Each one could be a regexp expression. A module
is considered local if it matches against one of the local prefixes. Note
that match is done agains the beginning of module name.

    [LocalHTML]
    local_prefix=My::Project::
    local_prefix=My\d::Project\b

The above expressions will match against:

=over 4

=item B<My::Project::Module>

=item B<My2::Project-A>

=back

B<NOTE> There is no way yet to define local status for files other that modules.
Solution is planned for future.

=head2 C<pod2html_class>

Class to be used for HTML generation. Must be a descendant of
L<Pod::Simple::HTML>. L<Dist::Zilla::Plugin::LocalHTML::Pod2HTML> is used by
default.

=head2 C<ignore>

This attribute allows to ignore some input files that would be
otherwise converted to HTML. Its value is a file name that should be
ignored (relative to the distribution root directory). By default no
(appropriate) files are ignored. The attribute can be repeated if you
wish to ignore more files. For example:

    [LocalHTML]
    ignore = lib/My/Sample.pm
    ignore = bin/obscure-script

=head1 METHODS

=head2 C<is_interesting_file>

The method decides (by returning something or undef) whether the given
file should be a candidate for the conversion to the HTML. The
parameter is a blessed object with the C<Dist::Zilla::Role::File>
role.

=head2 C<setup_installer>

The main job

=head2 C<base_filename( $file )>

Returns base name of HTML file formed of source file path. Rules are:

=over 4

=item 1. Suffix is stripped off

=item 2. Leading F<lib>, F<bin>, or F<script> subdir is removed.

=item 3. Remaining elements are joined with a dash symbol.

=back

The result gets appenede with F<.html>

=head2 C<output_filename( $file )>

Create and return a suitable name for the output file for the given input $file.

=head2 C<pod2html( $file )>

This method does the conversion to the HTML (using module defined by
C<pod2html_class>). It gets an input file (a blessed object with
the C<Dist::Zilla::Role::File> role) and it should return a converted
content. By overwriting this method a new plugin can make any
conversion, to anything.

=head2 C<get_css_style()>

It returns a string containing CSS-style definitions. The string will
be used in the C<head> section of the created HTML file. See its
default value in the I<__DATA__> section of this module.

=head1 ACKNOWLEDGEMENT

This plugin is a rewrite of L<Dist::Zilla::Plugin::Pod2Html>. I would like to
express my deepest gratitude to Martin Senger <martin.senger@gmail.com> for his
great work! The original copyright for L<Dist::Zilla::Plugin::Pod2Html> follows.

I<
This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..
>

=head1 AUTHOR

Vadim Belman <vrurg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vadim Belman.

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

