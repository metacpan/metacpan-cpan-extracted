use strict;
use warnings;
use Test::More;
use Email::MIME::Kit;
use Email::MIME::Kit::Assembler::Markdown;

for my $suffix ('', '-munge', '-renderer') {
  my $path = "t/kit/sample$suffix.mkit";

  subtest $path => sub {
    my $kit = Email::MIME::Kit->new({ source => $path });

    my $email = $kit->assemble({ mail_type => 'electrical', endorsement_type => 'PAID' });

    my ($plain, $html) = $email->subparts;

    like($email->content_type, qr{multipart/alternative}, "message is mp/a");

    like($plain->content_type, qr{text/plain}, "1st alternative is txt");
    like($plain->body_str, qr{PAID ENDORSEMENT}, "we used the text_wrapper");
    like($plain->body_str, qr{\*Markdown\* Assembler}, "Markdown in plaintext");

    like($html->content_type, qr{text/html}, "2nd alternative is html");
    like($html->body_str, qr{electrical mail}, "we used the html_wrapper");
    like($html->body_str, qr{<em>Markdown</em> Assembler}, "marked-down html");

    if ($suffix eq '-munge') {
      # Test munge_signatures while we're at it.
      like(
        $plain->body_str,
        qr{^-- (\x0d\x0a)+Yours}m,
        "sigdash still okay in plaintext",
      );

      unlike(
        $html->body_str,
        qr{(\x0d\x0a)+-- }m,
        "sigdash removed from html",
      );
    }
  };
}

subtest "encode_entities" => sub {
  my $path = "t/kit/sample-entities.mkit";
  my $kit = Email::MIME::Kit->new({ source => $path });

  my $email = $kit->assemble({ mail_type => 'electrical', endorsement_type => 'PAID' });

  my @parts = $email->subparts;

  like($email->content_type, qr{multipart/alternative}, "message is mp/a");

  like($parts[0]->content_type, qr{text/plain}, "1st alternative is txt");
  like($parts[0]->body, qr{<b>awesome</b>}, "didn't encode entities in text");

  like($parts[1]->content_type, qr{text/html}, "2nd alternative is html");
  like($parts[1]->body, qr{&lt;b&gt;awesome&lt;/b&gt;}, "did encode entities in html");
};

done_testing;
