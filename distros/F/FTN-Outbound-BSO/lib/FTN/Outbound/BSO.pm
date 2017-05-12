use strict;
use warnings;
use utf8;

package FTN::Outbound::BSO;
$FTN::Outbound::BSO::VERSION = '20160516';
# fts-5005.002  BinkleyTerm Style Outbound
# except s/Continuous/Crash/g

use Log::Log4perl ();
use Scalar::Util ();
use Encode::Locale ();
use Encode ();
use File::Spec ();
use Fcntl ();
use FTN::Addr ();
use FTN::Outbound::Reference_file ();

my %flavour_extension = ( immediate =>  [ qw/ iut ilo / ], # Xut (netmail) Xlo (reference file) by fts-5005.002
                          # continuous => [ qw/ c c / ], # except this one
                          crash =>      [ qw/ cut clo / ],
                          direct =>     [ qw/ dut dlo / ],
                          normal =>     [ qw/ out flo / ],
                          hold =>       [ qw/ hut hlo / ],
                        );
# Reference files consist of a number of lines (terminated by 0x0a or 0x0d,0x0a) each consisting of the name of the file to transfer to the remote system.

# file_type => extension.  both keys and values should be unique in their sets
# content notes are from fts-5005.002
my %control_file_extension = ( file_request => 'req', # file requests
                               # The format of request files is documented in FTS-0006.
                               busy => 'bsy', # busy control file.
                               # may contain one line of PID information (less than 70 characters).
                               call => 'csy', # call control file
                               # may contain one line of PID information (less than 70 characters).
                               hold => 'hld', # hold control file
                               # must contain a one line string with the expiration of the hold period expressed in UNIX-time.
                               # the second line of an hld file may contain one line of PID information. (Less than 70 characters)
                               try => 'try', # try control file
                               # A try file must contain one line string with a diagnostic message.  It is for information purposes only.
                               # the second line of a try file may contain one line of PID information. ( < 70 characters)
                             );

=head1 NAME

FTN::Outbound::BSO - Object-oriented module for working with BinkleyTerm Style Outbound.

=head1 VERSION

version 20160516

=head1 SYNOPSIS

  use Log::Log4perl ();
  use Encode ();
  use FTN::Outbound::BSO ();

  Log::Log4perl -> easy_init( $Log::Log4perl::INFO );

  my $bso = FTN::Outbound::BSO -> new( outbound_root => '/var/lib/ftn/outbound',
                                       domain => 'fidonet',
                                       zone => 2,
                                       domain_abbrev => { fidonet => '_out',
                                                          homenet => 'leftnet',
                                                        },
                                       maximum_session_time => 3600, # one hour
                                     ) or die 'cannot create bso object';

  my $addr = FTN::Addr -> new( '2:451/30' );

  sub poll {
    my $addr = shift;
    my $bso = shift;

    my $flo = $bso -> addr_file_to_change( $addr,
                                           'reference_file',
                                           'normal'
                                         );

    open my $fh, '>>', $flo
      or die sprintf 'cannot open %s: %s', $flo, $!;

    print $fh '';

    close $fh;
  }

  $bso -> busy_protected_sub( $addr,
                              \ &poll,
                            );

=head1 DESCRIPTION

FTN::Outbound::BSO module is for working with BinkleyTerm Style Outbound in FTN following specifications from fts-5005.002 document.  Figuring out correct file to process might be a tricky process: different casing, few our main domains, other differences.  This module helps with this task.

=head1 OBJECT CREATION

=head2 new

Expects parameters as hash:

  outbound_root - directory path as a character string where whole outbound is located.  Mandatory parameter.  This directory should exist.

By standard constructor needs our domain and zone.  They can be provided as:

  our_addr - either FTN::Addr object representing our address or our address as a string which will be passed to FTN::Addr constructor.

or as a pair:

  domain - domain part of our address as described in frl-1028.002.
  zone - our zone in that domain

At least one of the ways should be provided.  In case both are our_addr has higher priority.

  domain_abbrev - hash reference where keys are known domains and values are directory names (without extension) in outbound_root for those domains.  Mandatory parameter.

  reference_file_read_line_transform_sub - reference to a function that receives an octet string and returns a character string.  Will be passed to FTN::Outbound::Reference_file constructor.  If not provided reference file content won't be processed.

  maximum_session_time - maximum session time in seconds.  If provided, all found busy files older than 2 * value will be removed during outbound scan.

Returns newly created object on success.

=cut

sub new {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $class = shift ) and $logger -> logcroak( "I'm only a class method!" );

  return
    unless @_;

  $logger -> logdie( sprintf 'constructor expects even number of arguments, but received %d of them',
                     scalar @_,
                   )
    if @_ % 2;

  my %option = @_;
  my %self;

  # validating
  # mandatory parameters
  $logger -> logdie( 'mandatory outbound_root is not provided' )
    unless exists $option{outbound_root};

  # outbound_root
  my $outbound_root_fs = Encode::encode( locale_fs => $option{outbound_root} );

  unless ( -e $outbound_root_fs ) {
    $logger -> warn( sprintf 'outbound_root (%s) directory does not exist',
                     $option{outbound_root},
                   );

    return;
  }

  unless ( -d _ ) {            # if it exists it should be a directory
    $logger -> warn( sprintf 'outbound_root (%s) does not point to the directory',
                     $option{outbound_root},
                   );

    return;
  }

  $self{outbound_root} = $option{outbound_root};
  $self{outbound_root_fs} = $outbound_root_fs;


  # our_addr or ( domain + zone )
  if ( exists $option{our_addr}
       && $option{our_addr}
     ) {
    if ( ref $option{our_addr}
         && Scalar::Util::blessed $option{our_addr}
         && $option{our_addr} -> isa( 'FTN::Addr' )
       ) {
      $self{our_addr} = $option{our_addr};
    } else {
      $self{our_addr} = FTN::Addr -> new( $option{our_addr} )
        or $logger -> logdie( sprintf 'incorrect value of our_addr: %s',
                              $option{our_addr},
                            );
    }
    $self{domain} = $self{our_addr} -> domain;
    $self{zone} = $self{our_addr} -> zone;
  } else {
    $logger -> logdie( 'domain is not provided' )
      unless exists $option{domain}
      && $option{domain};

    $logger -> logdie( sprintf 'domain (%s) is not valid',
                       $option{domain},
                     )
      unless $option{domain} =~ m/^[a-z\d_~-]{1,8}$/; # frl-1028.002

    $logger -> logdie( 'zone is not provided' )
      unless exists $option{zone}
      && $option{zone};

    $logger -> logdie( sprintf 'zone (%s) is not valid',
                       $option{zone},
                     )
      unless $option{zone} =~ m/^\d+$/ # FRL-1002.001, frl-1028.002
      && 1 <= $option{zone}            # FRL-1002.001, frl-1028.002
      && $option{zone} <= 32767;       # FRL-1002.001, frl-1028.002

    $self{domain} = $option{domain};
    $self{zone} = $option{zone};
  }

  # domain abbreviations
  if ( exists $option{domain_abbrev}
       && defined $option{domain_abbrev}
       && ref $option{domain_abbrev} eq 'HASH'
     ) {
    $logger -> logdie( sprintf 'our domain (%s) is not in the passed domain_abbrev hash!',
                       $self{domain},
                     )
      unless exists $option{domain_abbrev}{ $self{domain} };

    $self{domain_abbrev} = $option{domain_abbrev};
  } else {
    $logger -> logdie( 'no valid domain_abbrev provided' );
  }

  # reference file read line transform sub
  if ( exists $option{reference_file_read_line_transform_sub} ) {
    $logger -> logdie( 'incorrect value of reference_file_read_line_transform_sub (should be a sub reference)' )
      unless defined $option{reference_file_read_line_transform_sub}
      && 'CODE' eq ref $option{reference_file_read_line_transform_sub};

    $self{reference_file_read_line_transform_sub} = $option{reference_file_read_line_transform_sub};
  }

  # maximum_session_time
  if ( exists $option{maximum_session_time} ) {
    $logger -> logdie( sprintf 'incorrect value of maximum_session_time: %s',
                       defined $option{maximum_session_time} ?
                       $option{maximum_session_time}
                       : 'undef'
                     )
      unless defined $option{maximum_session_time}
      && $option{maximum_session_time} =~ m/^\d+$/
      && $option{maximum_session_time}; # cannot be 0

    $self{maximum_session_time} = $option{maximum_session_time};
  }

  bless \ %self, $class;
}

sub _store {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my ( $file_prop,
       $ext,
       $target,
       $net,
       $node,
       $point,
     ) = @_;

  my %ext_netmail_flavour = map { $flavour_extension{ $_ }[ 0 ] => $_ } keys %flavour_extension;
  my %ext_reference_file_flavour = map { $flavour_extension{ $_ }[ 1 ] => $_ } keys %flavour_extension;
  my %ext_control_file = reverse %control_file_extension;

  my $lc_ext = lc $ext;

  if ( exists $ext_netmail_flavour{ $lc_ext } ) { # netmail
    push @{ $target -> { $net }{ $node }{ $point }{netmail}{ $ext_netmail_flavour{ $lc_ext } } },
      $file_prop;
  } elsif ( exists $ext_reference_file_flavour{ $lc_ext } ) { # reference file
    my $flavour = $ext_reference_file_flavour{ $lc_ext };
    # referenced files
    if ( $file_prop -> {size}   # empty files are empty, right?
         && exists $self -> {reference_file_read_line_transform_sub}
       ) {
      $file_prop -> {referenced_files} =
        FTN::Outbound::Reference_file
          -> new( $file_prop -> {full_name},
                  $self -> {reference_file_read_line_transform_sub},
                )
          -> read_existing_file
          -> referenced_files;
    }

    push @{ $target -> { $net }{ $node }{ $point }{reference_file}{ $flavour } },
      $file_prop;
  } elsif ( exists $ext_control_file{ $lc_ext } ) {
    my $age = $file_prop -> {mstat} ? time - $file_prop -> {mstat} : 0;
    if ( $ext_control_file{ $lc_ext } eq 'busy'
         && exists $self -> {maximum_session_time}
         && $self -> {maximum_session_time} * 2 < $age
       ) { # try to remove if maximum_session_time is defined and busy is older than it
      $logger -> info( sprintf 'removing expired busy %s (%d seconds old)',
                       $file_prop -> {full_name},
                       $age,
                     );

      unlink Encode::encode( locale_fs => $file_prop -> {full_name} )
        or $logger -> logdie( sprintf 'could not unlink %s: %s',
                              $file_prop -> {full_name},
                              $!,
                            );
    } else {
      push @{ $target -> { $net }{ $node }{ $point }{ $ext_control_file{ $lc_ext } } },
        $file_prop;
    }
  }
}

=head1 OBJECT METHODS

=head2 scan

Scans outbound for all known domains.  Old busy files might be removed.

Returns itself for chaining.

=cut

sub scan {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $logger -> logdie( sprintf 'outbound_root (%s) directory does not exist',
                     $self -> {outbound_root},
                   )
    unless -e $self -> {outbound_root_fs};

  # if it exists it should be a directory
  $logger -> logdie( sprintf 'outbound_root (%s) does not point to the directory',
                     $self -> {outbound_root},
                   )
    unless -d _;

  # check outbound_root for all domain abbrevs and zones
  my $domain_abbr_re = join '|', values %{ $self -> {domain_abbrev} };
  my %result;

  opendir my $or_dh, $self -> {outbound_root_fs}
    or $logger -> logdie( sprintf 'cannot opendir %s: %s',
                          $self -> {outbound_root},
                          $!,
                        );

  while ( my $dz_out = readdir $or_dh ) { # looking for domain abbreviations directories
    $dz_out = Encode::decode( locale_fs => $dz_out );

    next                        # skipping hidden files and ..
      if '.' eq substr $dz_out, 0, 1;

    my $dir_name = File::Spec -> catdir( $self -> {outbound_root},
                                         $dz_out,
                                       );

    my $dir_name_fs = Encode::encode( locale_fs => $dir_name );

    next                        # looking only for directories
      unless -d $dir_name_fs;

    # our_domain_dir, our_domain_dir.9999, other_domain.9999
    next
      unless $dz_out =~ /^($domain_abbr_re)(?:\.([1-7]?[0-9a-f]{3}))?$/i
      && ( $1 eq $self -> {domain_abbrev}{ $self -> {domain} }
           || defined $2
         );

    my ( $domain ) = grep $self -> {domain_abbrev}{ $_ } eq $1,
      keys %{ $self -> {domain_abbrev} };

    my $zone = defined $2 ? hex $2 : $self -> {zone};

    next
      unless 1 <= $zone && $zone <= 32767; # FRL-1002.001, frl-1028.002

    $logger -> debug( sprintf 'directory %s matches.  domain: %s  zone: %s',
                      $dz_out,
                      $domain,
                      $zone,
                    );

    $result{ $domain }{ $zone }{ $dz_out }{dir} = $dir_name;

    # now let's traverse found domain_abbrev[.zone] dir
    opendir my $dz_dh, $dir_name_fs
      or $logger -> logdie( sprintf 'cannot opendir %s: %s',
                            $dir_name,
                            $!,
                          );

    while ( readdir $dz_dh ) {
      $_ = Encode::decode( locale_fs => $_ );

      next
        unless m/^([0-9a-f]{4})([0-9a-f]{4})\.(.+)$/i;

      my ( $net, $node ) = map hex, $1, $2;
      my $ext = $3;

      my $full_name = File::Spec -> catfile( $dir_name,
                                             $_,
                                           );

      my $full_name_fs = Encode::encode( locale_fs => $full_name );

      if ( lc( $ext ) eq 'pnt'
           && -d $full_name_fs
         ) {                    # points subdir
        $logger -> debug( sprintf 'found %s#%d:%d/%d points subdirectory %s',
                          $domain,
                          $zone,
                          $net,
                          $node,
                          $full_name,
                        );

        $result{ $domain }{ $zone }{ $dz_out }{ $net }{ $node }{points_dir}{ $_ } = $full_name; # might be different hex casing for net/node or extension

        opendir my $p_dh, $full_name_fs
          or $logger -> logdie( sprintf 'cannot opendir %s: %s',
                                $full_name,
                                $!,
                              );

        while ( my $file = readdir $p_dh ) {
          $file = Encode::decode( locale_fs => $file );

          next
            unless $file =~ m/^([0-9a-f]{8})\.(.+)$/i;

          my $point = hex $1;
          my $ext = $2;

          my $full_name = File::Spec -> catfile( $full_name,
                                                 $file,
                                               );

          next          # in points dir we're interested in files only
            unless -f Encode::encode( locale_fs => $full_name );

          $self -> _store( { name => $file,
                             full_name => $full_name,
                             size => -s _,
                             mstat => ( stat _ )[ 9 ],
                           },
                           $ext,
                           $result{ $domain }{ $zone }{ $dz_out },
                           $net,
                           $node,
                           $point,
                         );
        }
        closedir $p_dh;
      } elsif ( -f $full_name_fs ) { # node related file
        $self -> _store( { name => $_,
                           full_name => $full_name,
                           size => -s _,
                           mstat => ( stat _ )[ 9 ],
                         },
                         $ext,
                         $result{ $domain }{ $zone }{ $dz_out },
                         $net,
                         $node,
                         0,     # point
                       );
      }
    }
    closedir $dz_dh;

  }
  closedir $or_dh;

  $self -> {scanned} = \ %result;

  $self;
}

=head2 scanned_hash

Returns internal structure representing scanned outbound (hash in list context, hashref in scalar context).  If scan method hasn't been called, it will be called implicitly by this method.

=cut

sub scanned_hash {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  $self -> scan
    unless exists $self -> {scanned};

  wantarray ?
    %{ $self -> {scanned} }
    : $self -> {scanned};
}


sub _validate_addr {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $addr = shift;

  $logger -> logdie( 'no valid address passed' )
    unless defined $addr
    && ref $addr
    && Scalar::Util::blessed $addr
    && $addr -> isa( 'FTN::Addr' );

  $logger -> logdie( 'passed address has unknown domain: %s',
                     $addr -> domain,
                   )
    unless exists $self -> {domain_abbrev}{ $addr -> domain };

  $addr;
}

=head2 is_busy

Expects one parameter - address as FTN::Addr object.  Returns true if that address is busy (connection session, mail processing, ...).

=cut

sub is_busy {
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $addr = $self -> _validate_addr( shift );

  $self -> scan
    unless exists $self -> {scanned};

  exists $self -> {scanned}{ $addr -> domain }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }
    && grep exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }{busy},
    keys %{ $self -> {scanned}{ $addr -> domain }{ $addr -> zone } };
}

sub _select_domain_zone_dir { # best one.  for updating.  for checking need a list (another method or direct access to the structure)
                              # and make it if it doesn't exist or isn't good enough (e.g. our_domain_abbr.our_zone)
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $domain = shift;
  my $zone = shift;

  $logger -> logdie( 'unknown domain: %s',
                     $domain,
                   )
    unless exists $self -> {domain_abbrev}{ $domain };

  my $best_match = $self -> {domain_abbrev}{ $domain };

  $best_match .= sprintf( '.%03x', $zone )
    unless $domain eq $self -> {domain}
    && $zone == $self -> {zone};

  $self -> scan
    unless exists $self -> {scanned};

  if ( exists $self -> {scanned}{ $domain }
       && exists $self -> {scanned}{ $domain }{ $zone }
       && ( $domain ne $self -> {domain} # other domains have zones in extensions
            || $zone != $self -> {zone} # other zones in our domain have zones in extensions
            || grep length( $_ ) == length( $best_match ),
            keys %{ $self -> {scanned}{ $domain }{ $zone } }
          )
     ) {
    my @list = sort { length $a <=> length $b }
      keys %{ $self -> {scanned}{ $domain }{ $zone } };

    my ( $t ) = grep $_ eq $best_match, @list; # might be exact case

    $best_match = defined $t ?
      $t
      : $list[ 0 ]; # if didn't find the best match, use very first existing
  } else {          # need to create
    my $dir_full_name = File::Spec -> catdir( $self -> {outbound_root},
                                              $best_match,
                                            );

    $logger -> debug( sprintf 'creating directory for domain %s zone %d: %s',
                      $domain,
                      $zone,
                      $dir_full_name,
                    );

    mkdir Encode::encode( locale_fs => $dir_full_name )
      or $logger -> logdie( sprintf 'cannot create domain/zone %s directory: %s',
                            $dir_full_name,
                            $!,
                          );

    $self -> {scanned}{ $domain }{ $zone }{ $best_match }{dir} = $dir_full_name;
  }

  # $self -> {scanned}{ $domain }{ $zone }{ $best_match }{dir};
  $best_match;
}

sub _select_points_dir { # select best existing.  or make it.  for updating
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my ( $domain,
       $zone,
       $net,
       $node,
     ) = @_;

  $logger -> logdie( 'unknown domain: %s',
                     $domain,
                   )
    unless exists $self -> {domain_abbrev}{ $domain };

  # domain zone dir might not exist at all
  my $dz_out = $self -> _select_domain_zone_dir( $domain, $zone );
  my $points_dir = sprintf( '%04x%04x.pnt',
                            $net,
                            $node,
                          );

  # what if other_domain_abbr.zone (perfect one) doesn't have required points dir
  # but other_domain_abbr.zOnE has?
  my @dz_out_with_existing_points_dir = grep exists $self -> {scanned}{ $domain }{ $zone }{ $_ }{ $net }
    && exists $self -> {scanned}{ $domain }{ $zone }{ $_ }{ $net }{ $node }
    && exists $self -> {scanned}{ $domain }{ $zone }{ $_ }{ $net }{ $node }{points_dir},
    grep length $_ == length $dz_out, # to filter out our_domain.our_zone versions
    keys %{ $self -> {scanned}{ $domain }{ $zone } };

  if ( @dz_out_with_existing_points_dir ) { # ok, there is at least one with points dir.  how do we select best of them?
    # let's prioritize domain_abbr[.zone] betterness over points_dir betterness
    unless ( grep $_ eq $dz_out,
             @dz_out_with_existing_points_dir
           ) { # ok, there is no best domain_abbr[.zone].  let's try to find best points_dir
      my ( $t ) = grep exists $self -> {scanned}{ $domain }{ $zone }{ $_ }{ $net }{ $node }{points_dir}{ $points_dir },
        @dz_out_with_existing_points_dir;

      $dz_out = defined $t ? $t : $dz_out_with_existing_points_dir[ 0 ]; # if no best in either place, just use very first one
    }

    # now we've got best outbound.  let's find best points dir.  or just very first
    $points_dir = ( keys %{ $self -> {scanned}{ $domain }{ $zone }{ $dz_out }{ $net }{ $node }{points_dir} } )[ 0 ]
      unless exists $self -> {scanned}{ $domain }{ $zone }{ $dz_out }{ $net }{ $node }{points_dir}{ $points_dir };

  } else { # doesn't exist.  we need to create it using best domain_abbr[.zone] dir
    my $dir_full_name = File::Spec -> catdir( $self -> {scanned}{ $domain }{ $zone }{ $dz_out }{dir},
                                              $points_dir,
                                            );

    $logger -> debug( sprintf 'creating %s#%d:%d/%d points directory %s',
                      $domain,
                      $zone,
                      $net,
                      $node,
                      $dir_full_name,
                    );

    mkdir Encode::encode( locale_fs => $dir_full_name )
      or $logger -> logdie( sprintf 'cannot create points directory %s: %s',
                            $dir_full_name,
                            $!,
                          );

    $self -> {scanned}{ $domain }{ $zone }{ $dz_out }{ $net }{ $node }{points_dir}{ $points_dir } = $dir_full_name;
  }

  # return ( dz_out, $points_dir) or full points directory path?
  $self -> {scanned}{ $domain }{ $zone }{ $dz_out }{ $net }{ $node }{points_dir}{ $points_dir };
}

=head2 busy_protected_sub

Expects two parameters:

  address going to be dealt with as a FTN::Addr object

  function reference that will receive passed address and us ($self) as parameters and which should do all required operations related to the passed address.

This method infinitely waits (most likely will be changed in the future) until address is not busy.  Then it creates busy flag and calls passed function reference providing itself as an argument for it.  After function return removes created busy flag.

Returns itself for chaining.

=cut

sub busy_protected_sub { # address, sub_ref( self ).  (order busy, execute sub, remove busy)
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $addr = $self -> _validate_addr( shift );

  $logger -> logdie( 'no valid sub_ref passed' )
    unless @_
    && defined $_[ 0 ]
    && 'CODE' eq ref $_[ 0 ];

  my $sub_ref = shift;

  $self -> scan
    unless exists $self -> {scanned};

  # check that it's not already busy
  while ( $self -> is_busy( $addr ) ) {
    sleep( 4 );                 # blocking...
    $self -> scan;
  }

  # here there are no busy flag for passed address.  make it in best dir then
  my $busy_name;

  if ( $addr -> point ) {       # possible dir creation
    $busy_name = File::Spec -> catfile( $self -> _select_points_dir( $addr -> domain,
                                                                     $addr -> zone,
                                                                     $addr -> net,
                                                                     $addr -> node,
                                                                   ),
                                        sprintf( '%08x',
                                                 $addr -> point,
                                               ),
                                      );
  } else {
    my $dz_out = $self -> _select_domain_zone_dir( $addr -> domain,
                                                   $addr -> zone,
                                                 );

    $busy_name = File::Spec -> catfile( $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $dz_out }{dir},
                                        sprintf( '%04x%04x',
                                                 $addr -> net,
                                                 $addr -> node,
                                               ),
                                      );
  }
  $busy_name .= '.' . $control_file_extension{busy};

  my $busy_name_fs = Encode::encode( locale_fs => $busy_name );

  sysopen my $fh, $busy_name_fs, Fcntl::O_WRONLY | Fcntl::O_CREAT | Fcntl::O_EXCL
    or $logger -> logdie( 'cannot open %s for writing: %s',
                          $busy_name,
                          $!,
                        );

  flock $fh, Fcntl::LOCK_EX
    or $logger -> logdie( q[can't flock file %s: %s],
                          $busy_name,
                          $!
                        );

  # For information purposes a bsy file may contain one line of PID information (less than 70 characters).
  printf $fh '%d %s',
    $$,
    substr( __FILE__, 0, 70 - 1 - length( $$ ) );

  eval {
    $sub_ref -> ( $addr,
                  $self,
                );
  };

  # remove busy first
  close $fh;

  unlink $busy_name_fs
    or $logger -> logwarn( sprintf 'could not unlink %s: %s',
                           $busy_name,
                           $!,
                         );

  if ( $@ ) {                   # something bad happened
    $logger -> logdie( 'referenced sub execution failed: %s',
                       $@,
                     );
  }

  $self;
}

=head2 addr_file_to_change

Expects arguments:

  address going to be dealt with as a FTN::Addr object

  file type as one of netmail, reference_file, file_request, busy, call, hold, try.

  If file type is netmail or reference_file, then next parameter should be its flavour: immediate, crash, direct, normal, hold.

  If optional function reference passed, then it will be called with one parameter - name of the file to process.  After that information in internal structure about that file will be updated.

Does not deal with busy flag implicitly.  Recommended usage is in the function passed to busy_protected_sub.

Returns full name of the file to process (might not exists though).

=cut

sub addr_file_to_change { # addr, type ( netmail, file_reference, .. ), [flavour], [ sub_ref( filename ) ].
  # figures required filetype name (new or existing) and calls subref with that name.
  # does not deal with busy implicitly
  # returns full name of changed file (might not exist though)
  my $logger = Log::Log4perl -> get_logger( __PACKAGE__ );

  ref( my $self = shift ) or $logger -> logcroak( "I'm only an object method!" );

  my $addr = $self -> _validate_addr( shift );

  my @flavoured = qw/ netmail
                      reference_file
                    /;

  $logger -> logdie( 'no type passed' )
    unless @_;

  $logger -> logdie( sprintf 'incorrect type: %s',
                     defined $_[ 0 ] ? $_[ 0 ] : 'undef',
                   )
    unless defined $_[ 0 ]
    && grep $_[ 0 ] eq $_,
    @flavoured,
    keys %control_file_extension;

  my $type = shift;

  my $filename = $addr -> point ?
    sprintf( '%08x.', $addr -> point )
    : sprintf( '%04x%04x.',
               $addr -> net,
               $addr -> node,
             );

  my $flavoured = grep $type eq $_, @flavoured;
  my $flavour;
  if ( $flavoured ) {
    $logger -> logdie( 'no flavour passed' )
      unless @_;

    $flavour = shift;

    $logger -> logdie( sprintf 'incorrect flavour: %s',
                       defined $flavour ? $flavour : 'undef',
                     )
      unless defined $flavour
      && exists $flavour_extension{ $flavour };

    $filename .= $type eq $flavoured[ 0 ] ? # netmail
      $flavour_extension{ $flavour }[ 0 ]
      : $flavour_extension{ $flavour }[ 1 ];
  } else {
    $filename .= $control_file_extension{ $type };
  }

  my $sub_ref;

  if ( @_ ) {                   # possible sub ref
    $logger -> logdie( 'no valid sub_ref passed' )
      unless defined $_[ 0 ]
      && 'CODE' eq ref $_[ 0 ];

    $sub_ref = shift;
  }


  $self -> scan
    unless exists $self -> {scanned};


  # check any outdir except our_domain.our_zone for already existing file
  my $dz_out = $self -> _select_domain_zone_dir( $addr -> domain, $addr -> zone );

  my @dz_out_with_existing_file = grep exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }
    && exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type }
    && ( ! $flavoured
         || exists $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type }{ $flavour }
       ),
         grep length $_ == length $dz_out, # to filter out our_domain.our_zone versions
         keys %{ $self -> {scanned}{ $addr -> domain }{ $addr -> zone } };

  my $full_filename;

  if ( @dz_out_with_existing_file ) { # file exists
    unless ( grep $dz_out eq $_,
             @dz_out_with_existing_file
           ) { # best domain.zone does not have existing file.  let's select best of the worst
      # first try to find one with best formatted file
      my ( $t ) = grep {
        my $r = $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $_ }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type };

        $r = $r -> { $flavour }
          if $flavoured;

        grep $filename eq $_ -> {name},
          @$r;
      } @dz_out_with_existing_file;

      $dz_out = $t ? $t : $dz_out_with_existing_file[ 0 ]; # or just very first one
    }

    # here we've got dz_out with existing file
    my $r = $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $dz_out }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type };

    $r = $r -> { $flavour }
      if $flavoured;

    $filename = $r -> [ 0 ]{name}
      unless grep $filename eq $_ -> {name}, # no best file name
      @$r;

    ( $full_filename ) = map $_ -> {full_name},
      grep $filename eq $_ -> {name},
      @$r;

    # and remove it..
    @$r = grep $filename ne $_ -> {name}, @$r;
  } else {                      # no file - create it
    $full_filename = File::Spec -> catfile( $addr -> point ?
                                            $self -> _select_points_dir( $addr -> domain,
                                                                         $addr -> zone,
                                                                         $addr -> net,
                                                                         $addr -> node,
                                                                       )
                                            : $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $dz_out }{dir},
                                            $filename,
                                          );
  }

  if ( $sub_ref ) {
    eval {
      $sub_ref -> ( $full_filename );
    };

    if ( $@ ) {                 # something bad happened
      $logger -> logdie( sprintf 'referenced sub execution failed: %s',
                         $@,
                       );
    }

    # update file information in internal structure
    # first remove existing record about file (if it's known)
    {
      my $r = $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $dz_out }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type };

      $r = $r -> { $flavour }
        if $flavoured;

      my ( $record_idx ) = grep $_ -> {full_name} eq $full_filename, 0 .. $#$r;
      splice @$r, $record_idx, 1
        if defined $record_idx;

      # might be a good idea to remove empty parents as well if there was just one file
    }

    if ( -e Encode::encode( locale_fs => $full_filename ) ) {
      my $r = $self -> {scanned}{ $addr -> domain }{ $addr -> zone }{ $dz_out }{ $addr -> net }{ $addr -> node }{ $addr -> point }{ $type };

      $r = $r -> { $flavour }
        if $flavoured;

      my %file_prop = ( name => $filename,
                        full_name => $full_filename,
                        mstat => ( stat _ )[ 9 ],
                        size => -s _,
                      );

      $file_prop{referenced_files} =
        FTN::Outbound::Reference_file
          -> new( $file_prop{full_name},
                  $self -> {reference_file_read_line_transform_sub},
                )
          -> read_existing_file
          -> referenced_files
          if $type eq 'reference_file'
          && $file_prop{size}  # empty files are empty, right?
          && exists $self -> {reference_file_read_line_transform_sub};

      push @$r, \ %file_prop;
    }
  }

  # what to return - just full name or open handle?  handle probably better (can update scanned structure, but buffered/unbuffered?  access details?)
  # let's try full name first
  $full_filename;
}

1;
