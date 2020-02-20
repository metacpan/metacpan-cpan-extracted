package HTML::DeferableCSS;

# ABSTRACT: Simplify management of stylesheets in your HTML

use v5.10;
use Moo 1.006000;

use Carp qw/ croak /;
use Devel::StrictMode;
use File::ShareDir 1.112 qw/ dist_file /;
use MooX::TypeTiny;
use List::Util 1.45 qw/ first uniqstr /;
use Path::Tiny;
use Types::Path::Tiny qw/ Dir File Path /;
use Types::Common::Numeric qw/ PositiveOrZeroInt /;
use Types::Common::String qw/ NonEmptySimpleStr SimpleStr /;
use Types::Standard qw/ Bool CodeRef HashRef Maybe Tuple /;

# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean;

our $VERSION = 'v0.2.0';



has aliases => (
    is       => 'ro',
    isa      => STRICT ? HashRef [Maybe[SimpleStr]] : HashRef,
    required => 1,
);


has css_root => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);


has url_base_path => (
    is      => 'ro',
    isa     => SimpleStr,
    default => '/',
);


has prefer_min => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has css_files => (
    is  => 'lazy',
    isa => STRICT
             ? HashRef [ Tuple [ Maybe[Path], NonEmptySimpleStr, PositiveOrZeroInt ] ]
             : HashRef,
    builder => 1,
    coerce  => 1,
);

use constant PATH => 0;
use constant NAME => 1;
use constant SIZE => 2;

sub _build_css_files {
    my ($self) = @_;

    my $root = $self->css_root;
    my $min  = !$self->prefer_min;

    my %files;
    for my $name (keys %{ $self->aliases }) {
        my $base  = $self->aliases->{$name} or next;
        if ($base =~ m{^(\w+:)?//}) {
            $files{$name} = [ undef, $base, 0 ];
        }
        else {
            $base = $name if $base eq '1';
            my @bases = ( $base );
            unshift @bases, "${base}.css" unless $base =~ /\.css$/;
            unshift @bases, "${base}.min.css" unless $min || $base =~ /\.min\.css$/;
            my $file = first { $_->exists } map { path( $root, $_ ) } @bases;
            unless ($file) {
                croak "alias '$name' refers to a non-existent file";
            }
            # PATH NAME SIZE
            $files{$name} = [ $file, $file->relative($root)->stringify, $file->stat->size ];
        }
    }

    return \%files;
}


has cdn_links => (
    is        => 'ro',
    isa       => STRICT ? HashRef [NonEmptySimpleStr] : HashRef,
    predicate => 1,
);


has use_cdn_links => (
    is      => 'lazy',
    isa     => Bool,
    builder => 'has_cdn_links',
);


has inline_max => (
    is      => 'ro',
    isa     => PositiveOrZeroInt,
    default => 1024,
);


has defer_css => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has include_noscript => (
    is      => 'lazy',
    isa     => Bool,
    builder => 'defer_css',
);


has preload_script => (
    is      => 'lazy',
    isa     => File,
    coerce  => 1,
    builder => sub { dist_file( qw/ HTML-DeferableCSS cssrelpreload.min.js / ) },
);


has link_template => (
    is      => 'ro',
    isa     => CodeRef,
    builder => sub {
        return sub { sprintf('<link rel="stylesheet" href="%s">', @_) },
    },
);



has preload_template => (
    is      => 'ro',
    isa     => CodeRef,
    builder => sub {
        return sub { sprintf('<link rel="preload" as="style" href="%s" onload="this.onload=null;this.rel=\'stylesheet\'">', @_) },
    },
);


has asset_id => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => 1,
);


sub href {
    my ($self, $name, $file) = @_;
    croak "missing name" unless defined $name;
    $file //= $self->css_files->{$name};
    croak "invalid name '$name'" unless defined $file;
    if (defined $file->[PATH]) {
        my $href = $self->url_base_path . $file->[NAME];
        $href .= '?' . $self->asset_id if $self->has_asset_id;
        if ($self->use_cdn_links && $self->has_cdn_links) {
            return $self->cdn_links->{$name} // $href;
        }
        return $href;
    }
    else {
        return $file->[NAME];
    }
}


sub link_html {
    my ( $self, $name, $file ) = @_;
    return $self->link_template->( $self->href( $name, $file ) );
}


sub inline_html {
    my ( $self, $name, $file ) = @_;
    croak "missing name" unless defined $name;
    $file //= $self->css_files->{$name};
    croak "invalid name '$name'" unless defined $file;
    if (my $path = $file->[PATH]) {
        return "<style>" . $file->[PATH]->slurp_raw . "</style>";
    }
    else {
        croak "'$name' refers to a URI";
    }
}


sub link_or_inline_html {
    my ($self, @names ) = @_;
    foreach my $name (@names) {
        croak "missing name" unless defined $name;
        my $file = $self->css_files->{$name};
        croak "invalid name '$name'" unless defined $file;
        if ($file->[SIZE] <= $self->inline_max) {
            return $self->inline_html($name, $file);
        }
        else {
            return $self->link_html($name, $file);
        }
    }
}


sub deferred_link_html {
    my ($self, @names) = @_;
    my $buffer = "";
    my @deferred;
    for my $name (uniqstr @names) {
        my $file = $self->css_files->{$name} or croak "invalid name '$name'";
        if ($file->[SIZE] <= $self->inline_max) {
            $buffer .= $self->inline_html($name, $file);
        }
        elsif ($self->defer_css) {
            my $href = $self->href($name, $file);
            push @deferred, $href;
            $buffer .= $self->preload_template->($href);
        }
        else {
            $buffer .= $self->link_html($name, $file);
        }
    }

    if (@deferred) {

        $buffer .= "<noscript>" .
            join("", map { $self->link_template->($_) } @deferred ) .
            "</noscript>" if $self->include_noscript;

        $buffer .= "<script>" .
            $self->preload_script->slurp_raw .
            "</script>";

    }

    return $buffer;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::DeferableCSS - Simplify management of stylesheets in your HTML

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

  use HTML::DeferableCSS;

  my $css = HTML::DeferableCSS->new(
      css_root      => '/var/www/css',
      url_base_path => '/css',
      inline_max    => 512,
      aliases => {
        reset => 1,
        jqui  => 'jquery-ui',
        site  => 'style',
      },
      cdn => {
        jqui  => '//cdn.example.com/jquery-ui.min.css',
      },
  );

  ...

  print $css->deferred_link_html( qw[ jqui site ] );

=head1 DESCRIPTION

This is an experimental module for generating HTML-snippets for
deferable stylesheets.

This allows the stylesheets to be loaded asynchronously, allowing the
page to be rendered faster.

Ideally, this would be a simple matter of changing stylesheet links
to something like

  <link rel="preload" as="stylesheet" href="....">

but this is not well supported by all web browsers. So a web page
needs some JavaScript to handle this, as well as a C<noscript> block
as a fallback.

This module allows you to simplify the management of stylesheets for a
web application, from development to production by

=over

=item *

declaring all stylesheets used by your web application;

=item *

specifying remote aliases for stylesheets, e.g. from a CDN;

=item *

enable or disable the use of minified stylesheets;

=item *

switch between local copies of stylesheets or CDN versions;

=item *

automatically inline small stylesheets;

=item *

use deferred-loading stylesheets, which requires embedding JavaScript
code as a workaround for web browsers that do not support these
natively.

=back

=head1 ATTRIBUTES

=head2 aliases

This is a required hash reference of names and their relative
filenames to L</css_root>.

It is recommended that the F<.css> and F<.min.css> suffixes be
omitted.

If the name is the same as the filename (without the extension) than
you can simply use C<1>.  (Likewise, an empty string or C<0> disables
the alias.)

Absolute paths cannot be used.

You may specify URLs instead of files, but this is not recommended,
except for cases when the files are not available locally.

=head2 css_root

This is the required root directory where all stylesheets can be
found.

=head2 url_base_path

This is the URL prefix for stylesheets.

It can be a full URL prefix.

=head2 prefer_min

If true (default), then a file with the F<.min.css> suffix will be
preferred, if it exists in the same directory.

Note that this does not do any minification. You will need separate
tools for that.

=head2 css_files

This is a hash reference used internally to translate L</aliases>
into the actual files or URLs.

If files cannot be found, then it will throw an error.

=head2 cdn_links

This is a hash reference of L</aliases> to URLs.

When L</use_cdn_links> is true, then these URLs will be used instead
of local versions.

=head2 has_cdn_links

This is true when there are L</cdn_links>.

=head2 use_cdn_links

When true, this will prefer CDN URLs instead of local files.

=head2 inline_max

This specifies the maximum size of an file to inline.

Local files under the size will be inlined using the
L</link_or_inline_html> or L</deferred_link_html> methods.

Setting this to 0 disables the use of inline links, unless
L</inline_html> is called explicitly.

=head2 defer_css

True by default.

This is used by L</deferred_link_html> to determine whether to emit
code for deferred stylesheets.

=head2 include_noscript

When true, a C<noscript> element will be included with non-deffered
links.

This defaults to the same value as L</defer_css>.

=head2 preload_script

This is the pathname of the F<cssrelpreload.js> file that will be
embedded in the resulting code.

You do not need to modify this unless you want to use a different
script from the one included with this module.

=head2 link_template

This is a code reference for a subroutine that returns a stylesheet link.

=head2 preload_template

This is a code reference for a subroutine that returns a stylesheet
preload link.

=head2 asset_id

This is an optional static asset id to append to local links. It may
refer to a version number or commit-id, for example.

This is useful to ensure that changes to stylesheets are picked up by
web browsers that would otherwise use cached copies of older versions
of files.

=head2 has_asset_id

True if there is an L</asset_id>.

=head1 METHODS

=head2 href

  my $href = $css->href( $alias );

This returns this URL for an alias.

=head2 link_html

  my $html = $css->link_html( $alias );

This returns the link HTML markup for the stylesheet referred to by
C<$alias>.

=head2 inline_html

  my $html = $css->inline_html( $alias );

This returns an embedded stylesheet referred to by C<$alias>.

=head2 link_or_inline_html

  my $html = $css->link_or_inline_html( @aliases );

This returns either the link HTML markup, or the embedded stylesheet,
if the file size is not greater than L</inline_max>.

=head2 deferred_link_html

  my $html = $css->deferred_link_html( @aliases );

This returns the HTML markup for the stylesheets specified by
L</aliases>, as appropriate for each stylesheet.

If the stylesheets are not greater than L</inline_max>, then it will
embed them.  Otherwise it will return the appropriate markup,
depending on L</defer_css>.

=for Pod::Coverage PATH NAME SIZE

=head1 KNOWN ISSUES

=head2 XHTML Support

This module is written for HTML5.

It does not support XHTML self-closing elements or embedding styles
and scripts in CDATA sections.

=head2 Encoding

All files are embedded as raw files.

No URL encoding is done on the HTML links or L</asset_id>.

=head2 It's spelled "Deferrable"

It's also spelled "Deferable".

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/HTML-DeferableCSS>
and may be cloned from L<git://github.com/robrwo/HTML-DeferableCSS.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/HTML-DeferableCSS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

F<reset.css> comes from L<http://meyerweb.com/eric/tools/css/reset/>.

F<cssrelpreload.js> comes from L<https://github.com/filamentgroup/loadCSS/>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The MIT (X11) License

=cut
