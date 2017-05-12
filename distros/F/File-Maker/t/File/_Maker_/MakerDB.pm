#!perl

 package  _Maker_::MakerDB;

 use strict;
 use warnings;
 use warnings::register;

 use vars qw($VERSION $DATE $FILE );
 $VERSION = '0.01';
 $DATE = '2004/05/10';
 $FILE = __FILE__;

 use File::Maker;
 use vars qw( @ISA );
 @ISA = qw(File::Maker);

 ######
 # Hash of targets
 #
 my %targets = (
    all => [ qw(target1 target2) ],
    target3 => [ qw(target1 target3) ],
    target4 => [ qw(target1 target2 target4) ],
    __no_target__ => [ qw(target3 target4 target5) ],
 );

 my $data = '';

 sub make
 {
    my $self = shift @_;
    $self->make_targets( \%targets, @_ );
    my $result = $data;
    $data = '';
    $result
 }

 sub target1
 {
   $data .= ' target1 ';
   1
 }

 sub target2
 {
   $data .= ' target2 ';
   1
 }

 sub target3
 {
   $data .= ' target3 ';
   1
 }

 sub target4
 {
   $data .= ' target4 ';
   1
 }

 sub target5
 {
   $data .= ' target5 ';
   1
 }

 1

__DATA__

Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Version: ^
Classification: None^

~-~
