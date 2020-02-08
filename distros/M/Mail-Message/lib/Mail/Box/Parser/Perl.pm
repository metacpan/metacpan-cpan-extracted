# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Parser::Perl;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Box::Parser';

use strict;
use warnings;

use Mail::Message::Field;
use List::Util 'sum';
use IO::File;


sub init(@)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;

    $self->{MBPP_trusted} = $args->{trusted};
    $self->{MBPP_fix}     = $args->{fix_header_errors};
    $self;
}

sub pushSeparator($)
{   my ($self, $sep) = @_;
    unshift @{$self->{MBPP_separators}}, $sep;
    $self->{MBPP_strip_gt}++ if $sep eq 'From ';
    $self;
}

sub popSeparator()
{   my $self = shift;
    my $sep  = shift @{$self->{MBPP_separators}};
    $self->{MBPP_strip_gt}-- if $sep eq 'From ';
    $sep;
}
    
sub filePosition(;$)
{   my $self = shift;
    @_ ? $self->{MBPP_file}->seek(shift, 0) : $self->{MBPP_file}->tell;
}

my $empty = qr/^\015?\012?$/;


sub readHeader()
{   my $self  = shift;
    my $file  = $self->{MBPP_file};

    my @ret   = ($file->tell, undef);
    my $line  = $file->getline;

  LINE:
    while(defined $line)
    {   last LINE if $line =~ $empty;
        my ($name, $body) = split /\s*\:\s*/, $line, 2;

        unless(defined $body)
        {   $self->log(WARNING =>
                "Unexpected end of header in ".$self->filename.":\n $line");

            if(@ret && $self->fixHeaderErrors)
            {   $ret[-1][1] .= ' '.$line;  # glue err line to previous field
                $line = $file->getline;
                next LINE;
            }
            else
            {   $file->seek(-length $line, 1);
                last LINE;
            }
        }

        $body = "\n" unless length $body;

        # Collect folded lines
        while($line = $file->getline)
        {   $line =~ m!^[ \t]! ? ($body .= $line) : last;
        }

        $body =~ s/\015//g;
        push @ret, [ $name, $body ];
    }

    $ret[1]  = $file->tell;
    @ret;
}

sub _is_good_end($)
{   my ($self, $where) = @_;

    # No seps, then when have to trust it.
    my $sep = $self->{MBPP_separators}[0];
    return 1 unless defined $sep;

    my $file = $self->{MBPP_file};
    my $here = $file->tell;
    $file->seek($where, 0) or return 0;

    # Find first non-empty line on specified location.
    my $line = $file->getline;
    $line    = $file->getline while defined $line && $line =~ $empty;

    # Check completed, return to old spot.
    $file->seek($here, 0);
    return 1 unless defined $line;

        substr($line, 0, length $sep) eq $sep
    && ($sep ne 'From ' || $line =~ m/ (?:19[6-9]|20[0-2])[0-9]\b/ );
}

sub readSeparator()
{   my $self = shift;

    my $sep   = $self->{MBPP_separators}[0];
    return () unless defined $sep;

    my $file  = $self->{MBPP_file};
    my $start = $file->tell;

    my $line  = $file->getline;
    while(defined $line && $line =~ $empty)
    {   $start   = $file->tell;
        $line    = $file->getline;
    }

    return () unless defined $line;

    $line     =~ s/[\012\015]+$/\n/;
    return ($start, $line)
        if substr($line, 0, length $sep) eq $sep;

    $file->seek($start, 0);
    ();
}

sub _read_stripped_lines(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    my @seps    = @{$self->{MBPP_separators}};

    my $file    = $self->{MBPP_file};
    my $lines   = [];
    my $msgend;

    if(@seps)
    {   
       LINE:
        while(1)
        {   my $where = $file->getpos;
            my $line  = $file->getline
                or last LINE;

            foreach my $sep (@seps)
            {   next if substr($line, 0, length $sep) ne $sep;

                # Some apps fail to escape lines starting with From
                next if $sep eq 'From ' && $line !~ m/ 19[789][0-9]| 20[0-9][0-9]/;

                $file->setpos($where);
                $msgend = $file->tell;
                last LINE;
            }

            push @$lines, $line;
        }

        if(@$lines && $lines->[-1] =~ s/(\r?\n)\z//)
        {   pop @$lines if length($lines->[-1])==0;
        }
    }
    else # File without separators.
    {   $lines = ref $file eq 'Mail::Box::FastScalar'
               ? $file->getlines : [ $file->getlines ];
    }

    my $bodyend = $file->tell;
    if($lines)
    {   if($self->{MBPP_strip_gt})
        {   s/^\>(\>*From\s)/$1/ for @$lines;
        }
        unless($self->{MBPP_trusted})
        {   s/\015$// for @$lines;
            # input is read as binary stream (i.e. preserving CRLF on Windows).
            # Code is based on this assumption. Removal of CR if not trusted
            # conflicts with this assumption. [Markus Spann]
        }
    }
#warn "($bodyend, $msgend, ".@$lines, ")\n";

    ($bodyend, $lines, $msgend);
}

sub _take_scalar($$)
{   my ($self, $begin, $end) = @_;
    my $file = $self->{MBPP_file};
    $file->seek($begin, 0);

    my $return;
    $file->read($return, $end-$begin);
    $return =~ s/\015//g;
    $return;
}

sub bodyAsString(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    my $file  = $self->{MBPP_file};
    my $begin = $file->tell;

    if(defined $exp_chars && $exp_chars>=0)
    {   # Get at once may be successful
        my $end = $begin + $exp_chars;

        if($self->_is_good_end($end))
        {   my $body = $self->_take_scalar($begin, $end);
            $body =~ s/^\>(\>*From\s)/$1/gm if $self->{MBPP_strip_gt};
            return ($begin, $file->tell, $body);
        }
    }

    my ($end, $lines) = $self->_read_stripped_lines($exp_chars, $exp_lines);
    return ($begin, $end, join('', @$lines));
}

sub bodyAsList(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    my $file  = $self->{MBPP_file};
    my $begin = $file->tell;

    my ($end, $lines) = $self->_read_stripped_lines($exp_chars, $exp_lines);
    ($begin, $end, $lines);
}

sub bodyAsFile($;$$)
{   my ($self, $out, $exp_chars, $exp_lines) = @_;
    my $file  = $self->{MBPP_file};
    my $begin = $file->tell;

    my ($end, $lines) = $self->_read_stripped_lines($exp_chars, $exp_lines);

    $out->print($_) foreach @$lines;
    ($begin, $end, scalar @$lines);
}

sub bodyDelayed(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    my $file  = $self->{MBPP_file};
    my $begin = $file->tell;

    if(defined $exp_chars)
    {   my $end = $begin + $exp_chars;

        if($self->_is_good_end($end))
        {   $file->seek($end, 0);
            return ($begin, $end, $exp_chars, $exp_lines);
        }
    }

    my ($end, $lines) = $self->_read_stripped_lines($exp_chars, $exp_lines);
    my $chars = sum(map {length} @$lines);
    ($begin, $end, $chars, scalar @$lines);
}

sub openFile($)
{   my ($self, $args) = @_;
    my $mode = $args->{mode} or die "mode required";
    my $fh = $args->{file} || IO::File->new($args->{filename}, $mode);

    return unless $fh;
    $self->{MBPP_file}       = $fh;

    $fh->binmode(':raw')
        if $fh->can('binmode') || $fh->can('BINMODE');

    $self->{MBPP_separators} = [];

#   binmode $fh, ':crlf' if $] < 5.007;  # problem with perlIO
    $self;
}

sub closeFile()
{   my $self = shift;

    delete $self->{MBPP_separators};
    delete $self->{MBPP_strip_gt};

    my $file = delete $self->{MBPP_file} or return;
    $file->close;
    $self;
}

#------------------------------------------


sub fixHeaderErrors(;$)
{   my $self = shift;
    @_ ? ($self->{MBPP_fix} = shift) : $self->{MBPP_fix};
}

#------------------------------------------

1;
