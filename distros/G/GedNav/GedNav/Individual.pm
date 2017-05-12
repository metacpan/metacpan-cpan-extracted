package GedNav::Individual;

use File::Basename;

use GedNav::Family;
use GedNav::Event;

sub new
{
   my $type = shift;
   $type = ref $type if ref $type;
   my $gedcom = shift;
   my $code = uc(shift);

   my $newobj = {
	code => $code,
	gedcom => $gedcom,
	};

   return bless $newobj, $type;
}

sub gedcom
{
   my $self = shift;
   return $self->{'gedcom'};
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
      $self->{$attrname} = $self->gedcom->_get_paragraph("indi:" . $self->code);
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

# assuming we're only a child in one family....
sub famc
{
   my $self = shift;
   my $attrname = 'famc';

   unless (exists $self->{$attrname})
   {
      my @matches =
	map { new GedNav::Family($self->gedcom, $_) }
	map { /^1\s+famc\s@(.*)@/i }
	grep { /^1\s+famc/i }
	@{$self->raw};

      warn "More than one famc!" if (@matches > 1);

      $self->{$attrname} = $matches[0];
   }

   return $self->{$attrname};
}

# there can easily be a spouse in more than one family -- returns a list
sub fams
{
   my $self = shift;
   my $attrname = 'fams';

   unless (exists $self->{$attrname})
   {
      my @matches =
	map { new GedNav::Family($self->gedcom, $_) }
	map { /^1\s+fams\s@(.*)@/i }
	grep { /^1\s+fams/i }
	@{$self->raw};

      $self->{$attrname} = \@matches;
   }

   return @{$self->{$attrname}};
}

sub sex
{
   my $self = shift;
   my $attrname = 'sex';

   unless (exists $self->{$attrname})
   {
      my @matches = grep { /^1\s+sex/i } @{$self->raw};
      if (@matches)
      {
         ($self->{$attrname}) = ($matches[0] =~ /^1\s+sex\s+(.*)\s*$/i);
      }
   }

   return $self->{$attrname};
}

sub child_type
{
   my $self = shift;
   return ($self->sex =~ /f/i) ? 'daughter' : 'son';
}

sub name
{
   my $self = shift;

   unless (exists $self->{'name'})
   {
      my @matches = grep { /^\d+\s+name/i } @{$self->raw};
      if (@matches)
      {
         ($self->{'name'}) = ($matches[0] =~ /^\d+\s+name\s+(.*)\s*$/i);
      }
   }

   return $self->{'name'};
}

sub name_html
{
   my $self = shift;
   my $name = $self->name;

   # also make the .* NOT greedy...
   $name =~ s,/(.*)/, <i>$1</i>,g;

   return $name;
}

sub name_html_linked
{
   my $self = shift;

   return sprintf("<a href=\"individual.pl?dataset=%s&indi=%s\">%s</a>",
	basename($self->dataset),
	$self->code,
	$self->name_html,
	);
}

sub name_normal
{
   my $self = shift;
   my $name = $self->name;

   # also make the .* NOT greedy...
   $name =~ s,/(.*)/, $1 ,g;
   $name =~ s, +, ,g;
   $name =~ s,^ *,,g;
   $name =~ s, *$,,g;

   return $name;
}

sub name_reversed
{
   my $self = shift;

   my $name = $self->name;

   $name =~ s!(.*)/(.*)/(.*)!$2, $1 $3!;

   return $name;
}

# just returns 'first' spouse...
sub spouse
{
   my $self = shift;

   my $fam;
   $fam = $self->fams->[0];

   my $spouse;
   if ($fam)
   {
      if ($self->sex =~ /^m$/i)
      {
         $spouse = $fam->wife;
      }
      elsif ($self->sex =~ /^f$/i)
      {
         $spouse = $fam->husb;
      }
   }

   return $spouse;
}

sub surname
{
   my $self = shift;
   my ($surname) = $self->name =~ m,/(.*)/,;
   return $surname;
}

sub birth
{
   my $self = shift;
   my $attrname = 'birth';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = new GedNav::Event('birt', $self);
   }

   return $self->{$attrname}
}

sub death
{
   my $self = shift;
   my $attrname = 'death';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = new GedNav::Event('deat', $self);
   }

   return $self->{$attrname}
}

sub birth_death_years
{
   my $self = shift;

   my $string = '';

   if ($self->birth && $self->death && $self->birth->year && $self->death->year)
   {
      $string = sprintf("%s - %s", $self->birth->year, $self->death->year);
   }
   elsif ($self->birth && $self->birth->year)
   {
      $string = sprintf("%s -", $self->birth->year);
   }
   elsif ($self->death && $self->death->year)
   {
      $string = sprintf("- %s", $self->death->year);
   }

   return $string;
}

sub has_children
{
   my $self = shift;

   my $childcount = 0;

   foreach ($self->fams)
   {
      if ($_->children)
      {
         $childcount += scalar $_->children;
      }
   }

   return $childcount;
}

###

1;

