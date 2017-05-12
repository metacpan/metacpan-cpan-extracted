package LEOCHARRE::Strings;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA);
use Exporter;
use Carp;
use String::Prettify;
use String::ShellQuote;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/sq pretty shomp is_blank_or_comment boc is_blank is_comment/;
%EXPORT_TAGS = ( all => \@EXPORT_OK );

*pretty = \&String::Prettify::prettify;
*sq     = \&String::ShellQuote::shell_quote;
*is_blank_or_comment = \&boc;
sub shomp;
sub shomp {
   my $a = \shift;
   # DONE need this to somhow reference to what's in front like with chomp
   # (the \shift does that)
   #printf STDERR "# shomp() got: '%s' %s\n", $a, (ref $a);
   $$a=~s/^\s+|\s+$//g ? 1 : 0;
    
}

sub is_blank {
   my $a = shift;
   ((defined $a) and length($a))or return 1; # if nothing, then is blank

   ($a=~/\S/ ) ? 0 : 1;
}

sub is_comment {
   my $a = shift;
   $a=~/^\s*#/ ? 1 : 0;
}

sub boc {
   my $a = shift;
   is_blank($a) and return 1;
   is_comment($a) and return 1;
   return 0;
}

1;

__END__

=pod

=head1 NAME

LEOCHARRE::Strings - Combines string procedures I frequently use

=head1 SYNOPSIS
   
   use LEOCHARRE:Strings ':all';
   
   my $var = ' /path/to/file ';
   
   shomp $var; # remove whitespace leading and trailing
   
   my $shell_safe = sq($var); # escapes chars for shell
   pretty($var); # make pretty

=head1 SUBS

Not imported by default.

=head2 sq()

String::ShellQuote::shell_quote.
Arg is string, makes safe for shell use.

=head2 pretty()

String::Prettify::prettify()

=head2 shomp()

Arg is string variable.
Takes out all leading and ending whitespace from string.

   my $var= ' this is ';

   shomp $var;

   # now $var is 'this is'

Returns true if it found something, false if not.
This alters your original variable, as chomp would.
cannot take lists as args.

=head2 is_blank()

Arg is string. Returns true if it's defined, and has a non space char.
Returns false if undefined or ony contains whitespace.

=head2 is_comment()

Arg is string. Returns true if it's # comment line only, false otherwise.

=head2 boc() is_blank_or_comment()

Arg is string. Returns true if it's a blank like or comment line.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the 'Artistic License' or the 'GNU General Public License'.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the 'GNU General Public License' for more details.

=cut



