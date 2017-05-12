package File::Type::Builder;
use strict;
use warnings;

use IO::File;

our $VERSION = "0.11";

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub parse_magic {
  my $self = shift;
  my $data = shift;
  my $line = shift;

  # storage  
  my $parsed = {};
  my $pattern;

  # offsets
  $data =~ s/^([0-9a-fx]+)\s+//;
  $parsed->{offset} = $1;
  
  # pattern type
  $data =~ s/(byte | short | long | string | date | beshort |
              belong | bedate | leshort | lelong | ledate)(\s+)?//x;
  $parsed->{pattern_type} = $1;
  
  unless ($parsed->{pattern_type} =~ m/^(string|beshort|belong)/) {
    return undef;
  }
  
  # pattern mask, if exists; buggy?
  if ($data =~ m/^\&/) {
    # warn "pattern mask on line $line\n";
    $data =~ s/\&([a-z0-9]+)\s+//;
    $parsed->{pattern_mask} = $1;
  }

  # handle pattern. Somewhat complex.
  PARSE: while ($data =~ s/(\s*\S*\s)//) {
    # add data to pattern. stop unless we've got significant whitespace.
    $pattern .= $1 unless $1 =~ m/^\s+$/;
    last PARSE unless ($pattern =~ m!\\\s$!);
  }
  # then tidy up
  return undef unless defined($pattern);

  $pattern =~ s/\s*$// unless $pattern =~ m/\\\s$/;
  $pattern =~ s/\\(\s)/$1/g;
  $pattern =~ s/\\$//g;
  $parsed->{pattern} = $pattern;
      
  # what's left is the MIME type
  $data =~ s/^\s*(.*)$//;
  $parsed->{mime_type} = $1;

  # check there's nothing undigested
  warn "On line $line, remaining '$data'. Using anyway.\n" if length($data);

  # check we've got a mime type to return
  if (!length($parsed->{mime_type})
   || $parsed->{mime_type} !~ m!^[^/]*/[^/]*$!) {
    # warn "On line $line, no or improper MIME type: not used\n";
    return undef;
  }

  return $parsed;
}

sub string {
  my $self   = shift;
  my $parsed = shift;

  my $escape = $self->_get_escapes();

  # build a code fragment.
  my $code;
  my $tab = '';
  
  if ($parsed->{offset}) {
    $code = $self->_substr_handling($parsed->{offset}, 1024); 
    $tab = '  ';

    # we have to use substr to advance to the anchor
    $code .= '    if (defined $substr && $substr =~ m[^';

  } else {
    # can just anchor normally
    $code = '  if ($data =~ m[^';
  }

  # manipulate regex; use File::MMagic code
  my $pattern = $parsed->{pattern};

  # quote metacharacters
#  unless ($pattern =~ m!\\x!) {
    $pattern = quotemeta($pattern);
  	$pattern =~ s/\\\\(.)/$escape->{$1}||$1/eg;
#  }

  $code .= $pattern;

  # close the [] delimited regex and return mime type 
  $code .= ']) {';
  $code .= "\n$tab    return q{$parsed->{mime_type}};\n$tab  }\n";

  if ($tab) {
    $code .= "$tab}\n";
  }
  
  return $code;
} 

sub be {
  my $self   = shift;
  my $parsed = shift;
  my $length = shift;

  # build both sides of the conditional
  my $offset  = $parsed->{offset};
  my $pattern = $parsed->{pattern};

  # start with substr handling
  my $code = $self->_substr_handling($offset, $length);

  # rhs: template
  my $rhs;
  if ($pattern =~ s/^0x//) {
    $rhs = "pack('H*', '$pattern')";
  } else {
    # warn "Not sure what this magic is";
    return undef;
  }
  
  # build condition
  $code .= "    if ($rhs eq ".'$substr ) {';
  $code .= "\n      return q{$parsed->{mime_type}};\n    }\n  }\n";
  
  return $code;
} 

sub _substr_handling {
  my $self = shift;
  my ($offset, $length) = @_;
  
  my $code = '  if (length $data > '.$offset.") {\n";
  $code   .= '    $substr = substr($data, '.$offset.', '.$length.");\n";
  
  return $code;
}

sub _get_escapes {
  return { n => '\n',
           r => '\r',
           b => '\b',
           t => '\t',
           f => '\f',
           x => '\x',
           0 => '\0',
           1 => '\1',
           2 => '\2',
           3 => '\3',
         };
}

1;

__END__

=head1 NAME

File::Type::Builder - parse mime-magic and generate code

=head1 SYNOPSIS

    my $build = File::Type::Builder->new();
    
    while (<magic>) {
      chomp;
      my $parsed = $build->parse_magic($_);
      
      my $code   = $build->string_start($parsed);
      (or string_offset or beshort)
    }

=head1 DESCRIPTION

Reads in the mime-magic file format and translates it to code.
(This documentation would be longer if I really expected anyone other 
than me to run the code.)

=head1 METHODS

=head2 new

Creates a new File::Type::Builder object.

=head2 parse_magic

Pulls apart a line of a mime-magic file using a string of regular 
expressions.

An example mime-magic file can be found in cleancode CVS at
L<http://cleancode.org/cgi-bin/viewcvs.cgi/email/mime-magic.mime?rev=1.1.1.1>

=head2 string

Builds code to match magic that's of type string.

Has to do some cleverness to make the regular expression work properly.

=head2 be

Builds code to match 'beshort' and 'belong' magic (eg audio/mpeg, 
image/jpeg).

=head1 PRIVATE METHODS

=head2 _substr_matching

Sometimes the data is smaller than the offset we're looking for in the
file. If this is the case, then the file is obviously not of that type,
and furthermore we should avoid issuing a couple of warnings that Perl
would otherwise emit.

This subroutine generates this code. 

=head2 _get_escapes

Returns a reference to a hash defining characters that should not be 
escaped.

=head1 TODO

=over 4

* Add handlers for other magic types (bedate, byte, etc)

* Make verbosity/logging nicer.

* Find more edge cases.

* Remove redundant 'if (length $data > 0)' check.

=back

Longer term:

=over 4

* Fix for multiple magic format types?

=back

=head1 BUGS

Incomplete. Some known issues with odd entries in mime-magic. Skips
some mime-magic lines.

=head1 SEE ALSO

L<File::Type>, which is partially generated by this module.

=head1 AUTHOR

Paul Mison <pmison@fotango.com>

=head1 COPYRIGHT 

Copyright 2003 Fotango Ltd.

=head1 LICENSE

Licensed under the same terms as Perl itself. 

=cut
