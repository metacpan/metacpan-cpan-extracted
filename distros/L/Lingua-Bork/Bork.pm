package Lingua::Bork;

use strict;
use warnings;

require Exporter;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ 'bork' ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

$VERSION = '0.03';

my %map = ( tion => 'shun', # tail only
            the  => 'zee',  # full match
            an   => 'un',
            au   => 'oo',
            en   => 'ee', # tail only
            ir   => 'ur',
            ow   => 'oo',
#           E    => 'I',  # head only
            e    => 'ea', # tail only
            f    => 'ff',
#           i    => 'ee', # first in word
            o    => 'u',  # within word
            u    => 'oo',
            v    => 'f',
            w    => 'v',
           );

sub new {
  my $class = shift;
  bless {}, ref($class)||$class;
}

sub bork {
   local $_ = shift;
   local $_ = shift if ref($_);
   
   s/(tion\b|\bthe\b|an|au|en\b|ir|ow|e\b|f|\Bo\B|u|v|w)/my $trans = $map{lc $1}; $1 eq lc($1) ? $map{lc $1} : ucfirst($map{lc $1})/eig;

   # first i in a word
   s/(i)(\S+)/ $1 eq 'i' ? "ee$2" : "Ee$2" /eig;

   # leading e
   s/\b(e)(?!e)/ $1 eq 'e' ? 'i' : 'I' /eig;

   s/([.!?])+/$1  Bork Bork Bork!/g;
   return $_;
}

1;
__END__

=head1 NAME

Lingua::Bork - Perl extension for Bork Bork Bork

=head1 SYNOPSIS

  use Lingua::Bork 'bork';
  print bork("This is the conjunction junction.")

=head1 DESCRIPTION

Bork Bork Bork.

=head1 EXPORT

None by default.

Can export bork function for convenience.

=head1 AUTHOR

Michael Ching, E<lt>michaelc@wush.netE<gt>

=head1 SEE ALSO

http://www.cs.yorku.ca/course_archive/2000-01/W/3311/assignments/a1.pdf

=head1 KNOWN PROBLEMS

Automagically title cases words to distinguish start and end 'e'.

This man page is not in Bork Bork Bork.

=cut