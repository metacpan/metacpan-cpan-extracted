# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Replace::MailHeader;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Head::Complete';

use strict;
use warnings;


sub new(@)
{   my $class = shift;
    unshift @_, 'raw_data' if @_ % 2;
    $class->SUPER::new(@_);
}

sub init($)
{   my ($self, $args) = @_;
    defined $self->SUPER::init($args) or return;

    $self->modify     ($args->{Modify}     || $args->{Reformat} || 0);
    $self->fold_length($args->{FoldLength} || 79);
    $self->mail_from  ($args->{MailFrom}   || 'KEEP');
    $self;
}


sub delete($;$)
{   my ($self, $tag) = (shift, shift);
    return $self->delete($tag) unless @_;

    my $index   = shift;
    my @fields  = $self->get($tag);
    my ($field) = splice @fields, $index, 1;
    $self->reset($tag, @fields);
    $field;
}


sub add($$)
{   my $self  = shift;
    my $field = $self->add(shift);
    $field->unfoldedBody;
}


sub replace($$;$)
{   my ($self, $tag, $line, $index) = @_;
    $line =~ s/^([^:]+)\:\s*// && ($tag = $1) unless defined $tag;

    my $field  = Mail::Message::Field::Fast->new($tag, $line);
    my @fields = $self->get($tag);
    $fields[ $index||0 ] = $field;
    $self->reset($tag, @fields);

    $field;
}


sub get($;$)
{   my $head = shift->head;
    my @ret  = map { $head->get(@_) } @_;

    if(wantarray) { return @ret ? map({$_->unfoldedBody} @ret) : () }
    else          { return @ret ? $ret[0]->unfoldedBody : undef }
}


sub modify(;$)
{   my $self = shift;
    @_ ? ($self->{MH_refold} = shift) : $self->{MH_refold};
}


sub mail_from(;$)
{   my $self = shift;
    return $self->{MH_mail_from} unless @_;

    my $choice = uc(shift);
    die "bad Mail-From choice: '$choice'"
        unless $choice =~ /^(IGNORE|ERROR|COERCE|KEEP)$/;

    $self->{MH_mail_from} = $choice;
}


sub fold(;$)
{   my $self = shift;
    my $wrap = @_ ? shift : $self->fold_length;
    $_->setWrapLength($wrap) foreach $self->orderedFields;
    $self;
}


sub unfold(;$)
{   my $self = shift;
    my @fields = @_ ? $self->get(shift) : $self->orderedFields;
    $_->setWrapLength(100_000) foreach @fields;  # blunt approach
    $self;
}


sub extract($)
{   my ($self, $lines) = @_;

    my $parser = Mail::Box::Parser::Perl->new
       ( filename  => 'extract from array'
       , data      => $lines
       , trusted   => 1
       );

    $self->read($parser);
    $parser->close;

    # Remove header from array
    shift @$lines while @$lines && $lines->[0] != m/^[\r\n]+/;
    shift @$lines if @$lines;
    $self;
}


sub read($)
{   my ($self, $file) = @_;
    my $parser = Mail::Box::Parser::Perl->new
       ( filename  => ('from file-handle '.ref $file)
       , file      => $file
       , trusted   => 1
       );
    $self->read($parser);
    $parser->close;
    $self;
}


sub empty() { shift->removeFields( m/^/ ) }


sub header(;$)
{   my $self = shift;
    $self->extract(shift) if @_;
    $self->fold if $self->modify;
    [ $self->orderedFields ];
}


sub header_hashref($) { die "Don't use header_hashref!!!" }


sub combine($;$) { die "Don't use combine()!!!" }


sub exists() { shift->count }


sub as_string() { shift->string }


sub fold_length(;$$)
{   my $self = shift;
    return $self->{MH_wrap} unless @_;

    my $old  = $self->{MH_wrap};
    my $wrap = $self->{MH_wrap} = shift;
    $self->fold($wrap) if $self->modify;
    $old;
}    


sub tags() { shift->names }


sub dup() { shift->clone }


sub cleanup() { shift }


BEGIN
{   no warnings;
    *Mail::Header::new =
     sub { my $class = shift;
           Mail::Message::Replace::MailHeader->new(@_);
         }
}



sub isa($)
{   my ($thing, $class) = @_;
    return 1 if $class eq 'Mail::Mailer';
    $thing->SUPER::isa($class);
}


1;


