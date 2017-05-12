package Finance::MICR::GOCR;
use strict;
use warnings;
use Carp;
use File::Which 'which';

#use Smart::Comments '###';
our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

$Finance::MICR::GOCR::DEBUG = 0;
sub DEBUG : lvalue { $Finance::MICR::GOCR::DEBUG }
# cleanup should be done here only?

=pod

=head1 NAME

Finance::MICR::GOCR - interface to using gocr for reading MICR line of a check image

=head1 DESCRIPTION

Ad hock module to inbetween with gocr
Most of the work offered in this module is about coaxing gocr to read an image and detect 
a MICR line.

The output of this module itself is not genuinely useful without using 

Finance::MICR::GOCR::Check

=head1 SYNOPSYS

	my $gocr = new Finance::MICR::GOCR({
		abs_path => '/tmp/xmicr/micr/micr_image.pbm', 
	});

	print $gocr->out;

=cut

sub new {
	my ($class, $self) = (shift, shift);		
	if (DEBUG){
		printf STDERR "new %s instanced for %s\n", __PACKAGE__, $self->{abs_path};
	}
		
	bless $self, $class;
	return $self;
}

=head1 new()

	my $gocr = new Finance::MICR::GOCR({
		abs_path => '/tmp/xmicr/micr/micr_image.pbm', 
		abs_gocr_bin => '/usr/local/bin/gocr', 
		abs_path_gocrdb => '/usr/share/micrdb/', 
		s => 80,
		d => 20,
		cleanup_string => 0,
	});

Parameters to constructor
Test the default values before experimenting.

=over4

=item abs_path

Required.
This is the absolute path to the image that is the check. The image pbm file with micr code in it.
The present filetypes for gocr are PNM, PGM, PBM, PPM, or PCX - depending on the version of gocr you have.

=item abs_gocr_bin

Optional.
If provided, this is absolut path to the gocr binary
if left out, we try to find with File::Which, if not found, dies.

=item abs_path_gocrdb

Defaults to '/usr/share/micrdb/'
absolute path to the directory holding your micr database
via the command line, the path must be set ending in backslash, the backslash can be used here or not

=item s

Optional.
spacing, gocr space between characters.
default value is 80. 
suggested is no more then 120.
If your resolution is high, you would want this higher.

=item d

Optional.
gocr dust size, default is 20
things smaller then this are ignored

=item cleanup_string

Optional.
boolean, default is 1.
more regexes to cleanup gocr garble.

=back

=head1 METHODS

=cut


sub out {
	my $self = shift;
	my $raw = $self->get_raw;
   
   unless ($raw){
      if (DEBUG){
         printf STDERR "out() has nothing. using %s\n", $self->abs_path_gocrdb;
      }
   } 
   
	$raw or return;

	if ($self->cleanup_string){
		print STDERR __PACKAGE__."::out() will cleanup string\n" if DEBUG;
		my $string = _cleanup_string($raw);		
		$string or return;
		print STDERR "cleaned up is [$string]\n" if DEBUG;
		return $string;
	}
		
	print STDERR __PACKAGE__."::out() did not cleanup string, returned raw [$raw]\n" if DEBUG;		
	return $raw;
}

=head2 out()

Returns MICR line from gocr.
This is not a verified MICR line.
The out is cleaned up unless you set cleanup_string to 0 via constructor.
returns undef if cannot get raw string.

=cut

sub abs_path {
	my $self = shift;
	unless( $self->{_abs_path} ){
		defined $self->{abs_path} or croak(__PACKAGE__."::abs_path() missing abs_path argument to constructor");
		-f $self->{abs_path} or croak(__PACKAGE__."::abs_path() argument $$self{abs_path} is not a file on disk");


		$self->{abs_path}=~/png$|jpg$|pnm$|pgm$|pbm$|ppm$|pcx$/i or 
			croak(__PACKAGE__."::abs_path() source file [$$self{abs_path}] is not a supported filetype for gocr, consult manual, but as of now, you can read PNM, PGM, PBM, PPM, or PCX format");
		
		$self->{_abs_path} = $self->{abs_path};
	}
	return $self->{_abs_path};
}

=head2 abs_path()

returns absolute path to file being used
if it is not on disk, croaks.
If the file is not PNM, PGM, PBM, PPM, or PCX, croaks.

=head1 Some gocr parameters

=cut

sub abs_gocr_bin {
	my $self = shift;
	$self->{abs_gocr_bin} ||= which('gocr') or die('cannot find path to gocr binary, is gocr isntalled?');
	return $self->{abs_gocr_bin};
}

sub abs_path_gocrdb {
	my $self = shift;
	unless( $self->{_abs_gocrdb} ){
		$self->{abs_path_gocrdb} ||= '/usr/share/micrdb/';
		$self->{abs_path_gocrdb}=~s/\/+$//;		
		-d $self->{abs_path_gocrdb} or croak(__PACKAGE__."::abs_path_gocrdb() [$$self{abs_path_gocrdb}] is not a dir");
		$self->{_abs_path_gocrdb} = $self->{abs_path_gocrdb}.'/';
		print STDERR "abs path to gocr db is $$self{_abs_path_gocrdb}\n" if DEBUG;
	}
	return $self->{_abs_path_gocrdb};
}

sub s {
	my ($self,$val) = @_;
	if (defined $val){ $self->{s} = $val; }
	$self->{s} ||= 80;
	return $self->{s};
}

sub d {
	my ($self,$val) = @_;
	if (defined $val){ $self->{d} = $val; }
	$self->{d} ||= 20;
	return $self->{d};
}

sub cleanup_string {
	my $self = shift;
	my $val = shift;
	
	if(defined $val){
		$self->{cleanup_string} = $val;
	}	
	unless ( defined $self->{cleanup_string} ){
		$self->{cleanup_string} = 1;
	}
	return $self->{cleanup_string};
}


=head2 abs_path_gocrdb()

returns absolute path to the database we are using for gocrdb
set via constructor
defaults to : /usr/share/micrdb/

=head2 abs_gocr_bin()

returns abs path to gocr binary being used

=head2 s()

returns gocr -s space between characters.
default value is 80
if you provide a value, will set to that

=head2 d()

returns dust size
if you provide a value, will set to that
default is 20

=head2 cleanup_string()

returns true or false
this is set via constructor argument
if argument provided, will set

=cut

sub get_raw {
	my $self = shift;	
	

	# using -C instead of -c gives ERROR :
		# unknown option use -h for help	
	
   # the -a 80 option is NEEDED for version 0.44 of gocr, version 0.40 will complain but still work
	my @args = ( $self->abs_gocr_bin, '-a',80,'-m', 256, '-m', 2, '-c', '0123456789CcAa', '-p', $self->abs_path_gocrdb, '-s', $self->s, '-d', $self->d, '-i', $self->abs_path );
	
	print STDERR __PACKAGE__."::get_raw() args will be:\n  @args\n" if DEBUG;
	#my $cmd  = qq|$abs_gocr_bin -p "$db" -m 256 -c 0123456789CcAa -m 2 -s $s -d $d -i "$abs_path"|; # try -m 4	
	## $cmd

	my $output = do { 
      open my $fh, '-|', @args or warn("command [@args], $!") and return;
      local $/;
      <$fh>
   };	
	
	$output or return;

	if ($output=~s/(CCc\d{4,}CCc)Ccc(\d{4,})Ccc(\d{4,}CCc)/$1Aa$2Aa$3/){ # 3.7.07
		print STDERR "regexed into shape.\n" if DEBUG;	
	}	
	return $output;
}

=head2 get_raw()

returns raw gocr output of the image file being used.
this is with the parameters we've set, s, d, etc.
Not entrirely raw.

=cut

sub _cleanup_string {
	my $in = shift;	
	
	
	$in=~s/.+\n([^\n]{30,70})$/$1/;
	$in=~s/[^0123456789AaCcTUXD _]//g;

	$in=~s/\s{2,}/ /g;
#	$in=~s/ /_/g;
	$in=~s/^_|_$//g;

	$in=~s/Ca/Aa/g;
	$in=~s/Ca/Aa/g;
	$in=~s/CCC/CCc/g;
	$in=~s/Ccc/Aa/g;
	
	$in=~s/([^Cc])Cc/$1CCc/g; 
	
	# this line will invalidate personal checks, will only work with business checks 
	$in=~s/^.+(CCc[\d])/$1/s;
	$in=~s/[\s_]//g;

	$in=~s/(\d)CCcc(\d)/$1Aa$2/;
	
	#$in=~s/ \w //g;
	$in=~s/^CCcc/CCc/;
	$in=~s/(\d{5,})CC$/$1CCc/;
	$in=~s/([\dcC])aa(\d)/$1Aa$2/; # using ./db/micr3 this changes a 85% hit to a 92%

	$in=~s/^c{2,3}/CCc/i;


	# ASSUMING THIS IS A BUISINESS CHECK HERE. WARNING
	$in=~s/(CCc[^Cc]+CCc[^Cc]+CCc).+/$1/s; ## iffy about this hack line
	return $in;
}

=head1 DEBUG

The debug flag is 

	$Finance::MICR::GOCR::DEBUG = 1;

This is also an lvalue sub.

=head1 SEE ALSO

Finance::MICR::LineParser

gocr manual

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut



1;



