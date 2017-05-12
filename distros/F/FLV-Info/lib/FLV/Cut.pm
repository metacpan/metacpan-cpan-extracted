package FLV::Cut;

use warnings;
use strict;
use 5.008;

use FLV::File;
use FLV::Util;
use List::MoreUtils qw(any);
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $VERSION = '0.24';

=for stopwords FLVs undef keyframes keyframe

=head1 NAME

FLV::Cut - Extract FLV segments into new files

=head1 LICENSE

See L<FLV::Info>

=head1 SYNOPSIS

   use FLV::Cut;
   my $converter = FLV::Cut->new();
   $converter->add_output('first_ten_sec.flv', undef, 10_000);
   $converter->add_output('middle_ten_sec.flv', 20_000, 30_000);
   $converter->add_output('tail.flv', 40_000, undef);
   $converter->parse_flv('input.flv');
   $converter->save_all;

=head1 DESCRIPTION

Efficiently extracts segments of an FLV into separate files.

WARNING: this tool does not help you find keyframes!  If you pick a
cut time that is not on a keyframe, you will see unpleasant video
artifacts in the resulting media.  For many input FLVs, you can use
the following to find the keyframe times:

   my $flv = FLV::File->new;
   $flv->parse;
   $flv->populate_meta; # optional
   my @times = @{ $flv->get_meta('keyframe')->{times} };

=head1 METHODS

=over

=item $pkg->new()

Instantiate a converter.

=cut

Readonly::Scalar my $MAX_TIME => 4_000_000_000;

sub new
{
   my $pkg = shift;

   my $start = { time => 0, out => [] };
   my $end = { time => $MAX_TIME + 1, out => [] };
   my $self = bless {
      times => [$start, $end],    ## no critic (Comma)
      outfiles => {},
   }, $pkg;
   return $self;
}

=item $self->add_output($flv_filename, $in_milliseconds, $out_milliseconds)

Register an output file for a particular time slice.  Either the in or
out times can be undefined to imply the beginning or end of the FLV,
respectively.  You can set both to undef, but that's pretty
pointless...  If the in or out times are not represented in the input
FLV, that's OK -- you may just end up with less data than you expected
in the output files.

=cut

sub add_output
{
   my $self    = shift;
   my $outfile = shift;
   my $cutin   = shift || 0;
   my $cutout  = shift || $MAX_TIME;

   if ($cutin < 0 || $cutout < 0)
   {
      croak 'Illegal negative time';
   }
   if ($cutin > $MAX_TIME || $cutout > $MAX_TIME)
   {
      croak 'Illegal huge time';
   }
   if ($cutin >= $cutout)
   {
      carp 'Ignoring cut-in >= cut-out';
      return;
   }

   my $out = FLV::File->new();
   $out->empty();
   my $outfh = FLV::Util->get_write_filehandle($outfile);
   if (!$outfh)
   {
      die 'Failed to write FLV file: ' . $OS_ERROR;
   }

   if ($self->{outfiles}->{$outfile})
   {
      if ($self->{outfiles}->{$outfile}->{cutin} > $cutin)
      {
         $self->{outfiles}->{$outfile}->{cutin} = $cutin;
      }
   }
   else
   {
      $self->{outfiles}->{$outfile}
          = { flv => $out, fh => $outfh, cutin => $cutin };
   }

   my $times = $self->{times};
   my $i     = 0;
   while ($times->[$i]->{time} < $cutin)
   {
      ++$i;
   }
   if ($times->[$i]->{time} != $cutin)
   {

      # A new cutin time
      my $new_time
          = { time => $cutin, out => [@{ $times->[$i - 1]->{out} }] };
      splice @{$times}, $i, 0, $new_time;
   }
   my $added_last;
   while ($times->[$i]->{time} <= $cutout)
   {
      if (any { $_ eq $outfile } @{ $times->[$i]->{out} })
      {
         $added_last = undef;
      }
      else
      {
         $added_last = 1;
         push @{ $times->[$i]->{out} }, $outfile;
      }
      ++$i;
   }
   if ($times->[$i]->{time} != $cutout + 1)
   {

      # A new cutout time

      my @out = @{ $times->[$i - 1]->{out} };

      # It should not include this $outfile, unless it previously
      # spanned this cutout
      if ($added_last)
      {
         pop @out;
      }

      splice @{$times}, $i, 0, { time => $cutout + 1, out => \@out };
   }

   return;
}

=item $self->parse_flv($flv_filename)

=item $self->parse_flv($flv_instance)

Open and parse the specified FLV file.  Alternatively, you may pass an
instantiated and parsed L<FLV::File> object.

=cut

sub parse_flv
{
   my $self   = shift;
   my $infile = shift;

   my $flv;
   if (ref $infile && $infile->isa('FLV::File'))
   {
      $flv = $infile;
   }
   else
   {
      $flv = FLV::File->new;
      $flv->parse($infile);
   }

   # ASSUMPTION: tags are time-sorted
   my $times = $self->{times};
   my $i     = 0;
   for my $tag ($flv->get_body->get_tags)
   {
      if ($tag->isa('FLV::VideoTag') || $tag->isa('FLV::AudioTag'))
      {
         my $time = $tag->get_time;
         while ($time >= $times->[$i + 1]->{time})
         {
            ++$i;
         }
         for my $outfile (@{ $times->[$i]->{out} })
         {
            my $out = $self->{outfiles}->{$outfile};
            my $tag_copy = bless { %{$tag} }, ref $tag;    # shallow clone
            $tag_copy->{start} -= $out->{cutin};
            push @{ $out->{flv}->get_body->{tags} }, $tag_copy;
         }
      }
   }
   return;
}

=item $self->save_all()

Serialize all of the extracted FLVs to file.

=cut

sub save_all
{
   my $self = shift;

   for my $out (values %{ $self->{outfiles} })
   {
      $out->{flv}->populate_meta();
      $out->{flv}->serialize($out->{fh});
   }

   return;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
