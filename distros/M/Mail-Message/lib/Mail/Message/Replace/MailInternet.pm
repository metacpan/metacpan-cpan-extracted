# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Replace::MailInternet;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message';

use strict;
use warnings;

use Mail::Box::FastScalar;
use Mail::Box::Parser::Perl;
use Mail::Message::Body::Lines;

use File::Spec;


sub new(@)
{   my $class = shift;
    my $data  = @_ % 2 ? shift : undef;
    $class = __PACKAGE__ if $class eq 'Mail::Internet';
    $class->SUPER::new(@_, raw_data => $data);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{head_type} ||= 'Mail::Message::Replace::MailHeader';
    $args->{head}      ||= $args->{Header};
    $args->{body}      ||= $args->{Body};

    defined $self->SUPER::init($args) or return;

    $self->{MI_wrap}      = $args->{FoldLength} || 79;
    $self->{MI_mail_from} = $args->{MailFrom};
    $self->{MI_modify}    = exists $args->{Modify} ? $args->{Modify} : 1;

    $self->processRawData($self->{raw_data}, !defined $args->{Header}
       , !defined $args->{Body}) if defined $self->{raw_data};

    $self;
}

sub processRawData($$$)
{   my ($self, $data, $get_head, $get_body) = @_;
    return $self unless $get_head || $get_body;
 
    my ($filename, $lines);
    if(ref $data eq 'ARRAY')
    {   $filename = 'array of lines';
        $lines    = $data;
    }
    elsif(ref $data eq 'GLOB')
    {   $filename = 'file (GLOB)';
        $lines    = [ <$data> ];
    }
    elsif(ref $data && $data->isa('IO::Handle'))
    {   $filename = 'file ('.ref($data).')';
        $lines    = [ $data->getlines ];
    }
    else
    {   $self->log(ERROR=> "Mail::Internet does not support this kind of data");
        return undef;
    }

    return unless @$lines;

    my $buffer = join '', @$lines;
    my $file   = Mail::Box::FastScalar->new(\$buffer);

    my $parser = Mail::Box::Parser::Perl->new
     ( filename  => $filename
     , file      => $file
     , trusted   => 1
     );

    my $head;
    if($get_head)
    {   my $from = substr($lines->[0], 0, 5) eq 'From ' ? shift @$lines : undef;

        my $head = $self->{MM_head_type}->new
          ( MailFrom   => $self->{MI_mail_from}
          , Modify => $self->{MI_modify}
          , FoldLength => $self->{MI_wrap}
          );
        $head->read($parser);
        $head->mail_from($from) if defined $from;
        $self->head($head);
    }
    else
    {   $head = $self->head;
    }

    $self->storeBody($self->readBody($parser, $head)) if $get_body;
    $self->addReport($parser);
    $parser->stop;
    $self;
}


sub dup()
{   my $self = shift;
    ref($self)->coerce($self->clone);
}


sub empty() { shift->DESTROY }

#--------------------------


sub MailFrom(;$)
{   my $self = shift;
    @_ ? ($self->{MI_mail_from} = shift) : $self->{MU_mail_from};
}

#--------------------------


sub read($@)
{   my $thing = shift;

    return $thing->SUPER::read(@_)   # Mail::Message behavior
        unless ref $thing;

    # Mail::Header emulation
    my $data = shift;
    $thing->processRawData($data, 1, 1);
}


sub read_body($)
{   my ($self, $data) = @_;
    $self->processRawData($data, 0, 1);
}


sub read_header($)
{   my ($self, $data) = @_;
    $self->processRawData($data, 1, 0);
}


sub extract($)
{   my ($self, $data) = @_;
    $self->processRawData($data, 1, 1);
}


sub reply(@)
{   my ($self, %args) = @_;

    my $reply_head = $self->{MM_head_type}->new;
    my $home       = $ENV{HOME} || File::Spec->curdir;
    my $headtemp   = File::Spec->catfile($home, '.mailhdr');

    if(open HEAD, '<:raw', $headtemp)
    {    my $parser = Mail::Box::Parser::Perl->new
           ( filename  => $headtemp
           , file      => \*HEAD
           , trusted   => 1
           );
         $reply_head->read($parser);
         $parser->close;
    }

    $args{quote}       ||= delete $args{Inline}   || '>';
    $args{group_reply} ||= delete $args{ReplyAll} || 0;
    my $keep             = delete $args{Keep}     || [];
    my $exclude          = delete $args{Exclude}  || [];

    my $reply = $self->SUPER::reply(%args);

    my $head  = $self->head;

    $reply_head->add($_->clone)
        foreach map { $head->get($_) } @$keep;

    $reply_head->reset($_) foreach @$exclude;

    ref($self)->coerce($reply);
}


sub add_signature(;$)
{   my $self     = shift;
    my $filename = shift
       || File::Spec->catfile($ENV{HOME} || File::Spec->curdir, '.signature');
    $self->sign(File => $filename);
}


sub sign(@)
{   my ($self, $args) = @_;
    my $sig;

    if(my $filename = delete $self->{File})
    {   $sig = Mail::Message::Body->new(file => $filename);
    }
    elsif(my $sig   = delete $self->{Signature})
    {   $sig = Mail::Message::Body->new(data => $sig);
    }

    return unless defined $sig;
 
    my $body = $self->decoded->stripSignature;
    my $set  = $body->concatenate($body, "-- \n", $sig);
    $self->body($set) if defined $set;
    $set;
}


sub send($@)
{   my ($self, $type, %args) = @_;
    $self->send(via => $type);
}


sub nntppost(@)
{   my ($self, %args) = @_;
    $args{port}       ||= delete $args{Port};
    $args{nntp_debug} ||= delete $args{Debug};

    $self->send(via => 'nntp', %args);
}



sub head(;$)
{  my $self = shift;
   return $self->SUPER::head(@_) if @_;
   $self->SUPER::head || $self->{MM_head_type}->new(message => $self);
}


sub header(;$) { shift->head->header(@_) }


sub fold(;$) { shift->head->fold(@_) }


sub fold_length(;$$) { shift->head->fold_length(@_) }


sub combine($;$) { shift->head->combine(@_) }


sub print_header(@) { shift->head->print(@_) }


sub clean_header() { shift->header }


sub tidy_headers() { }


sub add(@) { shift->head->add(@_) }


sub replace(@) { shift->head->replace(@_) }


sub get(@) { shift->head->get(@_) }


sub delete(@)
{   my $self = shift;
    @_ ?  $self->head->delete(@_) : $self->SUPER::delete;
}

#------------


sub body(@)
{   my $self = shift;

    unless(@_)
    {   my $body = $self->body;
        return defined $body ? scalar($body->lines) : [];
    }

    my $data = ref $_[0] eq 'ARRAY' ? shift : \@_;
    my $body  = Mail::Message::Body::Lines->new(data => $data);
    $self->body($body);

    $body;
}


sub print_body(@) { shift->SUPER::body->print(@_) }


sub bodyObject(;$) { shift->SUPER::body(@_) }


sub remove_sig(;$)
{   my $self  = shift;
    my $lines = shift || 10;
    my $stripped = $self->decoded->stripSignature(max_lines => $lines);
    $self->body($stripped) if defined $stripped;
    $stripped;
}


sub tidy_body(;$)
{   my $self  = shift;

    my $body  = $self->body or return;
    my @body  = $body->lines;

    shift @body while @body &&  $body[0] =~ m/^\s*$/;
    pop   @body while @body && $body[-1] =~ m/^\s*$/;

    return $body if $body->nrLines == @body;
    my $new = Mail::Message::Body::Lines->new(based_on => $body, data=>\@body);
    $self->body($new);
}


sub smtpsend(@)
{   my ($self, %args) = @_;
    my $from = $args{MailFrom} || $ENV{MAILADDRESS} || $ENV{USER} || 'unknown';
    $args{helo}       ||= delete $args{Hello};
    $args{port}       ||= delete $args{Port};
    $args{smtp_debug} ||= delete $args{Debug};

    my $host  = $args{Host};
    unless(defined $host)
    {   my $hosts = $ENV{SMTPHOSTS};
        $host = (split /\:/, $hosts)[0] if defined $hosts;
    }
    $args{host} = $host;

    $self->send(via => 'smtp', %args);
}

#------------


sub as_mbox_string()
{   my $self    = shift;
    my $mboxmsg = Mail::Box::Mbox->coerce($self);

    my $buffer  = '';
    my $file    = Mail::Box::FastScalar->new(\$buffer);
    $mboxmsg->print($file);
    $buffer;
}

#------------


BEGIN {
 no warnings;
 *Mail::Internet::new = sub (@)
   { my $class = shift;
     Mail::Message::Replace::MailInternet->new(@_);
   };
}


sub isa($)
{   my ($thing, $class) = @_;
    return 1 if $class eq 'Mail::Internet';
    $thing->SUPER::isa($class);
}

#------------


sub coerce() { confess }


1;

