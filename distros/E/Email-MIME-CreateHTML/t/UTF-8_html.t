use common::sense;

use Email::Address;
use Email::MIME::CreateHTML;
use Encode;
use FindBin qw($Bin);
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use MIME::Parser;
use MIME::Words qw(encode_mimeword);
use Test::More;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $response = LWP::UserAgent->new->get("file://$Bin/data/UTF-8.html");

my $body = $response->decoded_content;

my $from = generate_address('Föö', 'test@foo.example');
my $to   = generate_address('Bäz', 'test@baz.example');

my $subject = encode_mimeword(encode_utf8('Sübject'), 'Q', 'UTF-8');

my $mail = Email::MIME->create_html(
    header => [
        From    => $from->format,
        To      => $to->format,
        Subject => $subject,
    ],
    body            => $body,
    body_attributes => {
        charset  => 'UTF-8',
        encoding => 'quoted-printable',
    }
);

my $parsed_mail = parse_mail($mail->as_string);

is(decode_utf8($parsed_mail->{from}), 'Föö <test@foo.example>');
is(decode_utf8($parsed_mail->{to}),   'Bäz <test@baz.example>');
is(decode_utf8($parsed_mail->{subject}), 'Sübject');

is(decode_utf8($parsed_mail->{content}->findnodes('//p')->[0]->as_text), 'Umlaute: äöüßÄÖÜ');


done_testing();

sub generate_address {
    my ($name, $address) = @_;

    return Email::Address->new(
        encode_mimeword(encode_utf8($name), 'Q', 'UTF-8'),
        encode_utf8($address)
    );
}

sub parse_mail {
    my ($mail) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);

    my $parsed_mail = $parser->parse_data($mail);

    my $subject = MIME::Words::decode_mimewords( $parsed_mail->head->get('Subject') );
    my $from    = MIME::Words::decode_mimewords( $parsed_mail->head->get('From') );
    my $to      = MIME::Words::decode_mimewords( $parsed_mail->head->get('To') );

    defined and chomp foreach ($subject, $from, $to);

    return {
        content => HTML::TreeBuilder::XPath->new_from_content($parsed_mail->bodyhandle->as_string),
        subject => $subject,
        from    => $from,
        to      => $to,
    };
}
