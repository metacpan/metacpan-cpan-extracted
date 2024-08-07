package MIME::Lite::HT::HTML;

use 5.006001;
use strict;
use warnings;
use strict;
use MIME::Lite;
use MIME::Words qw(:all);
use Encode;
use HTML::Template;
use HTML::FormatText::WithLinks;
use DateTime::Format::Mail;
use Carp;

our $VERSION = '0.06';

=head1 NAME

MIME::Lite::HT::HTML - Create HTML mail with MIME::Lite and HTML::Template

=head1 SYNOPSIS

    use MIME::Lite::HT::HTML;
    
    my $msg = MIME::Lite::HT::HTML->new(
        From        => 'from@example.com',
        To          => 'to@example.com',
        Subject     => 'Subject',
        TimeZone    => 'Europe/Berlin',
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

This module provide easy interface to make L<MIME::Lite> object with HTML
formatted mail.

=head1 METHODS

=over 4

=item new

return L<MIME::Lite> object with HTML mail format. 

=back

=head1 ADDITIONAL OPTIONS

=head2 Template

This is a mapping of filenames to the two variants of templates (HTML or text).
You define, which file will be used for the HTML-part and the plain/text part.

The filenames will be passed to the constructor of HTML::Template, as
argument of the filename option. See L<HTML::Template> for more information.

=head2 TmplParams

The parameters of a template are set to these options.
This parameter must be the reference of hash.

=head2 TmplOptions

Configuration of L<HTML::Template> is set to this option (e.g.
die_on_bad_params or path).

=head2 TimeZone

You can specify the time zone of the mail date:

    TimeZone => 'Asia/Shanghai',

default using 'UTC' if not defined.

=head2 Encoding

Mail body will be encoded for transfer.

   Use encoding:     | If your message contains:
   ------------------------------------------------------------
   7bit              | Only 7-bit text, all lines <1000 characters
   8bit              | 8-bit text, all lines <1000 characters
   quoted-printable  | 8-bit text or long lines (more reliable than "8bit")
   base64            | Largely non-textual data: a GIF, a tar file, etc.

default using '7bit' if not defined.

=head2 Charset

You can specify the charset of your mail, both subject and body will using the charset
to make mail reader's client satisfied.

   Charset => 'big5',

And, if you are giving the original words as UTF8 and attempt to mail them as GB2312 charset,
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
	
	my %tmpl_options = ();
	%tmpl_options = %{delete $options->{ TmplOptions }} if $options->{ TmplOptions };

    my $msg = MIME::Lite->new(
        Subject => encode_subject( delete $options->{ Subject }, $charset_input, $charset_output ),
        Type    => 'multipart/alternative',
        Date    => DateTime::Format::Mail->format_datetime( DateTime->now->set_time_zone($time_zone) ),
        %$options,
    );

	# -- Create templates.
	my $t_html = HTML::Template->new( filename => $template->{html}, %tmpl_options );

	# -- fill in params
	$t_html->param($tmpl_params) if $tmpl_params;

	# -- generate output
	my $html = $t_html->output();
	my $text = undef;
	
	if( $template->{text} ) {
		my $t_text = HTML::Template->new( filename => $template->{text}, %tmpl_options );
		$t_text->param($tmpl_params) if $tmpl_params;
		$text = $t_text->output();
	}else{
		my $f2 = HTML::FormatText::WithLinks->new(
			before_link => '',
			after_link => '',
			footnote => '',
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

    return $msg;
} # /new

sub encode_subject {
    my ( $subject, $charset_input, $charset_output ) = @_;
    my $string = remove_utf8_flag( $subject );
	Encode::from_to( $string, $charset_input, $charset_output )
		if $charset_input ne $charset_output;
	encode_mimeword( $string, 'b', $charset_output );
} # /encode_subject

sub encode_body {
    my ( $body, $charset_input, $charset_output ) = @_;
    my $string = remove_utf8_flag( $body );
	Encode::from_to( $string, $charset_input, $charset_output )
		if $charset_input ne $charset_output;
	$string;
} # /encode_body

sub remove_utf8_flag {
    pack 'C0A*', shift;
} # /remove_utf8_flag


=head1 AUTHOR

Alexander Becker E<lt>asb@cpan.orgE<gt>
But all I did was c&p from L<MIME::Lite::TT::HTML>

=head1 SEE ALSO

L<HTML::Template>, L<MIME::Lite>, L<MIME::Lite::TT>, L<MIME::Lite::TT::HTML>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;