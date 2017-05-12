package GedNav::Family;

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

sub raw
{
   my $self = shift;
   my $attrname = 'raw';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = $self->gedcom->_get_paragraph("fam:" . $self->code)
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

sub marriage
{
   my $self = shift;
   my $attrname = 'marriage';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = GedNav::Event->new('marr', $self);
   }

   return $self->{$attrname}
}

sub husb
{
   my $self = shift;
   my $attrname = 'husb';

   unless (exists $self->{$attrname})
   {
      my @matches =
	map { GedNav::Individual->new($self->gedcom, $_) }
	map { /^\d+\s+husb\s@(.*)@/i }
	grep { /^\d+\s+husb/i }
	@{$self->raw};

      $self->{$attrname} = shift @matches;
   }

   return $self->{$attrname};
}

sub wife
{
   my $self = shift;
   my $attrname = 'wife';

   unless (exists $self->{$attrname})
   {
      my @matches =
	map { GedNav::Individual->new($self->gedcom, $_) }
	map { /^\d+\s+wife\s@(.*)@/i }
	grep { /^\d+\s+wife/i }
	@{$self->raw};

      $self->{$attrname} = shift @matches;
   }

   return $self->{$attrname};
}

sub children
{
   my $self = shift;
   my $attrname = 'children';

   unless (exists $self->{$attrname})
   {
      my @matches =
        map { GedNav::Individual->new($self->gedcom, $_) }
        map { /^\d+\s+chil\s@(.*)@/i }
        grep { /^\d+\s+chil/i }
        @{$self->raw};

      $self->{$attrname} = \@matches;
   }

   return @{$self->{$attrname}};
}

###

1;

