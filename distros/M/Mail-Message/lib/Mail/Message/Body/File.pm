# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::File;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Body';

use strict;
use warnings;

use Mail::Box::Parser;
use Mail::Message;

use Carp;
use File::Temp qw/tempfile/;
use File::Copy qw/copy/;


sub _data_from_filename(@)
{   my ($self, $filename) = @_;

    local $_;
    local (*IN, *OUT);

    unless(open IN, '<:raw', $filename)
    {   $self->log(ERROR =>
            "Unable to read file $filename for message body file: $!");
        return;
    }

    my $file   = $self->tempFilename;
    unless(open OUT, '>:raw', $file)
    {   $self->log(ERROR => "Cannot write to temporary body file $file: $!");
        return;
    }

    my $nrlines = 0;
    while(<IN>) { print OUT; $nrlines++ }

    close OUT;
    close IN;

    $self->{MMBF_nrlines} = $nrlines;
    $self;
}

sub _data_from_filehandle(@)
{   my ($self, $fh) = @_;
    my $file    = $self->tempFilename;
    my $nrlines = 0;

    local *OUT;

    unless(open OUT, '>:raw', $file)
    {   $self->log(ERROR => "Cannot write to temporary body file $file: $!");
        return;
    }

    while(my $l = $fh->getline)
    {   print OUT $l;
        $nrlines++;
    }
    close OUT;

    $self->{MMBF_nrlines} = $nrlines;
    $self;
}

sub _data_from_glob(@)
{   my ($self, $fh) = @_;
    my $file    = $self->tempFilename;
    my $nrlines = 0;

    local $_;
    local *OUT;

    unless(open OUT, '>:raw', $file)
    {   $self->log(ERROR => "Cannot write to temporary body file $file: $!");
        return;
    }

    while(<$fh>)
    {   print OUT;
        $nrlines++;
    }
    close OUT;

    $self->{MMBF_nrlines} = $nrlines;
    $self;
}

sub _data_from_lines(@)
{   my ($self, $lines)  = @_;
    my $file = $self->tempFilename;

    local *OUT;

    unless(open OUT, '>:raw', $file)
    {   $self->log(ERROR => "Cannot write to $file: $!");
        return;
    }

    print OUT @$lines;
    close OUT;

    $self->{MMBF_nrlines} = @$lines;
    $self;
}

sub clone()
{   my $self  = shift;
    my $clone = ref($self)->new(based_on => $self);

    copy($self->tempFilename, $clone->tempFilename)
       or return;

    $clone->{MMBF_nrlines} = $self->{MMBF_nrlines};
    $clone->{MMBF_size}    = $self->{MMBF_size};
    $self;
}

sub nrLines()
{   my $self    = shift;

    return $self->{MMBF_nrlines}
        if defined $self->{MMBF_nrlines};

    my $file    = $self->tempFilename;
    my $nrlines = 0;

    local $_;
    local *IN;

    open IN, '<:raw', $file
        or die "Cannot read from $file: $!\n";

    $nrlines++ while <IN>;
    close IN;

    $self->{MMBF_nrlines} = $nrlines;
}

#------------------------------------------

sub size()
{   my $self = shift;

    return $self->{MMBF_size}
       if exists $self->{MMBF_size};

    my $size = eval { -s $self->tempFilename };

    $size   -= $self->nrLines
        if $Mail::Message::crlf_platform;   # remove count for extra CR's

    $self->{MMBF_size} = $size;
}

sub string()
{   my $self = shift;

    my $file = $self->tempFilename;

    local *IN;

    open IN, '<:raw', $file
        or die "Cannot read from $file: $!\n";

    my $return = join '', <IN>;
    close IN;

    $return;
}

sub lines()
{   my $self = shift;

    my $file = $self->tempFilename;

    local *IN;
    open IN, '<:raw', $file
        or die "Cannot read from $file: $!\n";

    my @r = <IN>;
    close IN;

    $self->{MMBF_nrlines} = @r;
    wantarray ? @r: \@r;
}

sub file()
{   open my $tmp, '<:raw', shift->tempFilename;
    $tmp;
}

sub print(;$)
{   my $self = shift;
    my $fh   = shift || select;
    my $file = $self->tempFilename;

    local $_;
    local *IN;

    open IN, '<:raw', $file
        or croak "Cannot read from $file: $!\n";

    if(ref $fh eq 'GLOB') {print $fh $_ while <IN>}
    else                  {$fh->print($_) while <IN>}
    close IN;

    $self;
}

sub read($$;$@)
{   my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
    my $file = $self->tempFilename;

    local *OUT;

    open OUT, '>:raw', $file
        or die "Cannot write to $file: $!.\n";

    (my $begin, my $end, $self->{MMBF_nrlines}) = $parser->bodyAsFile(\*OUT,@_);
    close OUT;

    $self->fileLocation($begin, $end);
    $self;
}

# on UNIX always true.  Expensive to calculate on Windows: message size
# may be off-by-one in rare cases.
sub endsOnNewline() { shift->size==0 }

#------------------------------------------


sub tempFilename(;$)
{   my $self = shift;

      @_                     ? ($self->{MMBF_filename} = shift)
    : $self->{MMBF_filename} ? $self->{MMBF_filename}
    :                          ($self->{MMBF_filename} = (tempfile)[1]);
}

#------------------------------------------


sub DESTROY { unlink shift->tempFilename }

#------------------------------------------

1;
