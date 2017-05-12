use strict;
use warnings;
use utf8;
use Test::More;
use Email::MIME;
use Devel::Peek;

subtest 'multi part' => sub {
    my $src = Email::MIME->create(
        'header' => [
            'From'    => 'bar@example.jp',
            'To'      => 'foo@example.com',
            'Subject' => "Test mail",
        ],
        parts => [
            Email::MIME->create(
                'attributes' => {
                    'content_type' => 'text/plain',
                    'charset'      => 'US-ASCII',
                    'encoding'     => '7bit',
                },
                'body' => "test",
            ),
            Email::MIME->create(
                'attributes' => {
                    'fimename'     => 'hoge.jpg',
                    'content_type' => 'image/jpeg',
                    'encoding'     => 'base64',
                    'name'         => 'sample.jpg',
                },
                'body' => 'JFIF(ry',
            ),
        ],
    );
    # note $src->as_string;

    my $BODY = "NOT SET";
    my $mail = Email::MIME->new($src->as_string);
    $mail->walk_parts(sub {
        my $part = shift;
        return if $part->parts > 1; # multipart
        if ($part->content_type =~ /plain/) {
            $BODY = $part->body_str;
        }
    });

    is($BODY, 'test') or Dump($BODY);
};

done_testing;
__END__
    not ok 1
    #   Failed test at t/99_get_text_newline.t line 47.
    #          got: 'test
    # '
    #     expected: 'test'
SV = PV(0x2176c10) at 0x20f03e0
  REFCNT = 1
  FLAGS = (PADMY,POK,pPOK,UTF8)
  PV = 0x22e4730 "test\r\n"\0 [UTF8 "test\r\n"]
  CUR = 6
  LEN = 16
    1..1
    # Looks like you failed 1 test of 1.
not ok 1 - multi part
#   Failed test 'multi part'
#   at t/99_get_text_newline.t line 48.
1..1
# Looks like you failed 1 test of 1.
