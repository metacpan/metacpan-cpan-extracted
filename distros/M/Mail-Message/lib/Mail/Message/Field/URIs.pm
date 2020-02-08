# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::URIs;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field::Structured';

use warnings;
use strict;

use URI;



sub init($)
{   my ($self, $args) = @_;

    my ($body, @body);
    if($body = delete $args->{body})
    {   @body = ref $body eq 'ARRAY' ? @$body : ($body);
        return () unless @body;
    }

    $self->{MMFU_uris} = [];

    if(@body > 1 || ref $body[0])
    {   $self->addURI($_) foreach @body;
    }
    elsif(defined $body)
    {   $body = "<$body>\n" unless index($body, '<') >= 0;
        $args->{body} = $body;
    }

    $self->SUPER::init($args);
}

sub parse($)
{   my ($self, $string) = @_;
    my @raw = $string =~ m/\<([^>]+)\>/g;  # simply ignore all but <>
    $self->addURI($_) foreach @raw;
    $self;
}

sub produceBody()
{  my @uris = sort map { $_->as_string } shift->URIs;
   local $" = '>, <';
   @uris ? "<@uris>" : undef;
}

#------------------------------------------


sub addURI(@)
{   my $self  = shift;
    my $uri   = ref $_[0] ? shift : URI->new(@_);
    push @{$self->{MMFU_uris}}, $uri->canonical if defined $uri;
    delete $self->{MMFF_body};
    $uri;
}


sub URIs() { @{shift->{MMFU_uris}} }


sub addAttribute($;@)
{   my $self = shift;
    $self->log(ERROR => 'No attributes for URI fields.');
    $self;
}

#------------------------------------------


1;
