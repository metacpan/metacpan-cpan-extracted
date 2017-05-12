package MIME::Expander::Plugin::ApplicationGzip;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use parent qw(MIME::Expander::Plugin);
__PACKAGE__->mk_classdata('ACCEPT_TYPES' => [qw(
    application/gzip
    )]);

use IO::Uncompress::Gunzip;

sub expand {
    my $self        = shift;
    my $part        = shift;
    my $callback    = shift;
    my $c           = 0;

    my $contents = $part->body;
    my $z = IO::Uncompress::Gunzip->new(
        \$contents, Append => 1
        ) or die "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";

    my $buf;
    1 while( 0 < $z->read($buf) );
    
    my $h = $z->getHeaderInfo || {};
    $callback->( \$buf, {
        filename => $h->{Name},
        } ) if( ref $callback eq 'CODE' );
    ++$c;

    return $c;
}

1;
__END__


=pod

=head1 NAME

MIME::Expander::Plugin::ApplicationGzip - a plugin for MIME::Expander

=head1 SYNOPSIS

    my $expander = MIME::Expander::Plugin::ApplicationGzip->new;
    $expander->expand($part, sub {
            my $contents = shift;
            my $metadata = shift || {};
            print $metadata->{content_type}, "\n";
            print $metadata->{filename}, "\n";
        });

=head1 DESCRIPTION

Expand data that media type is "application/gzip" or "application/x-gzip".

=head1 SEE ALSO

L<MIME::Expander::Plugin>

L<IO::Uncompress::Gunzip>

=cut
