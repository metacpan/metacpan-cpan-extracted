# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Addresses;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field::Structured';

use strict;
use warnings;

use Mail::Message::Field::AddrGroup;
use Mail::Message::Field::Address;
use List::Util 'first';


#------------------------------------------
# what is permitted for each field.

my $address_list = {groups => 1, multi => 1};
my $mailbox_list = {multi => 1};
my $mailbox      = {};

my %accepted     =    # defaults to $address_list
  ( from       => $mailbox_list
  , sender     => $mailbox
  );

sub init($)
{   my ($self, $args) = @_;

    $self->{MMFF_groups}   = [];

    ( my $def = lc $args->{name} ) =~ s/^resent\-//;
    $self->{MMFF_defaults} = $accepted{$def} || $address_list;

    my ($body, @body);
    if($body = $args->{body})
    {   @body = ref $body eq 'ARRAY' ? @$body : ($body);
        return () unless @body;
    }

    if(@body > 1 || ref $body[0])
    {   $self->addAddress($_) foreach @body;
        delete $args->{body};
    }

    $self->SUPER::init($args) or return;
    $self;
}

#------------------------------------------


sub addAddress(@)
{   my $self  = shift;
    my $email = @_ && ref $_[0] ? shift : undef;
    my %args  = @_;
    my $group = delete $args{group} || '';

    $email = Mail::Message::Field::Address->new(%args)
        unless defined $email;

    my $set = $self->group($group) || $self->addGroup(name => $group);
    $set->addAddress($email);
    $email;
}


sub addGroup(@)
{   my $self  = shift;
    my $group = @_ == 1 ? shift
              : Mail::Message::Field::AddrGroup->new(@_);

    push @{$self->{MMFF_groups}}, $group;
    $group;
}


sub group($)
{   my ($self, $name) = @_;
    $name = '' unless defined $name;
    first { lc($_->name) eq lc($name) } $self->groups;
}


sub groups() { @{shift->{MMFF_groups}} }


sub groupNames() { map {$_->name} shift->groups }


sub addresses() { map {$_->addresses} shift->groups }


sub addAttribute($;@)
{   my $self = shift;
    $self->log(ERROR => 'No attributes for address fields.');
    $self;
}

#------------------------------------------


sub parse($)
{   my ($self, $string) = @_;
    my ($group, $email) = ('', undef);
    $string =~ s/\s+/ /gs;

    while(1)
    {   (my $comment, $string) = $self->consumeComment($string);

        if($string =~ s/^\s*\;//s ) { $group = ''; next }  # end group
        if($string =~ s/^\s*\,//s ) { next }               # end address

        (my $email, $string) = $self->consumeAddress($string);
        if(defined $email)
        {   # Pattern starts with e-mail address
            ($comment, $string) = $self->consumeComment($string);
            $email->comment($comment) if defined $comment;
        }
        else
        {   # Pattern not plain address
            my $real_phrase = $string =~ m/^\s*\"/;
            (my $phrase, $string) = $self->consumePhrase($string);

            if(defined $phrase)
            {   ($comment, $string) = $self->consumeComment($string);

                if($string =~ s/^\s*\://s )
                {   $group = $phrase;
                    # even empty groups must appear
                    $self->addGroup(name=>$group) unless $self->group($group);
                    next;
                }
            }

            my $angle;
            if($string =~ s/^\s*\<([^>]*)\>//s) { $angle = $1 }
            elsif($real_phrase)
            {   $self->log(ERROR => "Ignore unrelated phrase `$1'")
                    if $string =~ s/^\s*\"(.*?)\r?\n//;
                next;
            }
            elsif(defined $phrase)
            {   ($angle = $phrase) =~ s/\s+/./g;
                undef $phrase;
            }

            ($comment, $string) = $self->consumeComment($string);

            # remove obsoleted route info.
            return 1 unless defined $angle;
            $angle =~ s/^\@.*?\://;

            ($email, $angle) = $self->consumeAddress($angle
              , phrase => $phrase, comment => $comment);
        }

        $self->addAddress($email, group => $group) if defined $email;
        return 1 if $string =~ m/^\s*$/s;
   }

   $self->log(WARNING => 'Illegal part in address field '.$self->Name.
        ": $string\n");

   0;
}

sub produceBody()
{  my @groups = sort {$a->name cmp $b->name} shift->groups;

   @groups     or return '';
   @groups > 1 or return $groups[0]->string;

   my $plain
    = $groups[0]->name eq '' && $groups[0]->addresses
    ? (shift @groups)->string.','
    : '';

   join ' ', $plain, map({$_->string} @groups);
}


sub consumeAddress($@)
{   my ($self, $string, @options) = @_;

    my ($local, $shorter, $loccomment) = $self->consumeDotAtom($string);
    $local =~ s/\s//g if defined $local;

    return (undef, $string)
        unless defined $local && $shorter =~ s/^\s*\@//;
  
    (my $domain, $shorter, my $domcomment) = $self->consumeDomain($shorter);
    return (undef, $string) unless defined $domain;

    # loccomment and domcomment ignored
    my $email   = Mail::Message::Field::Address
        ->new(username => $local, domain => $domain, @options);

    ($email, $shorter);
}


sub consumeDomain($)
{   my ($self, $string) = @_;

    return ($self->stripCFWS($1), $string)
        if $string =~ s/\s*(\[(?:[^[]\\]*|\\.)*\])//;

    my ($atom, $rest, $comment) = $self->consumeDotAtom($string);
    $atom =~ s/\s//g if defined $atom;
    ($atom, $rest, $comment);
}

#------------------------------------------


1;
