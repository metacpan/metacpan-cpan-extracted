package JPEG::Comment;
use Exporter;

use strict;

use vars qw(@ISA $VERSION @EXPORT);
@ISA = qw(Exporter);
@EXPORT=qw(jpegcomment);
$VERSION='0.2';


sub jpegcomment($$){
    my ($image, $comment)=@_;
    $comment.="\0";
    my $i=2; # пропустить лидирующие FF SOI
    my(@datas);

    while(1){
      my $data;
      my $pre=unpack('n',substr($image,$i,2));
      if ( $pre == 0xFFDA ){ #собственно картинка
         push @datas, substr($image,$i,length($image)-$i);
         last;
      }      
      my $cnt=unpack('n',substr($image,$i+2,2));
      $i+=$cnt+2, next if ( $pre == 0xFFFE ); # изначальный комментарий. нафиг 
      die if ( $pre == 0xFFD8 );              #или конец, которого быть не должно
      push @datas, substr($image,$i,$cnt+2);
      $i+=$cnt+2;
      last if $i >= length($image);
    }
    @datas= ($datas[0],
             (pack('n n', 0xFFFE, length($comment)+2).$comment),
             @datas[1..$#datas]);

    return pack('n',0xFFD8) . join('', @datas) ;
}

1;
__END__

=head1 NAME

JPEG::Comment - add comment to JPEG file

=head1 SYNOPSIS
 
 use JPEG::Comment;

 $commented_image = jpegcomment($uncommented_image, $comment);

=head1 DESCRIPTION
 
The JPEG::Comment package allows you to add comment to jpeg file.
It is may be useful in web environment to mark downloaded images in your
site. The C<$commented_image> and C<$uncommented_image> is simple strings with
image data.

=head1 AUTHOR

Ivan Frolcov B<ifrol@cpan.org>
