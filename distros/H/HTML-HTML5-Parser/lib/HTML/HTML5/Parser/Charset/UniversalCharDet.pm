package HTML::HTML5::Parser::Charset::UniversalCharDet;

## skip Test::Tabs
use strict;
use warnings;
use IO::HTML ();

our $VERSION='0.992';
our $DEBUG;

# this really shouldn't work, but for some reason it does...
sub _detect {
	return +{ encoding => 'UTF-8' } if !utf8::is_utf8($_[0]); # huh?
	open my $fh, '<:raw', \$_[0];
	my $e = IO::HTML::sniff_encoding($fh => 'string');
	return +{ encoding => $e } if defined $e;
	return +{};
}

sub detect_byte_string ($$) {
  my $de;
  eval {
    $de = _detect $_[1];
    1;
  } or do {
    warn $@ unless $DEBUG;
    die $@ if $DEBUG;
  };
  if (defined $de and defined $de->{encoding}) {
    return lc $de->{encoding};
  } else {
    return undef;
  }
} # detect_byte_string

#Copyright 2007-2011 Wakaba <w@suika.fam.cx>
#Copyright 2009-2012 Toby Inkster <tobyink@cpan.org>
#
#This library is free software; you can redistribute it
#and/or modify it under the same terms as Perl itself.

1;
