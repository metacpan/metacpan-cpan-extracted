# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body;{
our $VERSION = '3.020';
}

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use Scalar::Util     qw/weaken refaddr blessed/;
use File::Basename   qw/basename/;

use Mail::Message::Field       ();
use Mail::Message::Body::Lines ();
use Mail::Message::Body::File  ();

use MIME::Types      ();
my $mime_types = MIME::Types->new;
my $mime_plain = $mime_types->type('text/plain');

#--------------------

use overload
	bool  => sub {1},   # $body->print if $body
	'""'  => 'string_unless_carp',
	'@{}' => 'lines',
	'=='  => sub {ref $_[1] && refaddr $_[0] == refaddr $_[1]},
	'!='  => sub {ref $_[1] && refaddr $_[0] != refaddr $_[1]};

#--------------------

my $body_count = 0;  # to be able to compare bodies for equivalence.

sub new(@)
{	my $class = shift;

	$class eq __PACKAGE__
		or return $class->SUPER::new(@_);

	my %args  = @_;
	exists $args{file} ? Mail::Message::Body::File->new(@_) : Mail::Message::Body::Lines->new(@_);
}

# All body implementations shall implement all of the following!!
sub _data_from_filename(@)   { $_[0]->notImplemented }
sub _data_from_filehandle(@) { $_[0]->notImplemented }
sub _data_from_lines(@)      { $_[0]->notImplemented }

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);

	$self->{MMB_modified} = $args->{modified} || 0;

	my $filename = $args->{filename};
	my $mime     = $args->{mime_type};

	if(defined(my $file = $args->{file}))
	{
		if(!ref $file)
		{	$self->_data_from_filename($file) or return;
			$filename ||= $file;
			$mime ||= $mime_types->mimeTypeOf($filename) || (-T $file ? 'text/plain' : 'application/octet-stream');
		}
		elsif(ref $file eq 'GLOB' || (blessed $file && $file->isa('IO::Handle')))
		{	$self->_data_from_filehandle($file) or return;
		}
		else
		{	croak "message body: illegal datatype `".ref($file)."' for file option";
		}
	}
	elsif(defined(my $data = $args->{data}))
	{
		if(!ref $data)
		{	my @lines = split /^/, $data;
			$self->_data_from_lines(\@lines)
		}
		elsif(ref $data eq 'ARRAY')
		{	$self->_data_from_lines($data) or return;
		}
		else
		{	croak "message body: illegal datatype `".ref($data)."' for data option";
		}
	}
	elsif(! $self->isMultipart && ! $self->isNested)
	{	# Neither 'file' nor 'data', so empty body.
		$self->_data_from_lines( [] ) or return;
	}

	# Set the content info

	my ($transfer, $disp, $descr, $cid, $lang) = @$args{
		qw/transfer_encoding disposition description content_id language/ };

	if(defined $filename)
	{	$disp //= Mail::Message::Field->new(
			'Content-Disposition' => (-T $filename ? 'inline' : 'attachment'),
			filename => basename($filename)
		);
		$mime //= $mime_types->mimeTypeOf($filename);
	}

	if(ref $mime && $mime->isa('MIME::Type'))
	{	$mime     = $mime->type;
	}

	if(defined(my $based = $args->{based_on}))
	{	$mime     //= $based->type;
		$transfer //= $based->transferEncoding;
		$disp     //= $based->disposition;
		$descr    //= $based->description;
		$lang     //= $based->language;
		$cid      //= $based->contentId;

		$self->{MMB_checked} = exists $args->{checked} ? $args->{checked} : $based->checked;
	}
	else
	{	$transfer = $args->{transfer_encoding};
		$self->{MMB_checked} = $args->{checked} || 0;
	}

	$mime ||= 'text/plain';
	$mime   = $self->type($mime);

	my $default_charset = exists $args->{charset} ? $args->{charset} : 'PERL';
	$mime->attribute(charset => $default_charset)
		if $default_charset
		&& $mime =~ m!^text/!i
		&& !$mime->attribute('charset');

	$self->transferEncoding($transfer) if defined $transfer;
	$self->disposition($disp)          if defined $disp;
	$self->description($descr)         if defined $descr;
	$self->language($lang)             if defined $lang;
	$self->contentId($cid)             if defined $cid;
	$self->type($mime);

	# Set message where the body belongs to.

	$self->message($args->{message})
		if defined $args->{message};

	$self->{MMB_seqnr} = $body_count++;
	$self;
}



sub clone() { $_[0]->notImplemented }

#--------------------

sub decoded(@)
{	my $self = shift;
	$self->encode(charset => 'PERL', transfer_encoding => 'none', @_);
}

#--------------------

sub message(;$)
{	my $self = shift;
	if(@_)
	{	if($self->{MMB_message} = shift)
		{	weaken $self->{MMB_message};
		}
	}
	$self->{MMB_message};
}


sub isDelayed() {0}


sub isMultipart() {0}


sub isNested() {0}


sub partNumberOf($)
{	shift->log(ERROR => 'part number needs multi-part or nested');
	'ERROR';
}

#--------------------

sub type(;$)
{	my $self = shift;
	return $self->{MMB_type} if !@_ && defined $self->{MMB_type};

	delete $self->{MMB_mime};
	my $type = shift // 'text/plain';

	$self->{MMB_type} = ref $type ? $type->clone : Mail::Message::Field->new('Content-Type' => $type);
}


sub mimeType()
{	my $self  = shift;
	return $self->{MMB_mime} if exists $self->{MMB_mime};

	my $field = $self->{MMB_type};
	my $body  = defined $field ? $field->body : '';
	$self->{MMB_mime} = length $body ? ($mime_types->type($body) || MIME::Type->new(type => $body)) : $mime_plain;
}


sub charset() { $_[0]->type->attribute('charset') }


sub transferEncoding(;$)
{	my $self = shift;
	return $self->{MMB_transfer} if !@_ && defined $self->{MMB_transfer};

	my $set = shift // 'none';
	$self->{MMB_transfer} = blessed $set ? $set->clone : Mail::Message::Field->new('Content-Transfer-Encoding' => $set);
}


sub description(;$)
{	my $self = shift;
	return $self->{MMB_description} if !@_ && $self->{MMB_description};

	my $disp = shift // 'none';
	$self->{MMB_description} = blessed $disp ? $disp->clone : Mail::Message::Field->new('Content-Description' => $disp);
}


sub disposition(;$)
{	my $self = shift;
	return $self->{MMB_disposition} if !@_ && $self->{MMB_disposition};

	my $disp = shift // 'none';
	$self->{MMB_disposition} = blessed $disp ? $disp->clone : Mail::Message::Field->new('Content-Disposition' => $disp);
}


sub language(@)
{	my $self = shift;
	return $self->{MMB_lang} if !@_ && $self->{MMB_lang};

	my $langs
	  = @_ > 1        ? (join ', ', @_)
	  : blessed $_[0] ? $_[0]
	  : ref $_[0] eq 'ARRAY' ? (join ', ', @{$_[0]})
	  :    $_[0];

	$self->{MMB_lang}
	  = ! defined $langs || ! length $langs ? undef
	  : blessed $langs ? $langs->clone
	  :    Mail::Message::Field->new('Content-Language' => $langs);
}


sub contentId(;$)
{	my $self = shift;
	return $self->{MMB_id} if !@_ && $self->{MMB_id};

	my $cid = shift // 'none';
	$self->{MMB_id} = blessed $cid ? $cid->clone : Mail::Message::Field->new('Content-ID' => $cid);
}


sub checked(;$)
{	my $self = shift;
	@_ ? ($self->{MMB_checked} = shift) : $self->{MMB_checked};
}


sub nrLines(@)  { $_[0]->notImplemented }


sub size(@)  { $_[0]->notImplemented }

#--------------------

sub string() { $_[0]->notImplemented }

sub string_unless_carp()
{	my $self  = shift;
	(caller)[0] eq 'Carp' or return $self->string;

	my $class = ref $self =~ s/^Mail::Message/MM/r;
	"$class object";
}


sub lines() { $_[0]->notImplemented }


sub file(;$) { $_[0]->notImplemented }


sub print(;$) { $_[0]->notImplemented }


sub printEscapedFrom($) { $_[0]->notImplemented }


sub write(@)
{	my ($self, %args) = @_;
	my $filename = $args{filename}
		or die "No filename for write() body";

	open my $out, '>', $filename or return;
	$self->print($out);
	$out->close or return undef;
	$self;
}


sub endsOnNewline() { $_[0]->notImplemented }


sub stripTrailingNewline() { $_[0]->notImplemented }

#--------------------

sub read(@) { $_[0]->notImplemented }


sub contentInfoTo($)
{	my ($self, $head) = @_;
	return unless defined $head;

	my $lines  = $self->nrLines;
	my $size   = $self->size;
	$size     += $lines if $Mail::Message::crlf_platform;

	$head->set($self->type);
	$head->set($self->transferEncoding);
	$head->set($self->disposition);
	$head->set($self->description);
	$head->set($self->language);
	$head->set($self->contentId);
	$self;
}


sub contentInfoFrom($)
{	my ($self, $head) = @_;

	$self->type($head->get('Content-Type', 0));

	my ($te, $disp, $desc, $cid, $lang) = map {
		my $x = $head->get("Content-$_") || '';
		s/^\s+//,s/\s+$// for $x;
		length $x ? $x : undef;
	} qw/Transfer-Encoding Disposition Description ID Language/;

	$self->transferEncoding($te);
	$self->disposition($disp);
	$self->description($desc);
	$self->language($lang);
	$self->contentId($cid);

	delete $self->{MMB_mime};
	$self;

}


sub modified(;$)
{	my $self = shift;
	@_ or return $self->isModified;  # compat 2.036
	$self->{MMB_modified} = shift;
}


sub isModified() { $_[0]->{MMB_modified} }


sub fileLocation(;@)
{	my $self = shift;
	@_ or return @$self{ qw/MMB_begin MMB_end/ };
	@$self{ qw/MMB_begin MMB_end/ } = @_;
}


sub moveLocation($)
{	my ($self, $dist) = @_;
	$self->{MMB_begin} -= $dist;
	$self->{MMB_end}   -= $dist;
	$self;
}


sub load() { $_[0] }

#--------------------

my @in_encode = qw/check encode encoded eol isBinary isText unify dispositionFilename/;
my %in_module = map +($_ => 'encode'), @in_encode;

sub AUTOLOAD(@)
{	my $self  = shift;
	our $AUTOLOAD;
	my $call = $AUTOLOAD =~ s/.*\:\://gr;

	my $mod = $in_module{$call} || 'construct';
	if($mod eq 'encode') { require Mail::Message::Body::Encode    }
	else                 { require Mail::Message::Body::Construct }

	no strict 'refs';
	return $self->$call(@_) if $self->can($call);  # now loaded

	# AUTOLOAD inheritance is a pain
	confess "Method $call() is not defined for a ", ref $self;
}

#--------------------

1;
