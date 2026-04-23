package Developer::Dashboard::Zipper;

use strict;
use warnings;

our $VERSION = '3.04';

use Exporter 'import';
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use URI::Escape qw(uri_escape);

use Developer::Dashboard::Codec qw(encode_payload decode_payload);

our @EXPORT = qw(zip unzip _cmdx _cmdp __cmdx acmdx Ajax);
our $AJAX_CONTEXT = {};

# zip($text)
# Encodes a text payload to the older token structure.
# Input: plain text string.
# Output: hash with raw and url token values.
sub zip {
    my ($text) = @_;
    return if !defined $text || $text eq '';
    my $raw = encode_payload($text);
    return {
        raw => $raw,
        url => uri_escape($raw),
    };
}

# unzip($token)
# Decodes a older token payload back to text.
# Input: encoded token string.
# Output: plain text string.
sub unzip {
    my ($token) = @_;
    return if !defined $token || $token eq '';
    return decode_payload($token);
}

# acmdx(%args)
# Builds a older ajax/action URL bundle for encoded code execution.
# Input: path, type, target, label, code, and optional app/save/base_url/singleton values.
# Output: hash with token, url, forward, and html keys.
sub acmdx {
    my %args = @_;
    my $type = $args{type} || 'text';
    my $path = $args{path} || '/ajax';
    my $code = $args{code} // '';
    my $base = $args{base_url} || '';
    my $token = zip($code) || { raw => '', url => '' };
    my $query = sprintf '%s?token=%s&type=%s', $path, $token->{url}, uri_escape($type);
    if ( defined $args{singleton} && $args{singleton} ne '' ) {
        $query .= '&singleton=' . uri_escape( $args{singleton} );
    }
    my $url = $base ? $base . $query : $query;
    return {
        token   => $token,
        url     => { tokenised => $url, app => $args{app} || $url },
        forward => [ $path => { token => $token->{raw}, type => $type } ],
        html    => sprintf( q{<a href="%s" target="%s">%s</a>}, $url, ( $args{target} || '_blank' ), ( $args{label} || 'Click Here' ) ),
    };
}

# Ajax(%args)
# Prints a older config-binding script for an encoded ajax endpoint.
# Input: jvar, type, optional file/singleton names, and optional code values.
# Output: hide marker string.
sub Ajax {
    my %args = @_;
    die "jvar is required" if !$args{jvar};
    my $type = $args{type} || 'text';
    my $context = ref($AJAX_CONTEXT) eq 'HASH' ? $AJAX_CONTEXT : {};
    if ( ( $context->{source} || '' ) eq 'saved' && ( $context->{page_id} || '' ) ne '' ) {
        my $file = $args{file} || '';
        if ( $file eq '' && !( $context->{allow_transient_urls} || 0 ) ) {
            die "file is required for saved bookmark Ajax when transient URL tokens are disabled";
        }
        if ( $file ne '' ) {
            my $saved = defined $args{code}
              ? _saved_ajax_url_and_store(
                file         => $file,
                page_id      => $context->{page_id},
                runtime_root => $context->{runtime_root} || '',
                type         => $type,
                code         => $args{code},
                singleton    => $args{singleton},
                base_url     => $args{base_url} || '',
              )
              : _saved_ajax_url(
                file      => $file,
                page_id   => $context->{page_id},
                type      => $type,
                singleton => $args{singleton},
                base_url  => $args{base_url} || '',
                );
                my ( $root, $path ) = split /\./, $args{jvar}, 2;
                $path ||= '';
                print sprintf qq{<script>set_chain_value(%s,'%s','%s')</script>}, $root, $path, $saved->{url};
                print sprintf qq{<script>dashboard_ajax_singleton_cleanup('%s')</script>}, _js_single_quote( $args{singleton} )
                  if defined $args{singleton} && $args{singleton} ne '';
                return 'HIDE-THIS';
            }
        }
    my $ajax = acmdx(
        %args,
        path => '/ajax',
        type => $type,
    );
    my ( $root, $path ) = split /\./, $args{jvar}, 2;
    $path ||= '';
    print sprintf qq{<script>set_chain_value(%s,'%s','%s')</script>}, $root, $path, $ajax->{url}{tokenised};
    return 'HIDE-THIS';
}

# _js_single_quote($text)
# Escapes one scalar so it is safe inside a single-quoted JavaScript string literal.
# Input: plain scalar string.
# Output: escaped string.
sub _js_single_quote {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return $text;
}

# saved_ajax_file_path(%args)
# Resolves the dashboards ajax-tree file path for a saved bookmark Ajax handler.
# Input: runtime_root and file name.
# Output: absolute file path string.
sub saved_ajax_file_path {
    my (%args) = @_;
    my $runtime_root = $args{runtime_root} || die 'runtime_root is required';
    my $file         = _validate_saved_ajax_file( $args{file} );
    return File::Spec->catfile( $runtime_root, 'dashboards', 'ajax', split( '/', $file ) );
}

# load_saved_ajax_code(%args)
# Loads stored code for a saved bookmark Ajax handler.
# Input: runtime_root and file name.
# Output: code string or undef when missing.
sub load_saved_ajax_code {
    my (%args) = @_;
    my $path = saved_ajax_file_path(%args);
    return if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $code = <$fh>;
    close $fh;
    return $code;
}

# _saved_ajax_url(%args)
# Builds the stable runtime URL for one saved bookmark Ajax handler.
# Input: file, type, and optional base_url/singleton values.
# Output: hash reference with url string.
sub _saved_ajax_url {
    my (%args) = @_;
    my $query = sprintf '/ajax/%s?type=%s',
      uri_escape( _validate_saved_ajax_file( $args{file} ) ),
      uri_escape( $args{type} || 'text' );
    if ( defined $args{singleton} && $args{singleton} ne '' ) {
        $query .= '&singleton=' . uri_escape( $args{singleton} );
    }
    return {
        url => ( $args{base_url} || '' ) . $query,
    };
}

# _saved_ajax_url_and_store(%args)
# Stores saved bookmark Ajax code under the dashboards ajax tree and returns the stable runtime URL.
# Input: runtime_root, file, type, code, and optional base_url/singleton values.
# Output: hash reference with url and file path.
sub _saved_ajax_url_and_store {
    my (%args) = @_;
    my $path = saved_ajax_file_path(%args);
    my $dir = dirname($path);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} defined $args{code} ? $args{code} : '';
    close $fh;
    chmod 0700, $path or die "Unable to chmod $path: $!";
    return {
        path => $path,
        %{ _saved_ajax_url(%args) },
    };
}

# _validate_saved_ajax_file($file)
# Validates a relative saved bookmark Ajax file name for stable dashboards ajax-tree storage.
# Input: requested file name string.
# Output: normalized relative file name string.
sub _validate_saved_ajax_file {
    my ($file) = @_;
    die "file is required" if !defined $file || $file eq '';
    die "file must be relative" if File::Spec->file_name_is_absolute($file);
    die "file contains invalid parent traversal" if $file =~ m{(?:\A|/)\.\.(?:/|\z)};
    die "file contains invalid characters" if $file !~ m{\A[A-Za-z0-9][A-Za-z0-9._/-]*\z};
    return $file;
}

# __cmdx($type, $code)
# Returns a shell pipeline string that decodes an encoded payload.
# Input: type string and code string.
# Output: shell command string.
sub __cmdx {
    my ( $type, $code ) = @_;
    my $token = zip($code) || { raw => '' };
    return "printf '%s' " . quotemeta( $token->{raw} ) . " | base64 -d | gunzip";
}

# _cmdx($type, $code)
# Returns older shell execution tuple values.
# Input: type string and code string.
# Output: list of shell tuple values.
sub _cmdx {
    my ( $type, $code ) = @_;
    my $switch = $type eq 'perl' ? '-e' : '-c';
    return ( $type, $switch, __cmdx( $type, $code ) );
}

# _cmdp($type, $code)
# Returns older shell pipeline tuple values.
# Input: type string and code string.
# Output: list of pipeline tuple values.
sub _cmdp {
    my ( $type, $code ) = @_;
    return ( __cmdx( $type, $code ), $type );
}

1;

__END__

=head1 NAME

Developer::Dashboard::Zipper - older token encoding and ajax URL compatibility helpers

=head1 SYNOPSIS

  use Developer::Dashboard::Zipper qw(zip unzip Ajax);
  my $token = zip("print qq{ok\\n};");

=head1 DESCRIPTION

This module recreates the small token and ajax helper surface expected by
older bookmark code without carrying forward any project-specific logic.

=head1 FUNCTIONS

=head2 zip, unzip, acmdx, Ajax, __cmdx, _cmdx, _cmdp

Encode and decode token payloads and generate older-style ajax links. Saved
bookmark Ajax file handlers are stored under the dashboards ajax tree as
executable files so the web runtime can run them as real processes.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module keeps the older bookmark and Ajax helper compatibility surface alive. It builds tokenised URLs, saved Ajax endpoints, and helper snippets such as C<Ajax()> while routing the actual encoding work through the modern codec module.

=head1 WHY IT EXISTS

It exists because older bookmarks still expect the historical helper names and URL-building patterns. Keeping those wrappers in one module preserves compatibility without forcing newer runtime code to keep re-implementing the old API directly.

=head1 WHEN TO USE

Use this file when changing older Ajax helper behavior, saved Ajax file validation, token URL generation, or the compatibility wrappers that older bookmark instructions still reference.

=head1 HOW TO USE

Import the specific helper you need, such as C<zip>, C<unzip>, or C<Ajax>, and let this module generate the compatibility structure or snippet. Newer code should prefer the lower-level runtime and codec modules where possible.

=head1 WHAT USES IT

It is used by older bookmark pages, by saved Ajax compatibility paths, by page-runtime helper injection, and by tests that guard the backward-compatible helper layer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Zipper -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/21-refactor-coverage.t t/00-load.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
