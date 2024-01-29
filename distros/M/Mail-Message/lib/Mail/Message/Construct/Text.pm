# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message;
use vars '$VERSION';
$VERSION = '3.015';


use strict;
use warnings;

use IO::Lines;


sub string()
{   my $self = shift;
    $self->head->string . $self->body->string;
}

#------------------------------------------


sub lines()
{   my $self = shift;
    my @lines;
    my $file = IO::Lines->new(\@lines);
    $self->print($file);
    wantarray ? @lines : \@lines;
}

#------------------------------------------


sub file()
{   my $self = shift;
    my @lines;
    my $file = IO::Lines->new(\@lines);
    $self->print($file);
    $file->seek(0,0);
    $file;
}


sub printStructure(;$$)
{   my $self    = shift;

    my $indent
      = @_==2                       ? pop
      : defined $_[0] && !ref $_[0] ? shift
      :                               '';

    my $fh      = @_ ? shift : select;

    my $buffer;   # only filled if filehandle==undef
    open $fh, '>:raw', \$buffer unless defined $fh;

    my $subject = $self->get('Subject') || '';
    $subject    = ": $subject" if length $subject;

    my $type    = $self->get('Content-Type', 0) || '';
    my $size    = $self->size;
    my $deleted = $self->label('deleted') ? ', deleted' : '';

    my $text    = "$indent$type$subject ($size bytes$deleted)\n";
    ref $fh eq 'GLOB' ? (print $fh $text) : $fh->print($text);

    my $body    = $self->body;
    my @parts
      = $body->isNested    ? ($body->nested)
      : $body->isMultipart ? $body->parts
      :                      ();

    $_->printStructure($fh, $indent.'   ')
        for @parts;

    $buffer;
}
    

1;
