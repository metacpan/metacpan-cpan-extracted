package Imager::File::HEIF::Encoder::Parameter;
use strict;
use warnings;

our $VERSION = "1.000";

sub name {
    $_[0]{name};
}

sub default {
    $_[0]{default};
}

sub type {
    $_[0]{type};
}

sub minimum {
    $_[0]{minimum};
}

sub maximum {
    $_[0]{maximum};
}

sub values {
    @{$_[0]{values} || []};
}

1;

=head1 NAME

Imager::File::HEIF::Encoder - information about a libheif encoder

=head1 SYNOPSIS

  # see Imager::File::HEIF::Encoders
  for my $param ($encoder->parameters) {
    print "Name: ", $param->name, "\n";
    print "Default: ", $param->default, "\n";
    print "Type: ", $param->type, "\n";
    my $min = $param->minimum;
    my $max = $param->maximum;
    my @values = $param->values;
    if (defined $maximum && defined $minimum) {
      print "Range: $minimum..$maximum\n";
    }
    elsif (defined $maximum) {
      print "Range: ..$maximum\n";
    }
    elsif (defined $minimum) {
      print "Range: $minimum..\n";
    }
    elsif (@values) {
      print "Values: @values\n";
    }
    else {
      # may not be true
      print "Values unrestricted\n";
    }
  }

=head1 DESCRIPTION

Provides information about one parameter of a libheif encoder, as
returned by the Imager::File::HEIF::Encoder parameters method.

These aren't yet useful.

=head1 METHODS

=over

=item name

The name of the parameter.

=item default

The default value of the parameter.  In some cases the API doesn't
return a default, or the default doesn't match the allowable values
for that parameter.

=item type

One of "integer", "boolean", or "string", representing the type of
value accepted by the parameter.

=item minimum, maximum, values

Describes the range or the possible values accepted by this parameter.

=back

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

L<Imager::File::HEIF>, L<Imager>, L<Imager::Files>.

=cut
