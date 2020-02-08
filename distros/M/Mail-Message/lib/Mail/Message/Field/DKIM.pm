# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::DKIM;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field::Structured';

use warnings;
use strict;

use URI;


sub init($)
{   my ($self, $args) = @_;
    $self->{MMFD_tags} = { v => 1, a => 'rsa-sha256' };
    $self->SUPER::init($args);
}

sub parse($)
{   my ($self, $string) = @_;

    my $tags = $self->{MMFD_tags};

    foreach (split /\;/, $string)
    {   m/^\s*([a-z][a-z0-9_]*)\s*\=\s*([\s\x21-\x7E]+?)\s*$/is or next;
        # tag-values stay unparsed (for now)
        $self->addTag($1, $2);
    }

    (undef, $string) = $self->consumeComment($string);

	$self;
}

sub produceBody()
{   my $self = shift;
}

#------------------------------------------



sub addAttribute($;@)
{   my $self = shift;
    $self->log(ERROR => 'No attributes for DKIM headers.');
    $self;
}


sub addTag($$)
{   my ($self, $name) = (shift, lc shift);
    $self->{MMFD_tags}{$name} = join ' ', @_;
    $self;
}


sub tag($) { $_[0]->{MMFD_tags}{lc $_[1]} }


#------------------------------------------

sub tagAlgorithm() { shift->tag('a')  }
sub tagSignData()  { shift->tag('b')  }
sub tagSignature() { shift->tag('bh') }
sub tagC14N()      { shift->tag('c')  }
sub tagDomain()    { shift->tag('d')  }
sub tagSignedHeaders() { shift->tag('h') }
sub tagAgentID()   { shift->tag('i') }
sub tagBodyLength(){ shift->tag('l') }
sub tagQueryMethods()  { shift->tag('q') }
sub tagSelector()  { shift->tag('s') }
sub tagTimestamp() { shift->tag('t') }
sub tagExpires()   { shift->tag('x') }
sub tagVersion()   { shift->tag('v') }
sub tagExtract()   { shift->tag('z') }

#------------------------------------------


1;
