use Test::More tests => 8;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store { only => [qw( Mail Attachment )] }, 
    ("dbi:SQLite:dbname=t/test.db", "", "", { sqlite_handle_binary_nulls => 1 } );
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/attach-test");
my $mail = Email::Store::Mail->store($data);
my @att = $mail->attachments;
is (@att, 2, "Has two attachments");
my $msg = $mail->message;
like ($msg, qr/pointless/, "Message with crap stripped");
unlike ($msg, qr/OkoQfvUzL/, "Message with crap stripped");
is($att[0]->content_type, "application/x-tex");
is($att[0]->filename, "foo.tex");
is($att[0]->payload, "Foo bar baz\n");
is($att[1]->content_type, "image/png");
