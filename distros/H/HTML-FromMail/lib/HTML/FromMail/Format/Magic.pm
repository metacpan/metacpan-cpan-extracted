# Copyrights 2003-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML-FromMail.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package HTML::FromMail::Format::Magic;
use vars '$VERSION';
$VERSION = '0.12';

use base 'HTML::FromMail::Format';

use strict;
use warnings;

use Carp;

BEGIN
{   eval { require Template::Magic };
    die "Install Bundle::Template::Magic for this formatter\n"
       if $@;
}


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;

    $self;
}

sub export($@)
{   my ($self, %args) = @_;

    my $magic = $self->{HFFM_magic}
      = Template::Magic->new
         ( markers       => 'HTML'
         , zone_handlers => sub { $self->lookupTemplate(\%args, @_) }
         );

   $self->log(ERROR => "Cannot write to $args{output}: $!"), return
      unless open my($out), ">", $args{output};

   my $oldout = select $out;
   $magic->print($args{input});
   select $oldout;

   close $out;
   $self;
}



sub magic() { shift->{HFFM_magic} }


sub lookupTemplate($$)
{   my ($self, $args, $zone) = @_;

    # Lookup the method to be called.
    my $method = 'html' . ucfirst($zone->id);
    my $prod   = $args->{producer};
    return undef unless $prod->can($method);

    # Split zone attributes into hash.  Added to %$args.
    my $param = $zone->attributes || '';
    $param =~ s/^\s+//;
    $param =~ s/\s+$//;

    my %args  = (%$args, zone => $zone);
    if(length $param)
    {   foreach my $pair (split /\s*\,\s*/, $param)
        {   my ($k, $v) = split /\s*\=\>\s*/, $pair, 2;
            $args{$k} = $v;
        }
    }

    my $value = $prod->$method($args{object}, \%args);
    $zone->value = $value if defined $value;
}

our $msg_zone;  # hack
sub containerText($)
{   my ($self, $args) = @_;
    my $zone = $args->{zone};
    $msg_zone = $zone if $zone->id eq 'message';  # hack
    $zone->content;
}

sub processText($$)
{   my ($self, $text, $args) = @_;
    my $zone = $args->{zone};

    # this hack is needed to get things to work :(
    # but this will not work in the future.
    $zone->_s = $msg_zone->_s;
    $zone->_e = $msg_zone->_e;
    $zone->merge;
}

sub lookup($$)
{   my ($self, $what, $args) = @_;
    my $zone  = $args->{zone} or confess;
    $zone->lookup($what);
}

sub onFinalToken($)
{   my ($self, $args) = @_;
    my $zone = $args->{zone} or confess;
    ! defined $zone->content;
}

1;
