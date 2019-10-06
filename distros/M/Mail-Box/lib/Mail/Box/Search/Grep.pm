# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Search::Grep;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Search';

use strict;
use warnings;

use Carp;

#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;

    $args->{in} ||= ($args->{field} ? 'HEAD' : 'BODY');

    my $deliver = $args->{deliver} || $args->{details};  # details is old name
    $args->{deliver}
     = !defined $deliver       ? $deliver
     : ref $deliver eq 'CODE'  ? $deliver
     : $deliver eq 'PRINT'     ? sub { $_[0]->printMatch($_[1]) }
     : ref $deliver eq 'ARRAY' ? sub { push @$deliver, $_[1] }
     :                           $deliver;

    $self->SUPER::init($args);

    my $take = $args->{field};
    $self->{MBSG_field_check}
     = !defined $take         ? sub {1}
     : !ref $take             ? do {$take = lc $take; sub { $_[1] eq $take }}
     :  ref $take eq 'Regexp' ? sub { $_[1] =~ $take }
     :  ref $take eq 'CODE'   ? $take
     : croak "Illegal field selector $take.";

    my $match = $args->{match}
       or croak "No match pattern specified.\n";
    $self->{MBSG_match_check}
     = !ref $match             ? sub { index("$_[1]", $match) >= $[ }
     :  ref $match eq 'Regexp' ? sub { "$_[1]" =~ $match } 
     :  ref $match eq 'CODE'   ? $match
     : croak "Illegal match pattern $match.";

    $self;
}

sub search(@)
{   my ($self, $object, %args) = @_;
    delete $self->{MBSG_last_printed};
    $self->SUPER::search($object, %args);
}

sub inHead(@)
{   my ($self, $part, $head, $args) = @_;

    my @details = (message => $part->toplevel, part => $part);
    my ($field_check, $match_check, $deliver)
      = @$self{ qw/MBSG_field_check MBSG_match_check MBS_deliver/ };

    my $matched = 0;
  LINES:
    foreach my $field ($head->orderedFields)
    {   next unless $field_check->($head, $field->name)
                 && $match_check->($head, $field);

        $matched++;
        last LINES unless $deliver;  # no deliver: only one match needed
        $deliver->( {@details, field => $field} );
    }

    $matched;
}

sub inBody(@)
{   my ($self, $part, $body, $args) = @_;

    my @details = (message => $part->toplevel, part => $part);
    my ($field_check, $match_check, $deliver)
      = @$self{ qw/MBSG_field_check MBSG_match_check MBS_deliver/ };

    my $matched = 0;
    my $linenr  = 0;

  LINES:
    foreach my $line ($body->lines)
    {   $linenr++;
        next unless $match_check->($body, $line);

        $matched++;
        last LINES unless $deliver;  # no deliver: only one match needed
        $deliver->( {@details, linenr => $linenr, line => $line} );
    }

    $matched;
}

#-------------------------------------------


sub printMatch($;$)
{   my $self = shift;
    my ($out, $match) = @_==2 ? @_ : (select, shift);

      $match->{field}
    ? $self->printMatchedHead($out, $match)
    : $self->printMatchedBody($out, $match)
}


sub printMatchedHead($$)
{   my ($self, $out, $match) = @_;
    my $message = $match->{message};
    my $msgnr   = $message->seqnr;
    my $folder  = $message->folder->name;
    my $lp      = $self->{MBSG_last_printed} || '';

    unless($lp eq "$folder $msgnr")  # match in new message
    {   my $subject = $message->subject;
        $out->print("$folder, message $msgnr: $subject\n");
        $self->{MBSG_last_printed} = "$folder $msgnr";
    }

    my @lines   = $match->{field}->string;
    my $inpart  = $match->{part}->isPart ? 'p ' : '  ';
    $out->print($inpart, join $inpart, @lines);
    $self;
}


sub printMatchedBody($$)
{   my ($self, $out, $match) = @_;
    my $message = $match->{message};
    my $msgnr   = $message->seqnr;
    my $folder  = $message->folder->name;
    my $lp      = $self->{MBSG_last_printed} || '';

    unless($lp eq "$folder $msgnr")  # match in new message
    {   my $subject = $message->subject;
        $out->print("$folder, message $msgnr: $subject\n");
        $self->{MBSG_last_printed} = "$folder $msgnr";
    }

    my $inpart  = $match->{part}->isPart ? 'p ' : '  ';
    $out->print(sprintf "$inpart %2d: %s", $match->{linenr}, $match->{line});
    $self;
}

1;
