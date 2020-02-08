# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Fast;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field';

use strict;
use warnings;


#------------------------------------------
#
# The DATA is stored as:   [ NAME, FOLDED-BODY ]
# The body is kept in a folded fashion, where each line starts with
# a single blank.


sub new($;$@)
{   my $class = shift;

    my ($name, $body) = $class->consume(@_==1 ? (shift) : (shift, shift));
    return () unless defined $body;

    my $self = bless [$name, $body], $class;

    # Attributes
    $self->comment(shift)             if @_==1;   # one attribute line
    $self->attribute(shift, shift) while @_ > 1;  # attribute pairs

    $self;
}

sub clone()
{   my $self = shift;
    bless [ @$self ], ref $self;
}

sub length()
{   my $self = shift;
    length($self->[0]) + 1 + length($self->[1]);
}

sub name() { lc shift->[0] }
sub Name() { shift->[0] }

sub folded()
{   my $self = shift;
    return $self->[0].':'.$self->[1]
        unless wantarray;

    my @lines = $self->foldedBody;
    my $first = $self->[0]. ':'. shift @lines;
    ($first, @lines);
}

sub unfoldedBody($;@)
{   my $self = shift;

    $self->[1] = $self->fold($self->[0], @_)
       if @_;

    $self->unfold($self->[1]);
}

sub foldedBody($)
{   my ($self, $body) = @_;
    if(@_==2) { $self->[1] = $body }
    else      { $body = $self->[1] }
     
    wantarray ? (split m/^/, $body) : $body;
}

# For performance reasons only
sub print(;$)
{   my $self = shift;
    my $fh   = shift || select;
    if(ref $fh eq 'GLOB') { print $fh $self->[0].':'.$self->[1]   }
    else                  { $fh->print($self->[0].':'.$self->[1]) }
    $self;
}

1;
