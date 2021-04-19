package Lingua::StopWords::ID;

use strict;
use warnings;

use utf8;

use Encode qw(encode);

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.12;

sub getStopWords {
    if ( @_ and $_[0] eq 'UTF-8' ) {
        my %stoplist = map { ( $_, 1 ) } _stopwords();
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( encode("iso-8859-1", $_), 1 ) } _stopwords();
        return \%stoplist;
    }
}

sub _stopwords {
    return qw(
            yang dan di dari ini pada kepada ada adalah dengan untuk dalam oleh
            sebagai juga ke atau tidak itu sebuah tersebut dapat ia telah satu
            memiliki mereka bahwa lebih karena seorang akan seperti secara kemudian
            beberapa banyak antara setelah yaitu hanya hingga serta sama dia tetapi
            namun melalui bisa sehingga ketika suatu sendiri bagi semua harus setiap
            maka maupun tanpa saja jika bukan belum sedangkan yakni meskipun hampir
            kita demikian daripada apa ialah sana begitu seseorang selain terlalu
            ataupun saya bila bagaimana tapi apabila kalau kami melainkan boleh aku
            anda kamu beliau kalian
    );
}

1;
