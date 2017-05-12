use strict;
use warnings;
use utf8;

package FTN::Outbound::Reference_file;
$FTN::Outbound::Reference_file::VERSION = '20170409';

# fts-5005.002  BinkleyTerm Style Outbound

# Reference files consist of a number of lines (terminated by 0x0a or 0x0d,0x0a) each consisting of the name of the file to transfer to the remote system.

use Log::Log4perl ();
use Encode::Locale ();
use Encode ();

# use File::Basename ();


my @line_joiner = ( "\x0a",
                    "\x0d\x0a",
                  );

my $prefix_re = qr/[-#^~!@]/;   # fts-5005.002

=head1 NAME

FTN::Outbound::Reference_file - Object-oriented module for working with FTN reference files.

=head1 VERSION

version 20170409

=head1 SYNOPSIS

  use Log::Log4perl ();
  use Encode ();
  use FTN::Outbound::Reference_file ();

  Log::Log4perl -> easy_init( $Log::Log4perl::INFO );

  my $reference_file = FTN::Outbound::Reference_file -> new( '/var/lib/ftn/outbound/fidonet/00010001.flo',
                                                             sub {
                                                               Encode::decode( 'cp866', shift );
                                                             },
                                                             sub {
                                                               Encode::encode( 'cp866', shift );
                                                             },
                                                             "\x0d\x0a",
                                                           );

  $reference_file
    -> read_existing_file
    -> push_reference( '#', '/tmp/file_to_transfer' )
    -> write_file;

=head1 DESCRIPTION

FTN::Outbound::Reference_file module is for working with reference files in FTN following specifications from fts-5005.002 document.

=head1 OBJECT CREATION

=head2 new

  my $reference_file = FTN::Outbound::Reference_file -> new( 'filename',
                                                             sub {
                                                               Encode::decode( 'UTF-8', shift );
                                                             },
                                                             sub {
                                                               Encode::encode( 'UTF-8', shift );
                                                             },
                                                             chr( 0x0a ),
                                                           );

First parameter is a filename as a character string.

Second parameter is either undef (in case no reading from the file expected (means file does not exist)) or sub reference that takes octet string (read from the existing reference file) and returns character string.  In simplest case does just decoding from some predefined character set used by your software.  Also might do other transformations.  For example if other software uses relative path, this is the place where you transform it to absolute path by some rules.  Output result used only in memory processing and won't be written to the file.

Third parameter is either undef (in case no updates expected) or sub reference that takes character string and returns octet stream that will be written to the file.  Used only by push_reference method.

Forth parameter defines line joiner as standard allows two of them.  If not defined or omitted will be either figured out from existing file (if possible) or character with code 0x0a will be used.

=cut

sub new {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $class = shift ) and $logger -> logcroak( "I'm only a class method!" );

  my ( $reference_file,
       $reference_file_read_line_transform_sub,
       $reference_file_write_line_transform_sub,
       $line_joiner,
     ) = @_;

  $logger -> logdie( 'reference file name cannot be undefined' )
    unless defined $reference_file;

  $logger -> debug( sprintf 'reference file name %s',
                    $reference_file,
                  );

  my %self = ( reference_file => $reference_file );

  $logger -> logdie( 'not valid reference file read line transform subroutine reference was passed as second argument' )
    if defined $reference_file_read_line_transform_sub
    && ref $reference_file_read_line_transform_sub ne 'CODE';

  $logger -> debug( sprintf 'reference file read line transform sub reference was%s passed',
                    defined $reference_file_read_line_transform_sub ?
                    ''
                    : ' not'
                  );

  $self{reference_file_read_line_transform_sub} = $reference_file_read_line_transform_sub
    if defined $reference_file_read_line_transform_sub;

  $logger -> logdie( 'not valid reference file write line transform subroutine reference was passed as third argument' )
    if defined $reference_file_write_line_transform_sub
    && ref $reference_file_write_line_transform_sub ne 'CODE';

  $logger -> debug( sprintf 'reference file write line transform sub reference was%s passed',
                    defined $reference_file_write_line_transform_sub ?
                    ''
                    : ' not'
                  );

  $self{reference_file_write_line_transform_sub} = $reference_file_write_line_transform_sub
    if defined $reference_file_write_line_transform_sub;

  if ( defined $line_joiner ) {
    $logger -> logdie( 'incorrect line joiner: ', $line_joiner )
      unless grep $line_joiner eq $_, @line_joiner;

    $self{line_joiner} = $line_joiner;
  } else {
    $logger -> debug( 'line joiner undefined' );
  }

  bless \ %self, $class;
}

sub _file_info {
  my $filename = shift;
  my $hashref = shift;

  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  $hashref -> {full_name} = $filename;
  # $hashref -> {name} = File::Basename::basename( $filename );

  if ( -e Encode::encode( locale_fs => $filename ) ) {
    if ( -f _ ) {
      $hashref -> {size} = -s _;
      $hashref -> {mstat} = ( stat _ )[ 9 ];
    } else {
      $logger -> warn( sprintf 'referenced file %s is not actually a file',
                       $filename,
                     );
    }
  } else {
    $logger -> warn( sprintf 'referenced file %s does not exist',
                     $filename,
                   );
  }
}

=head1 FILE READ/WRITE

=head2 read_existing_file

Method for explicit reading of existing file.  If file exists, this method has not been called and you're trying to update or write file it will be called implicitly before that.

Does not expect any arguments.

If file exists and isn't empty it will be read and each line will be passed to the sub reference which was passed as second parameter to the constructor.

Returns itself for method chaining.

=cut

sub read_existing_file {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $reference_file_fs = Encode::encode( locale_fs => $self -> {reference_file} );

  if ( -e $reference_file_fs ) {
    $logger -> logdie( sprintf '% is not a file',
                       $self -> {reference_file}
                     )
      unless -f _;

    if ( -s _ ) {               # non empty file
      $logger -> logdie( 'reference file exists, but reference file read line transform subroutine reference needed for reading its content was not provided to constructor' )
        unless exists $self -> {reference_file_read_line_transform_sub};

      $logger -> logdie( sprintf 'reference file %s is not readable',
                         $self -> {reference_file},
                       )
        unless -r _;

      open my $fh, '<', $reference_file_fs
        or $logger -> logdie( sprintf 'cannot open file %s for reading: %s',
                              $self -> {reference_file},
                              $!,
                            );
      binmode $fh;

      my $read_result = read $fh, ( my $t ), -s _;

      $logger -> logdie( sprintf 'reading from %s failed: %s',
                         $self -> {reference_file},
                         $!,
                       )
        unless defined $read_result;

      $logger -> logdie( sprintf 'errors while reading %s: expected to read %d bytes, but read %d',
                         $self -> {reference_file},
                         -s _,
                         $read_result,
                       )
        unless $read_result == -s _;

      $self -> {line_joiner} = $line_joiner[ 1 ]
        unless exists $self -> {line_joiner}
        || -1 == index $t, $line_joiner[ 1 ];

      for my $l ( split /\x0d?\x0a/, $t ) { # Reference files consist of a number of lines (terminated by 0x0a or 0x0d,0x0a) each consisting of the name of the file to transfer to the remote system.
        $logger -> debug( sprintf 'read octet line from reference file: %s',
                          $l,
                        );

        my %referenced_file = ( octet_line_in_reference_file => $l,
                                character_line_in_reference_file => $self -> {reference_file_read_line_transform_sub} -> ( $l ),
                              );

        my $full_name = $referenced_file{character_line_in_reference_file};
        $referenced_file{prefix} = $1
          if $full_name =~ s/^($prefix_re)//; # fts-5005.002

        _file_info( $full_name, \ %referenced_file );

        push @{ $self -> {referenced_files} },
          \ %referenced_file;
      }
      close $fh;
    } else {                    # file is empty
      $self -> {referenced_files} = [];
    }
  } else {                      # file does not exist
    $self -> {referenced_files} = [];
  }

  $self;
}

=head2 write_file

Method for writing content from memory to the file.  Does not need any parameters.
If file exists and its content in memory is empty, it will be deleted.

Returns itself for method chaining.

=cut

sub write_file {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $self -> read_existing_file
    unless exists $self -> {referenced_files};

  my $reference_file_fs = Encode::encode( locale_fs => $self -> {reference_file} );

  if ( @{ $self -> {referenced_files} } ) { # update the file
    # simple overwriting for now.  later try File::Temp for new file and then File::Copy::move for moving over existing one
    my $line_joiner = exists $self -> {line_joiner} ?
      $self -> {line_joiner}
      : $line_joiner[ 0 ];

    open my $fh, '>', $reference_file_fs
      or $logger -> logdie( sprintf 'cannot open %s: %s',
                            $self -> {reference_file},
                            $!,
                          );

    binmode $fh;

    print $fh join $line_joiner,
      map $_ -> {octet_line_in_reference_file},
      @{ $self -> {referenced_files} };

    close $fh;

  } elsif ( -e $reference_file_fs ) { # remove the file as it's empty
    $logger -> debug( 'removing empty ', $self -> {reference_file} );

    unlink $self -> {reference_file}
      or $logger -> logdie( sprintf 'could not unlink %s: %s',
                            $self -> {reference_file},
                            $!,
                          );
  }

  $self;
}

=head1 CONTENT ACCESS

=head2 referenced_files

Returns list of hash references describing referenced files in list content.
In scalar content returns array reference.

Each hash has fields:

  octet_line_in_reference_file - original line from the file or result returned by third parameter (sub reference) for constructor during push_reference method call.  This is the value that will be written by write_file method call

  character_line_in_reference_file - line that was returned by second parameter (sub reference) for constructor during existing file read or possibly prefixed second argument for push_reference

  full_name - character line without prefix

There might be other fields:

  prefix - if there is one

  size - size in bytes if file existed during read_existing_file or push_reference method call

  mstat - last modify time in seconds since the epoch if file existed during read_existing_file or push_reference method call

=cut

sub referenced_files {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $self -> read_existing_file
    unless exists $self -> {referenced_files};

  wantarray ?
    @{ $self -> {referenced_files} }
    : $self -> {referenced_files};
}

=head1 CONTENT MODIFICATION

=head2 process_lines

Method expects one parameter - function reference.  That function will be called for each line in reference file with one parameter - hash reference with all details about the referenced file.
Function can change/update fields - they are actual values, not a copy.

Function return value is very important.
If it is false then this line will be removed from the memory and after write_file call from the actual file.
If return value is true then line stays.

Method returns number of lines removed.

=cut

sub process_lines {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $sub_ref = shift; # gets line hash ref and should return boolean (keep the line or not)

  $logger -> logdie( 'not valid condition subroutine reference was passed' )
    unless defined $sub_ref
    && ref $sub_ref eq 'CODE';

  $self -> read_existing_file
    unless exists $self -> {referenced_files};

  my @idx_to_remove = grep ! $sub_ref -> ( $self -> {referenced_files}[ $_ ] ),
    0 .. $#{ $self -> {referenced_files} };

  for ( reverse @idx_to_remove ) {
    $logger -> info( sprintf 'remove %s from %s',
                     $self -> {referenced_files}[ $_ ]{full_name},
                     $self -> {reference_file},
                   );
    splice @{ $self -> {referenced_files} }, $_, 1;
  }

  scalar @idx_to_remove;
}

=head2 push_reference

Expects referenced filename as a character string.  If prefix [-#^~!@] needed, it should be defined as first parameter and filename as second parameter.

Returns itself for method chaining.

=cut

sub push_reference {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( 'reference file write line transform subroutine reference needed for update was not passed to constructor' )
    unless exists $self -> {reference_file_write_line_transform_sub};

  $self -> read_existing_file
    unless exists $self -> {referenced_files};

  my ( $prefix, $filename ) = ( @_ == 1 ? undef : (),
                                @_,
                              );

  $logger -> logdie( 'Incorrect prefix: ' . $prefix )
    if defined $prefix
    && $prefix !~ m/$prefix_re/;

  my %new;

  _file_info( $filename, \ %new );

  if ( defined $prefix ) {
    $new{prefix} = $prefix;
    $new{character_line_in_reference_file} = $prefix . $filename;
  } else {
    $new{character_line_in_reference_file} = $filename;
  }
  $new{octet_line_in_reference_file} = $self -> {reference_file_write_line_transform_sub} -> ( $new{character_line_in_reference_file} );

  push @{ $self -> {referenced_files} },
    \ %new;

  $self;
}

1;
