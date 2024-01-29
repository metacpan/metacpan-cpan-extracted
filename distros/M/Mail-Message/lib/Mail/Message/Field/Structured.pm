# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Structured;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Field::Full';

use strict;
use warnings;

use Mail::Message::Field::Attribute;
use Storable 'dclone';


sub init($)
{   my ($self, $args) = @_;
    $self->{MMFS_attrs} = {};
    $self->{MMFS_datum} = $args->{datum};

    $self->SUPER::init($args);

    my $attr = $args->{attributes} || [];
    $attr    = [ %$attr ] if ref $attr eq 'HASH';

    while(@$attr)
    {   my $name = shift @$attr;
        if(ref $name) { $self->attribute($name) }
        else          { $self->attribute($name, shift @$attr) }
    }

    $self;
}

sub clone() { dclone(shift) }

#------------------------------------------


sub attribute($;$)
{   my ($self, $attr) = (shift, shift);
    my $name;
    if(ref $attr) { $name = $attr->name }
    elsif( !@_ )  { return $self->{MMFS_attrs}{lc $attr} }
    else
    {   $name = $attr;
        $attr = Mail::Message::Field::Attribute->new($name, @_);
    }

    delete $self->{MMFF_body};
    $self->{MMFS_attrs}{lc $name} = $attr;
}


sub attributes() { values %{shift->{MMFS_attrs}} }
sub beautify() { delete shift->{MMFF_body} }


sub attrPairs() { map +($_->name, $_->value), shift->attributes }

#-------------------------


sub parse($)
{   my ($self, $string) = @_;

    for($string)
    {   # remove FWS, even within quoted strings
        s/\r?\n(\s)/$1/gs;
        s/\r?\n/ /gs;
	    s/\s+$//;
    }

    my $datum = '';
    while(length $string && substr($string, 0, 1) ne ';')
    {   (undef, $string)  = $self->consumeComment($string);
        $datum .= $1 if $string =~ s/^([^;(]+)//;
    }
    $self->{MMFS_datum} = $datum;

    my $found = '';
    while($string =~ m/\S/)
    {   my $len = length $string;

        if($string =~ s/^\s*\;\s*// && length $found)
        {   my ($name) = $found =~ m/^([^*]+)\*/;
            if($name && (my $cont = $self->attribute($name)))
            {   $cont->addComponent($found);   # continuation
            }
            else
            {   my $attr = Mail::Message::Field::Attribute->new($found);
                $self->attribute($attr);
            }
            $found = '';
        }

        (undef, $string) = $self->consumeComment($string);
        $string =~ s/^\n//;
        (my $text, $string) = $self->consumePhrase($string);
        $found .= $text if defined $text;

        if(length($string) == $len)
        {   # nothing consumed, remove character to avoid endless loop
            $string =~ s/^\s*\S//;
        }
    }

    if(length $found)
    {   my ($name) = $found =~ m/^([^*]+)\*/;
        if($name && (my $cont = $self->attribute($name)))
        {   $cont->addComponent($found); # continuation
        }
        else
        {   my $attr = Mail::Message::Field::Attribute->new($found);
            $self->attribute($attr);
        }
    }

    1;
}

sub produceBody()
{   my $self  = shift;
    my $attrs = $self->{MMFS_attrs};
    my $datum = $self->{MMFS_datum};

    join '; '
       , (defined $datum ? $datum : '')
       , map {$_->string} @{$attrs}{sort keys %$attrs};
}


sub datum(@)
{   my $self = shift;
    @_ or return $self->{MMFS_datum};
    delete $self->{MMFF_body};
    $self->{MMFS_datum} = shift;
}

1;
