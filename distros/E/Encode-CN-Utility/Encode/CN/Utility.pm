package Encode::CN::Utility;

use 5.006;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
			 hz2gbk gbk2hz hz2utf8 hz2unicode utf82hz unicode2hz
			 gbk2utf8 gbk2unicode utf82gbk utf82unicode
			 unicode2gbk unicode2utf8
			 );

$VERSION = '0.4';

use Encode;

sub hz2gbk {
	unpack "H*", shift;
}

sub gbk2hz {
	pack "H*", shift;
}

sub hz2utf8 {
	unpack("H*", encode("utf8", decode("gbk", shift)));
}

sub hz2unicode {
	my $res = "";

	my $str = decode("gbk", shift);
	my $len = length($str);
	for(0..$len - 1) {
		my $c = substr $str, $_, 1;
		$res .= sprintf("%x", unpack("U*", $c));
	} 
	
	return $res;	
}
sub utf82hz {
	 encode("gbk",decode("utf8",  pack("H*", shift)));;
}

sub unicode2hz {
	encode("gbk", pack("U*", sprintf("%d", hex(shift))))
}

sub AUTOLOAD {
	my($fun) = ($AUTOLOAD =~ /.*:(\w+)$/);
	my($f1, $f2) = split /2/, $fun;
	&{"hz2". $f2}(&{$f1."2hz"}(shift));
}

1;
__END__

=encoding utf8

=head1 NAME

Encode::CN::Utility - manipulations between Hanzi and its GBK, UTF8 and UNICODE encodings

=head1 SYNOPSIS

This module provides a flexible interface to convert Chinese Hanzi to its GBK, UTF8 and UNICODE
encodings, and vice versa. Meanwhile, it also can do conversation among the three encodings.
	
	use Encodings::CN::Utility; 
	print hz2gbk("小"); #expected "d0a1"
	print gbk2hz("d0a1"); #expected "小"


=head1 METHODS

This module  exports the following functions:

hz2gbk gbk2hz hz2utf8 hz2unicode utf82hz unicode2hz
gbk2utf8 gbk2unicode utf82gbk utf82unicode
unicode2gbk unicode2utf8

=over

=item * hz2gbk

convert hanzi(s) to its gbk encodings

=item * hz2utf8

convert hanzi(s) to its utf8 encodings

=item * hz2unicode

convert hanzi(s) to its unicode encodings

=item * gbk2hz

convert gbk encodings to its corresponding hanzi(s)

=item * utf82hz

convert utf8 encodings to its corresponding hanzi(s)

=item * unicode2hz

convert unicode encoding to its corresponding hanzi, which temporarily
doesn't support string conversion

=item * gbk2utf8

convert gbk encodings to the utf8 encodings of its correspoinding hanzi(s)

=item * gbk2unicode

convert gbk encodings to the unicode encodings of its correspoinding hanzi(s)

=item * utf82gbk 

convert utf8 encodings to the gbk encodings of its correspoinding hanzi(s)

=item * utf82unicode

convert utf8 encodings to the unicode encodings of its correspoinding hanzi(s)


=item * unicode2gbk

convert unicode encodings to the gbk encodings of its correspoinding hanzi(s)

=item * unicode2utf8

convert unicode encodings to the utf8 encodings of its correspoinding hanzi(s)

=back


=head1 AUTHOR

Sal Zhong(仲伟祥) L<zhongxiang721@gmail.com>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode>


