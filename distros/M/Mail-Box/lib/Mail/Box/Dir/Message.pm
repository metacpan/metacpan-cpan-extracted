# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Dir::Message;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Message';

use strict;
use warnings;

use File::Copy qw/move/;
use IO::File;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->filename($args->{filename})
        if $args->{filename};

    $self->{MBDM_fix_header} = $args->{fix_header};
    $self;
}

#-------------------------------------------


#-------------------------------------------

sub print(;$)
{   my $self     = shift;
    my $out      = shift || select;

    return $self->SUPER::print($out)
        if $self->isModified;

    my $filename = $self->filename;
    if($filename && -r $filename)
    {   if(open my $in, '<:raw', $filename)
        {    local $_;
             print $out $_ while <$in>;
             close $in;
             return $self;
        }
    }

    $self->SUPER::print($out);

    1;
}

#-------------------------------------------

BEGIN { *write = \&print }  # simply alias

#-------------------------------------------


sub filename(;$)
{   my $self = shift;
    @_ ? ($self->{MBDM_filename} = shift) : $self->{MBDM_filename};
}

#-------------------------------------------


# Asking the filesystem for the size is faster counting (in
# many situations.  It even may be lazy.

sub size()
{   my $self = shift;

    unless($self->isModified)
    {   my $filename = $self->filename;
        if(defined $filename)
        {   my $size = -s $filename;
            return $size if defined $size;
        }
    }

    $self->SUPER::size;
}

#-------------------------------------------

sub diskDelete()
{   my $self = shift;
    $self->SUPER::diskDelete;

    my $filename = $self->filename;
    unlink $filename if $filename;
    $self;
}

#-------------------------------------------


sub parser()
{   my $self   = shift;

    my $parser = Mail::Box::Parser->new
      ( filename => $self->{MBDM_filename}
      , mode     => 'r'
      , fix_header_errors => $self->{MBDM_fix_header}
      , $self->logSettings
      );

    unless($parser)
    {   $self->log(ERROR => "Cannot create parser for $self->{MBDM_filename}.");
        return;
    }

    $parser;
}

#-------------------------------------------


sub loadHead()
{   my $self     = shift;
    my $head     = $self->head;
    return $head unless $head->isDelayed;

    my $folder   = $self->folder;
    $folder->lazyPermitted(1);

    my $parser   = $self->parser or return;
    $self->readFromParser($parser);
    $parser->stop;

    $folder->lazyPermitted(0);

    $self->log(PROGRESS => 'Loaded delayed head.');
    $self->head;
}

#-------------------------------------------


sub loadBody()
{   my $self     = shift;

    my $body     = $self->body;
    return $body unless $body->isDelayed;

    my $head     = $self->head;
    my $parser   = $self->parser or return;

    if($head->isDelayed)
    {   $head = $self->readHead($parser);
        if(defined $head)
        {   $self->log(PROGRESS => 'Loaded delayed head.');
            $self->head($head);
        }
        else
        {   $self->log(ERROR => 'Unable to read delayed head.');
            return;
        }
    }
    else
    {   my ($begin, $end) = $body->fileLocation;
        $parser->filePosition($begin);
    }

    my $newbody  = $self->readBody($parser, $head);
    $parser->stop;

    unless(defined $newbody)
    {   $self->log(ERROR => 'Unable to read delayed body.');
        return;
    }

    $self->log(PROGRESS => 'Loaded delayed body.');
    $self->storeBody($newbody->contentInfoFrom($head));
}

#-------------------------------------------


sub create($)
{   my ($self, $filename) = @_;

    my $old = $self->filename || '';
    return $self if $filename eq $old && !$self->isModified;

    # Write the new data to a new file.

    my $new     = $filename . '.new';
    my $newfile = IO::File->new($new, 'w');
    $self->log(ERROR => "Cannot write message to $new: $!"), return
        unless $newfile;

    $self->write($newfile);
    $newfile->close;

    # Accept the new data
# maildir produces warning where not expected...
#   $self->log(WARNING => "Failed to remove $old: $!")
#       if $old && !unlink $old;

    unlink $old if $old;

    $self->log(ERROR => "Failed to move $new to $filename: $!"), return
         unless move($new, $filename);

    $self->modified(0);

    # Do not affect flags for Maildir (and some other) which keep it
    # in there.  Flags will be processed later.
    $self->Mail::Box::Dir::Message::filename($filename);

    $self;
}

#-------------------------------------------

1;
