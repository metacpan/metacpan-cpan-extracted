use strict;
use warnings;
use utf8;

package Ed2k_link;
$Ed2k_link::VERSION = '20160412';

use Carp ();
use File::Basename ();
use URI::Escape ();
use Encode::Locale ();
use Encode ();
use Digest::MD4 ();
use Digest::SHA ();

use constant {
  CHUNK_SIZE => 9_728_000,
    BLOCK_SIZE => 184_320,
  };

=head1 NAME

Ed2k_link - module for creating eD2K links and working with them.

=head1 VERSION

version 20160412

=head1 SYNOPSIS

  use Ed2k_link ();

  print Ed2k_link -> from_file( 'c:\\temp\\new_movie.mkv' ) -> link( 'h' ) . "\n";

  my $emule = Ed2k_link -> from_file( 'eMule0.49c.zip' ) or die 'something wrong with file!');

  my $sources = Ed2k_link -> from_link( 'ed2k://|file|eMule0.49c.zip|2868871|0F88EEFA9D8AD3F43DABAC9982D2450C|/' ) or die 'incorrect link!';

  $sources -> from_link( 'ed2k://|file|eMule0.49c-Sources.zip|5770302|195B6D8286BF184C3CC0665148D746CF|/' ) or die 'incorrect link!';

  print $emule -> link( 'h' ) if $emule -> filesize <= 10 * 1024 * 1024, "\n";

  if ( Ed2k_link -> equal( $emule, $sources ) {
    printf "files %s and %s are equal\n";
      $emule -> filename,
      $sources -> filename;
  }

  print Ed2k_link -> from_file( '/somethere/cool_file.txt' ) -> link('hp');

=head1 DESCRIPTION

Ed2k_link module for creating eD2K links from files with correct hash, AICH hash and complete hashset fields.
Also it can work with already created links (e. g. from textfile).

=cut

sub _encode_base32 {
  my %bits_to_char = qw# 00000 A 00001 B 00010 C 00011 D 00100 E 00101 F 00110 G 00111 H
                         01000 I 01001 J 01010 K 01011 L 01100 M 01101 N 01110 O 01111 P
                         10000 Q 10001 R 10010 S 10011 T 10100 U 10101 V 10110 W 10111 X
                         11000 Y 11001 Z 11010 2 11011 3 11100 4 11101 5 11110 6 11111 7
                       #;
  my ($source, $bits, $res) = shift;
  $bits .= unpack('B*', substr($source, $_, 1)) for 0 .. length($source) - 1;
  # generally $bits length could be not 40 * k and there has to be padding.  not our case
  $res .= $bits_to_char{$&} while $bits =~ m/.{5}/g;
  $res;
}

sub _define_base_trees_orientation { # l/r, array_ref, start_idx, end_idx
  if ($_[2] - $_[3] >= 0) {
    $_[1][$_[2]] = $_[0];
  } elsif ($_[2] + 1 == $_[3]) {
    $_[1][$_[2]] = 'l';
    $_[1][$_[3]] = 'r';
  } else {
    my $med = sprintf("%d", ($_[2] + $_[3]) / 2);
    -- $med if $_[ 0 ] eq 'r' && $_[ 2 ] + $_[ 3 ] == $med * 2;
    &_define_base_trees_orientation( 'l', $_[ 1 ], $_[ 2 ], $med );
    &_define_base_trees_orientation( 'r', $_[ 1 ], ++ $med, $_[ 3 ] );
  }
}

sub _get_root_hash {            # l/r, array_ref, start_idx, end_idx
  my $med = $_[3];
  if ($_[2] - $_[3] >= 0) {
    return;
  } elsif ($_[3] - $_[2] > 1) {
    $med = sprintf("%d", ($_[2] + $_[3]) / 2);
    -- $med if $_[ 0 ] eq 'r' && $_[ 2 ] + $_[ 3 ] == $med * 2;
    &_get_root_hash( 'l',
                     $_[ 1 ],
                     $_[ 2 ],
                     $med
                   );
    &_get_root_hash( 'r',
                     $_[ 1 ],
                     ++ $med,
                     $_[ 3 ]
                   );
  }

  $_[ 1 ] -> [ $_[ 2 ] ] = Digest::SHA::sha1( $_[ 1 ] -> [ $_[ 2 ] ],
                                              $_[ 1 ] -> [ $med ]
                                            );
}

=head1 CLASS METHODS

=head2 from_file

Can be called as class or instance method:

  my $t = Ed2k_link -> from_file( 'file_1.txt' ) or die 'error!';

  $t -> from_file( 'file_2.txt' ) or die 'error!';

Creates all fields of eD2K link including hash, AICH hashset, complete hashset.

Filename should be a character string (as opposed to octet string).  In case of any error returns undef and object doesn't hold any link information.

Sets Reliable flag to true.

=cut

sub from_file {
  my $either = shift;
  %$either = () if ref $either;
  my $file = shift;       # string of characters (not an octet stream)
  return undef unless defined $file;

  # file must exist and be not empty!
  my $filename_to_access = Encode::encode( locale_fs => $file );
  return undef unless -f $filename_to_access && -s _;

  my $self = { path_to_file => $file,
               size => -s _,
               filename => File::Basename::fileparse( $file ),
             };

  # emule doesn't escape #[]@$&+,;=
  $self -> {escaped_filename} = URI::Escape::uri_escape_utf8( $self -> {filename}, '^A-Za-z0-9\-_.!~*\'()#&+,;=' );
  # []@$
  $self -> {escaped_filename} =~ s/%5B/[/g;
  $self -> {escaped_filename} =~ s/%5D/]/g;
  $self -> {escaped_filename} =~ s/%40/\@/g;
  $self -> {escaped_filename} =~ s/%24/\$/g;
  # hashes. step 1
  my @aich_tree;
  {
    my $base_blocks = sprintf("%d", $self -> {size} / CHUNK_SIZE);
    -- $base_blocks if $self -> {size} == $base_blocks * CHUNK_SIZE;
    &_define_base_trees_orientation( 'l', \ @aich_tree, 0, $base_blocks );
  }

  {
    open my $f, '<', $filename_to_access
      or die sprintf( 'cannot open %s for reading: %s',
                      $file,
                      $!,
                    );

    binmode $f;
    my ($t, $readed_bytes);
    my $md4 = Digest::MD4 -> new;
    while (defined($readed_bytes = read $f, $t, CHUNK_SIZE)) {
      $md4 -> add($t);
      $self -> {hash} .= $md4 -> clone -> digest;
      push @{$self -> {p}}, uc $md4 -> hexdigest;
      if ($readed_bytes) {
        my $pos = 0;
        my @t_sha1;
        while ($pos < $readed_bytes) {
          push @t_sha1, Digest::SHA::sha1( substr( $t, $pos, BLOCK_SIZE ) );
          $pos += BLOCK_SIZE;
        }
        # sha1 for chunk
        &_get_root_hash( $aich_tree[ $#{ $self -> {p} } ],
                         \ @t_sha1,
                         0,
                         $#t_sha1
                       );
        $aich_tree[$#{$self -> {p}}] = $t_sha1[0];
      }
      last if $readed_bytes != CHUNK_SIZE;
    }
    close $f;
    return undef unless defined $readed_bytes
      && $self -> {size} == $#{$self -> {p}} * CHUNK_SIZE + $readed_bytes;
  }

  # hashes. step 2
  if (@{$self -> {p}} == 1) {
    $self -> {hash} = $self -> {p}[0];
  } else {
    $self -> {hash} = uc Digest::MD4::md4_hex( $self -> {hash} );
  }
  # aich hashset
  &_get_root_hash( 'l',
                   \ @aich_tree,
                   0,
                   $#aich_tree
                 );
  $self -> {aich} = _encode_base32( $aich_tree[ 0 ] );
  $self -> {reliable} = 1;

  if (ref $either) {
    %$either = %$self;
    1;
  } else {
    bless $self, $either;
  }
}

=head2 from_link

Can be called as class or object method:

  my $tl = Ed2k_link -> from_link( 'ed2k://|file|eMule0.49c.zip|2868871|0F88EEFA9D8AD3F43DABAC9982D2450C|/' )
    or die 'incorrect link!';

  $t1 = from_link( 'ed2k://|file|eMule0.49c-Sources.zip|5770302|195B6D8286BF184C3CC0665148D746CF|/' )
    or die 'incorrect link!';

Takes mandatory (filename/size/hash) and optional (AICH hash, complete hashset) fields from the link.
Checks some correctness of fields (acceptable symbols, length, ...).
If link in parameter has complete hashset, checks compliance between hash and complete hashset.

In case of any incorrectness returns undef and object doesn't hold any link information.

If link in parameter has AICH and/or complete hashset, sets Reliable flag to false. Otherwise it's true.

=cut

sub from_link {
  my $either = shift;
  %$either = () if ref $either;
  my $link = shift;
  return undef unless defined $link;
  return undef unless $link =~ m#^ed2k://\|file\|([\d\D]+?)\|(\d+)\|([\da-f]{32})\|#i;
  my $self = { escaped_filename => $1,
               size => $2,
               hash => uc $3,
               filename => Encode::decode( 'UTF-8', URI::Escape::uri_unescape( $1 ) ),
               reliable => 1,
             };

  $link = "|$'";
  return undef unless $self -> {size};

  # complete hashset
  if ($link =~ m/\|p=([\d\D]*?)\|/) {
    my $t = uc $1;
    $link = "|$`$'";
    return undef unless $t =~ m/^([\dA-F]{32}(:[\dA-F]{32})*)$/;

    my @t = split ':', $1;
    $t = sprintf("%d", $self -> {size} / CHUNK_SIZE);
    ++ $t if $self -> {size} >= $t * CHUNK_SIZE;
    return undef unless $t == @t;

    if (@t == 1) {
      return undef unless $self -> {hash} eq $t[0];
    } else {
      my $t = '';
      foreach my $bh (@t) {
        $t .= chr(hex($&)) while $bh =~ m/../g;
      }
      return undef unless $self -> {hash} eq uc Digest::MD4::md4_hex( $t );
      $self -> {reliable} = 0;
    }
    $self -> {p} = \@t;
  }
  $self -> {p}[0] = $self -> {hash} if $self -> {size} < CHUNK_SIZE && not exists $self -> {p};

  # aich
  if ($link =~ m/\|h=([\d\D]*?)\|/) {
    $self -> {aich} = uc $1;
    $link = "|$`$'";
    return undef unless $self -> {aich} =~ m/^[A-Z2-7]{32}$/;
    $self -> {reliable} = 0;
  }

  if (ref $either) {
    %$either = %$self;
    $either;
  } else {
    bless $self, $either;
  }
}

=head2 ok

Instance only method.  Returns true if object was successfully created and holds all required fields;

  &do_something() if $t1 -> ok;

=cut

sub ok {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  return exists $instance -> {escaped_filename} && exists $instance -> {size} && exists $instance -> {hash};
}

=head2 filename

Instance method.  Returns filename as character string:

  print $t -> filename;

=cut

sub filename {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {filename};
}

=head2 escaped_filename

Instance method.  Returns escaped filename (as in link);

  print $t -> escaped_filename;

=cut

sub escaped_filename {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {escaped_filename};
}

=head2 filesize

Instance method.  Returns filesize;

=cut

sub filesize {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {size};
}

=head2 hash

Instance method.  Returns hash field from link;

=cut

sub hash {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {hash};
}

=head2 has_complete_hashset

Instance method.  Returns true if object has complete hashset, false otherwise;

=cut

sub has_complete_hashset {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  exists $instance -> {p} && @{$instance -> {p}};
}

=head2 complete_hashset

Instance method.  Returns complete hashset if object has it.  undef otherwise;

=cut

sub complete_hashset {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> has_complete_hashset ?
    join ':', @{$instance -> {p}}
    : undef;
}

=head2 has_aich

Instance method.  Returns true if object has aich hash, false otherwise;

=cut

sub has_aich {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  exists $instance -> {aich};
}

=head2 aich

Instance method.  Returns AICH hash if object has it.  undef otherwise;

=cut

sub aich {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {aich};
}

=head2 link

Instance only method.  Returns string representation of link.  Can have parameter with options:

    h - include AICH hash if available.  Recommended.
    p - include complete hashset if available.

  my $link1 = $t -> link;
  my $link_with_aich = $t -> link( 'h' );
  my $link_with_hashset = $t -> link( 'p' );
  my $iron_link = $t -> link( 'hp' );

=cut

sub link {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  my $optional = shift;
  return undef unless $instance -> ok;

  my @part = ( 'ed2k://|file',
               $instance -> escaped_filename,
               $instance -> filesize,
               $instance -> hash,
             );

  if ( defined $optional ) {
    # complete hashset
    push @part,
      'p=' . $instance -> complete_hashset
      if index( $optional, 'p' ) != -1
      && $instance -> filesize >= CHUNK_SIZE
      && $instance -> has_complete_hashset;

    # aich hashset
    push @part,
      'h=' . $instance -> aich
      if index( $optional, 'h' ) != -1
      && $instance -> has_aich;
  }

  join '|', @part, '/';
}

=head2 is_reliable

Instance method.  Returns true if object is reliable, false otherwise;

=cut

sub is_reliable {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {reliable};
}

=head2 set_reliable

Instance method.  Sets Reliable flag for object.  Use it very carefully, or you could end up with fake link
that doesn't reference any file and you won't be able to download anything with them.

Carefully means: you got string link from someone, who you trust.  Or you previously created it from file
by yourself and saved somethere and now you're reading those links from file of database.
Such usage of this method is appropriated;

=cut

sub set_reliable {
  ref(my $instance = shift) or Carp::croak "class usage! need to be instance usage";
  $instance -> {reliable} = 1;
}

=head2 equal

Class only method.
Compares two Ed2k_link objects by complex rules.  Returns true if they point to the same file.
Could fill some fields of one object with other's objects fields.  Also can set Reliable flag.

  print "hey! they are the same!" if Ed2k_link -> equal($t1, $t2);

=cut

sub equal {
  my $class = shift;
  return undef unless @_ == 2;
  my $one = shift;
  my $two = shift;
  my $res = $one -> ok && $two -> ok && $one -> filesize == $two -> filesize && $one -> hash eq $two -> hash;
  return undef unless $res;
  $res = $one -> complete_hashset eq $two -> complete_hashset
    if $one -> has_complete_hashset && $two -> has_complete_hashset;
  return undef unless $res;
  $res = $one -> aich eq $two -> aich
    if $one -> has_aich && $two -> has_aich;
  return undef unless $res;

  # cases with copying complete hash or aich and setting reliable flag
  if ($one -> is_reliable && $two -> is_reliable) {
    if ($one -> has_complete_hashset && !$two -> has_complete_hashset) {
      $two -> {p} = $one -> {p};
    } elsif (!$one -> has_complete_hashset && $two -> has_complete_hashset) {
      $one -> {p} = $two -> {p};
    }
    if ($one -> has_aich && !$two -> has_aich) {
      $two -> {aich} = $one -> {aich};
    } elsif (!$one -> has_aich && $two -> has_aich) {
      $one -> {aich} = $two -> {aich};
    }
  } elsif ($one -> is_reliable) {
    my $t = 0;
    if ($one -> has_complete_hashset) {
      ++ $t;
      $two -> {p} = $one -> {p};
    }
    if ($one -> has_aich) {
      ++ $t;
      $two -> {aich} = $one -> {aich};
    }
    -- $t if $two -> has_complete_hashset;
    -- $t if $two -> has_aich;
    $two -> set_reliable if $t >= 0;
  } elsif ($two -> is_reliable) {
    my $t = 0;
    if ($two -> has_complete_hashset) {
      ++ $t;
      $one -> {p} = $two -> {p};
    }
    if ($two -> has_aich) {
      ++ $t;
      $one -> {aich} = $two -> {aich};
    }
    -- $t if $one -> has_complete_hashset;
    -- $t if $one -> has_aich;
    $one -> set_reliable if $t >= 0;
  }

  $res;
}

1;
__END__

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ed2k_link at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ed2k_link>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ed2k_link

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ed2k_link>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ed2k_link>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ed2k_link>

=item * Search CPAN

L<http://search.cpan.org/dist/Ed2k_link/>

=back

=cut
