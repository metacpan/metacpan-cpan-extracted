package GedNav::Event;

use strict;

use Date::Manip;

use GedNav::Source;

sub new
{
   my $type = shift;
   $type = ref $type if ref $type;

   my $event_type = uc(shift);
   my $parent = shift;

   my @paragraph = @{$parent->raw};	# copy so we can play with it

   while ( @paragraph && ($paragraph[0] !~ /1 $event_type/i) )
   {
      shift @paragraph;
   }

   my $top = $paragraph[0] =~ /^(\d+)/;
   shift @paragraph;

   my $newobj = {
	type => $event_type,
	parent => $parent,
	};

   my @raw;

   my ($indent) = $paragraph[0] =~ /^(\d+)/;
   while ( @paragraph && ($indent > $top) )
   {
      push @raw, $paragraph[0];

      if ($paragraph[0] =~ /^\d+\s+date\s+/i)
      {
         ($newobj->{'date'}) = $paragraph[0] =~ /^\d+\s+date\s+(.*)$/i;
      }
      elsif ($paragraph[0] =~ /^\d+\s+plac\s+/i)
      {
         ($newobj->{'place'}) = $paragraph[0] =~ /^\d+\s+plac\s+(.*)$/i;
      }

      shift @paragraph;
      ($indent) = $paragraph[0] =~ /^(\d+)/;
   }

   return undef unless ($newobj->{'date'} || $newobj->{'place'});

   $newobj->{'raw'} = \@raw;

   return bless $newobj, $type;
}

sub type
{
   my $self = shift;
   return $self->{'type'};
}

sub parent
{
   my $self = shift;
   return $self->{'parent'};
}

sub raw
{
   my $self = shift;
   return $self->{'raw'};
}

sub gedcom
{
   my $self = shift;
   return $self->parent->gedcom;
}

sub date
{
   my $self = shift;
   return $self->{'date'};
}

sub date_formatted
{
   my $self = shift;
   my $format = shift;

   my $date = $self->date;

   if ($date =~ /private/i)
   {
      $date = '';
   }
   elsif ($date =~ /wft/i)
   {
      $date =~ s/.*(\d{4}\s*-\s*\d{4})/Abt $1/;
   }
   else
   {
      my $prefix = '';

      if ($date =~ /(abt|est)/i)
      {
         $prefix = 'About ';
         $date =~ s/(abt|est)\.?//i;
      }

      if ($date =~ /aft/i)
      {
         $prefix = 'After ';
         $date =~ s/aft\.?//i;
      }

      if ($date =~ /bef/i)
      {
         $prefix = 'Before ';
         $date =~ s/bef\.?//i;
      }

      $date =~ s/^ +//g;
      $date =~ s/ +$//g;

      if ($date =~ /^\d{1,2} \w{3} \d{4}$/i)
      {
         $date = UnixDate($date, $format || "%e %b %Y");
      }
      elsif ($date =~ /\d{4}$/)
      {
         $date =~ s/^.*(\d{4})$/$1/;
      }

      $date = $prefix . $date;
   }

   return $date;
}

sub year
{
   my $self = shift;

   my ($year) = $self->date =~ /(\d{4})/;

   return $year;
}

sub place
{
   my $self = shift;
   return $self->{'place'};
}

sub date_in_place
{
   my $self = shift;

   my $string;

   if ($self->date && $self->place)
   {
      $string = sprintf("%s in %s", $self->date_formatted, $self->place);
   }
   elsif ($self->date)
   {
      $string = $self->date_formatted;
   }
   elsif ($self->place)
   {
      $string = sprintf("in %s", $self->place);
   }

   return $string; 
}

sub on_date_in_place
{
   my $self = shift;

   my $string;

   if ($self->date && $self->place)
   {
      if ($self->date_formatted =~ /^\d+$/)
      {
         $string = "in " . $self->date_in_place;
      }
      else
      {
         $string = "on " . $self->date_in_place;
      }
   }
   elsif ($self->date)
   {
      if ($self->date_formatted =~ /^\d+$/)
      {
         $string = "in " . $self->date_formatted;
      }
      else
      {
         $string = "on " . $self->date_formatted;
      }
   }
   elsif ($self->place)
   {
      $string = "in " . $self->place;
   }

   return $string; 
}

sub sources
{
   my $self = shift;
   my $attrname = 'sour';

   unless (exists $self->{$attrname})
   {
      my @matches =
        map { new GedNav::Source($self, $_) }
        map { /^2\s+sour\s+@(.*)@/i }
        grep { /^2\s+sour/i }
        @{$self->raw};

      $self->{$attrname} = \@matches;
   }

   return @{$self->{$attrname}} if wantarray;
   return $self->{$attrname};
}

###

1;

