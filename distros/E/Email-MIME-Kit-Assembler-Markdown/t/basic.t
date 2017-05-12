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

    my @parts = $email->subparts;

    like($email->content_type, qr{multipart/alternative}, "message is mp/a");

    like($parts[0]->content_type, qr{text/plain}, "1st alternative is txt");
    like($parts[0]->body, qr{PAID ENDORSEMENT}, "we used the text_wrapper");
    like($parts[0]->body, qr{\*Markdown\* Assembler}, "Markdown in plaintext");

    like($parts[1]->content_type, qr{text/html}, "2nd alternative is html");
    like($parts[1]->body, qr{electrical mail}, "we used the html_wrapper");
    like($parts[1]->body, qr{<em>Markdown</em> Assembler}, "marked-down html");
  };
}

done_testing;
