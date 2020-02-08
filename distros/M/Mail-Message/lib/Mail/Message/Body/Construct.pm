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

# Mail::Message::Body::Construct adds functionality to Mail::Message::Body

use strict;
use warnings;

use Carp;
use Mail::Message::Body::String;
use Mail::Message::Body::Lines;


sub foreachLine($)
{   my ($self, $code) = @_;
    my $changes = 0;
    my @result;

    foreach ($self->lines)
    {   my $becomes = $code->();
        if(defined $becomes)
        {   push @result, $becomes;
            $changes++ if $becomes ne $_;
        }
        else {$changes++}
    }
      
    $changes
        or return $self;

    ref($self)->new
      ( based_on => $self
      , data     => \@result
      );
}

#------------------------------------------


sub concatenate(@)
{   my $self = shift;

    return $self
        if @_==1;

    my @unified;
    foreach (@_)
    {   next unless defined $_;
        push @unified
         , !ref $_           ? $_
         : ref $_ eq 'ARRAY' ? @$_
         : $_->isa('Mail::Message')       ? $_->body->decoded
         : $_->isa('Mail::Message::Body') ? $_->decoded
         : carp "Cannot concatenate element ".$_;
    }

    ref($self)->new
      ( based_on  => $self
      , mime_type => 'text/plain'
      , data      => join('', @unified)
      );
}

#------------------------------------------


sub attach(@)
{   my $self  = shift;

    my @parts;
    push @parts, shift while @_ && ref $_[0];

    return $self unless @parts;
    unshift @parts,
      ( $self->isNested    ? $self->nested
      : $self->isMultipart ? $self->parts
      : $self
      );

    return $parts[0] if @parts==1;
    Mail::Message::Body::Multipart->new(parts => \@parts, @_);
}

#------------------------------------------


# tests in t/51stripsig.t

sub stripSignature($@)
{   my ($self, %args) = @_;

    return $self if $self->mimeType->isBinary;

    my $pattern = !defined $args{pattern} ? qr/^--\s?$/
                : !ref $args{pattern}     ? qr/^\Q${args{pattern}}/
                :                           $args{pattern};
 
    my $lines   = $self->lines;   # no copy!
    my $stop    = defined $args{max_lines}? @$lines - $args{max_lines}
                : exists $args{max_lines} ? 0 
                :                           @$lines-10;

    $stop = 0 if $stop < 0;
    my ($sigstart, $found);
 
    if(ref $pattern eq 'CODE')
    {   for($sigstart = $#$lines; $sigstart >= $stop; $sigstart--)
        {   next unless $pattern->($lines->[$sigstart]);
            $found = 1;
            last;
        }
    }
    else
    {   for($sigstart = $#$lines; $sigstart >= $stop; $sigstart--)
        {   next unless $lines->[$sigstart] =~ $pattern;
            $found = 1;
            last;
        }
    }
 
    return $self unless $found;
 
    my $bodytype = $args{result_type} || ref $self;

    my $stripped = $bodytype->new
      ( based_on => $self
      , data     => [ @$lines[0..$sigstart-1] ]
      );

    return $stripped unless wantarray;

    my $sig      = $bodytype->new
      ( based_on => $self
      , data     => [ @$lines[$sigstart..$#$lines] ]
      );
      
    ($stripped, $sig);
}

#------------------------------------------

1;
