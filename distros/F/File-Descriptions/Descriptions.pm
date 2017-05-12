package File::Descriptions;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

#=========================================================================
# Require
#-------------------------------------------------------------------------
# Modules also used
# require Tie::CPHash;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.03';


# Preloaded methods go here.

#=========================================================================
# Methods
#-------------------------------------------------------------------------
# Constructor

sub new
{
   my $class = shift;
   my $self = {};
   $self->{dir} = $_[0] || '.';
   %{$self->{desc}} = ();
#   tie %{$self->{desc}},'Tie::CPHash';
   bless $self, $class;
   $self;
}

#=========================================================================
# Methods
#-------------------------------------------------------------------------
# Destructor

sub DESTROY
{
  my $self = shift;
#  untie %{$self->{desc}};
}

#=========================================================================
# Methods
#-------------------------------------------------------------------------
# gethash($directory)

sub gethash
{
  my $self = shift;
  $self->{dir} = $_[0] if $_[0];

# Make something to cache dir's ...
  %{$self->{desc}->{ $self->{dir} }} = ();

# get file descriptions on $self->dir
  $self->{desc}->{ $self->{dir} }->{'test'} = 'okay';

  $self->try_simtelnet();
  $self->try_debian();
  $self->try_freebsd();

# return the array...
  return %{$self->{desc}->{ $self->{dir} }};
}

sub directory
{
  my $self = shift;

  return $self->{dir};

}

sub try_simtelnet
{
  my $self = shift;
  my $current_dir = $self->directory;

  $current_dir.='/' unless ($current_dir =~ /\/$/);

  my $current_file=$current_dir.'dirs.txt';

  if ( -f $current_file ) {
   if ( -r _ ) {
     if (open(DESCRIPTOR,"<".$current_file)) {
# ok, we got the dirs, checking:
       my $line = <DESCRIPTOR>;
       if ($line =~ /simtel/i) {
# checked it's a simtel file...
       my $got_the_blank = 0;
         while (<DESCRIPTOR>) {
           chomp;
# chomping a probable \r also...
           chomp;
           $got_the_blank++ if ($_ eq '');
           last if ($got_the_blank > 1);
           if ($got_the_blank) {
# start picking up the passangers
             my $file;
             my $desc;
             ($file,$desc) = ($_ =~ /^(\S+)\s+(.+)$/);
             $self->{desc}->{ $self->{dir} }->{$file} = $desc;
           }
         }
       }
       close(DESCRIPTOR);
     }
   }
  }

  my $current_file=$current_dir.'00_index.txt';


  if ( -f $current_file ) {
   if ( -r _ ) {
     if (open(DESCRIPTOR,"<".$current_file)) {
# ok, we got the dirs, checking:
       my $line = <DESCRIPTOR>;
       if ($line =~ /^NOTE/i) {
# checked it's a simtel file...
       my $got_the_blank = 0;
         while (<DESCRIPTOR>) {
           chomp;
# chomping a probable \r also...
           chomp;
           $got_the_blank++ if ($_ eq '');
           last if ($got_the_blank > 2);
           if ($got_the_blank == 2) {
# skip rubble
             <DESCRIPTOR>;
             <DESCRIPTOR>;
             <DESCRIPTOR>;
# start picking up the passangers
             my $file;
             my $desc;
             ($file,$desc) = ($_ =~ /^(\S+)\s+\S+\s+\S+\s+\S+\s+(.+)$/);
             $self->{desc}->{ $self->{dir} }->{$file} = $desc;
           }
         }
       }
       close(DESCRIPTOR);
     }
   }
  }
}

sub try_debian
{
  my $self = shift;
  my $current_dir = $self->directory;

  $current_dir.='/' unless ($current_dir =~ /\/$/);

  my $current_file=$current_dir.'../'.'Packages';

  if ( -f $current_file ) {
   if ( -r _ ) {
     if (open(DESCRIPTOR,"<".$current_file)) {
# ok, we got the dirs
       my $got_the_file = 0;
       my $file;
       my $desc;
         while (<DESCRIPTOR>) {
           chomp;
# chomping a probable \r also...
           chomp;
# start picking up the passangers
            if ($_ =~ /^Filename:/i) {
                ($file) = ($_ =~ /\/([^\/]*?)$/);
               if ($file ne '') {
                 my $current_test = $current_dir.$file;
                 if ( -e $current_test ) {
                   $got_the_file++;
                 }
               }
            }
            if ($_ =~ /Description:/i) {
             ($desc) = ($_ =~ /^\S+:\s+(.+)$/);
             $got_the_file++;
            }
            if ($got_the_file == 2) {
              $self->{desc}->{ $self->{dir} }->{$file} = $desc;
            }
            if ($_ eq '') {
              $got_the_file = 0;
            }
        }
       close(DESCRIPTOR);
     }
   }
  }
}

sub try_freebsd
{
  my $self = shift;
  my $current_dir = $self->directory;

  $current_dir.='/' unless ($current_dir =~ /\/$/);

  my $current_file=$current_dir.'../'.'INDEX';

  if ( -f $current_file ) {
   if ( -r _ ) {
     if (open(DESCRIPTOR,"<".$current_file)) {
# ok, we got the dirs
       my $got_the_file = 0;
       my @desc;
         while (<DESCRIPTOR>) {
           chomp;
# chomping a probable \r also...
           chomp;
# start picking up the passangers
           @desc = split (/\|/,$_);
            if ($#desc = 6) {
              my $current_test = $current_dir.$desc[0].'.tgz';
              if ( -e $current_test ) {
               $self->{desc}->{ $self->{dir} }->{$desc[0].'.tgz'} = $desc[3];
              }
            }
        }
       close(DESCRIPTOR);
     }
   }
  }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

File::Descriptions - Perl extension for getting file descriptions

=head1 SYNOPSIS

  use File::Descriptions;

    $d = new File::Descriptions;
    %descriptions = $d->gethash($directory);

=head1 DESCRIPTION

This extension retrieves file descriptions from common mirror distributions like
SimtelNet, Debian, etc...

It should auto-recognize the presence of file descriptions for a particular type
soon there will be more methods implemented

=head1 AUTHOR

Pedro Leite, leite@ua.pt

=head1 SEE ALSO

perl(1).

=cut
