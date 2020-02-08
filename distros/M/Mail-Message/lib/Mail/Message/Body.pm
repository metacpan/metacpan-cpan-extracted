# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Field;
use Mail::Message::Body::Lines;
use Mail::Message::Body::File;

use Carp;
use Scalar::Util     qw/weaken refaddr/;
use File::Basename   qw/basename/;

use MIME::Types;
my $mime_types = MIME::Types->new;
my $mime_plain = $mime_types->type('text/plain');


use overload
    bool  => sub {1}   # $body->print if $body
  , '""'  => 'string_unless_carp'
  , '@{}' => 'lines'
  , '=='  => sub {ref $_[1] && refaddr $_[0] == refaddr $_[1]}
  , '!='  => sub {ref $_[1] && refaddr $_[0] != refaddr $_[1]};

#------------------------------------------


my $body_count = 0;  # to be able to compare bodies for equivalence.

sub new(@)
{   my $class = shift;

    return $class->SUPER::new(@_)
         unless $class eq __PACKAGE__;

    my %args  = @_;

      exists $args{file}
    ? Mail::Message::Body::File->new(@_)
    : Mail::Message::Body::Lines->new(@_);
}

# All body implementations shall implement all of the following!!

sub _data_from_filename(@)   {shift->notImplemented}
sub _data_from_filehandle(@) {shift->notImplemented}
sub _data_from_glob(@)       {shift->notImplemented}
sub _data_from_lines(@)      {shift->notImplemented}

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    $self->{MMB_modified} = $args->{modified} || 0;

    my $filename = $args->{filename};
	my $mime     = $args->{mime_type};

    if(defined(my $file = $args->{file}))
    {
        if(!ref $file)
        {   $self->_data_from_filename($file) or return;
            $filename ||= $file;
            $mime ||= $mime_types->mimeTypeOf($filename)
                  || (-T $file ? 'text/plain' : 'application/octet-stream');
        }
        elsif(ref $file eq 'GLOB')
        {   $self->_data_from_glob($file) or return }
        elsif($file->isa('IO::Handle'))
        {   $self->_data_from_filehandle($file) or return }
        else
        {   croak "message body: illegal datatype `".ref($file)."' for file option" }
    }
    elsif(defined(my $data = $args->{data}))
    {
        if(!ref $data)
        {   my @lines = split /^/, $data;
            $self->_data_from_lines(\@lines)
        }
        elsif(ref $data eq 'ARRAY')
        {   $self->_data_from_lines($data) or return;
        }
        else
        {   croak "message body: illegal datatype `".ref($data)."' for data option" }
    }
    elsif(! $self->isMultipart && ! $self->isNested)
    {   # Neither 'file' nor 'data', so empty body.
        $self->_data_from_lines( [] ) or return;
    }

    # Set the content info

    my ($transfer, $disp, $charset, $descr, $cid) = @$args{
       qw/transfer_encoding disposition charset description content_id/ }; 

    if(defined $filename)
    {   $disp //= Mail::Message::Field->new
          ( 'Content-Disposition' => (-T $filename ? 'inline' : 'attachment')
          , filename => basename($filename)
          );
        $mime //= $mime_types->mimeTypeOf($filename);
    }

    if(ref $mime && $mime->isa('MIME::Type'))
    {   $mime     = $mime->type;
    }

    if(defined(my $based = $args->{based_on}))
    {   $mime     = $based->type             unless defined $mime;
        $transfer = $based->transferEncoding unless defined $transfer;
        $disp     = $based->disposition      unless defined $disp;
        $descr    = $based->description      unless defined $descr;
        $cid      = $based->contentId        unless defined $cid;

        $self->{MMB_checked}
          = defined $args->{checked} ? $args->{checked} : $based->checked;
    }
    else
    {   $transfer = $args->{transfer_encoding};
        $self->{MMB_checked} = $args->{checked} || 0;
    }

    $mime ||= 'text/plain';
    $mime = $self->type($mime);
    $mime->attribute(charset => ($charset || 'PERL'))
        if $mime =~ m!^text/!i && !$mime->attribute('charset');

    $self->transferEncoding($transfer) if defined $transfer;
    $self->disposition($disp)          if defined $disp;
    $self->description($descr)         if defined $descr;
    $self->contentId($cid)             if defined $cid;
    $self->type($mime);

    $self->{MMB_eol}   = $args->{eol} || 'NATIVE';

    # Set message where the body belongs to.

    $self->message($args->{message})
        if defined $args->{message};

    $self->{MMB_seqnr} = $body_count++;
    $self;
}



sub clone() {shift->notImplemented}

#------------------------------------------


sub decoded(@)
{   my $self = shift;
    $self->encode(charset => 'PERL', transfer_encoding => 'none', @_);
}


sub eol(;$)
{   my $self = shift;
    return $self->{MMB_eol} unless @_;

    my $eol  = shift;
    if($eol eq 'NATIVE')
    {   $eol = $^O =~ m/^win/i ? 'CRLF'
             : $^O =~ m/^mac/i ? 'CR'
             :                   'LF';
    }

    return $self if $eol eq $self->{MMB_eol} && $self->checked;
    my $lines = $self->lines;
    if(@$lines)
    {   # sometimes texts lack \n on last line
        $lines->[-1] .= "\n";
       

           if($eol eq 'CR')   {s/[\015\012]+$/\015/     for @$lines}
        elsif($eol eq 'LF')   {s/[\015\012]+$/\012/     for @$lines}
        elsif($eol eq 'CRLF') {s/[\015\012]+$/\015\012/ for @$lines}
        else
        {   $self->log(WARNING => "Unknown line terminator $eol ignored");
            return $self->eol('NATIVE');
        }
    }

    (ref $self)->new(based_on => $self, eol => $eol, data => $lines);
}

#------------------------------------------


sub message(;$)
{   my $self = shift;
    if(@_)
    {   if($self->{MMB_message} = shift)
        {   weaken $self->{MMB_message};
        }
    }
    $self->{MMB_message};
}


sub isDelayed() {0}


sub isMultipart() {0}


sub isNested() {0}


sub partNumberOf($)
{   shift->log(ERROR => 'part number needs multi-part or nested');
    'ERROR';
}

#------------------------------------------


sub type(;$)
{   my $self = shift;
    return $self->{MMB_type} if !@_ && defined $self->{MMB_type};

    delete $self->{MMB_mime};
    my $type = defined $_[0] ? shift : 'text/plain';

    $self->{MMB_type} = ref $type ? $type->clone
      : Mail::Message::Field->new('Content-Type' => $type);
}


sub mimeType()
{   my $self  = shift;
    return $self->{MMB_mime} if exists $self->{MMB_mime};

    my $field = $self->{MMB_type};
    my $body  = defined $field ? $field->body : '';

    return $self->{MMB_mime} = $mime_plain
       unless length $body;

    $self->{MMB_mime}
       = $mime_types->type($body) || MIME::Type->new(type => $body);
}


sub charset() { shift->type->attribute('charset') }


sub transferEncoding(;$)
{   my $self = shift;
    return $self->{MMB_transfer} if !@_ && defined $self->{MMB_transfer};

    my $set = defined $_[0] ? shift : 'none';
    $self->{MMB_transfer} = ref $set ? $set->clone
       : Mail::Message::Field->new('Content-Transfer-Encoding' => $set);
}


sub description(;$)
{   my $self = shift;
    return $self->{MMB_description} if !@_ && $self->{MMB_description};

    my $disp = defined $_[0] ? shift : 'none';
    $self->{MMB_description} = ref $disp ? $disp->clone
       : Mail::Message::Field->new('Content-Description' => $disp);
}


sub disposition(;$)
{   my $self = shift;
    return $self->{MMB_disposition} if !@_ && $self->{MMB_disposition};

    my $disp = defined $_[0] ? shift : 'none';

    $self->{MMB_disposition} = ref $disp ? $disp->clone
       : Mail::Message::Field->new('Content-Disposition' => $disp);
}


sub contentId(;$)
{   my $self = shift;
    return $self->{MMB_id} if !@_ && $self->{MMB_id};

    my $cid = defined $_[0] ? shift : 'none';
    $self->{MMB_id} = ref $cid ? $cid->clone
       : Mail::Message::Field->new('Content-ID' => $cid);
}


sub checked(;$)
{   my $self = shift;
    @_ ? ($self->{MMB_checked} = shift) : $self->{MMB_checked};
}


sub nrLines(@)  {shift->notImplemented}


sub size(@)  {shift->notImplemented}

#------------------------------------------


sub string() {shift->notImplemented}

sub string_unless_carp()
{   my $self  = shift;
    return $self->string unless (caller)[0] eq 'Carp';

    (my $class = ref $self) =~ s/^Mail::Message/MM/;
    "$class object";
}


sub lines() {shift->notImplemented}


sub file(;$) {shift->notImplemented}


sub print(;$) {shift->notImplemented}


sub printEscapedFrom($) {shift->notImplemented}


sub write(@)
{   my ($self, %args) = @_;
    my $filename = $args{filename};
    die "No filename for write() body" unless defined $filename;

    open OUT, '>', $filename or return;
    $self->print(\*OUT);
    close OUT or return undef;
    $self;
}


sub endsOnNewline() {shift->notImplemented}


sub stripTrailingNewline() {shift->notImplemented}

#------------------------------------------


sub read(@) {shift->notImplemented}


sub contentInfoTo($)
{   my ($self, $head) = @_;
    return unless defined $head;

    my $lines  = $self->nrLines;
    my $size   = $self->size;
    $size     += $lines if $Mail::Message::crlf_platform;

    $head->set($self->type);
    $head->set($self->transferEncoding);
    $head->set($self->disposition);
    $head->set($self->description);
    $head->set($self->contentId);
    $self;
}


sub contentInfoFrom($)
{   my ($self, $head) = @_;

    $self->type($head->get('Content-Type', 0));

    my ($te, $disp, $desc, $cid)
      = map { my $x = $head->get("Content-$_") || '';
              s/^\s+//,s/\s+$// for $x;
              length $x ? $x : undef
            } qw/Transfer-Encoding Disposition Description ID/;

    $self->transferEncoding($te);
    $self->disposition($disp);
    $self->description($desc);
    $self->contentId($cid);

    delete $self->{MMB_mime};
    $self;

}


sub modified(;$)
{  my $self = shift;
   return $self->isModified unless @_;  # compat 2.036
   $self->{MMB_modified} = shift;
}


sub isModified() { shift->{MMB_modified} }


sub fileLocation(;@)
{   my $self = shift;
    return @$self{ qw/MMB_begin MMB_end/ } unless @_;
    @$self{ qw/MMB_begin MMB_end/ } = @_;
}


sub moveLocation($)
{   my ($self, $dist) = @_;
    $self->{MMB_begin} -= $dist;
    $self->{MMB_end}   -= $dist;
    $self;
}


sub load() {shift}

#------------------------------------------


my @in_encode = qw/check encode encoded eol isBinary isText unify
                   dispositionFilename/;
my %in_module = map { ($_ => 'encode') } @in_encode;

sub AUTOLOAD(@)
{   my $self  = shift;
    our $AUTOLOAD;
    (my $call = $AUTOLOAD) =~ s/.*\:\://g;

    my $mod = $in_module{$call} || 'construct';
    if($mod eq 'encode'){ require Mail::Message::Body::Encode    }
    else                { require Mail::Message::Body::Construct }

    no strict 'refs';
    return $self->$call(@_) if $self->can($call);  # now loaded

	# AUTOLOAD inheritance is a pain
	confess "Method $call() is not defined for a ", ref $self;
}   

#------------------------------------------


1;
