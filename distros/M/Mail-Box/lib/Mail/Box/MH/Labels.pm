# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::MH::Labels;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Head::Subset;

use File::Copy;
use Carp;


#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{MBML_filename}  = $args->{filename}
       or croak "No label filename specified.";

    $self;
}

#-------------------------------------------


sub filename() {shift->{MBML_filename}}

#-------------------------------------------


sub get($)
{   my ($self, $msgnr) = @_;
    $self->{MBML_labels}[$msgnr];
}

#-------------------------------------------


sub read()
{   my $self = shift;
    my $seq  = $self->filename;

    open SEQ, '<:raw', $seq
       or return;

    my @labels;

    local $_;
    while(<SEQ>)
    {   s/\s*\#.*$//;
        next unless length;

        next unless s/^\s*(\w+)\s*\:\s*//;
        my $label = $1;

        my $set   = 1;
           if($label eq 'cur'   ) { $label = 'current' }
        elsif($label eq 'unseen') { $label = 'seen'; $set = 0 }

        foreach (split /\s+/)
        {   if( /^(\d+)\-(\d+)\s*$/ )
            {   push @{$labels[$_]}, $label, $set foreach $1..$2;
            }
            elsif( /^\d+\s*$/ )
            {   push @{$labels[$_]}, $label, $set;
            }
        }
    }

    close SEQ;

    $self->{MBML_labels} = \@labels;
    $self;
}

#-------------------------------------------


sub write(@)
{   my $self     = shift;
    my $filename = $self->filename;

    # Remove when no messages are left.
    unless(@_)
    {   unlink $filename;
        return $self;
    }

    open my $out, '>:raw', $filename or return;
    $self->print($out, @_);
    close $out;

    $self;
}

#-------------------------------------------


sub append(@)
{   my $self     = shift;
    my $filename = $self->filename;

    open(my $out, '>>:raw', $filename) or return;
    $self->print($out, @_);
    close $out;

    $self;
}

#-------------------------------------------


sub print($@)
{   my ($self, $out) = (shift, shift);

    # Collect the labels from the selected messages.
    my %labeled;
    foreach my $message (@_)
    {   my $labels = $message->labels;
        (my $seq   = $message->filename) =~ s!.*/!!;

        push @{$labeled{unseen}}, $seq
            unless $labels->{seen};

        foreach (keys %$labels)
        {   push @{$labeled{$_}}, $seq
                if $labels->{$_};
        }
    }
    delete $labeled{seen};

    # Write it out

    local $"     = ' ';
    foreach (sort keys %labeled)
    {
        my @msgs = @{$labeled{$_}};  #they are ordered already.
        $_ = 'cur' if $_ eq 'current';
        print $out "$_:";

        while(@msgs)
        {   my $start = shift @msgs;
            my $end   = $start;

            $end = shift @msgs
                 while @msgs && $msgs[0]==$end+1;

            print $out ($start==$end ? " $start" : " $start-$end");
        }
        print $out "\n";
    }

    $self;
}

#-------------------------------------------


1;
