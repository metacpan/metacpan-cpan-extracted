package GedNav;

use Cwd;
use POSIX qw(ctime);
use File::Basename;
use FileHandle;
use GDBM_File;
use Text::Soundex;

use strict;

use vars qw($VERSION);
$VERSION = '0.03';

use GedNav::Individual;

sub new
{
   my $type = shift;
   $type = ref $type if ref $type;
   my $dataset = shift;

   my $file = new FileHandle;
   $file->open("<$dataset.ged") || die "Can't open gedcom file $dataset.ged: $!";

   my @stat = stat "$dataset.ged";

   my $newobj = {
	dataset => $dataset,
	file => $file,
	private => 1,
	lastmod => $stat[9],
	};

   bless $newobj, $type;

   my $ref_tie = $newobj->build_refindex_somewhere;

   die "Couldn't open/find index file $dataset-refs.gdbm: $!" unless $ref_tie;

   my $si_tie = $newobj->build_surnameindex_somewhere;

   warn "Can't open index file $dataset-surnames.gdbm: $!" unless $si_tie;

   return $newobj;
}

sub private
{
   my $self = shift;
   my $attrname = 'private';

   if (@_)
   {
      $self->{$attrname} = shift;
   }

   return $self->{$attrname};
}

sub dataset
{
   my $self = shift;
   return $self->{'dataset'};
}

sub lastmod
{
   my $self = shift;
   return ctime($self->{'lastmod'});
}

sub get_indi
{
   my $self = shift;
   my $code = shift;

   return new GedNav::Individual($self, $code);
}

sub individuals
{
   my $self = shift;

   my @indis =
	map { new GedNav::Individual($self, $_) }
	grep { s/^indi://i }
	keys %{$self->{'index'}};

   return @indis;
}

sub surnames
{
   my $self = shift;
   my $attrname = 'surnames';

   unless (exists $self->{$attrname})
   {
      $self->{$attrname} = [];

      if (exists $self->{'surnameindex'})
      {
         @{$self->{$attrname}} =
		grep { length($_) > 1 }
		keys %{$self->{'surnameindex'}};
      }
      else
      {
         my %surnames =
		map { $_->surname => 1 }
		grep { length($_->surname) > 1 }
		$self->individuals;

         @{$self->{$attrname}} = keys %surnames;
      }
   }

   return @{$self->{$attrname}};
}

sub families
{
   my $self = shift;

   my @famlies =
	map { $self->{'index'}->{$_} }
	grep { s/^fam://i }
	keys %{$self->{'index'}};

   return @famlies;
}

sub by_surname
{
   my $self = shift;
   my $surname = shift;

   my @indis =
	map { new GedNav::Individual($self, $_) }
	split(/:/, $self->{'surnameindex'}->{uc($surname)})
	;

   return @indis;
}

sub by_soundex
{
   my $self = shift;
   my $soundex = uc(shift);

   my @indis =
	sort { $a->surname cmp $b->surname || $a->name cmp $b->name }
	map { $self->by_surname($_) }
	grep { soundex($_) eq $soundex }
	$self->surnames
	;

   return @indis;
}

sub _get_paragraph
{
   my $self = shift;
   my $key = uc(shift);

   unless (exists $self->{'index'}->{$key})
   {
      warn "Unknown key: $key";
      return undef;
   }

   my $fh = $self->{'file'};

   $self->{'file'}->seek($self->{'index'}->{$key}, 0);

   my @par;

   my $line = <$fh>;
   $line =~ s/[\r\n]+$//g;
   push @par, $line;

   while (defined ($line = <$fh>) && $line !~ /^0\s/)
   {
      $line =~ s/[\r\n]+$//g;
      push @par, $line;
   }

   return \@par;
}

my @trydirs = qw(. /tmp);

sub build_refindex_somewhere
{
   my $self = shift;

   my $tie;
   my $dbfile;
   my %refindex;

   my $basename = basename($self->{'dataset'});
   my $file = $self->{'file'};
   my @filestat = $file->stat;

   foreach (dirname($self->{'dataset'}), @trydirs)
   {
      $dbfile = "$_/$basename-refs.gdbm";

      my @dbstat = stat($dbfile);
      next unless @dbstat;
      next if $dbstat[9] < $filestat[9];

      $tie = tie(%refindex, 'GDBM_File', $dbfile, &GDBM_READER, 0644);

      last if $tie;
   }

   if ($tie)
   {
      $self->{'index'} = \%refindex;
      return $tie;
   }

   foreach (dirname($self->{'dataset'}), @trydirs)
   {
      $dbfile = "$_/$basename-refs.gdbm";

      $tie = tie(%refindex, 'GDBM_File', $dbfile, &GDBM_NEWDB, 0644);

      last if $tie;
   }

   return undef unless $tie;

   warn "Creating new refdb at $dbfile\n";

   my %counts = (
	INDI => 0,
	FAM => 0,
	SOUR => 0,
	);

   $file->seek(0, 0);

   my $count = 0;
   my $offset = 0;
   while (<$file>)
   {
      s/[\r\n]+$//g;

      my ($tag, $type) = /^0\s+@([\w]+)@\s+(indi|fam|sour)/i;

      if ($tag)
      {
         $tag = uc($tag);
         $type = uc($type);

         $counts{$type} += 1;

         $refindex{"$type:$tag"} = $offset;
      }

      $offset = $file->tell;
   }

   untie %refindex;
   undef $tie;

   warn "Index built: ", join(", ", map { $counts{$_} . " " . $_ } sort keys %counts), "\n";

   $tie = tie(%refindex, 'GDBM_File', $dbfile, &GDBM_READER, 0644);
   $self->{'index'} = \%refindex;

   return $tie;
}

sub build_surnameindex_somewhere
{
   my $self = shift;

   my $tie;
   my $dbfile;
   my %surnameindex;

   my $basename = basename($self->{'dataset'});
   my @filestat = $self->{'file'}->stat;

   foreach (dirname($self->{'dataset'}), @trydirs)
   {
      $dbfile = "$_/$basename-surnames.gdbm";

      my @dbstat = stat($dbfile);
      next unless @dbstat;
      next if $dbstat[9] < $filestat[9];

      $tie = tie(%surnameindex, 'GDBM_File', $dbfile, &GDBM_READER, 0644);

      last if $tie;
   }

   if ($tie)
   {
      $self->{'surnameindex'} = \%surnameindex;
      return $tie;
   }

   foreach (dirname($self->{'dataset'}), @trydirs)
   {
      $dbfile = "$_/$basename-surnames.gdbm";

      $tie = tie(%surnameindex, 'GDBM_File', $dbfile, &GDBM_NEWDB, 0644);

      last if $tie;
   }

   return undef unless $tie;

   warn "Creating new surnamedb at $dbfile\n";

   my %surnames;

   foreach ($self->individuals)
   {
      my $surname = uc($_->surname);

      if (exists $surnames{$surname})
      {
         $surnames{$surname} .= ":" . $_->code;
      }
      else
      {
         $surnames{$surname} = $_->code;
      }
   }

   %surnameindex = %surnames;

   # now just close & reopen as a reader

   untie %surnameindex;
   undef $tie;

   $tie = tie(%surnameindex, 'GDBM_File', $dbfile, &GDBM_READER, 0644);
   $self->{'surnameindex'} = \%surnameindex;

   return $tie;
}

###

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GedNav - Perl extension for quick (& dirty) navigation of GEDCOM files

=head1 SYNOPSIS

  use GedNav;
  blah blah blah

=head1 DESCRIPTION

GedNav is a set of perl modules for navigating a GEDCOM file quickly.
The intent was to make it fast enough for CGI purposes, on large
GEDCOM files.

I have not yet included the code for the report objects I've written
(outline & register so far), except for the example code in outline.pl.

I've also not included the Apache::GedNav stuff I've written.  That'll
probably come in a separate lump, when the time comes.

=head1 AUTHOR

Rob Fugina, robf@fugina.com

=head1 SEE ALSO

perl(1).

=cut

