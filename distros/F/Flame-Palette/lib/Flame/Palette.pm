package Flame::Palette;

use 5.008;
use strict;
use warnings;

use Carp 'croak';
use Math::Interpolator::Linear;
use Math::Interpolator::Knot;
use XML::Parser;
use XML::Writer;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Flame::Palette ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub check_integer {
    my $self = shift;
    my $subject = shift;
    my $name = shift;

    croak "undefined subject" unless defined $subject;

    unless($subject =~ /^\d+$/ && $subject >= 0 && $subject <= 255) {
	croak "invalid $name '$subject'";
    }
}

sub set {
    my($self, %stuff) = @_;

    croak "missing index argument" unless exists $stuff{index};

    my $index = $stuff{index};

    $self->check_integer($index, 'index');

    if(exists $stuff{red} && exists $stuff{green} && exists $stuff{blue}) {
	foreach(qw(red green blue)) {
	    $self->check_integer($stuff{$_}, $_);
	}

	my($r, $g, $b) = map { $stuff{$_} } qw(red green blue);

	$self->{data}->[$index] = [$r, $g, $b];

	return 1;
    }

    croak "expect index, red, green, blue arguments";
}

sub get {
    my($self, %stuff) = @_;

    croak "missing 'index' argument" unless exists $stuff{index};

    my $index = $stuff{index};

    $self->check_integer($index, 'index');

    my @data = (0, 0, 0);

    if(exists $self->{data} && $index < @{$self->{data}}) {
	@data = @{$self->{data}->[$index] || []};
    }

    if(wantarray) {
	return @data;
    }

    return \@data;
}

sub unparse_xml {
    my($self, $stream) = @_;

    my $w = XML::Writer->new(OUTPUT => $stream);

    $w->startTag('palette');

    foreach my $i (0...255) {
	my($r, $g, $b) = $self->get(index => $i);

	$w->emptyTag('color', index => $i, rgb => join ' ', $r, $g, $b);
    }

    $w->endTag;
}

sub clear {
    my $self = shift;

    delete $self->{data};
}

sub parse_flame {
    my($self, $stream) = @_;

    $self->clear;

    my $ok = 0;
    my $done = 0;

    my $s_start = sub {
	my(undef, $tag, %attr) = @_;

	unless($done) {
	    if($tag =~ /^flame$/) {
		$ok = 1;
	    } elsif($ok) {
		if($tag =~ /^color$/) {
		    croak "missing 'index' attribute in 'color' tag" unless exists $attr{index};
		    croak "missing 'rgb' attribute in 'color' tag" unless exists $attr{rgb};

		    my($red, $green, $blue) = split '\D+', $attr{rgb};

		    $self->set(index => $attr{index},
			       red => $red,
			       green => $green,
			       blue => $blue);
		}
	    }
	}
    };

    my $s_end = sub {
	my(undef, $tag) = @_;

	unless($done) {
	    if($tag =~ /^flame$/) {
		$done = 1;
	    }
	}
    };

    XML::Parser->new(Handlers => { Start => $s_start, End => $s_end })->parse($stream);
}

sub parse_xml {
    my($self, $stream) = @_;

    $self->clear;

    my $level = 0;

    my $s_start = sub {
	my(undef, $tag, %attr) = @_;

	if($tag =~ /^palette$/ && $level == 0) {
	    if(keys %attr != 0) {
		croak "the 'palette' tag doesn't accept attributes";
	    }
	} elsif($tag =~ /^color$/ && $level == 1) {
	    croak "missing 'index' attribute" unless exists $attr{index};
	    croak "missing 'rgb' attribute" unless exists $attr{rgb};

	    my $index = $attr{index};
	    my $rgb = $attr{rgb};

	    delete $attr{index};
	    delete $attr{rgb};

	    if(keys %attr != 0) {
		croak "the 'color' tag doesn't accept attributes but index,rgb";
	    }

	    my($red, $green, $blue) = split '\D+', $rgb;

	    $self->set(index => $index, red => $red, green => $green, blue => $blue);
	} else {
	    croak "unknown tag '$tag'";
	}

	$level++;
    };

    my $s_end = sub { $level-- };

    XML::Parser->new(Handlers => { Start => $s_start, End => $s_end })->parse($stream);
}

sub interpolate {
    my $self = shift;

    my $i = 0;

    while($i < 255) {
	if(defined $self->{data}->[$i] && !defined $self->{data}->[$i + 1]) {
	    my $j = $i + 1;

	    while($j < 255 && !defined $self->{data}->[$j]) {
		$j++;
	    }

	    my($fr, $fg, $fb) = $self->get(index => $i);
	    my($tr, $tg, $tb) = $self->get(index => $j);

	    my $ci = sub {
		push my @p, Math::Interpolator::Knot->new($i, $_[0]);
		push @p, Math::Interpolator::Knot->new($j, $_[1]);

		my $ipl = Math::Interpolator::Linear->new(@p);

		sub { int($ipl->y($_[0])) }
	    };

	    my $r_ip = $ci->($fr, $tr);
	    my $g_ip = $ci->($fg, $tg);
	    my $b_ip = $ci->($fb, $tb);

	    foreach($i...$j) {
		$self->set(index => $_,
			   red   => $r_ip->($_),
			   green => $g_ip->($_),
			   blue  => $b_ip->($_));
	    }
	}

	$i++;
    }
}

# TODO: CHECK DOCUMENTATION

1;
__END__

=head1 NAME

Flame::Palette - Perl extension to parse, unparse, create, process Flam3 palettes

=head1 SYNOPSIS

  use Flame::Palette;

  my $pal = Flame::Palette->new;
  $pal->set(index => 0, red => 255, green => 0, blue => 0);
  $pal->set(index => 127, red => 0, green => 255, blue => 0);
  $pal->set(index => 255, red => 0, green => 0, blue => 255);
  $pal->interpolate;
  $pal->unparse_xml(\*STDOUT);

=head1 DESCRIPTION

This module provides a palette class, which knows these methods:

=over

=item

$pal = Flame::Palette->new

Constructor. Creates an empty palette, consisting of nothing

=item

$pal->set(index => n, red => x, green => y, blue => z)

Set the entry whose number is I<n> to the RGB values red=I<x>,
green=I<y>, blue=I<z>. All of those values have to be in the range
0...255

=item

(red, green, blue) = $pal->get(index => n)

Retrieve the entry whose number is I<n>. Returns an array in array
context and an array reference otherwise. Returns black if the
requested entry was not previously set.

=item

$pal->parse_xml(stream)

Clear the existing palette and parse the XML file which is retrieved
when reading the supplied stream. The XML file has to look like:

 <palette>
   <color index="0" rgb="255 0 0" />
   <!-- some entries are omitted -->
   <color index="255" rgb="0 0 255" />
 </palette>

Trick: you can read from plain strings so you do not need to provide
an actual file. Try this:

 my $string;
 open(my $stream, '<', \$string);
 $pal->parse_xml($stream);

=item

$pal->parse_flame(stream)

Do the same as the parse_xml() method, with the exception that the XML
file must be a .flame one.

=item

$pal->unparse_xml(stream)

Dump the palette to an XML file. The stream doesn't have to be an open
file, the trick shown above also works in the opposite direction:

 my $string;
 open(my $stream, '>', \$string);
 $pal->unparse_xml($stream);

=item

$pal->interpolate

If the palette is sparse, e.g there are at least two entries with no
other entires but space in between (similar to the sparse file concept
of modern operating systems), the missing entries are interpolated
from the entries around. Try the example shown at the top.

=item

$pal->clear

Remove all the existing entries.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

Flam3 itself: http://www.flam3.com/

=head1 VERSION

SVN: $Id: Palette.pm 125 2010-12-28 23:34:37Z daniel $

=head1 AUTHOR

David Kroeber E<lt>david@mousemail.me.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by David Kroeber

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
