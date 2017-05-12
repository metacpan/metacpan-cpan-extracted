use strict;
use Test;

sub case
{
    my($params)=@_;
    for my $body ($params->{body}) {
	my($bodylen,$headers,$title);

	$bodylen=length($body);
	$title=$params->{title};
	$headers=new HTTP::Headers('Content-Length' => $bodylen);
	$headers->header(%{$params->{headers}});
	for my $chunklen (@{$params->{chunk_lengths}}) {
	    my($resp,$destination,$fh,$saver,$pos);

	    $resp=new HTTP::Response($params->{code},undef,$headers);
	    $destination=$params->{before};
	    open($fh,'+<',\$destination)
		or die "Can't open scalar: $!";
	    eval {
		$saver=new HTTP::RangeSaver($fh,%{$params->{saverparams}});
		$pos=0;
		while ($pos<$bodylen) {
		    my($len);

		    $len=$bodylen-$pos;
		    $len=$chunklen if $len>$chunklen;
		    $saver->process(substr($body,$pos,$len),$resp);
		    $pos+=$len;
		}
	    };
	    if (defined(my $die=$params->{die})) {
		ok($@,$die,
		   "case $title: unexpected error");
	    }
	    if (defined(my $after=$params->{after})) {
		ok($destination,$after,
		   "case $title: unexpected file contents");
	    }
	    if (defined(my $ignored=$params->{ignored})) {
		ok($resp->content(),$ignored,
		   "case $title: unexpected junk");
	    }
	    if (defined(my $length=$params->{length})) {
		ok($saver->get_length(),$length,
		   "case $title: unexpected entity length");
	    }
	    if (defined(my $type=$params->{type})) {
		ok($saver->get_type(),$type,
		   "case $title: unexpected content type");
	    }
	    if (defined(my $written=$params->{written})) {
		ok($saver->get_written(),$written,
		   "case $title: unexpected written byte count");
	    }
	    if (defined(my $ranges=$params->{ranges})) {
		ok(join(",",map(join("-",@{$_}),@{$saver->get_ranges()})),
		   $ranges,
		   "case $title: unexpected written ranges");
	    }
	    if (defined(my $incomplete=$params->{incomplete})) {
		ok($saver->is_incomplete(),$incomplete);
	    }
	}
    }
}

sub count_tests
{
    my($params)=@_;
    my($result);

    $result=0;
    foreach my $key (qw(die type length after written ranges
			ignored incomplete)) {
	$result++ if defined($params->{$key});
    }
    return $result*@{$params->{chunk_lengths}};
}

sub make_multipart_body
{
    my(%params)=@_;
    my($result,$boundary,$type,$length);

    $result='';
    $type=$params{content_type};
    $boundary=$params{boundary};
    $length=$params{length};
    foreach my $part (@{$params{parts}}) {
	my($first,$last);

	$first=$part->{pos};
	$last=$first+length($part->{text})-1;
	$result.="\x0D\x0A--$boundary\x0D\x0A";
	$result.="Content-Type: $type\x0D\x0A";
	$result.="Content-Range: bytes $first-$last/$length\x0D\x0A\x0D\xA";
	$result.=$part->{text};
    }
    $result.="\x0D\x0A--$boundary--\x0D\x0A";
    $result.=$params{junk};
    return $result;
}

my(@cases);

BEGIN {
    @cases=
    (
     {
	 title   => 'one range',
	 code    => 206,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Range'  => 'bytes 10-19/30',
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '**********0123456789*****',
	 ignored => 'junk',
	 length  => 30,
	 type    => 'application/octet-stream',
	 written => 10,
	 ranges  => '10-19',
	 incomplete => '',
     },
     {
	 title   => 'two ranges',
	 code    => 206,
	 headers => {
	     'Content-Type' => 'multipart/byteranges; boundary=THIS_SEPARATES',
	 },
	 body    => make_multipart_body(
	     content_type => 'text/plain',
	     boundary     => 'THIS_SEPARATES',
	     length       => 50,
	     parts        => [
		  {
		      pos  => 10,
		      text => '0123456789',
		  },
		  {
		      pos  => 30,
		      text => 'abcdefghij',
		  },
	     ],
	     junk         => 'garbage',
	 ),
	 before  => '***********************************',
	 chunk_lengths => [1,1024],

	 after   => '**********0123456789**********abcdefghij',
	 ignored => 'garbage',
	 length  => 50,
	 type    => 'text/plain',
	 written => 20,
	 ranges  => '10-19,30-39',
	 incomplete => '',
     },
     {
	 title   => 'one incomplete',
	 code    => 206,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Range'  => 'bytes 10-19/30',
	 },
	 body    => '0123456',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '**********0123456********',
	 ignored => '',
	 length  => 30,
	 type    => 'application/octet-stream',
	 written => 7,
	 ranges  => '10-16',
	 incomplete => 1,
     },
     {
	 title   => 'two incomplete',
	 code    => 206,
	 headers => {
	     'Content-Type' => 'multipart/byteranges; boundary=THIS_SEPARATES',
	 },
	 body    => substr(make_multipart_body(
	     content_type => 'text/plain',
	     boundary     => 'THIS_SEPARATES',
	     length       => 50,
	     parts        => [
		  {
		      pos  => 10,
		      text => '0123456789',
		  },
		  {
		      pos  => 30,
		      text => 'abcdefghij',
		  },
	     ],
	     junk         => '',
	 ),0,-27),
	 before  => '****************************************',
	 chunk_lengths => [1024],

	 after   => '**********0123456789**********abcde*****',
	 ignored => '',
	 length  => 50,
	 type    => 'text/plain',
	 written => 15,
	 ranges  => '10-19,30-34',
	 incomplete => 1,
     },
     {
	 title   => 'definite incomplete',
	 code    => 200,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Length' => 20,
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '0123456789junk***********',
	 ignored => '',
	 length  => 20,
	 type    => 'application/octet-stream',
	 written => 14,
	 ranges  => '0-13',
	 incomplete => 1,
     },
     {
	 title   => 'require partial',
	 code    => 200,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],
	 saverparams => {
	     require_partial => 1,
	 },

	 die     => qr/No partial content/,
	 after   => '*************************',
     },
     {
	 title   => 'require length 1',
	 code    => 200,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Length' => undef,
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],
	 saverparams => {
	     require_length => 1,
	 },

	 die     => qr/No length/,
	 after   => '*************************',
     },
     {
	 title   => 'require length 2',
	 code    => 206,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Range'  => 'bytes 10-19/*',
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],
	 saverparams => {
	     require_length => 1,
	 },

	 die     => qr/No length/,
	 after   => '*************************',
     },
     {
	 title   => 'require resource',
	 code    => 202,
	 headers => {
	     'Content-Type'   => 'text/plain',
	 },
	 body    => 'Might get around to it some day.',
	 before  => '*************************',
	 chunk_lengths => [1024],
	 saverparams => {
	     require_resource => 1,
	 },

	 die     => qr/No resource/,
	 after   => '*************************',
     },
     {
	 title   => 'ignore',
	 code    => 202,
	 headers => {
	     'Content-Type'   => 'text/plain',
	 },
	 body    => 'Might get around to it some day.',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '*************************',
	 ignored => 'Might get around to it some day.',
	 type    => undef,
	 written => 0,
	 ranges  => '',
     },
     {
	 title   => 'indefinite',
	 code    => 200,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	     'Content-Length' => undef,
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '0123456789junk***********',
	 ignored => '',
	 length  => undef,
	 type    => 'application/octet-stream',
	 written => 14,
	 ranges  => '0-13',
	 incomplete => '',
     },
     {
	 title   => 'definite',
	 code    => 200,
	 headers => {
	     'Content-Type'   => 'application/octet-stream',
	 },
	 body    => '0123456789junk',
	 before  => '*************************',
	 chunk_lengths => [1024],

	 after   => '0123456789junk***********',
	 ignored => '',
	 length  => 14,
	 type    => 'application/octet-stream',
	 written => 14,
	 ranges  => '0-13',
	 incomplete => '',
     },
);

    my($count);
    foreach my $case (@cases) {
	$count+=count_tests($case);
    }

    plan(tests => $count);
}

use LWP;
use HTTP::RangeSaver;

foreach my $case (@cases) {
    case($case);
}

