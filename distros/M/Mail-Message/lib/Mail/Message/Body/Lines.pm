# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::Lines;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Body';

use strict;
use warnings;

use Mail::Box::Parser;
use IO::Lines;

use Carp;


sub _data_from_filename(@)
{   my ($self, $filename) = @_;

    local *IN;

    unless(open IN, '<', $filename)
    {   $self->log(ERROR =>
             "Unable to read file $filename for message body lines: $!");
        return;
    }

    $self->{MMBL_array} = [ <IN> ];

    close IN;
    $self;
}

sub _data_from_filehandle(@)
{   my ($self, $fh) = @_;
    $self->{MMBL_array} =
       ref $fh eq 'Mail::Box::FastScalar' ? $fh->getlines : [ $fh->getlines ];
    $self
}

sub _data_from_glob(@)
{   my ($self, $fh) = @_;
    $self->{MMBL_array} = [ <$fh> ];
    $self;
}

sub _data_from_lines(@)
{   my ($self, $lines)  = @_;
    $lines = [ split /^/, $lines->[0] ]    # body passed in one string.
        if @$lines==1;

    $self->{MMBL_array} = $lines;
    $self;
}

#------------------------------------------

sub clone()
{   my $self  = shift;
    ref($self)->new(data => [ $self->lines ], based_on => $self);
}

#------------------------------------------

sub nrLines() { scalar @{shift->{MMBL_array}} }

#------------------------------------------
# Optimized to be computed only once.

sub size()
{   my $self = shift;
    return $self->{MMBL_size} if exists $self->{MMBL_size};

    my $size = 0;
    $size += length $_ foreach @{$self->{MMBL_array}};
    $self->{MMBL_size} = $size;
}

#------------------------------------------

sub string() { join '', @{shift->{MMBL_array}} }

#------------------------------------------

sub lines() { wantarray ? @{shift->{MMBL_array}} : shift->{MMBL_array} }

#------------------------------------------

sub file() { IO::Lines->new(shift->{MMBL_array}) }

#------------------------------------------

sub print(;$)
{   my $self = shift;
    my $fh   = shift || select;
    if(ref $fh eq 'GLOB') { print $fh @{$self->{MMBL_array}}   }
    else                  { $fh->print(@{$self->{MMBL_array}}) }
    $self;
}

#------------------------------------------

sub read($$;$@)
{   my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
    my ($begin, $end, $lines) = $parser->bodyAsList(@_);
    $lines or return undef;

    $self->fileLocation($begin, $end);
    $self->{MMBL_array} = $lines;
    $self;
}

#------------------------------------------

sub endsOnNewline()
{   my $last = shift->{MMBL_array}[-1];
    !defined $last || $last =~ m/\n$/;
}

#------------------------------------------

1;
