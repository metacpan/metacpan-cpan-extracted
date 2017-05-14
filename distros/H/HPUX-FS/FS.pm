package HPUX::FS;

use 5.006;
use strict;
#use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HPUX::FS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.03';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

### start

use Carp;
use Storable;

sub new
  {
    my $debug=0;
    my $debug2=0;

    my ($class, @subargs) = @_ ;

    my %arglist  =      (
        target_type     => "local"      ,
        persistance     => "new"        ,
        datafile        => "/tmp/fsinfo.dat",
        access_prog     => "ssh -1"        ,
        access_system   => "localhost"  ,
        access_user     => "root"       ,
        remote_command1 => 'cat /etc/fstab',
        remote_command2 => '/usr/sbin/mount -p',
        remote_command3 => 'bdf',
        @subargs,
                        );

        if ($debug)     {
         print "target_type  : $arglist{target_type}\n";
         print "persistance  : $arglist{persistance}\n";
         print "datafile     : $arglist{datafile}\n";
         print "access_prog  : $arglist{access_prog}\n";
         print "access_system: $arglist{access_system}\n";
         print "access_user  : $arglist{access_user}\n";
         print "remote_command1: $arglist{remote_command1}\n";
         print "remote_command2: $arglist{remote_command2}\n";
         print "remote_command3: $arglist{remote_command3}\n";
                        }

    my $source_access  =$arglist{target_type};
    my $new_or_saved   =$arglist{persistance};
    my $datafile       =$arglist{datafile};
    my $remote_access  =$arglist{access_prog};
    my $remote_system  =$arglist{access_system};
    my $remote_user    =$arglist{access_user};
    my $remote_command1 =$arglist{remote_command1};
    my $remote_command2 =$arglist{remote_command2};
    my $remote_command3 =$arglist{remote_command3};

    my $line;		
    my $fsinfo_ref;
    my @commands_out;
    my @first_command;
    my @second_command;
    my @third_command;
    my $first_command="";
    my $second_command="";
    my $third_command="";
    my %filesys_hash;
    my $filesys_hash = \%filesys_hash;
    my $fstab_line;
    my @split_fstab_line;
    my $fstab_line_mnt;
    my @split_fstab_line_mnt;

    my @infstab;	#filesystems in fstab
    my %seen; 		#Used when comparing arrays of fstab and mounted fs's
    my @notfstab; 	#see above
    my $item;		#foreach variable in comparison
    my @mounted_fs;	#figure it out

    my $remote_fs;	# this block used in bdf parsing
    my @remote_fs_line;
    my $fixflag="no";
    my $remote_fs_save;
    my $filesys;
    my $kilo_used;
    my $kilo_total;
    my $kilo_avail;
    my $percent_full;
    my $mountpoint;


# Check for persistance request
	 print "checking persistance now\n" if $debug;

        if ($arglist{persistance} eq "old")     {
                print "retrieving a copy from prosperity...\n" if $debug;
                $filesys_hash = Storable::retrieve $datafile
                        or die "unable to retrieve hash data in /tmp\n";
			return bless($filesys_hash, $class);
                                                }
	 print "Executing remote command now\n" if $debug;
# do all 3 commands and parse them out on this side to minimize net connect overhead

    @commands_out=`$remote_access $remote_system -l $remote_user -n "echo My$remote_command1;$remote_command1;echo My$remote_command2;$remote_command2;echo My$remote_command3;$remote_command3"`
        or die "Unable to execute remote commands: $@\n";
	 print "got past remote command\n" if $debug;

	foreach $line (@commands_out)	{

	 if ( $line =~ /My$remote_command1/ ){$first_command="yes"};
	 if ( $line =~ /My$remote_command2/ ){$first_command="no";$second_command="yes"};
	 if ( $line =~ /My$remote_command3/ ){$first_command="no" ; $second_command="no"; $third_command="yes"};


	if ($first_command  eq "yes") { push @first_command, $line };
	if ($second_command eq "yes") { push @second_command, $line };
	if ($third_command  eq "yes") { push @third_command, $line };
				}
	 print "First_command : @first_command\n" if $debug;
	 print "Second_command: @second_command\n" if $debug;
	 print "Third_command : @third_command\n" if $debug;

# check fs's in fstab

	FSTAB_LOOP: foreach $fstab_line (@first_command)	{
		if ($fstab_line =~ /^#/ )	{
			next FSTAB_LOOP;
						}
		if ($fstab_line !~ /^\/dev/ )	{
			next FSTAB_LOOP;
						}
	@split_fstab_line = split /\s+/, $fstab_line;
	$filesys_hash{$split_fstab_line[0]} =  {
					directory	=> $split_fstab_line[1],
					type		=> $split_fstab_line[2],
					options		=> $split_fstab_line[3],
					backup_freq	=> $split_fstab_line[4-5],
					kbytes		=> "NA",
					kbytes_used	=> "NA",
					kbytes_avail	=> "NA",
					percent_used	=> "NA",
					mounted		=> "yes",
					fstab		=> "yes",
					capture_date	=> scalar(localtime) 
						};
								}
# Check mounted fs's

	MOUNT_LOOP: foreach $fstab_line_mnt (@second_command)	{
		if ($fstab_line_mnt =~ /^#/ )	{
			next MOUNT_LOOP;
						}
		if ($fstab_line_mnt !~ /^\/dev/ )	{
			next MOUNT_LOOP;
							}
	@split_fstab_line_mnt = split /\s+/, $fstab_line_mnt;
	push @mounted_fs, $split_fstab_line_mnt[0];
								}
#
# Compare mounted to not mounted but in fstab
# Array compare starts
#

	%seen = ();
	@notfstab = ();
	@infstab = ( sort keys %{ $filesys_hash } );
	 print "infstab: @infstab\<\<\-End\n" if $debug;
	 print "mounted: @mounted_fs\<\<\-End\n" if $debug;

	foreach $item ( @infstab ) { print "item: $item\n" if $debug ; $seen{$item} = 1 };

	foreach $item ( @mounted_fs ) 	{
	        push(@notfstab, $item) unless exists $seen{$item};
       	                                }
	foreach $item (@notfstab)	{
	        print "Filesystem not mounted: $item\n" if $debug;
		$filesys_hash{mounted}="no";
					} 

# Check bdf stats

foreach $remote_fs ( @third_command )       	{
                @remote_fs_line = split /\s+/, $remote_fs;
		print "remote_fs_line has $#remote_fs_line entries\n" if $debug;
		print "filesys1: $remote_fs_line[0]\n" if $debug;
        if ( $remote_fs =~ /^\// || $#remote_fs_line == 5 )       {
		print length($remote_fs_line[0]),"\n" if $debug;
		if ($fixflag eq "yes") { shift @remote_fs_line ; unshift @remote_fs_line, $remote_fs_save ; $fixflag="no"; print "Fixflag found\n" if $debug}
		if ( length($remote_fs_line[0]) > 18 and $fixflag eq "no" and $#remote_fs_line !=5 ) { $remote_fs_save = $remote_fs_line[0]; $fixflag="yes"; print "Marked fixflag" if $debug; }
		 $filesys = $remote_fs_line[0];
                chop $remote_fs_line[4];
		 print "filesys: $filesys\<\<\-\-\n" if $debug;
		$kilo_total = $remote_fs_line[1];
		$kilo_used = $remote_fs_line[2];
		$kilo_avail = $remote_fs_line[3];
                $percent_full = $remote_fs_line[4];
                $mountpoint = $remote_fs_line[5];
		 print "$remote_fs $kilo_total $kilo_used $kilo_avail $percent_full $mountpoint\n" if $debug;
		$filesys_hash{$filesys}->{kbytes}=$kilo_total;
		$filesys_hash{$filesys}->{kbytes_used}=$kilo_used;
		$filesys_hash{$filesys}->{kbytes_avail}=$kilo_avail;
		$filesys_hash{$filesys}->{percent_used}=$percent_full;
								}
	else	{
		print "skipping $remote_fs due to non match\n" if $debug;
		}
							}

        if ( $new_or_saved eq "new" )   {
                print "saving a copy for prosperity...\n" if $debug;
                Storable::nstore \%filesys_hash, $datafile
                        or die "unable to store hash data in /tmp\n";
                                        }

					

							

	

	return bless($filesys_hash, $class);
# now hash it all and preserve it if requested
      }

sub traverse	{

	my $self = shift;
	my $debug=1;
	print "I am self: $self\n" if $debug;
	my $item;
	my $mainkey;
	my $subkey;

	foreach $item ( sort keys %{ $self } )	{
		print "Main Key: $item\n";
		foreach $subkey ( keys %{ $self->{$item} } )	{
			print "subkey: $subkey		Value: $self->{$item}->{$subkey}\n";
									}
							}
		}
sub get_all_filesystems	{
# returns an array ref of all the keys (filesystems)
	my $self = shift;
	my $debug=0;
	my $item;
	my @filesystems;
	foreach $item ( sort keys %{ $self } )	{
		push @filesystems, $item;
						}
	return \@filesystems;



			}
sub get_filesystem_attr {
 my ($self, @subargs) = @_;
        my %arglist      =      (
                filesystem     	=> ""   ,
		attribute       => ""   ,
                @subargs,
                                );



	my $debug=0;
	my $attribute;
	my $attr	=$arglist{attribute};
	my $item	=$arglist{filesystem};
	$attribute = $self->{$item}->{$attr};	
	return $attribute;
			}
### end

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HPUX::FS - Perl function to handle HPUX filesystem stats

=head1 SYNOPSIS

  use HPUX::FSInfo;

  my $fsinfo_data = new HPUX::FSInfo(
                                target_type     =>"local",
                                persistance     =>"new",
                                datafile        =>"/tmp/fsdata.dat",
                                access_prog     =>"ssh -1",
                                access_system   =>"localhost",
                                access_user     =>"root"
                                        );
 
=head1 DESCRIPTION

This module takes the output from 3 different commands and query the filesystem and then hashes the results.

It utilizes the Storable module for persistance so once called you can 
then recall it without re-running the command and/or wait for the network 
by setting persistance from "new" to "old".

Remote node access is supported via remsh or ssh.  ssh is highly recommended.

=head1 FUNCTION

=head2 new()

The main object constructor that returns the hash refrence.
The keys of the hash are all the logical volumes.
  
It accepts the following paramters:

        target_type     values: local(default) or remote
        persistance     values: new(default) or old
        datafile        values: filename and path to presistant data file
        access_prog     values: ssh(default) or remsh
        access_system   values: localhost(default) or remote system name
        access_user     values: root(default) or remote username

The value is another hash ref containing these keys :

  backup_freq
  capture_date
  directory
  fstab
  kbytes
  kbytes_avail
  kbytes_used
  mounted
  options
  percent_used
  type

=head1 EXAMPLE

Here's an example of the structure returned:

 $result = 

   '/dev/vg09/lvol1' => HASH(0x404841cc)
      'backup_freq' => 3
      'capture_date' => 'Tue Nov 13 19:26:02 2001'
      'directory' => '/data/dcomm5'
      'fstab' => 'yes'
      'kbytes' => 8198946
      'kbytes_avail' => 7297058
      'kbytes_used' => 81993
      'mounted' => 'yes'
      'options' => 'rw,suid'
      'percent_used' => 1
      'type' => 'hfs'


=head2 traverse()

  example method that traverses the main object.

=head2 get_all_filesystems()

  returns an array refrence to and array containing all the filesystems

=head2 get_filesystem_attr(	
			filesystem	=> "/dev/vg00/lvol1",
			attribute	=> "percent_used",
			  )

  returns the scalar value of the attribute requested.

=head1 CAVEATS

None known yet.

=head1 AUTHOR

Christopher White <chrwhite@seanet.com>

Copyright (C) 2001 Christopher White.  All rights reserved.  this program is fre
e software;  you can redistribute it and/or modify it under the same terms as pe
rl itself.

### end

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HPUX::FS - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HPUX::FS;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HPUX::FS, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut
