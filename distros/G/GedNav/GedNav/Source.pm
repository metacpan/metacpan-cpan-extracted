package GedNav::Source;

use GedNav::Family;
use GedNav::Event;

sub new
{
   my $type = shift;
   $type = ref $type if ref $type;
   my $parent = shift;
   my $code = uc(shift);

   my $newobj = {
	code => $code,
	parent => $parent,
	};

   warn "New source: code is $code\n";

   return bless $newobj, $type;
}

sub parent
{
   my $self = shift;
   return $self->{'parent'};
}

sub gedcom
{
   my $self = shift;
   return $self->parent->gedcom;
}

sub dataset
{
   my $self = shift;
   return $self->gedcom->dataset;
}

sub raw
{
   my $self = shift;
   my $attrname = 'raw';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = $self->gedcom->_get_paragraph("sour:" . $self->code);
   }

   return $self->{$attrname};
}

sub code
{
   my $self = shift;
   return $self->{'code'};
}

sub private
{
   my $self = shift;
   my $attrname = 'private';

   if (@_)
   {
      $self->{$attrname} = shift;
   }

   return 1 if $self->gedcom->private;
   return $self->{$attrname};
}

sub title
{
   my $self = shift;

   unless (exists $self->{'title'})
   {
      my @matches = grep { /^\d+\s+titl/i } @{$self->raw};
      if (@matches)
      {
         ($self->{'titl'}) = ($matches[0] =~ /^\d+\s+titl\s+(.*)\s*$/i);
      }
   }

   return $self->{'titl'};
}

###

1;

