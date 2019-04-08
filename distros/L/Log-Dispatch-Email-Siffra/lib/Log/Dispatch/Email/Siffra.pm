package Log::Dispatch::Email::Siffra;

use 5.014;
use strict;
use warnings;
use Carp;
$Carp::Verbose = 1;
use utf8;
use Data::Dumper;
use DDP;
use Encode qw(decode encode);
use Log::Any qw($log);

$| = 1;    #autoflush

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );
    require Log::Dispatch::Email;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.01';
    @ISA     = qw(Log::Dispatch::Email Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

=head3 C<send_email()>
=cut

sub send_email
{
    my ( $self, %parameters ) = @_;

    # Send email somehow. Message is in $parameters{message}
    use MIME::Lite;

    my $to      = ( join ',', @{ $self->{ to } } );
    my $from    = $self->{ from };
    my $subject = encode( 'utf8', 'Test Email encode : não / ü / ção...' );
    my $message = "<h4>$parameters{ message }</h4>";
    $message = encode( 'utf8', $message );

    my $msg = MIME::Lite->new(
        From    => $from,
        To      => $to,
        Subject => $subject,
        Data    => $message,
        Type    => 'text/html; charset=UTF-8',
    );

    $msg->attr( 'content-type'         => 'text/html' );
    $msg->attr( 'content-type.charset' => 'UTF-8' );
    $msg->send( 'smtp', 'mail', 'port', 2525 );
    $log->info( "Email Sent Successfully\n" );
} ## end sub send_email

=head3 C<flush()>
=cut

sub flush
{
    my ( $self, %parameters ) = @_;

    if ( $self->{ buffered } && @{ $self->{ buffer } } )
    {
        my $message = join "<br>", @{ $self->{ buffer } };

        $self->send_email( message => $message );
        $self->{ buffer } = [];
    } ## end if ( $self->{ buffered...})
} ## end sub flush

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Log::Dispatch::Email::Siffra - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use Log::Dispatch::Email::Siffra;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Luiz Benevenuto
    CPAN ID: LUIZBENE
    Siffra TI
    luiz@siffra.com.br
    https://siffra.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

