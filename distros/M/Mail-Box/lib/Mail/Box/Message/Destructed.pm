# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Message::Destructed;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Message';

use strict;
use warnings;

use Carp;


sub new(@)
{   my $class = shift;
    $class->log(ERROR => 'You cannot instantiate a destructed message');
    undef;
}
 
sub isDummy()    { 1 }


sub head(;$)
{    my $self = shift;
     return undef if @_ && !defined(shift);

     $self->log(ERROR => "You cannot take the head of a destructed message");
     undef;
}


sub body(;$)
{    my $self = shift;
     return undef if @_ && !defined(shift);

     $self->log(ERROR => "You cannot take the body of a destructed message");
     undef;
}


sub coerce($)
{  my ($class, $message) = @_;

   unless($message->isa('Mail::Box::Message'))
   {  $class->log(ERROR=>"Cannot coerce a ",ref($message), " into destruction");
      return ();
   }

   $message->body(undef);
   $message->head(undef);
   $message->modified(0);

   bless $message, $class;
}

sub modified(;$)
{  my $self = shift;

   $self->log(ERROR => 'Do not set the modified flag on a destructed message')
      if @_ && $_[0];

   0;
}

sub isModified() { 0 }


sub label($;@)
{  my $self = shift;

   if(@_==1)
   {   my $label = shift;
       return $self->SUPER::label('deleted') if $label eq 'deleted';
       $self->log(ERROR => "Destructed message has no labels except 'deleted', requested is $label");
       return 0;
   }

   my %flags = @_;
   unless(keys %flags==1 && exists $flags{deleted})
   {   $self->log(ERROR => "Destructed message has no labels except 'deleted', trying to set @{[ keys %flags ]}");
       return;
   }

   $self->log(ERROR => "Destructed messages can not be undeleted")
      unless $flags{deleted};

   1;
}

sub labels() { wantarray ? ('deleted') : +{deleted => 1} }

1;
