# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use Mail::Address;
use Date::Format 'strftime';
use IO::Handle;

our %_structured;  # not to be used directly: call isStructured!
my $default_wrap_length = 78;


use overload
   qq("")  => sub { $_[0]->unfoldedBody }
 , '0+'    => sub { $_[0]->toInt || 0 }
 , bool    => sub {1}
 , cmp     => sub { $_[0]->unfoldedBody cmp "$_[1]" }
 , '<=>'   => sub { $_[2] ? $_[1] <=> $_[0]->toInt : $_[0]->toInt <=> $_[1] }
 , fallback => 1;

#------------------------------------------


sub new(@)
{   my $class = shift;
    if($class eq __PACKAGE__)  # bootstrap
    {   require Mail::Message::Field::Fast;
        return Mail::Message::Field::Fast->new(@_);
    }
    $class->SUPER::new(@_);
}



#------------------------------------------


sub length { length shift->folded }


BEGIN {
%_structured = map { (lc($_) => 1) }
  qw/To Cc Bcc From Date Reply-To Sender
     Resent-Date Resent-From Resent-Sender Resent-To Return-Path
     List-Help List-Post List-Unsubscribe Mailing-List
     Received References Message-ID In-Reply-To
     Content-Type Content-Disposition Content-ID
     Delivered-To
     MIME-Version
     Precedence
     Status/;
} 

sub isStructured(;$)
{   my $name  = ref $_[0] ? shift->name : $_[1];
    exists $_structured{lc $name};
}


sub print(;$)
{   my $self = shift;
    my $fh   = shift || select;
    $fh->print(scalar $self->folded);
}


sub toString(;$) {shift->string(@_)}
sub string(;$)
{   my $self  = shift;
    return $self->folded unless @_;

    my $wrap  = shift || $default_wrap_length;
    my $name  = $self->Name;
    my @lines = $self->fold($name, $self->unfoldedBody, $wrap);
    $lines[0] = $name . ':' . $lines[0];
    wantarray ? @lines : join('', @lines);
}


sub toDisclose()
{   shift->name !~ m!^(?: (?:x-)?status
                      |   (?:resent-)?bcc
                      |   Content-Length
                      |   x-spam-
                      ) $!x;
}


sub nrLines() { my @l = shift->foldedBody; scalar @l }


*size = \&length;

#------------------------------------------


# attempt to change the case of a tag to that required by RFC822. That
# being all characters are lowercase except the first of each
# word. Also if the word is an `acronym' then all characters are
# uppercase. We, rather arbitrarily, decide that a word is an acronym
# if it does not contain a vowel and isn't the well-known 'Cc' or
# 'Bcc' headers.

my %wf_lookup
  = qw/mime MIME  ldap LDAP  soap SOAP  swe SWE
       bcc Bcc  cc Cc  id ID/;

sub wellformedName(;$)
{   my $thing = shift;
    my $name = @_ ? shift : $thing->name;

    join '-',
       map { $wf_lookup{lc $_} || ( /[aeiouyAEIOUY]/ ? ucfirst lc : uc ) }
          split /\-/, $name, -1;
}

#------------------------------------------


sub folded { shift->notImplemented }


sub body()
{   my $self = shift;
    my $body = $self->unfoldedBody;
    return $body unless $self->isStructured;

    my ($first) = $body =~ m/^((?:"[^"]*"|'[^']*'|[^;])*)/;
	$first =~ s/\s+$//;
	$first;
}


sub foldedBody { shift->notImplemented }


sub unfoldedBody { shift->notImplemented }


sub stripCFWS($)
{   my $thing  = shift;

    # get (folded) data
    my $string = @_ ? shift : $thing->foldedBody;

    # remove comments
    my $r          = '';
    my $in_dquotes = 0;
    my $open_paren = 0;

    my @s = split m/([()"])/, $string;
    while(@s)
    {   my $s = shift @s;

           if(CORE::length($r)&& substr($r, -1) eq "\\")  { $r .= $s }
        elsif($s eq '"')   { $in_dquotes = not $in_dquotes; $r .= $s }
        elsif($s eq '(' && !$in_dquotes) { $open_paren++ }
        elsif($s eq ')' && !$in_dquotes) { $open_paren-- }
        elsif($open_paren) {}  # in comment
        else               { $r .= $s }
    }

    # beautify and unfold at the same time
    for($r)
    {  s/\s+/ /gs;
       s/\s+$//;
       s/^\s+//;
    }

    $r;
}

#------------------------------------------


sub comment(;$)
{   my $self = shift;
    return undef unless $self->isStructured;

    my $body = $self->unfoldedBody;

    if(@_)
    {   my $comment = shift;
        $body    =~ s/\s*\;.*//;
        $body   .= "; $comment" if defined $comment && CORE::length($comment);
        $self->unfoldedBody($body);
        return $comment;
    }
 
    $body =~ s/.*?\;\s*// ? $body : '';
}

sub content() { shift->unfoldedBody }  # Compatibility


sub attribute($;$)
{   my ($self, $attr) = (shift, shift);
    my $body  = $self->unfoldedBody;

    unless(@_)
    {   # only get a value
        if($body =~ m/\b$attr\s*\=\s*
                      ( "( (?> [^\\"]+|\\. )* )"
                      | ([^";\s]*)
                      )/xi)
        {   (my $val = $+) =~ s/\\(.)/$1/g;
            return $val;
        }
        return undef;
    }

    # set the value
    my $value = shift;
    unless(defined $value)  # remove attribute
    {   for($body)
        {      s/\b$attr\s*=\s*"(?>[^\\"]|\\.)*"//i
            or s/\b$attr\s*=\s*[;\s]*//i;
        }
        $self->unfoldedBody($body);
        return undef;
    }

    (my $quoted = $value) =~ s/(["\\])/\\$1/g;

    for($body)
    {       s/\b$attr\s*=\s*"(?>[^\\"]|\\.){0,1000}"/$attr="$quoted"/i
         or s/\b$attr\s*=\s*[^;\s]*/$attr="$quoted"/i
         or do { $_ .= qq(; $attr="$quoted") }
    }

    $self->unfoldedBody($body);
    $value;
}

#------------------------------------------


sub attributes()
{   my $self  = shift;
    my $body  = $self->unfoldedBody;

    my @attrs;
    while($body =~ m/\b(\w+)\s*\=\s*
                       ( "( (?: [^"]|\\" )* )"
                       | '( (?: [^']|\\' )* )'
                       | ([^;\s]*)
                       )
                    /xig)
    {   push @attrs, $1 => $+;
    }

    @attrs;
}

#------------------------------------------


sub toInt()
{   my $self = shift;
    return $1 if $self->body =~ m/^\s*(\d+)\s*$/;

    $self->log(WARNING => "Field content is not numerical: ". $self->toString);

    return undef;
}

#------------------------------------------


my @weekday = qw/Sun Mon Tue Wed Thu Fri Sat Sun/;
my @month   = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

sub toDate(@)
{   my $class  = shift;
    my @time   = @_== 0 ? localtime() : @_==1 ? localtime(shift) : @_;
    my $format = "$weekday[$time[6]], %d $month[$time[4]] %Y %H:%M:%S %z";
    my $time   = strftime $format, @time;

    # for C libs which do not (GNU compliantly) support %z
    $time =~ s/ (\%z|[A-Za-z ]+)$/_tz_offset($1)/e;

    $time; 
}

sub _tz_offset($)
{  my $zone = shift;
   require Time::Zone;

   my $diff = $zone eq '%z' ? Time::Zone::tz_local_offset()
           :                  Time::Zone::tz_offset($zone);
   my $minutes = int((abs($diff)+0.01) / 60);     # float rounding errors
   my $hours   = int(($minutes+0.01) / 60);
   $minutes   -= $hours * 60;
   sprintf( ($diff < 0 ? " -%02d%02d" : " +%02d%02d"), $hours, $minutes);
}

#------------------------------------------


sub addresses() { Mail::Address->parse(shift->unfoldedBody) }

#------------------------------------------


sub study()
{   my $self = shift;
    require Mail::Message::Field::Full;
    Mail::Message::Field::Full->new(scalar $self->folded);
}

#------------------------------------------


sub dateToTimestamp($)
{   my $string = $_[0]->stripCFWS($_[1]);

    # in RFC822, FWSes can appear within the time.
    $string =~ s/(\d\d)\s*\:\s*(\d\d)\s*\:\s*(\d\d)/$1:$2:$3/;

    require Date::Parse;
    Date::Parse::str2time($string, 'GMT');
}


#------------------------------------------


sub consume($;$)
{   my $self = shift;
    my ($name, $body) = defined $_[1] ? @_ : split(/\s*\:\s*/, (shift), 2);

    Mail::Reporter->log(WARNING => "Illegal character in field name $name")
       if $name =~ m/[^\041-\071\073-\176]/;

    #
    # Compose the body.
    #

    if(ref $body)                 # Objects or array
    {   my $flat = $self->stringifyData($body) // return ();
        $body = $self->fold($name, $flat);
    }
    elsif($body !~ s/\n+$/\n/g)   # Added by user...
    {   $body = $self->fold($name, $body);
    }
    else                          # Created by parser
    {   # correct erroneous wrap-seperators (dos files under UNIX)
        $body =~ s/[\012\015]+/\n/g;
        $body =~ s/^[ \t]*/ /;  # start with one blank, folding kept unchanged
    }

    ($name, $body);
}

#------------------------------------------


sub stringifyData($)
{  my ($self, $arg) = (shift, shift);
   my @addr;
   foreach my $obj (ref $arg eq 'ARRAY' ? @$arg : ($arg))
   {  next unless defined $obj;

      if(!ref $obj)                  { push @addr, $obj; next }
      if($obj->isa('Mail::Address')) { push @addr, $obj->format; next }

      if($obj->isa('Mail::Identity') || $obj->isa('User::Identity'))
      {   require Mail::Message::Field::Address;
          push @addr, Mail::Message::Field::Address->coerce($obj)->string;
      }
      elsif($obj->isa('User::Identity::Collection::Emails'))
      {   my @roles = $obj->roles or next;
          require Mail::Message::Field::AddrGroup;
          my $group = Mail::Message::Field::AddrGroup->coerce($obj);
          push @addr, $group->string if $group;
      }
      elsif($obj->isa('Mail::Message::Field'))
      {
          my $folded = join ' ', $obj->foldedBody;
          $folded =~ s/^ //;
          $folded =~ s/\n\z//;
          push @addr, $folded;
      }
      else
      {   push @addr, "$obj";    # any other object is stringified
      }
   }

   @addr ? join(', ',@addr) : undef;
}

#------------------------------------------


sub setWrapLength(;$)
{   my $self = shift;

    $self->foldedBody(scalar $self->fold($self->Name, $self->unfoldedBody, @_))
        if @_;

    $self;
}

#------------------------------------------


sub defaultWrapLength(;$)
{   my $self = shift;
    @_ ? ($default_wrap_length = shift) : $default_wrap_length;
}

#------------------------------------------


sub fold($$;$)
{   my $thing = shift;
    my $name  = shift;
    my $line  = shift;
    my $wrap  = shift || $default_wrap_length;
    defined $line or $line = '';

    $line    =~ s/\n(\s)/$1/gms;            # Remove accidental folding
    return " \n" unless CORE::length($line);  # empty field

    my $lname = CORE::length($name);
    $lname <= $wrap -5  # Cannot find a real limit in the spec
       or $thing->log(ERROR => "Field name too long (max ".($wrap-5)."), in '$name'");

    my @folded;
    while(1)
    {   my $max = $wrap - (@folded ? 1 : $lname + 2);
        my $min = $max >> 2;
        last if CORE::length($line) < $max;

           $line =~ s/^ ( .{$min,$max}   # $max to 30 chars
                         [;,]            # followed at a ; or ,
                        )[ \t]           # and then a WSP
                     //x
        || $line =~ s/^ ( .{$min,$max} ) # $max to 30 chars
                        [ \t]            # followed by a WSP
                     //x
        || $line =~ s/^ ( .{$max,}? )    # longer, but minimal chars
                        [ \t]            # followed by a WSP
                     //x
        || $line =~ s/^ (.*) //x;        # everything

        push @folded, " $1\n";
    }

    push @folded, " $line\n" if CORE::length($line);
    wantarray ? @folded : join('', @folded);
}


sub unfold($)
{   my $string = $_[1];
    for($string)
    {   s/\r?\n(\s)/$1/gs;  # remove FWS
        s/\r?\n/ /gs;
        s/^\s+//;
        s/\s+$//;
    }
    $string;
}

#------------------------------------------


1;
