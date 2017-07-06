# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;
use warnings;

package Mail::Server::IMAP4::Fetch;
use vars '$VERSION';
$VERSION = '3.002';


use Date::Parse;
use Digest::MD5   qw/md5_base64/;


sub new($)
{   my ($class, $part, %args) = @_;

    my $head  = $part->head;
    my $body  = $part->body;
    my $type  = $body->type->study;

    my $self  = bless
      { type        => $type->body
      , typeattr    => [ $type->attrPairs ]
      , charset     => $body->charset
      , bodylines   => $body->nrLines
      , bodysize    => $body->size
      }, $class;

    $self->{headbegin} = ($head->fileLocation)[0];
    @{$self}{qw/bodybegin bodyend/} = $body->fileLocation;

    # The fields use the defined() check, to avoid accidental expensive
    # stringification by the field objects.

    my ($field, $value);
    $self->{date}         = $field->unfoldedBody
        if defined($field = $head->get('Date'));

    $self->{subject}      = $field->unfoldedBody
        if defined($field = $head->get('Subject'));

    $self->{description}  = $field->unfoldedBody
        if defined($field = $head->get('Content-Description'));

    $self->{language}     = $field->unfoldedBody
        if defined($field = $head->get('Content-Language'));

    $self->{filename}     = $value
        if defined($value = $body->dispositionFilename);

    $self->{bodyMD5}      = md5_base64($body->string)
        if $args{md5checksums};

    if(defined($field = $body->transferEncoding))
    {   my $tf            = $field->unfoldedBody;
        $self->{transferenc} = $tf unless $tf eq 'none';
    }

# Should become:
#   $self->{disposition} = [ $field->body, $field->study->attributes ]
    if(defined($field = $body->disposition))
    {   my $how = $field->body;
        $how = $body->isText ? 'inline' : 'attachment' if $how eq 'none';
        $self->{disposition} = [ $how, $field->attributes ];
    }
    else
    {   $self->{disposition} = [ ($body->isText ? 'inline' : 'attachment') ];
    }

    my $id = $head->get('Content-Message-ID') || $head->get("Message-ID");
    if(defined $id)
    {   my $msgid = $id->unfoldedBody;
        $msgid =~ s/^\<*/</;
        $msgid =~ s/\>*$/>/;
        $self->{messageid} = $msgid if length $msgid;
    }

    foreach my $addr ( qw/to from sender reply-to cc bcc/ )
    {   my $addrs = $head->study($addr) or next;
        foreach my $group ($addrs->groups)
        {   my @addrs = map { [ $_->phrase, $_->username, $_->domain ] }
               $group->addresses;

            push @{$self->{$addr}}, [ $group->name, @addrs ];
        }
    }

    if($body->isMultipart)
    {   $self->{parts} = [ map { $class->new($_) } $body->parts ];
    }
    elsif($body->isNested)
    {   $self->{nest}  = $class->new($body->nested);
    }

    $self;
}

#------------------------------------------

sub headLocation() { @{ (shift) }{ qw/headbegin bodybegin/ } }
sub bodyLocation() { @{ (shift) }{ qw/bodybegin bodyend/ } }
sub partLocation() { @{ (shift) }{ qw/headbegin bodyend/ } }

#------------------------------------------

sub fetchBody($)
{   my ($self, $extended) = @_;

    my $type = uc $self->{type};
    my ($mediatype, $subtype) = split m[/], $type;

    if($self->{parts})
    {   # Multipart message
        # WARNING: no blanks between part descriptions
        my $parts  = join '', map $_->fetchBody($extended), @{$self->{parts}};
        my @fields = (\$parts, $subtype || 'MIXED');

        if($extended)     # only included when any valid info
        {   my @attr;     # don't know what to include here
            my @disp;     # don't know about this either

            push @fields, \@attr, \@disp, $self->{language}
                if @attr || @disp || defined $self->{language};
        }

        return $self->_imapList(@fields);
    }

    #
    # Simple message
    #

    my @fields = 
      ( ($mediatype || 'TEXT')
      , ($subtype   || 'PLAIN')
      , $self->{typeattr}
      , $self->{messageid}
      , $self->{description}
      , uc($self->{transferenc} || '8BIT')
      , \($self->{bodysize})
      );

    if(my $nest = $self->{nest})
    {   # type MESSAGE (message/rfc822 encapsulated)
        push @fields
         , \$nest->fetchEnvelope,
         , \$nest->fetchBody($extended);
    }
    push @fields, \$self->{bodylines};

    push @fields, @{$self}{ qw/bodyMD5 disposition language/ }
        if $extended
        && ($self->{bodyMD5} || $self->{disposition} || $self->{language});

    $self->_imapList(@fields);
}


sub fetchEnvelope()
{   my $self   = shift;
    my @fields = ($self->{date}, $self->{subject});

    foreach my $addr ( qw/from sender reply-to to cc bcc/ )
    {   unless($self->{$addr})
        {   push @fields, undef;  # NIL
            next;
        }

        # For now, group information is ignored... RFC2060 is very
        # unclear about it... and seems incompatible with RFC2822
        my $addresses = '';
        foreach my $group (@{$self->{$addr}})
        {   my ($name, @addr) = @$group;

            # addr_adl is obsoleted by rfc2822
            $addresses .= $self->_imapList($_->[0], undef, $_->[1], $_->[2])
               foreach @addr;
        }

        push @fields, \$addresses;
    }

    push @fields, $self->{'in-reply-to'}, $self->{messageid};

    $self->_imapList(@fields);
}


sub fetchSize() { shift->{bodysize} }


sub part(;$)
{   my $self = shift;
    my $nr   = shift or return $self;

    my @nrs  = split /\./, $nr;
    while(@nrs)
    {   my $take = shift @nrs;
        if(exists $self->{nest} && $take==1)
	{   $self = $self->{nest} }
	elsif(exists $self->{parts} && @{$self->{parts}} >= $take)
	{   $self = $self->{parts}[$take-1] }
	else { return undef }
    }

    $self;
}


sub printStructure(;$$)
{   my $self    = shift;

    my $fh      = @_ ? shift : select;
    my $number  = @_ ? shift : '';

    my $buffer;   # only filled if filehandle==undef
    open $fh, '>:raw', \$buffer unless defined $fh;

    my $type    = $self->{type};
    my $subject = $self->{subject} || '';
    my $text    = "$number $type: $subject\n";

    my $hbegin  = $self->{headbegin} || 0;
    my $bbegin  = $self->{bodybegin} || '?';
    my $bodyend = $self->{bodyend}   || '?';
    my $size    = defined $self->{bodysize}  ? $self->{bodysize}  : '?';
    my $lines   = defined $self->{bodylines} ? $self->{bodylines} : '?';

    $text      .= ' ' x (length($number) + 1);
    $text      .= "@ $hbegin-$bbegin-$bodyend, $size bytes, $lines lines\n";

    ref $fh eq 'GLOB' ? (print $fh $text) : $fh->print($text);

    if($self->{nest})
    {   $self->{nest}->printStructure($fh, length($number) ? $number.'.1' :'1');
    }
    elsif($self->{parts})
    {   my $count = 1;
        $number  .= '.' if length $number;
        $_->printStructure($fh, $number.$count++)
           foreach @{$self->{parts}};
    }

    $buffer;
}

#------------------------------------------


# Concatenate the elements of a list, as the IMAP protocol does.
# ARRAYS are included a sublist, and normal strings get quoted.
# Pass a ref-scalar if something needs to be included without
# quoting.

sub _imapList(@)
{   my $self = shift;
    my @f;

    foreach (@_)
    {      if(ref $_ eq 'ARRAY')  { push @f, $self->_imapList(@$_) }
        elsif(ref $_ eq 'SCALAR') { push @f, ${$_} }
        elsif(!defined $_)        { push @f, 'NIL' }
        else
        {    my $copy = $_;
             $copy =~ s/\\/\\\\/g;
             $copy =~ s/\"/\\"/g;
             push @f, qq#"$_"#;
        }
    }

    local $" = ' ';
    "(@f)";
}

#------------------------------------------


1;
