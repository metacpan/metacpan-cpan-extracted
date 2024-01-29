# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::String;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Body';

use strict;
use warnings;

use Carp;
use Mail::Box::FastScalar;


#------------------------------------------
# The scalar is stored as reference to avoid a copy during creation of
# a string object.

sub _data_from_filename(@)
{   my ($self, $filename) = @_;

    delete $self->{MMBS_nrlines};

    local *IN;
    unless(open IN, '<', $filename)
    {   $self->log(ERROR =>
            "Unable to read file $filename for message body scalar: $!");
        return;
    }

    my @lines = <IN>;
    close IN;

    $self->{MMBS_nrlines} = @lines;
    $self->{MMBS_scalar}  = join '', @lines;
    $self;
}

sub _data_from_filehandle(@)
{   my ($self, $fh) = @_;
    if(ref $fh eq 'Mail::Box::FastScalar')
    {   my $lines = $fh->getlines;
        $self->{MMBS_nrlines} = @$lines;
        $self->{MMBS_scalar}  = join '', @$lines;
    }
    else
    {    my @lines = $fh->getlines;
         $self->{MMBS_nrlines} = @lines;
         $self->{MMBS_scalar}  = join '', @lines;
    }
    $self;
}

sub _data_from_glob(@)
{   my ($self, $fh) = @_;
    my @lines = <$fh>;
    $self->{MMBS_nrlines} = @lines;
    $self->{MMBS_scalar}  = join '', @lines;
    $self;
}

sub _data_from_lines(@)
{   my ($self, $lines) = @_;
    $self->{MMBS_nrlines} = @$lines unless @$lines==1;
    $self->{MMBS_scalar}  = @$lines==1 ? shift @$lines : join('', @$lines);
    $self;
}

sub clone()
{   my $self = shift;
    ref($self)->new(data => $self->string, based_on => $self);
}

sub nrLines()
{   my $self = shift;
    return $self->{MMBS_nrlines} if defined $self->{MMBS_nrlines};

    my $lines = $self->{MMBS_scalar} =~ tr/\n/\n/;
    $lines++ if $self->{MMBS_scalar} !~ m/\n\z/;
    $self->{MMBS_nrlines} = $lines;
}

sub size() { length shift->{MMBS_scalar} }

sub string() { shift->{MMBS_scalar} }

sub lines()
{   my @lines = split /^/, shift->{MMBS_scalar};
    wantarray ? @lines : \@lines;
}

sub file() { Mail::Box::FastScalar->new(\shift->{MMBS_scalar}) }

sub print(;$)
{   my $self = shift;
    my $fh   = shift || select;
    if(ref $fh eq 'GLOB') { print $fh $self->{MMBS_scalar} }
    else                  { $fh->print($self->{MMBS_scalar}) }
    $self;
}

sub read($$;$@)
{   my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
    delete $self->{MMBS_nrlines};

    (my $begin, my $end, $self->{MMBS_scalar}) = $parser->bodyAsString(@_);
    $self->fileLocation($begin, $end);

    $self;
}

sub endsOnNewline() { shift->{MMBS_scalar} =~ m/\A\z|\n\z/ }

1;
