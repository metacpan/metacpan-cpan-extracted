package Getopt::Std::Strict;
use strict;
use vars qw(@EXPORT @EXPORT_OK $VERSION @ISA %OPT $opt_string @OPT_KEYS);
use Exporter;
@EXPORT_OK = qw(%OPT &opt);
@EXPORT = qw(OPT);
@ISA = qw/Exporter/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)/g;

sub import {
   my $class = shift;
   $opt_string = shift;


   my $caller = caller;

   ### $class
   ### $caller
   ### $opt_string

   no strict 'refs';
   
   #*{"$caller\::OPT"}  = \%OPT;
   *{"$caller\::OPT"}  = \%OPT;


   require Getopt::Std;
   Getopt::Std::getopts($opt_string, \%OPT);
   
   ### %OPT
   
   my $_opt_string = $opt_string;
   $_opt_string=~s/\W//g;
   @OPT_KEYS = split(//, $_opt_string);
   ### @OPT_KEYS
   
   # make variables
   for my $opt_key (@OPT_KEYS){
      *{"$caller\::opt_$opt_key"} = \$OPT{$opt_key};
   }

   ### @_

   Getopt::Std::Strict->export_to_level(1, ( $class, @_));  
   

}


sub opt {
   my $opt_key = shift;
   my $opt_val = shift;
   if (defined $opt_val){
      $OPT{$opt_key} = $opt_val;
   }
   
   $opt_string=~/$opt_key/ 
      or die("There's no $opt_key option") 
      and return;
   return $OPT{$opt_key};
}

1;

__END__





=pod

=head1 NAME

Getopt::Std::Strict

=head1 SYNOPSIS

   use Getopt::Std::Strict 'abc:', 'opt';
   
   $opt_a;
   $opt_b;
   $opt_c;

   $OPT{a};
   $OPT{b};
   $OPT{c};

   opt(a);
   opt(b);
   opt(c);

   opt(f); # dies, there's no opt f.

   # To change the values..
   $opt_a = 1;
   opt( a => 1 ); 
   opt( 'a', 1 );
   $OPT{a} = 1;

=head1 DESCRIPTION

Getopt::Std is nice but it could be even easier to use.
This is how I would like Getopt::Std to behave.

Two main concepts are strengthened here, on top of Getopt::Std.

   1) Variables are created even under use strict
   2) Your option specs are passed at compile time.

The first import string to use is what you would send to Getopt::Std.
If you have an option flag 'g' and a paramater 'r' taking an argument,
the usage would be..
   
   use strict;
   use Getopt::Std::Strict 'gr:';

   $opt_g;

This makes available throughout your program the variables $opt_g and $opt_r,
as well as the hash %OPT, which contains $OPT{g} and $OPT{r}.

Compare that with the alternative..

   use strict;
   use Getopt::Std;

   my %o;

   getopts('gr:', \%o);

   $o->{g};

=head1 SUBS

=head2 opt()

=head1 CAVEATS

In development. But works great.

=head1 BUGS

Send any bugs or feature requests to AUTHOR.

=head1 SEE ALSO

L<Getopt::Std>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org


   

