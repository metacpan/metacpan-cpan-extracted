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

use Mail::Message::Head::Complete;
use Mail::Message::Body::Lines;
use Mail::Message::Body::Multipart;

use Mail::Address;
use Scalar::Util    'blessed';
use List::Util      'first';
use Mail::Box::FastScalar;


my @default_rules =
  qw/replaceDeletedParts descendMultiparts descendNested
     flattenMultiparts flattenEmptyMultiparts/;

sub rebuild(@)
{   my ($self, %args) = @_;
    my $keep  = delete $args{keep_message_id};

    # Collect the rules to be run
    my @rules = $args{rules} ? @{delete $args{rules}} : @default_rules;
    unshift @rules, @{delete $args{extra_rules}} if $args{extra_rules};
    unshift @rules, @{delete $args{extraRules}}  if $args{extraRules}; #old name

    foreach my $rule (@rules)
    {   next if ref $rule;
        unless($self->can($rule))
        {   $self->log(ERROR => "No rebuild rule '$rule' defined.\n");
            return 1;
        }
    }

    # Start off with the message

    my $rebuild = $self->recursiveRebuildPart($self, %args, rules => \@rules)
        or return;

    # Be sure we end-up with a message

    if($rebuild->isa('Mail::Message::Part'))
    {   # a bit too much information is lost: we are left without the
        # main message headers....
        my $clone = Mail::Message->new(head => $self->head->clone);
        $clone->body($rebuild->body);  # to update the Content lines
        $rebuild = $clone;
    }

    $keep or $rebuild->takeMessageId;
    $rebuild;
}

#------------------------------------------
# The general rules

sub flattenNesting($@)
{   my ($self, $part) = @_;
    $part->isNested ? $part->body->nested : $part;
}

sub flattenMultiparts($@)
{   my ($self, $part) = @_;
    return $part unless $part->isMultipart;
    my @active = $part->parts('ACTIVE');
    @active==1 ? $active[0] : $part;
}

sub removeEmptyMultiparts($@)
{   my ($self, $part) = @_;
    $part->isMultipart && $part->body->parts==0 ? undef : $part;
}

sub flattenEmptyMultiparts($@)
{   my ($self, $part) = @_;

    $part->isMultipart && $part->parts('ACTIVE')==0
        or return $part;

    my $body     = $part->body;
    my $preamble = $body->preamble || Mail::Message::Body::Lines->new(data=>'');
    my $epilogue = $body->epilogue;
    my $newbody  = $preamble->concatenate($preamble, <<NO_PARTS, $epilogue);
  * PLEASE NOTE:
  * This multipart did not contain any parts (anymore)
  * and was therefore flattened.

NO_PARTS

    my $rebuild  = Mail::Message::Part->new
      ( head      => $part->head->clone
      , container => undef
      );
    $rebuild->body($newbody);
    $rebuild;
}

sub removeEmptyBodies($@)
{   my ($self, $part) = @_;
    $part->body->lines==0 ? undef : $part;
}

sub descendMultiparts($@)
{   my ($self, $part, %args) = @_;
    return $part unless $part->isMultipart;

    my $body    = $part->body;
    my $changed = 0;
    my @newparts;

    foreach my $part ($body->parts)
    {   my $new = $self->recursiveRebuildPart($part, %args);
        if(!defined $new)  { $changed++ }
	elsif($new==$part) { push @newparts, $part }
	else               { push @newparts, $new; $changed++ }
    }

    $changed or return $part;

    my $newbody = ref($body)->new
      ( based_on  => $body
      , parts     => \@newparts
      );

    my $rebuild = ref($part)->new
      ( head      => $part->head->clone
      , container => undef
      );

    $rebuild->body($newbody);   # update Content-* lines
    $rebuild;
}

sub descendNested($@)
{   my ($self, $part, %args) = @_;
    $part->isNested or return $part;

    my $body      = $part->body;
    my $srcnested = $body->nested;
    my $newnested = $self->recursiveRebuildPart($srcnested, %args);

    defined $newnested or return undef;
    return $part if $newnested==$srcnested;

    # Changes in the encapsulated message
    my $newbody = ref($body)->new(based_on => $body, nested => $newnested);
    my $rebuild = ref($part)->new(head => $part->head->clone
      , container => undef);

    $rebuild->body($newbody);
    $rebuild;
}

sub removeDeletedParts($@)
{   my ($self, $part) = @_;
    $part->isDeleted ? undef : $part;
}

sub replaceDeletedParts($@)
{   my ($self, $part) = @_;

    ($part->isNested && $part->body->nested->isDeleted) || $part->isDeleted
        or return $part;

    my $structure = '';
    my $output    = Mail::Box::FastScalar->new(\$structure, '  ');
    $part->printStructure($output);

    my $dispfn   = $part->body->dispositionFilename || '';
    Mail::Message::Part->build
      ( data => "Removed content:\n\n$structure\n$dispfn"
      );
}

#------------------------------------------
# The more complex rules

sub removeHtmlAlternativeToText($@)
{   my ($self, $part) = @_;
    $part->body->mimeType eq 'text/html'
        or return $part;

    my $container = $part->container;

    return $part
        unless defined $container
            && $container->mimeType eq 'multipart/alternative';

    # The HTML $part will be nulled when a plain text part is found
    foreach my $subpart ($container->parts)
    {   return undef if $subpart->body->mimeType eq 'text/plain';
    }

    $part;
}

sub removeExtraAlternativeText($@)
{   my ($self, $part) = @_;

    my $container = $part->container;
    $container && $container->mimeType eq 'multipart/alternative'
        or return $part;

    # The last part is the preferred part (as per RFC2046)
    my $last = ($container->parts)[-1];
    $last && $part==$last ? $part : undef;
}

my $has_hft;
sub textAlternativeForHtml($@)
{   my ($self, $part, %args) = @_;

    my $hft = 'Mail::Message::Convert::HtmlFormatText';
    unless(defined $has_hft)
    {   eval "require $hft";
        $has_hft = $hft->can('format');
    }

    return $part
        unless $has_hft && $part->body->mimeType eq 'text/html';

    my $container = $part->container;
    my $in_alt    = defined $container
                    && $container->mimeType eq 'multipart/alternative';

    return $part
        if $in_alt
        && first { $_->body->mimeType eq 'text/plain' } $container->parts;


    # Create the plain part

    my $html_body  = $part->body;
    my $plain_body = $hft->new(%args)->format($html_body);

    my $plain_part = Mail::Message::Part->new(container => undef);
    $plain_part->body($plain_body);

    return $container->attach($plain_part)
       if $in_alt;

    # Recreate the html part to loose some header lines

    my $html_part = Mail::Message::Part->new(container => undef);
    $html_part->body($html_body);

    # Create the new part, with the headers of the html part

    my $mp = Mail::Message::Body::Multipart->new
     ( mime_type => 'multipart/alternative'
     , parts     => [ $plain_part, $html_part ]
     );

    my $newpart  = ref($part)->new
     ( head      => $part->head->clone   # Subject field, and such
     , container => undef
     );
    $newpart->body($mp);
    $newpart;
}

#------------------------------------------


sub recursiveRebuildPart($@)
{   my ($self, $part, %args) = @_;

  RULES:
    foreach my $rule (@{$args{rules}})
    {   my %params  = ( %args, %{$args{$rule} || {}} );
        my $rebuild = $self->$rule($part, %params)
            or return undef;

        if($part != $rebuild)
        {   $part = $rebuild;
            redo RULES;
        }
    }

    $part;
}

#------------------------------------------



1;
