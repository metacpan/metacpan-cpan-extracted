package MasonX::Plugin::Compress;

use warnings;
use strict;

use Compress::Zlib();
use Compress::Bzip2 2.0 ();
use List::Util();

#use Apache::Constants();

use base 'HTML::Mason::Plugin';

our $VERSION = 0.1;

=head1 NAME

MasonX::Plugin::Compress - send compressed output if the client supports it

=head1 SYNOPSIS

    PerlAddVar MasonPlugins MasonX::Plugin::Compress
    
    # or in a handler.pl script
    my $ah = HTML::Mason::ApacheHandler->new( plugins => [ MasonX::Plugin::Compress-> new ],
                                              # ...
                                              );

=head1 DESCRIPTION

Negotiates a preferred compression method (currently, gzip, bzip2 or deflate) with the client, 
compresses the response and sets appropriate headers. 

=head2 Methods

=over 4

=item end_request_hook

=back

=cut

my %AcceptMap = ( gzip          => '_gzip',
                  'x-gzip'      => '_gzip',
                  deflate       => '_deflate',
                  'x-deflate'   => '_deflate',   # does this exist?
                  bzip2         => '_bzip2',
                  'x-bzip2'     => '_bzip2',     # does this exist?
                  );
                   
sub end_request_hook
{
    my ( $proto, $context ) = @_;
    
    my $o = $context->output;
    my $m = $context->request;
    
    my $r = $m->apache_req || $m->cgi_request;
    
    return unless length $$o;
    
    return if $r->content_encoding;
    
    #return if $context->error; # there always seems to be one
    
    # not sure from the docs if results->[0] contains the request return code, but 
    # it seems to - does this break CGI? Anyway, seems to be undef.
    #return unless $context->result->[0] == Apache::Constants::OK(); 
    
    # maybe worth accepting a few others, see e.g. http://www.pipeboost.com/contenttypes.asp 
    return unless $r->content_type  =~ /^text/; 
    
    # FireFox gives gzip, deflate
    return unless my @accept = split /[\s,]/, $r->header_in( 'Accept-Encoding' );
    
    return unless my $encoding = List::Util::first { $AcceptMap{ $_ } } @accept;
    
    # Phew, we're really going to do this!
    
    my $compress = $AcceptMap{ $encoding };
    
    $proto->$compress( $context );
}

sub _set_headers
{
    my ( $class, $context, $enc ) = @_;
    
    my $m = $context->request;
    my $r = $m->apache_req || $m->cgi_request;
    
    $r->content_encoding( $enc );
    
    $r->header_out( Vary => 'Accept-Encoding' );
    
    # I guess Mason sets this
    #$r->content_length( length ${ $context->output } );
}

sub _gzip 
{
    my ( $class, $context ) = @_;
    
    my $o = $context->output;
    
    $$o = Compress::Zlib::memGzip( $$o );
    
    $class->_set_headers( $context, 'gzip' );
}

sub _bzip2
{
    my ( $class, $context ) = @_;

    my $o = $context->output;
    
    $$o = Compress::Bzip2::memBzip( $$o );
    
    $class->_set_headers( $context, 'bzip2' );
}

sub _deflate
{
    my ( $class, $context ) = @_;
    
    my $d = Compress::Zlib::deflateInit;
    
    warn "Cannot create a deflation stream" unless $d;
    
    return unless $d;
    
    my $o = $context->output;
    
    my ( $out1, $status ) = $d->deflate( $o );
    
    warn "Deflation failed: $status" unless $status == Compress::Zlib::Z_OK();
    
    return unless $status == Compress::Zlib::Z_OK();
    
    ( my $out2, $status ) = $d->flush;

    warn "Deflation failed during flush: $status" unless $status == Compress::Zlib::Z_OK();
    
    return unless $status == Compress::Zlib::Z_OK();
    
    $$o = $out1 . $out2;
    
    $class->_set_headers( $context, 'deflate' );
}

=head1 TODO

Investigate what other types to compress (currently, only compresses text/*).

=head1 SEE ALSO

C<Catalyst::Plugin::Compress::*>.

L<Apache::Compress|Apache::Compress>.

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-masonx-plugin-compress@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MasonX-Plugin-Compress>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MasonX::Plugin::Compress
