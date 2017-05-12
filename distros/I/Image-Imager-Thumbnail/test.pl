use Test;
BEGIN { plan tests => 3 };
use Image::Imager::Thumbnail 0.01;
ok(1);
skip (!-e 'source.jpg', &img_tests);
exit;

sub img_tests {
	unlink 'source_thumb.jpg' if -e 'source_thumb.jpg';
	my $tb = new Image::Imager::Thumbnail(
                                    file_src  => 'source.jpg',
                                    file_dst  => 'source_thumb.jpg',
                                    width     => 50,
                                    height    => 50 
                                  );
  $tb->save;
	ok (-e 'source_thumb.jpg');
	unlink 'source_thumb.jpg' if -e 'source_thumb.jpg';

}

__END__
