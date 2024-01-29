# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message;
use vars '$VERSION';
$VERSION = '3.015';


use strict;
use warnings;

use Mail::Message::Head::Complete  ();
use Mail::Message::Body::Lines     ();
use Mail::Message::Body::Multipart ();
use Mail::Message::Body::Nested    ();
use Mail::Message::Field           ();

use Mail::Address  ();


sub build(@)
{   my $class = shift;

    if($class->isa('Mail::Box::Message'))
    {   $class->log(ERROR
           => "Only build() Mail::Message's; they are not in a folder yet"); 
         return undef;
    }

    my @parts
      = ! ref $_[0] ? ()
      : $_[0]->isa('Mail::Message')       ? shift
      : $_[0]->isa('Mail::Message::Body') ? shift
      :               ();

    my ($head, @headerlines);
    my ($type, $transfenc, $dispose, $descr, $cid);
    while(@_)
    {   my $key = shift;
        if(ref $key && $key->isa('Mail::Message::Field'))
        {   my $name = $key->name;
               if($name eq 'content-type')        { $type    = $key }
            elsif($name eq 'content-transfer-encoding') { $transfenc = $key }
            elsif($name eq 'content-disposition') { $dispose = $key }
            elsif($name eq 'content-description') { $descr   = $key }
            elsif($name eq 'content-id')          { $cid     = $key }
            else { push @headerlines, $key }
            next;
        }

        my $value = shift;
        next unless defined $value;

        my @data;

        if($key eq 'head')
        {   $head = $value }
        elsif($key eq 'data')
        {   @data = Mail::Message::Body->new(data => $value) }
        elsif($key eq 'file' || $key eq 'files')
        {   @data = map Mail::Message::Body->new(file => $_)
              , ref $value eq 'ARRAY' ? @$value : $value;
        }
        elsif($key eq 'attach')
        {   foreach my $c (ref $value eq 'ARRAY' ? @$value : $value)
            {   defined $c or next;
                push @data, ref $c && $c->isa('Mail::Message')
		          ? Mail::Message::Body::Nested->new(nested => $c)
                  : $c;
            }
        }
        elsif($key =~
           m/^content\-(type|transfer\-encoding|disposition|description|id)$/i )
        {   my $k     = lc $1;
            my $field = Mail::Message::Field->new($key, $value);
               if($k eq 'type')        { $type    = $field }
            elsif($k eq 'disposition') { $dispose = $field }
            elsif($k eq 'description') { $descr   = $field }
            elsif($k eq 'id')          { $cid     = $field }
            else                     { $transfenc = $field }
        }
        elsif($key =~ m/^[A-Z]/)
        {   push @headerlines, $key, $value }
        else
        {   $class->log(WARNING => "Skipped unknown key '$key' in build");
        }

        push @parts, grep defined, @data;
    }

    my $body
       = @parts==0 ? Mail::Message::Body::Lines->new()
       : @parts==1 ? $parts[0]
       : Mail::Message::Body::Multipart->new(parts => \@parts);

    # Setting the type explicitly, only after the body object is finalized
    $body->type($type)           if defined $type;
    $body->disposition($dispose) if defined $dispose;
    $body->description($descr)   if defined $descr;
    $body->contentId($cid)       if defined $cid;
    $body->transferEncoding($transfenc) if defined $transfenc;

    $class->buildFromBody($body, $head, @headerlines);
}

#------------------------------------------


sub buildFromBody(@)
{   my ($class, $body) = (shift, shift);
    my @log     = $body->logSettings;

    my $head;
    if(ref $_[0] && $_[0]->isa('Mail::Message::Head')) { $head = shift }
    else
    {   shift unless defined $_[0];   # undef as head
        $head = Mail::Message::Head::Complete->new(@log);
    }

    while(@_)
    {   if(ref $_[0]) {$head->add(shift)}
        else          {$head->add(shift, shift)}
    }

    my $message = $class->new
     ( head => $head
     , @log
     );

    $message->body($body);

    # be sure the message-id is actually stored in the header.
    $head->add('Message-Id' => '<'.$message->messageId.'>')
        unless defined $head->get('message-id');

    $head->add(Date => Mail::Message::Field->toDate)
        unless defined $head->get('Date');

    $head->add('MIME-Version' => '1.0')  # required by rfc2045
        unless defined $head->get('MIME-Version');

    $message;
}

#------------------------------------------


1;
