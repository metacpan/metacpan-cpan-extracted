package Dezi::Utils;
use Moose;
use Carp;
use Data::Dump qw( dump );
use File::Basename;
use Search::Tools::XML;
use SWISH::3 qw( :constants );

# this class differs from SWISH::Prog::Utils chiefly in that
# it uses SWISH::3::Config rather than hardcoding mime types
# and parser mappings. This is to ensure consistency with
# the SWISH::3 parser used in Indexer and Aggregator.

# singletons
my $SWISH3 = SWISH::3->new();
my $XML    = Search::Tools::XML->new;

our $VERSION = '0.015';

=pod

=head1 NAME

Dezi::Utils - utility variables and methods

=head1 SYNOPSIS

 use Dezi::Utils;

 my $ext = Dezi::Utils->get_file_ext( $filename );
 my $mime = Dezi::Utils->get_mime( $filename );
 if (Dezi::Utils->looks_like_gz( $filename )) {
     $mime = Dezi::Utils->get_real_mime( $filename );
 }
 my $parser = Dezi::Utils->get_parser_for_mime( $mime );

=head1 DESCRIPTION

This class provides commonly used variables and methods
shared by many classes in the Dezi project.

=head1 VARIABLES

=over

=item $ExtRE

Regular expression of common file type extensions.

=item %ParserTypes

Hash of MIME types to their equivalent parser. This hash is
used to cache lookups in get_parser_for_mime().
You really don't want to mess with this, but documented
in case you're brave or foolish.

=item $DefaultExtension

Defaults to C<html>.

=item $DefaultMIME

Defaults to C<text/html>.

=back

=cut

our $ExtRE            = qr{\.(\w+)(\.gz)?$}io;
our %ParserTypes      = ();
our $DefaultExtension = 'html';
our $DefaultMIME      = 'text/html';

# internal cache to avoid hitting SWISH::3 each time
# and to map common extensions that SWISH::3 may not define
my %ext2mime = (
    doc  => 'application/msword',
    pdf  => 'application/pdf',
    ppt  => 'application/vnd.ms-powerpoint',
    html => 'text/html',
    htm  => 'text/html',
    txt  => 'text/plain',
    text => 'text/plain',
    xml  => 'application/xml',
    mp3  => 'audio/mpeg',
    gz   => 'application/x-gzip',
    xls  => 'application/vnd.ms-excel',
    zip  => 'application/zip',
    json => 'application/json',
    yml  => 'application/x-yaml',
    php  => 'text/html',

);

=head1 METHODS

=head2 get_mime( I<url> [, I<swish3>] )

Returns MIME type for I<url>, using optional I<swish3> instance to look it up.
If I<swish3> is missing, will use the L<SWISH::3> default mapping.

=cut

sub get_mime {
    my $self = shift;
    my $url  = shift;
    confess "url required" unless defined $url;
    my $s3 = shift;
    if ($s3) {

        if ( !$s3->isa('SWISH::3') ) {
            confess "s3 object must be instance of SWISH::3, not " . ref($s3);
        }

        # look it up
        my $ext = $s3->get_file_ext($url) || $DefaultExtension;
        return
               $s3->get_mime($url)
            || $ext2mime{$ext}
            || $DefaultMIME;
    }
    else {
        # check our cache first
        my $ext = $SWISH3->get_file_ext($url) || $DefaultExtension;
        if ( exists $ext2mime{$ext} ) {
            return $ext2mime{$ext};
        }

        # no cache? look it up and cache
        my $mime = $SWISH3->get_mime($url);
        $ext2mime{$ext} = $mime;
        return $mime || $DefaultMIME;
    }
}

=head2 mime_type( I<url> [, I<ext> ] )

Backcompat for SWISH::Prog::Utils. Use get_mime() instead,
which is what this does internally.

=cut

sub mime_type {
    my $self = shift;
    my $url = shift or return;
    return $self->get_mime($url);
}

=head2 get_parser_for_mime( I<mime> [, I<swish3_object>] )

Returns the SWISH::3 parser type for I<mime>. This can be
configured via the C<%ParserTypes> class variable.

=cut

sub get_parser_for_mime {
    my $self = shift;
    my $mime = shift;
    confess "mime required" unless defined($mime);
    my $s3 = shift;
    if ($s3) {
        return
               $s3->config->get_parsers->get($mime)
            || $s3->config->get_parsers->get( SWISH_DEFAULT_PARSER() )
            || $ParserTypes{$mime};
    }
    else {
        return $ParserTypes{$mime} if exists $ParserTypes{$mime};
        $ParserTypes{$mime} = $SWISH3->config->get_parsers->get($mime)
            || $SWISH3->config->get_parsers->get( SWISH_DEFAULT_PARSER() );
        return $ParserTypes{$mime};
    }
}

=head2 parser_for( I<url> )

Backcompat for SWISH::Prog::Utils. Use get_parser_for_mime() instead,
which is what this does internally.

=cut

sub parser_for {
    my $self = shift;
    my $url  = shift;
    confess "url required" unless defined($url);
    return $self->get_parser_for_mime( $self->get_mime($url) );
}

=head2 path_parts( I<url> [, I<regex> ] )

Returns array of I<path>, I<file> and I<extension> using the
File::Basename module. If I<regex> is missing or false,
uses $ExtRE.

=cut

sub path_parts {
    my $self = shift;
    my $url  = shift;
    my $re   = shift || $ExtRE;

    # TODO build regex from ->config
    my ( $file, $path, $ext ) = fileparse( $url, $re );
    return ( $path, $file, $ext );
}

=head2 merge_swish3_config( I<key> => I<value> [, I<swish3>] )

The L<SWISH::3> class currently does not allow for modification
of the internal C structs from Perl space. Instead,
the SWISH::3::Config->merge method can be used to parse
XML strings. Since hand-crafting XML is tedious,
this method eases the pain.

I<key> should be a SWISH::3::Config reserved word. Use
the SWISH::3::Constants for safety.

I<value> is passed through perl_to_xml().
If I<value> is a hashref, it should be a simple key/value set with strings.
You may use arrayref values, where items in the array are strings.

The optional I<swish3> object is modified, or the internal
singleton SWISH::3 object will be modified if I<swish3>
is missing.

Example:

 use SWISH::3 qw( :constants );
 $utils->merge_swish3_config(
     SWISH_PARSERS() => {
         'XML'  => [ 'application/x-bar', 'application/x-foo' ],
         'HTML' => [ 'application/x-blue', 'application/x-red' ]
     }
 );
 $utils->merge_swish3_config(
     'foo' => 'bar'
 );
 $utils->get_parser_for_mime( 'application/x-foo' );   # returns 'XML'

=cut

sub merge_swish3_config {
    my $self    = shift;
    my $key     = shift or confess "key required";
    my $hashref = shift or confess "hashref required";
    my $s3      = shift || $SWISH3;
    my $xml     = $XML->perl_to_xml( { $key => $hashref },
        { root => 'swish', wrap_array => 0 } );

    #warn "xml=" . $XML->tidy($xml) . "\n";
    $s3->config->merge($xml);
    return $xml;
}

=head2 get_swish3

Returns the class singleton.

=cut

sub get_swish3 {$SWISH3}

=head2 perl_to_xml( I<ref>, I<root_element> [, I<strip_plural> ] )

Similar to the XML::Simple XMLout() feature, perl_to_xml()
will take a Perl data structure I<ref> and convert it to XML,
using I<root_element> as the top-level element.

As of version 0.38 this method is now part of Search::Tools
and included here simply as a backcompat feature.

=cut

sub perl_to_xml {
    my $self = shift;
    return $XML->perl_to_xml(@_);
}

=head2 write_log( I<args> )

Logging method. By default writes to stderr via warn().

I<args> is a key/value pair hash, with keys B<uri> and B<msg>.

=cut

sub write_log {
    my $self = shift;
    my %args = @_;
    my $uri  = delete $args{uri} or croak "uri required";
    my $msg  = delete $args{msg} or croak "msg required";
    warn sprintf( "[%s][%s] %s [%s]\n", scalar localtime(), $$, $uri, $msg );
}

=head2 write_log_line([I<char>, I<width>])

Writes I<char> x I<width> to stderr, to provide some visual separation when viewing logs.
I<char> defaults to C<-> and I<width> to C<80>.

=cut

sub write_log_line {
    my $self  = shift;
    my $char  = shift || '-';
    my $width = shift || 80;
    warn $char x $width, "\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Utils

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>
