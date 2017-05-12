# Copyrights 2003,2004,2007 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.00.

use strict;
use warnings;

package HTML::FromMail::Format::OODoc;
use vars '$VERSION';
$VERSION = '0.11';
use base 'HTML::FromMail::Format';

use Carp;
use OODoc::Template;


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;
    $self;
}

sub export($@)
{   my ($self, %args) = @_;

    my $oodoc  = $self->{HFFM_oodoc} = OODoc::Template->new;

    my $output = $args{output};
    $self->log(ERROR => "Cannot write to $output: $!"), return
       unless open my($out), ">", $output;

    my $input  = $args{input};
    $self->log(ERROR => "Cannot open template file $input: $!"), return
       unless open my($in), "<", $input;

    my $template = join '', <$in>;
    close $in;

    my %defaults =
      ( DYNAMIC => sub { $self->expand(\%args, @_) }
      );

    my $oldout   = select $out;
    $oodoc->parse($template, \%defaults);
    select $oldout;

    close $out;
    $self;
}


sub oodoc() { shift->{HFFM_oodoc} }


sub expand($$$)
{   my ($self, $args, $tag, $attrs, $textref) = @_;

    # Lookup the method to be called.
    my $method = 'html' . ucfirst($tag);
    my $prod   = $args->{producer};

    return undef unless $prod->can($method);

    my %info  = (%$args, %$attrs, textref => $textref);
    $prod->$method($args->{object}, \%info);
}

sub containerText($)
{   my ($self, $args) = @_;
    my $textref = $args->{textref};
    defined $textref ? $$textref : undef;
}

sub processText($$)
{   my ($self, $text, $args) = @_;
    $self->oodoc->parse($text, {});
}

sub lookup($$)
{   my ($self, $what, $args) = @_;
    $self->oodoc->valueFor($what);
}

sub onFinalToken($)
{   my ($self, $args) = @_;
    not (defined $args->{textref} && defined ${$args->{textref}});
}

1;
