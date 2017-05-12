package FTN::Message::serialno::File;

use strict;
use warnings FATAL => 'all';

use File::Spec ();

use parent 'FTN::Message::serialno';

use constant {
  FILE_EXTENSION => 'sn',
    FILENAME_PATTERN => '^([0-9a-fA-F]{1,8})$',
      FILENAME_FORMAT => '%x',
        SERIALNO_FORMAT => '%08x',
          MAX_TRIES => 5,
        };

=encoding utf8

=head1 NAME

FTN::Message::serialno::File - handles FTN message serialno via file in dedicated directory

=head1 VERSION

Version 20141121

=cut

our $VERSION = '20141121';

=head1 SYNOPSIS

  use FTN::Message::serialno::File ();

  my $serialno = FTN::Message::serialno::File -> new( directory => '/home/user/ftn/_serialno' );

  my $new_serialno = $serialno -> get_serialno;

  die 'cannot get new serialno' unless defined $new_serialno;

  # use $new_serialno value for constructing new message

=head1 DESCRIPTION

This class is for handling serialno value for new FTN messages.  Assigns consecutive unique values.

=head1 USAGE

This class has the following methods:

=head2 new

Class constructor.  Has the following options:

=cut

sub _initialize {
  my $self = shift;

  my %param = @_;

=over

=item * directory

The only mandatory option.  Specifies directory where files with serialno are being created and removed.  It is recommended to have it as a dedicated directory and not to keep any other files in it.

  FTN::Message::serialno::File -> new( directory => '/some/dir' );

=cut

  # directory
  die 'directory parameter should be defined!'
    unless $param{directory}
      && -d $param{directory};

  $self -> {directory} = $param{directory};


=item * file_extension

Serialno files extension.  Dot before its value will be added.

  FTN::Message::serialno::File -> new( directory => '/some/dir',
                                       file_extension => 'seq',
                                     );  

Default value is 'sn'.

=cut

  my $extension = exists $param{file_extension}? $param{file_extension} : FILE_EXTENSION;

=item * filename_pattern

Defines pattern and matching files in the directory are considered as serialno files and hence can be removed/renamed.  File extension shouldn't be specified as it's added automatically.

=cut

  my $pattern = $param{filename_pattern} || FILENAME_PATTERN;

=item * filename_format

Defines filename format (as in printf) with encoded serialno value.  File extension shouldn't be specified as it's added automatically.  Filename created with filename_format should match filename_pattern.

Default value is '%x'.

=cut

  $self -> {filename_format} = $param{filename_format} || FILENAME_FORMAT;
  if ( defined $extension
       && length $extension
     ) {
    if ( substr( $pattern, -1 ) eq '$' ) {
      $pattern = substr( $pattern, 0, -1 ) . '\.' . $extension . '$';
    } else {
      $pattern .= '\.' . $extension;
    }
    $self -> {filename_format} .= '.' . $extension;
  }
  $self -> {filename_pattern} = qr/$pattern/;


  # validate that filename_pattern will match filename_format
  my $t = sprintf $self -> {filename_format}, 1;
  die 'not matching filename_format ( ' . $self -> {filename_format} . ' ) and filename_pattern ( ' . $self -> {filename_pattern} . ' )'
    unless $t =~ m/$self->{filename_pattern}/;


  # decode filename
  $self -> {decode_filename} = $param{decode_filename} && ref $param{decode_filename} eq 'CODE'?
    $param{decode_filename}
      : sub {
        shift =~ m/$self->{filename_pattern}/?
          ( $1 . '.' . $extension,
	    hex( $1 )
	  )
            : ();
      };

  # encode filename
  $self -> {encode_filename} = $param{encode_filename} && ref $param{encode_filename} eq 'CODE'?
    $param{encode_filename}
      : sub {
        sprintf $self -> {filename_format}, shift;
      };

  die 'incorrect decode_filename and/or encode_filename'
    unless $self -> {decode_filename}( $self -> {encode_filename}( 1 ) ) == 1;


=item * max_tries

Defines how many times renaming of the file is tried before it is considered failed.

Default value is 5.

=cut

  # max_tries for renaming
  $self -> {max_tries} = $param{max_tries} && $param{max_tries} =~ m/^(\d+)$/?
    $1
      : MAX_TRIES;


=item * very_first_init

Defines reference to a function for generating very first serialno value in case there are no matching files in the directory.

The possible values:

=over 6

=item * CURRENT_UNIXTIME

use current unixtime as a starting value.

  FTN::Message::serialno::File -> new( directory => '/some/dir',
                                       very_first_init => 'CURRENT_UNIXTIME',
                                     );  
  

=item * CURRENT_UNIXTIME_MINUS_3_YEARS

use current unixtime minus 3 years as a starting value.

=item * user defined function

  FTN::Message::serialno::File -> new( directory => '/some/dir',
                                       very_first_init => sub {
                                         42; # voices in my head tell me to use 42
                                       },
                                     );  

=back

Default value is function returning 1.

=cut

  # very_first_init
  if ( $param{very_first_init} ) {
    if ( ref $param{very_first_init} eq 'CODE' ) {
      $self -> {very_first_init} = $param{very_first_init};
    } elsif ( $param{very_first_init} eq 'CURRENT_UNIXTIME_MINUS_3_YEARS' ) {
      $self -> {very_first_init} = sub { time - 3 * 365 * 24 * 60 * 60 };
    } elsif ( $param{very_first_init} eq 'CURRENT_UNIXTIME' ) {
      $self -> {very_first_init} = sub { time; };
    }
  }

  $self -> {very_first_init} = sub { 1; }
    unless $self -> {very_first_init};

=item * serialno_format

serialno format (as in printf) for a return value.  Can be changed in case you want another casing ('%08X') or no leading zeroes ('%x') for example.

Default value is '%08x'.

=back

=cut

  $self -> {serialno_format} = $param{serialno_format} || SERIALNO_FORMAT;
}


sub new {
  ref( my $class = shift ) and Carp::croak 'I am only a class method!';

  my $self = $class -> SUPER::new( @_ );

  _initialize( $self, @_ );      # not $self -> _initialize!

  $self;
}


=head2 get_serialno()

Method that does all the work and returns either new valid serialno value or undef.

If this is the very first run and no signs of previous serialno values, creates new file with starting value and returns it.

If there is just one file with previous serialno value, tries to rename it to a new value (up to defined value (constructor option) times due to parallel execution) and returns that new value on success.

If there are more than one file with previous serialno values, sorts them and removes all but last one.  Then tries previous approach with last value.

If renaming fails more than allowed count, undef is returned.

=cut

sub get_serialno {
  ref( my $self = shift ) or Carp::croak 'I am only an object method!';

  my $try = 1;
  my $new_serialno;

  {
    opendir my $dh, $self -> {directory}
      or die "can't opendir $self->{directory}: $!";

    my @found_file = sort { $a -> [ 1 ] <=> $b -> [ 1 ] }
      map {
        my $filename = $_;
        my @r;

        my @t = $self -> {decode_filename}( $filename );

        if ( @t ) {
          # my $full_name = $self -> _full_filename( $filename );  tainted on win
          my $full_name = $self -> _full_filename( $t[ 0 ] );

          push @r,
            [ $full_name,
              $t[ 1 ],
            ]
              if -f $full_name;
        }

        @r;
      } readdir $dh;

    closedir $dh;

    if ( @found_file ) {
      # as old numbers can be deleted by other process, we don't care about errors here, so let's do it in one shot
      unlink map $_ -> [ 0 ],
        splice @found_file, 0, -1
          if @found_file > 1;

      # here we try to rename
      my $new_id = ( $found_file[ 0 ][ 1 ] + 1 ) & 0xffffffff;
      my $new_file = $self -> _full_filename( $self -> {encode_filename}( $new_id ) );

      if ( rename $found_file[ 0 ][ 0 ], $new_file ) {
	$new_serialno = sprintf $self -> {serialno_format}, $new_id;
      } else {                  # might be a parallel request
        redo if $try++ < $self -> {max_tries};
      }
    } else { # nothing in found_file.  must be the very first run.  create new file and return id
      my $id = $self -> {very_first_init}();

      my $fn = $self -> _full_filename( $self -> {encode_filename}( $id ) );
      open my $fh, '>', $fn
        or die 'cannot create file ' . $fn . ': ' . $!;
      print $fh $id;            # save start value there for a history
      close $fh;

      $new_serialno = sprintf $self -> {serialno_format}, $id;
    }
  }

  $new_serialno;
}


sub _full_filename {
  ref( my $self = shift ) or Carp::croak 'I am only an object method!';

  my $filename = shift;

  File::Spec -> catfile( $self -> {directory},
                         $filename,
                       );
}

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-message-serialno-file at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Message-serialno-File>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::Message::serialno::File


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-Message-serialno-File>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FTN-Message-serialno-File>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FTN-Message-serialno-File>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-Message-serialno-File/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Valery Kalesnik.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
