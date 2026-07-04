use strict;
use warnings;
use Test::More tests => 7;
use Path::Class::Dir;
use Path::Class::File;
use Class::Load;
use Try::Tiny;
use Data::Dump qw( dump );

use_ok('Dezi::Test::Indexer');
use_ok('Dezi::Test::Searcher');

my $num_tests = 5;

SKIP: {

    my @required = qw(
        Mail::Box
        Dezi::Aggregator::Mail
    );
    for my $cls (@required) {
        diag("Checking on $cls");
        my $missing;
        my $loaded = try {
            Class::Load::load_class($cls);
        }
        catch {
            warn $_;
            if ( $_ =~ m/Can't locate (\S+)/ ) {
                $missing = $1;
                $missing =~ s/\//::/g;
                $missing =~ s/\.pm//;
            }
            return 0;
        };
        if ( !$loaded ) {
            if ($missing) {
                diag( '-' x 40 );
                diag("Do you need to install $missing ?");
                diag( '-' x 40 );
            }
            skip "$cls required for spider test", $num_tests;
            last;
        }
    }

    # is executable present?
    my $indexer = Dezi::Test::Indexer->new( 'invindex' => 't/mail.index' );

    # maildir requires the 'cur', 'tmp' and 'new' dirs to exist
    my $maildir = Path::Class::Dir->new( 't', 'maildir' );
    for my $dirname (qw( cur tmp new )) {
        Path::Class::Dir->new( $maildir, $dirname )->mkpath;
        Path::Class::Dir->new( $maildir, '.INBOX', $dirname )->mkpath;
    }

    my $email_fname = Path::Class::File->new( $maildir, '.INBOX', 'cur',
        '1201404060.V802I5f9e4M893922.louvin.peknet.com:2,' );
    my $email_content = do { local $/; <DATA> };
    open my $fh, ">", $email_fname or die "Could not open $email_fname: $!";
    print $fh $email_content;
    close $fh;

    ok( my $mail = Dezi::Aggregator::Mail->new(
            indexer => $indexer,
            verbose => $ENV{DEZI_DEBUG},
        ),
        "new mail aggregator"
    );

    ok( $mail->indexer->start, "start" );
    is( $mail->crawl('t/maildir'), 1, "crawl" );
    ok( $mail->indexer->finish, "finish" );

    # verify parsing
    my $inv_index = $indexer->invindex;
    my $searcher  = Dezi::Test::Searcher->new(
        invindex      => $inv_index,
        swish3_config => $indexer->swish3->get_config
    );
    my $res     = $searcher->search('Passage');
    my $matches = () = $res->payload->docs->[0]->swishdefault =~ /Passage/g;
    # dump $res;
    is( $matches, 1, 'text/plain skipped in mail message multipart' );

    # clean up
    $maildir->rmtree();

}

__DATA__
MIME-Version: 1.0
Date: Fri, 30 Apr 2021 20:48:43 -0500
Message-ID: <CAF6iaBOfD3w1KGzydUHgFE0=vBC_91jyqZ3tUo_D2bPJHS4Vgw@mail.gmail.com>
Subject: Revolution
From: Peter Karman <peknet@gmail.com>
To: Peter Karman <peter@peknet.com>
Content-Type: multipart/alternative; boundary="000000000000b7d02905c13aed12"

--000000000000b7d02905c13aed12
Content-Type: text/plain; charset="UTF-8"

The revolution was still fresh
Backmarket foodstuffs day by day
Lying awake while voices called
Outside in the streets
The trains running again
Coupling down in the yard
While shipmen called their droning
Patter over the darkness on the river

I could smell you, like a memory,
Like the folded corner of my favorite
Passage
--
Peter Karman .  he/him/his  .  https://karpet.github.io/ . 785.337.0405

--000000000000b7d02905c13aed12
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

The revolution was still fresh<div dir=3D"auto">Backmarket foodstuffs day b=
y day</div><div dir=3D"auto">Lying awake while voices called=C2=A0</div><di=
v dir=3D"auto">Outside in the streets</div><div dir=3D"auto">The trains run=
ning again</div><div dir=3D"auto">Coupling down in the yard</div><div dir=
=3D"auto">While shipmen called their droning</div><div dir=3D"auto">Patter =
over the darkness on the river</div><div dir=3D"auto"><br></div><div dir=3D=
"auto">I could smell you, like a memory,</div><div dir=3D"auto">Like the fo=
lded corner of my favorite</div><div dir=3D"auto">Passage</div>-- <br><div =
dir=3D"ltr" class=3D"gmail_signature" data-smartmail=3D"gmail_signature"><d=
iv dir=3D"ltr"><div><div dir=3D"ltr"><div>Peter Karman .=C2=A0 he/him/his=
=C2=A0 .=C2=A0 <a href=3D"https://karpet.github.io/" target=3D"_blank">http=
s://karpet.github.io/</a>=C2=A0. 785.337.0405</div></div></div></div></div>

--000000000000b7d02905c13aed12--
