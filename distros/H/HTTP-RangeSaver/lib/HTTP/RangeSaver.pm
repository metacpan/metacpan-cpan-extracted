package HTTP::RangeSaver;

use strict;

our $VERSION='0.01';

=head1 NAME

HTTP::RangeSaver - handle partial content HTTP responses

=head1 SYNOPSIS

 use LWP;
 use HTTP::RangeSaver;

 open(my $fh,'+<','example.mpeg') || die $!;
 my $req=new HTTP::Request
    (GET => 'http://www.example.com/example.mpeg');
 $req->header(Range => 'bytes='.(-s $fh).'-');
 my $saver=new HTTP::RangeSaver($fh);
 my $ua=new LWP::UserAgent;
 my $resp=$ua->request($req,$saver->get_callback());

=head1 DESCRIPTION

HTTP::RangeSaver is a helper class for updating an existing file with
data from a partial content HTTP response.  It understands both of the
partial content formats defined in RFC 2616 (a single Content-Range
header or a multipart/byteranges Content-Type).  For convenience, it
also handles complete content HTTP responses (status 200 or 203 rather
than 206).

=cut

use fields
    qw(fh delta truncate
       require_partial require_length require_resource
       methods expected buffer start_boundary end_boundary
       type length written partheaders ranges);

use Symbol
    qw(qualify_to_ref);

use HTTP::Headers;
use HTTP::Headers::Util
    qw(split_header_words);

=head1 CONSTRUCTOR

=over

=item my $saver=HTTP::RangeSaver->new($fh,%options);

$fh is an open filehandle.  It must allow seeking and writing.

%options is a list of key/value pairs for modifying the saver's
behaviour.

=over

=item truncate

Pass a true value to make the saver truncate the file to match the full
length of the returned entity.  Ignored if the server doesn't report a
definite length.

=item require_length

Pass a true value to make the saver die if the server doesn't report a
definite full length for the returned entity.

=item require_partial

Pass a true value to make the saver die if the server returns a complete
entity rather than a partial one.

=item require_resource

Pass a true value to make the saver die if the server returns an entity
that doesn't represent the requested resource (i.e. a 2xx status code
other than 200, 203, or 206).  This should never happen for a GET
request.

=item delta

A adjustment to be applied to all file offsets in the destination file.

=back

=back

=cut

sub new
{
    my($class,$fh,%params)=@_;
    my __PACKAGE__ $self;

    $self=fields::new($class);
    $self->{fh}=qualify_to_ref($fh,caller());
    if (exists($params{delta})) {
	$self->{delta}=int($params{delta});
    } else {
	$self->{delta}=0;
    }
    $self->{truncate}=$params{truncate} && 1;
    $self->{require_partial}=$params{require_partial} && 1;
    $self->{require_length}=$params{require_length} && 1;
    $self->{require_resource}=$params{require_resource} && 1;
    $self->{methods}=['init'];
    $self->{written}=0;
    return $self;
}

=head1 METHODS

=over

=item my $callback=$saver->get_callback();

Returns a closure suitable for passing as the callback function argument
to L<LWP::UserAgent>'s request methods.

=cut

sub get_callback
{
    my __PACKAGE__ $self=shift(@_);

    return sub
    {
	$self->process(@_);
    };
}

=item $saver->process($data,$response,$protocol);

=item $saver->process(@_); # if called directly from the callback function

Call this method from your callback function if you want to do more than
just save the incoming data (e.g. display a progress indicator).

=cut

sub process
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	my($len,$methods);

	$len=length($data);
	$methods=$self->{methods};
	for (my $off=0; $off<$len; ) {
	    my($method);

	    $method=$methods->[-1];
	    if ($off) {
		$off+=$self->$method(substr($data,$off),@_);
	    } else {
		$off+=$self->$method($data,@_);
	    }
	}
    }
}

=item $saver->get_length();

Returns the total length of the returned entity, or an undefined value
if the length is indefinite (or hasn't arrived yet).

=cut

sub get_length
{
    my __PACKAGE__ $self=shift(@_);
    my($length);

    $length=$self->{length};
    undef $length if defined($length) && $length eq '*';
    return $length;
}

=item $saver->get_type();

Returns the MIME type of the returned entity, from either the
Content-Type header of the response or the first part header of a
multipart response.  Returns undef if this information hasn't arrived
yet.

=cut

sub get_type
{
    my __PACKAGE__ $self=shift(@_);

    return $self->{type};
}

=item $saver->get_written();

Returns the total number of bytes written by the saver (so far).  Useful
for displaying a simple progress indicator.

=cut

sub get_written
{
    my __PACKAGE__ $self=shift(@_);

    return $self->{written};
}

=item $saver->get_ranges();

Returns a reference to an array of ranges written by the saver (so far).
Each range is represented by a reference to a two-element array containing
the first and last byte numbers (ignoring the delta parameter) with the
same semantics as in the HTTP protocol.  Useful for displaying a complex
progress indicator.

=cut

sub get_ranges
{
    my __PACKAGE__ $self=shift(@_);

    return [map([@{$_}],grep($_->[1]>=$_->[0],@{$self->{ranges} || []}))];
}

=item $saver->get_partheaders();

Returns a reference to an array of HTTP::Headers objects, one for each
part (seen so far) of a multipart response.

=cut

sub get_partheaders
{
    my __PACKAGE__ $self=shift(@_);

    return [@{$self->{partheaders} || []}];
}

=item $saver->is_incomplete();

Returns true if the saver hasn't seen a complete response yet.

=cut

sub is_incomplete
{
    my __PACKAGE__ $self=shift(@_);
    my($method);

    $method=$self->{methods}->[-1];
    return $method ne 'ignore'
	&& $method ne 'indefinite';
}

=back

=cut

sub ignore
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	my($resp)=@_;

	$resp->add_content($data);
	return length($data);
    }
}

sub indefinite
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	my($len);
	local($\);

	$len=length($data);
	print {$self->{fh}} $data
	    or die "print error: $!";
	$self->{written}+=$len;
	$self->{ranges}->[-1]->[1]+=$len;
	return $len;
    }
}

sub definite
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	my($len,$expected);
	local($\);

	$len=length($data);
	$expected=$self->{expected};
	if ($len>$expected) {
	    $len=$expected;
	    print {$self->{fh}} substr($data,0,$len);
	} else {
	    print {$self->{fh}} $data;
	}
	$self->{ranges}->[-1]->[1]+=$len;
	$self->{written}+=$len;
	$expected-=$len;
	$self->{expected}=$expected;
	if (!$expected) {
	    pop(@{$self->{methods}});
	}
	return $len;
    }
}

sub headers
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	for my $buffer ($self->{buffer}) {
	    my($len,$buflen,@lines,$headers,$content_range);

	    $len=length($data);
	    $buflen=length($buffer);
	    $buffer.=$data;
	    $buffer =~ /\x0D?\x0A\x0D?\x0A/
		or return $len;
	    $len=$+[0]-$buflen;
	    substr($buffer,$-[0])='';
# why is there no HTTP::Headers::parse anyway?
	    $buffer =~ s/\x0D?\x0A\s+/ /g;
	    @lines=split(/\x0D?\x0A/,$buffer);
	    $buffer='';
	    $self->{methods}->[-1]='boundary';
	    $headers=new HTTP::Headers;
	    foreach my $line (@lines) {
		my($name,$value);

		$line =~ s/\s+$//;
		($name,$value)=($line =~ /^([^\s:]+)\s*:\s*(.*)$/)
		    or die "Malformed part headers";
		$headers->push_header($name,$value);
	    }
	    push(@{$self->{partheaders}},$headers);
	    $content_range=$headers->header('Content-Range');
	    defined($content_range)
		or die "Content-Range missing from part headers";
	    $self->content_range($content_range);
	    if (!defined($self->{type})) {
		$self->{type}=$headers->header('Content-Type');
	    }
	    return $len;
	}
    }
}

sub boundary
{
    my __PACKAGE__ $self=shift(@_);

    for my $data (shift(@_)) {
	for my $buffer ($self->{buffer}) {
	    my($len,$buflen,$pos,$methods);

	    $methods=$self->{methods};
	    $len=length($data);
	    $buflen=length($buffer);
	    $buffer.=$data;
	    if ($buffer =~ $self->{start_boundary}) {
		$len=$+[0]-$buflen;
		$buffer='';
		$methods->[-1]='headers';
	    } elsif ($buffer =~ $self->{end_boundary}) {
		$len=$+[0]-$buflen;
		$buffer='';
		pop(@{$methods});
	    }
	    return $len;
	}
    }
}

sub init
{
    my __PACKAGE__ $self=shift(@_);
    my(undef,$resp)=@_;
    my($code,$fh,$delta,$methods,$content_type);

    $methods=$self->{methods};
    $methods->[-1]='ignore';
    $fh=$self->{fh};
    $delta=$self->{delta};
    $code=$resp->code();
    $content_type=$resp->header('Content-Type');
    if ($code==206) {
	if (defined(my $content_range=$resp->header('Content-Range'))) {
	    $self->content_range($content_range);
	    $self->{type}=$content_type;
	} elsif (defined($content_type)) {
	    my($split,$ct,%params,$boundary);

	    ($split)=split_header_words($content_type);
	    ($ct,undef,%params)=@{$split};
	    unless ($ct eq 'multipart/byteranges'
		    && defined($boundary=$params{boundary})) {
		die "Unsupported Content-Type header";
	    }
	    undef $self->{type};
	    push(@{$methods},'boundary');
	    $self->{buffer}='';
	    $self->{start_boundary}=qr/\x0D?\x0A--\Q$boundary\E\x0D?\x0A/;
	    $self->{end_boundary}=qr/\x0D?\x0A--\Q$boundary\E--\x0D?\x0A/;
	    $self->{partheaders}=[];
	} else {
	    die "Unsupported kind of partial content";
	}
    } elsif ($code==200 || $code==203) {
	if ($self->{require_partial}) {
	    die "No partial content returned";
	}
	if (defined(my $content_length=$resp->header('Content-Length'))) {
	    $self->{length}=$content_length;
	    if ($self->{truncate}) {
		truncate($fh,$content_length+$delta)
		    or die "truncate error: $!";
	    }
	    $self->{expected}=$content_length;
	    if ($content_length>0) {
		push(@{$methods},'definite');
	    }
	} else {
	    if ($self->{require_length}) {
		die "No length returned";
	    }
	    $methods->[-1]='indefinite';
	}
	seek($fh,$delta,0)
	    or die "seek error: $!";
	if ($methods->[-1] ne 'ignore') {
	    push(@{$self->{ranges}},[0,-1]);
	}
	$self->{type}=$content_type;
    } else {
	if ($self->{require_resource}) {
	    die "No resource returned";
	}
    }
    return 0;
}

my $content_range_re=qr#^\s*bytes\s+(\d+)-(\d+)/(\d+|\*)#;

sub content_range
{
    my __PACKAGE__ $self=shift(@_);
    my($content_range)=@_;
    my($first,$last,$length,$fh,$delta);

    unless (($first,$last,$length)=($content_range =~ $content_range_re)
	    and $last>=$first
	    and $length eq '*' || $last<$length) {
	die "Malformed Content-Range header ($content_range)";
    }
    $fh=$self->{fh};
    $delta=$self->{delta};
    if (!defined($self->{length})) {
	$self->{length}=$length;
	if ($length eq '*') {
	    if ($self->{require_length}) {
		die "No length returned";
	    }
	} else {
	    if ($self->{truncate}) {
		truncate($fh,$length+$delta)
		    or die "truncate error: $!";
	    }
	}
    }
    seek($fh,$first+$delta,0)
	or die "seek error: $!";
    $self->{expected}=$last-$first+1;
    push(@{$self->{methods}},'definite');
    push(@{$self->{ranges}},[$first,$first-1]);
}

1;

=head1 AUTHOR

Bo Lindbergh E<lt>blgl@stacken.kth.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Bo Lindbergh

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

=cut

