# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Flex;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field';

use strict;
use warnings;

use Carp;


sub new($;$$@)
{   my $class  = shift;
    my $args   = @_ <= 2 || ! ref $_[-1] ? {}
                : ref $_[-1] eq 'ARRAY'  ? { @{pop @_} }
                :                          pop @_;

    my ($name, $body) = $class->consume(@_==1 ? (shift) : (shift, shift));
    return () unless defined $body;

    # Attributes preferably stored in array to protect order.
    my $attr   = $args->{attributes};
    $attr      = [ %$attr ] if defined $attr && ref $attr eq 'HASH';
    push @$attr, @_;

    $class->SUPER::new(%$args, name => $name, body => $body,
         attributes => $attr);
}

sub init($)
{   my ($self, $args) = @_;

    @$self{ qw/MMFF_name MMFF_body/ } = @$args{ qw/name body/ };

    $self->comment($args->{comment})
        if exists $args->{comment};

    my $attr = $args->{attributes};
    $self->attribute(shift @$attr, shift @$attr)
        while @$attr;

    $self;
}

#------------------------------------------

sub clone()
{   my $self = shift;
    (ref $self)->new($self->Name, $self->body);
}

#------------------------------------------

sub length()
{   my $self = shift;
    length($self->{MMFF_name}) + 1 + length($self->{MMFF_body});
}

#------------------------------------------

sub name() { lc shift->{MMFF_name}}

#------------------------------------------

sub Name() { shift->{MMFF_name}}

#------------------------------------------

sub folded(;$)
{   my $self = shift;
    return $self->{MMFF_name}.':'.$self->{MMFF_body}
        unless wantarray;

    my @lines = $self->foldedBody;
    my $first = $self->{MMFF_name}. ':'. shift @lines;
    ($first, @lines);
}

#------------------------------------------

sub unfoldedBody($;@)
{   my $self = shift;
    $self->{MMFF_body} = $self->fold($self->{MMFF_name}, @_)
       if @_;

    $self->unfold($self->{MMFF_body});
}

#------------------------------------------

sub foldedBody($)
{   my ($self, $body) = @_;
    if(@_==2) { $self->{MMFF_body} = $body }
    else      { $body = $self->{MMFF_body} }

    wantarray ? (split /^/, $body) : $body;
}

#------------------------------------------

1;
