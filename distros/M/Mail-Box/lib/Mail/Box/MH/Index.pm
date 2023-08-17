# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::MH::Index;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Head::Subset;
use Carp;


#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{MBMI_filename}  = $args->{filename}
       or croak "No index filename specified.";

    $self->{MBMI_head_wrap} = $args->{head_wrap} || 72;
    $self->{MBMI_head_type}
       = $args->{head_type} || 'Mail::Message::Head::Subset';

    $self;
}

#-------------------------------------------


sub filename() {shift->{MBMI_filename}}

#-------------------------------------------


sub write(@)
{   my $self  = shift;
    my $index = $self->filename or return $self;

    # Remove empty index-file.
    unless(@_)
    {   unlink $index;
        return $self;
    }

    local *INDEX;
    open INDEX, '>:raw', $index
        or return $self;

    my $fieldtype = 'Mail::Message::Field';
    my $written    = 0;

    foreach my $msg (@_)
    {   my $head     = $msg->head;
        next if $head->isDelayed && $head->isa('Mail::Message::Head::Subset');

        my $filename = $msg->filename;
        print INDEX "X-MailBox-Filename: $filename\n"
                  , 'X-MailBox-Size: ', (-s $filename), "\n";

        $head->print(\*INDEX);
        $written++;
    }

    close INDEX;

    $written or unlink $index;

    $self;
}

#-------------------------------------------


sub append(@)
{   my $self      = shift;
    my $index     = $self->filename or return $self;

    local *INDEX;
    open INDEX, '>>:raw', $index
        or return $self;

    my $fieldtype = 'Mail::Message::Field';

    foreach my $msg (@_)
    {   my $head     = $msg->head;
        next if $head->isDelayed && $head->isa('Mail::Message::Head::Subset');

        my $filename = $msg->filename;
        print INDEX "X-MailBox-Filename: $filename\n"
                  , 'X-MailBox-Size: ', (-s $filename), "\n";

        $head->print(\*INDEX);
    }

    close INDEX;
    $self;
}

#-------------------------------------------


sub read(;$)
{   my $self     = shift;
    my $filename = $self->{MBMI_filename};

    my $parser   = Mail::Box::Parser->new
      ( filename => $filename
      , mode     => 'r'
      ) or return;

    my @options  = ($self->logSettings, wrap_length => $self->{MBMI_head_wrap});
    my $type     = $self->{MBMI_head_type};
    my $index_age= -M $filename;
    my %index;

    while(my $head = $type->new(@options)->read($parser))
    {
        # cleanup the index from files which were renamed
        my $msgfile = $head->get('x-mailbox-filename');
        my $size    = int $head->get('x-mailbox-size');
        next unless -f $msgfile && -s _ == $size;
        next if defined $index_age && -M _ < $index_age;

        # keep this one
        $index{$msgfile} = $head;
    }

    $parser->stop;

    $self->{MBMI_index} = \%index;
    $self;
}

#-------------------------------------------


sub get($)
{   my ($self, $msgfile) = @_;
    $self->{MBMI_index}{$msgfile};
}

#-------------------------------------------


1;
