package MIME::Lite::TT::HTML;
use strict;
use MIME::Lite;
use MIME::Words qw(:all);   
use Encode;
use Template;
use DateTime::Format::Mail;
use HTML::FormatText::WithLinks;
use Carp;

our $VERSION = '0.04';

=head1 NAME

MIME::Lite::TT::HTML - Create html mail with MIME::Lite and TT

=head1 SYNOPSIS

    use MIME::Lite::TT::HTML;
    
    my $msg = MIME::Lite::TT::HTML->new(
        From        => 'from@example.com',
        To          => 'to@example.com',
        Subject     => 'Subject',
        TimeZone    => 'Asia/Shanghai',
        Encoding    => 'quoted-printable',
        Template    => {
            html => 'mail.html',
            text => 'mail.txt',
        },
        Charset     => 'utf8',
        TmplOptions => \%options,
        TmplParams  => \%params,
    );
    
    $msg->send;

=head1 DESCRIPTION

This module provide easy interface to make L<MIME::Lite> object with html formatted mail.

=head1 METHODS

=over 4

=item new

return L<MIME::Lite> object with html mail format. 

=head1 ADITIONAL OPTIONS

=head2 Template

The same value passed to the 1st argument of the process method of L<Template::Toolkit> is set to this option.

=head2 TmplParams

The parameter of a template is set to this option.
This parameter must be the reference of hash.

=head2 TmplOptions

configuration of L<Template::Toolkit> is set to this option.
ABSOLUTE and RELATIVE are set to 1 by the default.

=head2 TimeZone

You can specified the time zone of the mail date:

    TimeZone => 'Asia/Shanghai',

default using 'UTC' if not defined.

=head2 Encoding

Mail body will be encoded for tranfer.

   Use encoding:     | If your message contains:
   ------------------------------------------------------------
   7bit              | Only 7-bit text, all lines <1000 characters
   8bit              | 8-bit text, all lines <1000 characters
   quoted-printable  | 8-bit text or long lines (more reliable than "8bit")
   base64            | Largely non-textual data: a GIF, a tar file, etc.

default using '7bit' if not defined.

=head2 Charset

You can specified the charset of your mail, both subject and body will using the charset
to make mail reader's client satisfied.

   Charset => 'big5',

And, if you giving the orignal words as UTF8 and attempt to mail them as GB2312 charset,
you can define the charset like:

   Charset => [ 'utf8' => 'gb2312' ], 

We will using L<Encode> to make this happy.

=cut

sub new {
    my $class = shift;
    my $options = @_ > 1 ? {@_} : $_[0];

    my $template = delete $options->{ Template };
    return croak "html template not defined" unless $template->{html};

    my $time_zone   = delete $options->{ TimeZone } || 'UTC';
    my $tmpl_params = delete $options->{ TmplParams };
    my $encoding = delete $options->{ Encoding } || '7bit';
    my $charset_option = delete $options->{ Charset };
    my $charset = ref $charset_option eq 'ARRAY' ? [ @{$charset_option} ] : [ $charset_option ];
    $charset = [ $charset ] unless ref $charset eq 'ARRAY';
	my $charset_input  = shift @$charset || 'US-ASCII';
	my $charset_output = shift @$charset || $charset_input;
	
    my $tt = Template->new( delete $options->{ TmplOptions } );

    my $msg = MIME::Lite->new(
        Subject => encode_subject( delete $options->{ Subject }, $charset_input, $charset_output ),
        Type    => 'multipart/alternative',
        Date    => DateTime::Format::Mail->format_datetime( DateTime->now->set_time_zone($time_zone) ),
        %$options,
    );

    my ( $text, $html );
    $tt->process( $template->{html}, $tmpl_params, \$html ) or croak $tt->error;
	if ( $template->{text} ){
	    $tt->process( $template->{text}, $tmpl_params, \$text ) or croak $tt->error;
	}else{
		my $f2 = HTML::FormatText::WithLinks->new(
			before_link => '',
			after_link => '',
			footnote => ''
		);
		$text = $f2->parse($html);
	}

    $msg->attach(
        Type => sprintf( 'text/plain; charset=%s', $charset_output ),
        Data => encode_body( $text, $charset_input, $charset_output ),
        Encoding => $encoding,
    );

    $msg->attach(
        Type => sprintf( 'text/html; charset=%s', $charset_output ),
        Data => encode_body( $html, $charset_input, $charset_output ),
        Encoding => $encoding,
    );

    $msg;
}

sub encode_subject {
    my ( $subject, $charset_input, $charset_output ) = @_;
    my $string = remove_utf8_flag( $subject );
	Encode::from_to( $string, $charset_input, $charset_output )
		if $charset_input ne $charset_output;
	encode_mimeword( $string, 'b', $charset_output );
}

sub encode_body {
    my ( $body, $charset_input, $charset_output ) = @_;
    my $string = remove_utf8_flag( $body );
	Encode::from_to( $string, $charset_input, $charset_output )
		if $charset_input ne $charset_output;
	$string;
}

sub remove_utf8_flag {
    pack 'C0A*', shift;
}

=back

=head1 AUTHOR

Sheng Chun E<lt>chunzi@cpan.orgE<gt>

=head1 SEE ALSO

L<MIME::Lite::TT> L<MIME::Lite::TT::Japanese> L<MIME::Lite::TT::HTML::Japanese>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
