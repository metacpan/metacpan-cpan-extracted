package MIME::Expander::Plugin::ApplicationZip;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use parent qw(MIME::Expander::Plugin);
__PACKAGE__->mk_classdata('ACCEPT_TYPES' => [qw(
    application/zip
    )]);

use IO::Uncompress::Unzip;

sub expand {
    my $self        = shift;
    my $part        = shift;
    my $callback    = shift;
    my $c           = 0;

    my $contents = $part->body;
    my $uzip = IO::Uncompress::Unzip->new(
        \$contents, Append => 1
        ) or die "unzip failed: $IO::Uncompress::Unzip::UnzipError\n";

    my $status;
    for( $status = 1; 0 < $status; $status = $uzip->nextStream ){

        die "Error processing as zip: $!"
            if( $status < 0 );

        my $bytes;
        my $buff;
        1 while( 0 < ($bytes = $uzip->read($buff)) );

        last if( $bytes < 0 );

        my $name = $uzip->getHeaderInfo->{Name};
        next if( $name and $name =~ m,/$, );
        
        $callback->( \$buff, {
            filename => $name,
            } ) if( ref $callback eq 'CODE' );
        ++$c;
    }

    return $c;
}

1;
__END__


=pod

=head1 NAME

MIME::Expander::Plugin::ApplicationZip - a plugin for MIME::Expander

=head1 SYNOPSIS

    my $expander = MIME::Expander::Plugin::ApplicationZip->new;
    $expander->expand($part, sub {
            my $contents = shift;
            my $metadata = shift || {};
            print $metadata->{content_type}, "\n";
            print $metadata->{filename}, "\n";
        });

=head1 DESCRIPTION

Expand data that media type is "application/zip" or "application/x-zip".

=head1 SEE ALSO

L<MIME::Expander::Plugin>

L<IO::Uncompress::Unzip>

=cut
