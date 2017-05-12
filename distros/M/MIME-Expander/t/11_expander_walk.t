use strict;
use warnings;
#use Test::More tests => 1;
use Test::More qw(no_plan);
use lib './t/lib';
use MyUtils;

use MIME::Expander;


#---------------------------------------

my $pdf_base64_named = MyUtils::create_part('t/untitled.pdf', {
        filename     => "untitled.pdf",
        content_type => "application/pdf",
        encoding     => "base64",
        name         => "untitled",
        });

my $targz_base64_named = MyUtils::create_part('t/untitled.tar.gz', {
        filename     => "untitled.tar.gz",
        content_type => "application/x-gzip",
        encoding     => "base64",
        });

my $tarbz2_base64_named = MyUtils::create_part('t/untitled.tar.bz2', {
        filename     => "untitled.tar.bz2",
        content_type => "application/x-bzip",
        encoding     => "base64",
        });

my $zip_base64_named = MyUtils::create_part('t/untitled.zip', {
        filename     => "untitled.zip",
        content_type => "application/zip",
        encoding     => "base64",
        });

my $text_attach_named = MyUtils::create_part( \ 'attach this text', {
        filename     => 'hello.txt',
        content_type => 'text/plain',
        disposition  => 'attachment',
        charset      => 'US-ASCII',
        encoding     => '7bit',
        });

my $text_inline = MyUtils::create_part( \ 'hello inline!', {
        content_type => "text/plain",
        charset      => "US-ASCII",
        encoding     => "7bit",
        });

# bared text
{;
    my $me = MIME::Expander->new;
    my $body;
    $me->walk( 'katakuriko', sub {
        if( $_[0]->content_type =~ m|text/plain| ){
            $body = $_[0]->body;
        }
        });
    is( $body, 'katakuriko', 'bared text');
}

# bared pdf
{;
    my $me = MIME::Expander->new;
    my $data = MyUtils::read_file('t/untitled.pdf');
    my $body;
    $me->walk( $data, sub {
        if( $_[0]->content_type =~ m|application/pdf| ){
            $body = $_[0]->body;
        }
        });
    is( $body, $$data, 'bared pdf');
}

# multipart message contains pdf
{;
    my $me = MIME::Expander->new;
    my $email = MyUtils::create_email;
    my $data = MyUtils::read_file('t/untitled.pdf');
    $email->parts_set([$pdf_base64_named]);
    my $body;
    $me->walk( $email->as_string, sub {
        if( $_[0]->content_type =~ m|application/pdf| ){
            $body = $_[0]->body;
        }
        });
    is( $body, $$data, 'multipart message contains pdf');
}

# (A-1) tar contains txt and pdf
{;
    my $me = MIME::Expander->new;
    my $data = MyUtils::read_file('t/untitled.tar.gz');
    my $txt  = MyUtils::read_file('t/untitled.txt');
    my $pdf  = MyUtils::read_file('t/untitled.pdf');
    my $rtxt;
    my $rpdf;
    $me->walk( $data, sub {
        if( $_[0]->content_type =~ m|text/plain| ){
            $rtxt = $_[0]->body;
        }
        if( $_[0]->content_type =~ m|application/pdf| ){
            $rpdf = $_[0]->body;
        }
        });
    is( $rtxt, $$txt, 'tar contains txt');
    is( $rpdf, $$pdf, 'and pdf');
}

# (A-2) tar.gz contains txt and pdf, but expects tar
{;
    my $me = MIME::Expander->new( expects => ['/tar'] );
    my $data = MyUtils::read_file('t/untitled.tar.gz');
    my $tar  = MyUtils::read_file('t/untitled.tar');
    my $rtxt;
    my $rpdf;
    my $rtar;
    $me->walk( $data, sub {
        if( $_[0]->content_type =~ m|application/tar| ){
            $rtar = $_[0]->body;
        }
        if( $_[0]->content_type =~ m|text/plain| ){
            $rtxt = $_[0]->body;
        }
        if( $_[0]->content_type =~ m|application/pdf| ){
            $rpdf = $_[0]->body;
        }
        });
    is( $rtar, $$tar, 'expects - tar.gz expanded tar');
    is( $rtxt, undef, 'expects - no more expand, no txt found');
    is( $rpdf, undef, 'expects - no more expand, no pdf found');
}

# (A-3) by depth = 1
{;
    my $me = MIME::Expander->new( depth => 1 );
    my $data = MyUtils::read_file('t/untitled.tar.gz');
    my $tar  = MyUtils::read_file('t/untitled.tar');
    my $rtxt;
    my $rpdf;
    my $rtar;
    $me->walk( $data, sub {
        if( $_[0]->content_type =~ m|application/tar| ){
            $rtar = $_[0]->body;
        }
        if( $_[0]->content_type =~ m|text/plain| ){
            $rtxt = $_[0]->body;
        }
        if( $_[0]->content_type =~ m|application/pdf| ){
            $rpdf = $_[0]->body;
        }
        });
    is( $rtar, $$tar, 'depth 1 - tar.gz expanded tar');
    is( $rtxt, undef, 'depth 1 - no more expand, no txt found');
    is( $rpdf, undef, 'depth 1 - no more expand, no pdf found');
}

# 
{;
    my $email = MyUtils::create_email;
    my $parts = MyUtils::create_part;

    $parts->parts_set([
        $pdf_base64_named,
        $targz_base64_named,
        $tarbz2_base64_named,
        $zip_base64_named,
        ]);

    $email->parts_set([
        $parts,
        $text_attach_named,
        $text_inline,
        ]);

    my $me = MIME::Expander->new;
    my @types = ();
    my $num = $me->walk( $email->as_string, sub {
        push @types, $_[0]->content_type;
        });
    is( $num, 9, 'contain 9 parts' );
    is( scalar @types, 9, 'return value' );
    is_deeply( [sort @types], [sort qw{
        text/plain
        text/plain
        application/pdf
        application/pdf
        text/plain
        application/pdf
        text/plain
        application/pdf
        text/plain
        }], 'types of each contents 9');
}

# 
{;
    my $email = MyUtils::create_email;
    my $parts = MyUtils::create_part;

    $parts->parts_set([
        $pdf_base64_named,
        $targz_base64_named,
        $tarbz2_base64_named,
        $zip_base64_named,
        ]);

    $email->parts_set([
        $parts,
        $text_attach_named,
        $text_inline,
        ]);

    my $me = MIME::Expander->new({
        expects => ['/tar'],
        });
    my @types = ();
    my $num = $me->walk( $email->as_string, sub {
        push @types, $_[0]->content_type;
        });
    is( $num, 7, 'contain 7 parts' );
    is( scalar @types, 7, 'return value' );
    ok( eq_array( [sort @types], [sort qw{
        application/tar
        application/tar
        text/plain
        application/pdf
        text/plain
        application/pdf
        text/plain
        }] ),  'types of each contents 7');
}

# multipart/mixed
{;
    my $mime = Email::MIME->new(MyUtils::read_file('t/multipart.eml'));
    my $me = MIME::Expander->new;
    my @names = ();
    my $num = $me->walk($mime, sub {
            my $email = shift;
            my $name = $email->filename;
            my $body = $email->body;
            my ($f) = $body =~ /^(.+)\n/; # the 1st line
            if( $name ){
                push @names, $name;
                $name =~ s/\.txt//;
                like($name, qr/$f/i, "attachment fruit: $f");
            }else{
                like($f, qr/Welcome to test MIME::Expander!/, 'body');
            }
        });
    is( $num, 5, 'contain 5 parts' );
}
