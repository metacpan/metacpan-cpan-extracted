# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::Multipart;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Body';

use strict;
use warnings;

use Mail::Message::Body::Lines;
use Mail::Message::Part;

use Mail::Box::FastScalar;
use Carp;


sub init($)
{   my ($self, $args) = @_;
    my $based = $args->{based_on};
    $args->{mime_type} ||= defined $based ? $based->type : 'multipart/mixed';

    $self->SUPER::init($args);

    my @parts;
    if($args->{parts})
    {   foreach my $raw (@{$args->{parts}})
        {   next unless defined $raw;
            my $cooked = Mail::Message::Part->coerce($raw, $self);

            $self->log(ERROR => 'Data not convertible to a message (type is '
                      , ref $raw,")\n"), next unless defined $cooked;

            push @parts, $cooked;
        }
    }

    my $preamble = $args->{preamble};
    $preamble    = Mail::Message::Body->new(data => $preamble)
       if defined $preamble && ! ref $preamble;
    
    my $epilogue = $args->{epilogue};
    $epilogue    = Mail::Message::Body->new(data => $epilogue)
       if defined $epilogue && ! ref $epilogue;
    
    if($based)
    {   $self->boundary($args->{boundary} || $based->boundary);
        $self->{MMBM_preamble}
            = defined $preamble ? $preamble : $based->preamble;

        $self->{MMBM_parts}
            = @parts ? \@parts
            : !$args->{parts} && $based->isMultipart
                     ? [ $based->parts('ACTIVE') ]
            :          [];

        $self->{MMBM_epilogue}
            = defined $epilogue ? $epilogue : $based->epilogue;
    }
    else
    {   $self->boundary($args->{boundary} ||$self->type->attribute('boundary'));
        $self->{MMBM_preamble} = $preamble;
        $self->{MMBM_parts}    = \@parts;
        $self->{MMBM_epilogue} = $epilogue;
    }

    $self;
}

sub isMultipart() {1}

# A multipart body is never binary itself.  The parts may be.
sub isBinary() {0}

sub clone()
{   my $self     = shift;
    my $preamble = $self->preamble;
    my $epilogue = $self->epilogue;

    my $body     = ref($self)->new
     ( $self->logSettings
     , based_on => $self
     , preamble => ($preamble ? $preamble->clone : undef)
     , epilogue => ($epilogue ? $epilogue->clone : undef)
     , parts    => [ map {$_->clone} $self->parts('ACTIVE') ]
     );

}

sub nrLines()
{   my $self = shift;
    my $nr   = 1;  # trailing part-sep

    if(my $preamble = $self->preamble)
    {   $nr += $preamble->nrLines;
        $nr++ if $preamble->endsOnNewline;
    }

    foreach my $part ($self->parts('ACTIVE'))
    {   $nr += 1 + $part->nrLines;
        $nr++ if $part->body->endsOnNewline;
    }

    if(my $epilogue = $self->epilogue)
    {   $nr += $epilogue->nrLines;
    }

    $nr;
}

sub size()
{   my $self   = shift;
    my $bbytes = length($self->boundary) +4;  # \n--$b\n

    my $bytes  = $bbytes +2;   # last boundary, \n--$b--\n
    if(my $preamble = $self->preamble)
         { $bytes += $preamble->size }
    else { $bytes -= 1 }      # no leading \n

    $bytes += $bbytes + $_->size foreach $self->parts('ACTIVE');
    if(my $epilogue = $self->epilogue)
    {   $bytes += $epilogue->size;
    }
    $bytes;
}

sub string() { join '', shift->lines }

sub lines()
{   my $self     = shift;

    my $boundary = $self->boundary;
    my @lines;

    my $preamble = $self->preamble;
    push @lines, $preamble->lines if $preamble;

    foreach my $part ($self->parts('ACTIVE'))
    {   # boundaries start with \n
        if(!@lines) { ; }
        elsif($lines[-1] =~ m/\n$/) { push @lines, "\n" }
        else { $lines[-1] .= "\n" }
        push @lines, "--$boundary\n", $part->lines;
    }

    if(!@lines) { ; }
    elsif($lines[-1] =~ m/\n$/) { push @lines, "\n" }
    else { $lines[-1] .= "\n" }
    push @lines, "--$boundary--";

    if(my $epilogue = $self->epilogue)
    {   $lines[-1] .= "\n";
        push @lines, $epilogue->lines;
    }

    wantarray ? @lines : \@lines;
}

sub file()                    # It may be possible to speed-improve the next
{   my $self   = shift;       # code, which first produces a full print of
    my $text;                 # the message in memory...
    my $dump   = Mail::Box::FastScalar->new(\$text);
    $self->print($dump);
    $dump->seek(0,0);
    $dump;
}

sub print(;$)
{   my $self = shift;
    my $out  = shift || select;

    my $boundary = $self->boundary;
    my $count    = 0;
    if(my $preamble = $self->preamble)
    {   $preamble->print($out);
        $count++;
    }

    if(ref $out eq 'GLOB')
    {   foreach my $part ($self->parts('ACTIVE'))
        {   print $out "\n" if $count++;
            print $out "--$boundary\n";
            $part->print($out);
        }
        print $out "\n" if $count++;
        print $out "--$boundary--";
    }
    else
    {   foreach my $part ($self->parts('ACTIVE'))
        {   $out->print("\n") if $count++;
            $out->print("--$boundary\n");
            $part->print($out);
        }
        $out->print("\n") if $count++;
        $out->print("--$boundary--");
    }

    if(my $epilogue = $self->epilogue)
    {   $out->print("\n");
        $epilogue->print($out);
    }

    $self;
}


sub foreachLine($)
{   my ($self, $code) = @_;
    $self->log(ERROR => "You cannot use foreachLine on a multipart");
    confess;
}

sub check()
{   my $self = shift;
    $self->foreachComponent( sub {$_[1]->check} );
}

sub encode(@)
{   my ($self, %args) = @_;
    $self->foreachComponent( sub {$_[1]->encode(%args)} );
}

sub encoded()
{   my $self = shift;
    $self->foreachComponent( sub {$_[1]->encoded} );
}

sub read($$$$)
{   my ($self, $parser, $head, $bodytype) = @_;

    my $boundary   = $self->boundary;

    $parser->pushSeparator("--$boundary");
    my @msgopts    = $self->logSettings;

    my $te;
    $te = lc $1
        if +($head->get('Content-Transfer-Encoding') || '') =~ m/(\w+)/;
    
    my @sloppyopts = 
      ( mime_type         => 'text/plain'
      , transfer_encoding => $te
      );

    # Get preamble.
    my $headtype = ref $head;

    my $begin    = $parser->filePosition;
    my $preamble = Mail::Message::Body::Lines->new(@msgopts, @sloppyopts)
       ->read($parser, $head);

    $preamble->nrLines
        or undef $preamble;

    $self->{MMBM_preamble} = $preamble
        if defined $preamble;

    # Get the parts.

    my @parts;
    while(my $sep = $parser->readSeparator)
    {   last if $sep eq "--$boundary--\n";

        my $part = Mail::Message::Part->new
         ( @msgopts
         , container => $self
         );

        last unless $part->readFromParser($parser, $bodytype);
        push @parts, $part
            if $part->head->names || $part->body->size;
    }
    $self->{MMBM_parts} = \@parts;

    # Get epilogue

    $parser->popSeparator;
    my $epilogue = Mail::Message::Body::Lines->new(@msgopts, @sloppyopts)
        ->read($parser, $head);

    my $end = defined $epilogue ? ($epilogue->fileLocation)[1]
            : @parts            ? ($parts[-1]->body->fileLocation)[1]
            : defined $preamble ? ($preamble->fileLocation)[1]
            :                      $begin;
    $self->fileLocation($begin, $end);

   $epilogue->nrLines
        or undef $epilogue;

    $self->{MMBM_epilogue} = $epilogue
        if defined $epilogue;

    $self;
}

#------------------------------------------


sub foreachComponent($)
{   my ($self, $code) = @_;
    my $changes  = 0;

    my $new_preamble;
    if(my $preamble = $self->preamble)
    {   $new_preamble = $code->($self, $preamble);
        $changes++ unless $preamble == $new_preamble;
    }

    my $new_epilogue;
    if(my $epilogue = $self->epilogue)
    {   $new_epilogue = $code->($self, $epilogue);
        $changes++ unless $epilogue == $new_epilogue;
    }

    my @new_bodies;
    foreach my $part ($self->parts('ACTIVE'))
    {   my $part_body = $part->body;
        my $new_body  = $code->($self, $part_body);

        $changes++ if $new_body != $part_body;
        push @new_bodies, [$part, $new_body];
    }

    return $self unless $changes;

    my @new_parts;
    foreach (@new_bodies)
    {   my ($part, $body) = @$_;
        my $new_part = Mail::Message::Part->new
           ( head      => $part->head->clone,
             container => undef
           );
        $new_part->body($body);
        push @new_parts, $new_part;
    }

    my $constructed = (ref $self)->new
      ( preamble => $new_preamble
      , parts    => \@new_parts
      , epilogue => $new_epilogue
      , based_on => $self
      );

    $_->container($constructed)
        foreach @new_parts;

    $constructed;
}


sub attach(@)
{   my $self  = shift;
    my $new   = ref($self)->new
      ( based_on => $self
      , parts    => [$self->parts, @_]
      );
}


sub stripSignature(@)
{   my $self  = shift;

    my @allparts = $self->parts;
    my @parts    = grep {! $_->body->mimeType->isSignature} @allparts;

    @allparts==@parts ? $self
    : (ref $self)->new(based_on => $self, parts => \@parts);
}

#------------------------------------------


sub preamble() {shift->{MMBM_preamble}}


sub epilogue() {shift->{MMBM_epilogue}}


sub parts(;$)
{   my $self  = shift;
    return @{$self->{MMBM_parts}} unless @_;

    my $what  = shift;
    my @parts = @{$self->{MMBM_parts}};

      $what eq 'RECURSE' ? (map {$_->parts('RECURSE')} @parts)
    : $what eq 'ALL'     ? @parts
    : $what eq 'DELETED' ? (grep {$_->isDeleted} @parts)
    : $what eq 'ACTIVE'  ? (grep {not $_->isDeleted} @parts)
    : ref $what eq 'CODE'? (grep {$what->($_)} @parts)
    : ($self->log(ERROR => "Unknown criterium $what to select parts."), return ());
}


sub part($) { shift->{MMBM_parts}[shift] }

sub partNumberOf($)
{   my ($self, $part) = @_;
    my @parts = $self->parts('ACTIVE');
    my $msg   = $self->message;
    unless($msg)
    {   $self->log(ERROR => 'multipart is not connected');
        return 'ERROR';
    }
    my $base  = $msg->isa('Mail::Message::Part') ? $msg->partNumber.'.' : '';
    foreach my $partnr (0..@parts)
    {   return $base.($partnr+1)
            if $parts[$partnr] == $part;
    }
    $self->log(ERROR => 'multipart is not found or not active');
    'ERROR';
}


sub boundary(;$)
{   my $self  = shift;
    my $mime  = $self->type;

    unless(@_)
    {   my $boundary = $mime->attribute('boundary');
        return $boundary if defined $boundary;
    }

    my $boundary = @_ && defined $_[0] ? (shift) : "boundary-".int rand(1000000);
    $self->type->attribute(boundary => $boundary);
}

sub endsOnNewline() { 1 }

sub toplevel() { my $msg = shift->message; $msg ? $msg->toplevel : undef}

#-------------------------------------------


1;
