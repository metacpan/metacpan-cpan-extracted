# $Id: /local/perl/HTTP-Response-OnDisk/trunk/lib/HTTP/Response/OnDisk.pm 11653 2007-05-26T04:35:46.191733Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTTP::Response::OnDisk;
use strict;
use warnings;
use base qw(Class::Data::Inheritable Class::Accessor::Fast);
use Class::Inspector;
use File::Spec;
use File::Temp;
use HTTP::Headers;
use HTTP::Status();
use Fcntl qw(SEEK_SET SEEK_END);
use Path::Class::Dir;

our $URI_CLASS = $HTTP::URI_CLASS || "URI";

our $VERSION = '0.02002';

__PACKAGE__->mk_classdata(default_dir => File::Spec->tmpdir);
__PACKAGE__->mk_accessors($_) for qw(storage_dir storage code message headers request previous protocol);

{
    foreach my $method (@{ Class::Inspector->methods('HTTP::Headers', 'public') }) {
        next if __PACKAGE__->can($method);
        # use eval to enforce method names on stack traces
        eval sprintf(<<"        EOSUB", $method, $method);
            sub %s { shift->headers->%s(\@_) }
        EOSUB
    }
}

sub new
{
    my ($class, $rc, $msg, $header, $content, $opts) = @_;
    $opts ||= {};

    my $dir = Path::Class::Dir->new($opts->{dir} || $class->default_dir || die "No directory specified");
    $dir->mkpath;

    my $self = bless {}, $class;
    $self->storage_dir($dir);
    $self->_init_storage();

    if (defined $header) {
        Carp::croak("Bad header argument") unless ref $header;
        if (ref $header eq 'ARRAY') {
            $header = HTTP::Headers->new(@$header);
        } else {
            $header = $header->clone;
        }
    } else {
        $header = HTTP::Headers->new;
    }
    $content = '' unless defined $content;

    $self->code($rc);
    $self->message($msg);
    $self->headers($header);
    $self->content($content);

    $self;
}

sub _init_storage
{
    my ($self) = @_;

    my $dir = $self->storage_dir();
    my $fh  =  File::Temp->new( TEMPLATE => 'hto-XXXXXXXXX', DIR => $dir->stringify, UNLINK => 1 ) ;
    $self->storage($fh);
    $fh->truncate(0); # XXX - This isn't portable, is it?
}

sub is_info     { HTTP::Status::is_info     (shift->code); }
sub is_success  { HTTP::Status::is_success  (shift->code); }
sub is_redirect { HTTP::Status::is_redirect (shift->code); }
sub is_error    { HTTP::Status::is_error    (shift->code); }

sub parse
{
    my($class, $str) = @_;
    my $status_line;
    if ($str =~ s/^(.*)\n//) {
        $status_line = $1;
    } else {
        $status_line = $str;
        $str = "";
    }

    my @hdr;
    while (1) {
        if ($str =~ s/^([^\s:]+)[ \t]*: ?(.*)\n?//) {
            push(@hdr, $1, $2);
            $hdr[-1] =~ s/\r\z//;
        } elsif (@hdr && $str =~ s/^([ \t].*)\n?//) {
            $hdr[-1] .= "\n$1";
            $hdr[-1] =~ s/\r\z//;
        } else {
            $str =~ s/^\r?\n//;
            last;
        }
    }
    
    my($protocol, $code, $message);
    if ($status_line =~ /^\d{3} /) {
       # Looks like a response created by HTTP::Response->new
       ($code, $message) = split(' ', $status_line, 2);
    } else {
       ($protocol, $code, $message) = split(' ', $status_line, 3);
    }
    my $self = $class->new($code, $message, \@hdr, $str);
    $self->protocol($protocol) if $protocol;
    $self;
}

sub clone
{
    my $self = shift;
    die "unimplemented";
}

sub status_line
{
    my $self = shift;
    my $code = $self->code || "000";
    my $mess = $self->message || HTTP::Status::status_message($code) || "Unknown code";
    return "$code $mess";
}

sub base
{   
    my $self = shift;
    my $base = $self->header('Content-Base')     ||  # used to be HTTP/1.1
               $self->header('Content-Location') ||  # HTTP/1.1
               $self->header('Base');                # HTTP/1.0
    if ($base && $base =~ /^$URI::scheme_re:/o) {
        # already absolute
        return $URI_CLASS->new($base);
    }

    my $req = $self->request;
    if ($req) {
        # if $base is undef here, the return value is effectively
        # just a copy of $self->request->uri.
        return $URI_CLASS->new_abs($base, $req->uri);
    } 
       
    # can't find an absolute base
    return undef;
}

sub _slurp_storage
{
    my $self = shift;
    my $fh   = $self->storage();
    $fh->seek(0, 0);
    return do { local $/ = undef; <$fh> } || '';
}

sub content
{
    my $self = shift;
    if (@_) {
        $self->_init_storage();
        $self->add_content( $_[0] );
    }
    my $wantarray = wantarray;
    return ! defined $wantarray ? () : $self->_slurp_storage();
}

sub add_content
{
    my ($self, $content) = @_;
    return unless defined $content;
    my $fh = $self->storage();
    $fh->seek(0, SEEK_END);
    $fh->print($content);
}

sub current_age
{   
    my $self = shift;
    # Implementation of RFC 2616 section 13.2.3
    # (age calculations)
    my $response_time = $self->client_date;
    my $date = $self->date;
    
    my $age = 0;
    if ($response_time && $date) {
        $age = $response_time - $date;  # apparent_age
        $age = 0 if $age < 0;
    }
    
    my $age_v = $self->header('Age');
    if ($age_v && $age_v > $age) {
        $age = $age_v;   # corrected_received_age
    }  
    
    my $request = $self->request; 
    if ($request) {
        my $request_time = $request->date;
        if ($request_time) {
            # Add response_delay to age to get 'corrected_initial_age'
            $age += $response_time - $request_time;
        }
    }
    if ($response_time) {
        $age += time - $response_time;
    }
    return $age;
}

sub freshness_lifetime
{
    my $self = shift;

    # First look for the Cache-Control: max-age=n header
    my @cc = $self->header('Cache-Control');
    if (@cc) {
        my $cc;
        for $cc (@cc) {
            my $cc_dir;
            for $cc_dir (split(/\s*,\s*/, $cc)) {
                if ($cc_dir =~ /max-age\s*=\s*(\d+)/i) {
                    return $1;
                }
            }
        }  
    } 
       
    # Next possibility is to look at the "Expires" header
    my $date = $self->date || $self->client_date || time;
    my $expires = $self->expires;
    unless ($expires) {
        # Must apply heuristic expiration
        my $last_modified = $self->last_modified;
        if ($last_modified) {
            my $h_exp = ($date - $last_modified) * 0.10;  # 10% since last-mod
            if ($h_exp < 60) {
                return 60;  # minimum
            } elsif ($h_exp > 24 * 3600) {
                # Should give a warning if more than 24 hours according to
                # RFC 2616 section 13.2.4, but I don't know how to do it
                # from this function interface, so I just make this the
                # maximum value.
                return 24 * 3600;
            }
            return $h_exp;
        } else {
            return 3600;  # 1 hour is fallback when all else fails
        }
    }
    return $expires - $date;
}

sub is_fresh
{   
    my $self = shift;
    $self->freshness_lifetime > $self->current_age;
}

sub fresh_until
{   
    my $self = shift;
    return $self->freshness_lifetime - $self->current_age + time;
}

sub as_string
{   
    my($self, $eol) = @_;
    $eol = "\n" unless defined $eol;
    
    # The calculation of content might update the headers
    # so we need to do that first.
    my $content = $self->content;

    my $status_line = $self->status_line;
    my $proto = $self->protocol;
    $status_line = "$proto $status_line" if $proto;
    
    return 
        # This from HTTP::Response
        join($eol, $status_line,
            # Below from HTTP::Message
            join("", $self->headers->as_string($eol),
            $eol,
            $content,
            (@_ == 1 && length($content) &&
             $content !~ /\n\z/) ? "\n" : "",
        )
    );
}

sub content_ref { die "content_ref not supported for HTTP::Response::OnDisk" }

# XXX - Ripped right out of HTTP::Response, except for the content_ref part.
sub decoded_content
{
    my($self, %opt) = @_;

    eval {
	require HTTP::Headers::Util;
	my($ct, %ct_param);
	if (my @ct = HTTP::Headers::Util::split_header_words($self->header("Content-Type"))) {
	    ($ct, undef, %ct_param) = @{$ct[-1]};
	    $ct = lc($ct);

	    die "Can't decode multipart content" if $ct =~ m,^multipart/,;
	}

	if (my $h = $self->header("Content-Encoding")) {
	    $h =~ s/^\s+//;
	    $h =~ s/\s+$//;
	    for my $ce (reverse split(/\s*,\s*/, lc($h))) {
		next unless $ce || $ce eq "identity";
		if ($ce eq "gzip" || $ce eq "x-gzip") {
		    require IO::Uncompress::Gunzip;
            # open the filehandle, and sequentially write the decoded 
            # content to disk. For this, we swap the temp storage
            my $source = $self->storage;
            $source->seek(0, SEEK_SET);
            $self->_init_storage();
            my $dest   = $self->storage;
            IO::Uncompress::Gunzip::gunzip($source, $dest) or
                die "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
		}
		elsif ($ce eq "x-bzip2") {
		    require IO::Uncompress::Bunzip2;
            # open the filehandle, and sequentially write the decoded 
            # content to disk. For this, we swap the temp storage
            my $source = $self->storage;
            $source->seek(0, SEEK_SET);
            $self->_init_storage();
            my $dest   = $self->storage;
            IO::Uncompress::Bunzip2::bunzip2($source, $dest) or
                die "bunzip failed: $IO::Uncompress::Bunzip::Bunzip2Error";
		}
		elsif ($ce eq "deflate") {
            # XXX - Please, somebody more knowledgeable with this stuff, help.
            # This whole deflate stuff is so rediculously expensive, I'd
            # rather avoid it if not for completeness.
            require IO::Uncompress::Inflate;
            my $source = $self->storage;
            $source->seek(0, SEEK_SET);
            $self->_init_storage();
            my $dest   = $self->storage;

            # file handle to file handle transfer
            unless (IO::Uncompress::Inflate::inflate($source, $dest)) {
    			# "Content-Encoding: deflate" is supposed to mean the "zlib"
                # format of RFC 1950, but Microsoft got that wrong, so some
                # servers sends the raw compressed "deflate" data.  This
                # tries to inflate this format.
    			my($i, $status) = Compress::Zlib::inflateInit(
    			    WindowBits => -Compress::Zlib::MAX_WBITS(),
                );
    			die "Can't init inflate object" unless 
                    $i && $status == Compress::Zlib::Z_OK();

                # XXX - Argh, we're reading the *entire* contents from disk...
                my $out;
    			($out, $status) = $i->inflate($self->content);
    			if ($status != Compress::Zlib::Z_STREAM_END()) {
    			    if ($status == Compress::Zlib::Z_OK()) {
        				$self->push_header("Client-Warning" =>
        				    "Content might be truncated; incomplete deflate stream");
    			    } else {
        				# something went bad, can't trust $out any more
        				$out = undef;
    			    }
    			}
    		    die "Can't inflate content" unless defined $out;

                # finally write to buffer. sigh.
                $self->content( $out );
		    }
		} elsif ($ce eq "compress" || $ce eq "x-compress") {
		    die "Can't uncompress content";
		} elsif ($ce eq "base64") {  # not really C-T-E, but should be harmless
            # XXX - We read the entire content here, too
		    require MIME::Base64;
            $self->content( MIME::Base64::decode( $self->content ) );
		} elsif ($ce eq "quoted-printable") { # not really C-T-E, but should be harmless
            # XXX - We read the entire content here, too
		    require MIME::QuotedPrint;
            $self->content( MIME::QuotedPRint::decode( $self->content ) );
		} else {
		    die "Don't know how to decode Content-Encoding '$ce'";
		}
	    }
	}

	if ($ct && $ct =~ m,^text/,,) {
	    my $charset = $opt{charset} || $ct_param{charset} || $opt{default_charset} || "ISO-8859-1";
	    $charset = lc($charset);
	    if ($charset ne "none") {
    		require Encode;
            my $source = $self->storage;
            $source->seek(0, SEEK_SET);
            $self->_init_storage();
            my $dest   = $self->storage;
            my $buffer = '';
            while (1) {
                my $read = $source->read($buffer, 4092, length($buffer));
                last if ($read <= 0);

                $dest->print( Encode::decode($charset, $buffer, Encode::FB_QUIET() ) );
    	    }
    	}
    }
    };
    if ($@) {
    	Carp::croak($@) if $opt{raise_error};
    	return undef;
    }

    return defined wantarray ? 
         ($opt{ref} ? \$self->content : $self->content) :
        () # don't do anything if we're doing this in void context
    ;
}

1;

__END__

=head1 NAME

HTTP::Response::OnDisk - HTTP::Response That Writes To Disk

=head1 SYNOPSIS

  use HTTP::Response::OnDisk;

  my $r = HTTP::Response::OnDisk->new($rc, $message, $headers, $content);

  my $r = HTTP::Response::OnDisk->new($rc, $message, $headers, $content,
    { dir => '/var/blah' }
  );

  # Change the default storage path
  HTTP::Response::OnDisk->default_dir('/var/blah');

=head1 DESCRIPTION

HTTP::Response::OnDisk is an API-compatible replacement for HTTP::Response,
whose purpose is to store the content into disk instead of memory. This
greatly reduces overhead on long-running processes, such as crawlers like
Gungho.

Code, message, and headers are fairly harmless in comparison to the content,
so they are stored in memory. Content is stored on a temporary file disk,
which is cleaned up when the response is freed.

=head1 CLASS METHODS

=head2 default_dir

When set, changes the default directory where the data is stored.

=head1 METHODS

=head2 new $code, $message, $headers, $content, $opts

Creates a new HTTP::Response::OnDisk instance. Accepts the same parameters
as HTTP::Response, plus an optional fifth hashref, where you may specify
the following:

=over 4

=item dir

The directory where the temporary file is stored. See default_dir() to
change the default directory path.

=back

=head2 content

Sets/gets the content. Internally this accesses the underlying temporary
file storage. If called in void context, attempts to avoid reading from
the storage.

=head2 add_content

Adds content to the end of buffer.

=head2 storage

Returns the File::Temp object that contains the buffer. Note that when
accessing this, you should probably do a seek() to ensure you are at the
right location in the file.

=head2 as_string

Returns the string representation of the object.

=head2 clone

Clones the object.

=head2 code

Returns the status code.

=head2 current_age

=head2 fresh_until

=head2 freshness_lifetime

=head2 is_fresh

=head2 parse

Given a string, parses it and creates a new HTTP::Response::OnDisk instance

=head2 status_line

=head2 base

=head2 is_success

=head2 is_info

=head2 is_redirect

=head2 is_error

=head2 content_ref

This doesn't make sense in HTTP::Response::OnDisk, so is intentionally not
implemented. It will croak if used.

=head2 decoded_content

Attempts to decode the content based on Content-Transfer-Encoding, and the
character set specified. Note that this method internally behaves quite
differently from that of HTTP::Response.

For now this actually overwrites the internal buffer. If you care enough
about memory to use this module, you shouldn't be doing stuff that requires
reading the entire buffer out anyways. Let this method take care of the
content, and access it later.

=head1 PROXIED METHODS

These methods are proxied to HTTP::Headers object.

=head2 authorization

=head2 authorization_basic

=head2 clear

=head2 client_date

=head2 content_encoding

=head2 content_language

=head2 content_length                               

=head2 content_type

=head2 date

=head2 expires

=head2 from

=head2 header

=head2 header_field_names

=head2 if_modified_since

=head2 if_unmodified_since

=head2 init_header

=head2 last_modified

=head2 proxy_authenticate

=head2 proxy_authorization

=head2 proxy_authorization_basic

=head2 push_header

=head2 referer

=head2 referrer

=head2 remove_content_headers

=head2 remove_header

=head2 scan

=head2 server

=head2 title

=head2 user_agent

=head2 warning

=head2 www_authenticate

=head1 SEE ALSO

L<HTTP::Response|HTTP::Response>

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut