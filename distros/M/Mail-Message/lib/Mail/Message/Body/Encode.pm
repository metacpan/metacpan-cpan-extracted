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

use Carp;
use MIME::Types    ();
use File::Basename 'basename';
use Encode         'find_encoding';

use Mail::Message::Field        ();
use Mail::Message::Field::Full  ();

# http://www.iana.org/assignments/character-sets
use Encode::Alias;
define_alias(qr/^unicode-?1-?1-?utf-?([78])$/i => '"UTF-$1"');  # rfc1642

my $mime_types;


sub encode(@)
{   my ($self, %args) = @_;

    # simplify the arguments
    my $type_from = $self->type;
    my $type_to   = $args{mime_type} || $type_from->clone->study;
    $type_to = Mail::Message::Field::Full->new('Content-Type' => $type_to)
        unless ref $type_to;

    my $transfer = $args{transfer_encoding} || $self->transferEncoding->clone;
    $transfer    = Mail::Message::Field->new('Content-Transfer-Encoding'
        => $transfer) unless ref $transfer;

    my $trans_was = lc $self->transferEncoding;
    my $trans_to  = lc $transfer;

    my ($char_was, $char_to, $from, $to);
    if($type_from =~ m!^text/!i)
    {   $char_was = $type_from->attribute('charset') || 'us-ascii';
        $char_to  = $type_to->attribute('charset');

        if(my $charset = delete $args{charset})
        {   if(!$char_to || $char_to ne $charset)
            {   $char_to = $charset;
                $type_to->attribute(charset => $char_to);
            }
        }
        elsif(!$char_to)
        {   $char_to = 'utf8';
            $type_to->attribute(charset => $char_to);
        }

        if($char_was ne 'PERL')
        {   $from = find_encoding $char_was
                or $self->log(WARNING => "Charset `$char_was' is not known.");
        }
        if($char_to ne 'PERL')
        {   $to = find_encoding $char_to
                or $self->log(WARNING => "Charset `$char_to' is not known.");
        }

        if($trans_to ne 'none' && $char_to eq 'PERL')
        {   # We cannot leave the body into the 'PERL' charset when transfer-
            # encoding is applied.
            $self->log(WARNING => "Transfer-Encoding `$trans_to' requires "
              . "explicit charset, defaulted to utf8");
            $char_to = 'utf8';
        }
    }


    # Any changes to be made?
    if($trans_was eq $trans_to)
    {   return $self if !$from && !$to;
        if($from && $to && $from->name eq $to->name)
        {   # modify charset into an alias, if requested
            $self->charset($char_to) if $char_was ne $char_to;
            return $self;
        }
    }

    my $bodytype  = $args{result_type} || ref $self;

    my $decoded;
    if($trans_was eq 'none')
    {   $decoded = $self }
    elsif(my $decoder = $self->getTransferEncHandler($trans_was))
    {   $decoded = $decoder->decode($self, result_type => $bodytype) }
    else
    {   $self->log(WARNING =>
           "No decoder defined for transfer encoding $trans_was.");
        return $self;
    }

    my $new_data
      = $to   && $char_was eq 'PERL' ? $to->encode($decoded->string)
      : $from && $char_to  eq 'PERL' ? $from->decode($decoded->string)
      : $to && $from && $from->name ne $to->name
      ?    $to->encode($from->decode($decoded->string))
      : undef;

    my $recoded = $new_data ? $bodytype->new(based_on => $decoded
      , data => $new_data, mime_type => $type_to, checked => 1) : $decoded;

    my $trans;
    if($trans_to ne 'none')
    {   $trans = $self->getTransferEncHandler($trans_to)
           or $self->log(WARNING =>
               "No encoder defined for transfer encoding `$trans_to'.");
    }

    my $encoded = defined $trans
      ? $trans->encode($recoded, result_type => $bodytype)
      : $recoded;

    $encoded;
}

#------------------------------------------


sub check()
{   my $self     = shift;
    return $self if $self->checked;
    my $eol      = $self->eol;

    my $encoding = $self->transferEncoding->body;
    return $self->eol($eol)
       if $encoding eq 'none';

    my $encoder  = $self->getTransferEncHandler($encoding);

    my $checked
      = $encoder
      ? $encoder->check($self)->eol($eol)
      : $self->eol($eol);

    $checked->checked(1);
    $checked;
}

#------------------------------------------


sub encoded()
{   my $self = shift;

    $mime_types ||= MIME::Types->new;
    my $mime    = $mime_types->type($self->type->body);

    my $charset = $self->charset || '';
    my $enc_was = $self->transferEncoding;
    my $enc     = $enc_was;
    $enc        = defined $mime ? $mime->encoding : 'base64'
        if $enc eq 'none';

    # we could (expensively) try to autodetect character-set used,
    # but everything is a subset of utf-8.
    my $new_charset
       = (!$mime || $mime !~ m!^text/!i)   ? ''
       : (!$charset || $charset eq 'PERL') ? 'utf-8'
       :                                     $charset;

      ($enc_was ne 'none' && $charset eq $new_charset)
    ? $self->check
    : $self->encode(transfer_encoding => $enc, charset => $new_charset);
}

#------------------------------------------


sub unify($)
{   my ($self, $body) = @_;
    return $self if $self==$body;

    my $mime     = $self->type;
    my $transfer = $self->transferEncoding;

    my $encoded  = $body->encode
     ( mime_type         => $mime
     , transfer_encoding => $transfer
     );

    # Encode makes the best of it, but is it good enough?

    my $newmime     = $encoded->type;
    return unless $newmime  eq $mime;
    return unless $transfer eq $encoded->transferEncoding;
    $encoded;
}

#------------------------------------------


sub isBinary()
{   my $self = shift;
    $mime_types ||= MIME::Types->new(only_complete => 1);
    my $type = $self->type                    or return 1;
    my $mime = $mime_types->type($type->body) or return 1;
    $mime->isBinary;
}
 

sub isText() { not shift->isBinary }


sub dispositionFilename(;$)
{   my $self = shift;
    my $raw;

    my $field;
    if($field = $self->disposition)
    {   $field = $field->study if $field->can('study');
        $raw   = $field->attribute('filename')
              || $field->attribute('file')
              || $field->attribute('name');
    }

    if(!defined $raw && ($field = $self->type))
    {   $field = $field->study if $field->can('study');
        $raw   = $field->attribute('filename')
              || $field->attribute('file')
              || $field->attribute('name');
    }

    my $base;
    if(!defined $raw || !length $raw) {}
    elsif(index($raw, '?') >= 0)
    {   eval 'require Mail::Message::Field::Full';
        $base = Mail::Message::Field::Full->decode($raw);
    }
    else
    {   $base = $raw;
    }

    return $base
        unless @_;

    my $dir      = shift;
    my $filename = '';
    if(defined $base)   # RFC6266 section 4.3, very safe
    {   $filename = basename $base;
        for($filename)
        {   s/\s+/ /g;  s/ $//; s/^ //;
            s/[^\w .-]//g;
        }
    }

	my ($filebase, $ext) = length $filename && $filename =~ m/(.*)\.([^.]+)/
      ? ($1, $2) : (part => ($self->mimeType->extensions)[0] || 'raw');

    my $fn = File::Spec->catfile($dir, "$filebase.$ext");

    for(my $unique = 1; -e $fn; $unique++)
    {   $fn = File::Spec->catfile($dir, "$filebase-$unique.$ext");
    }

	$fn;
}

#------------------------------------------


my %transfer_encoder_classes =
 ( base64  => 'Mail::Message::TransferEnc::Base64'
 , binary  => 'Mail::Message::TransferEnc::Binary'
 , '8bit'  => 'Mail::Message::TransferEnc::EightBit'
 , 'quoted-printable' => 'Mail::Message::TransferEnc::QuotedPrint'
 , '7bit'  => 'Mail::Message::TransferEnc::SevenBit'
 );

my %transfer_encoders;   # they are reused.

sub getTransferEncHandler($)
{   my ($self, $type) = @_;

    return $transfer_encoders{$type}
        if exists $transfer_encoders{$type};   # they are reused.

    my $class = $transfer_encoder_classes{$type};
    return unless $class;

    eval "require $class";
    confess "Cannot load $class: $@\n" if $@;

    $transfer_encoders{$type} = $class->new;
}


sub addTransferEncHandler($$)
{   my ($this, $name, $what) = @_;

    my $class;
    if(ref $what)
    {   $transfer_encoders{$name} = $what;
        $class = ref $what;
    }
    else
    {   delete $transfer_encoders{$name};
        $class = $what;
    }

    $transfer_encoder_classes{$name} = $class;
    $this;
}

1;
