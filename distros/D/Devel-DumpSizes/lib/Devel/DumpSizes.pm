use strict;
use warnings;

package Devel::DumpSizes;

use PadWalker;
use Devel::Size;
use Devel::Symdump;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw (dump_sizes);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "0.01";

sub dump_sizes {

	my $dump_file_prefix = shift || "";
	my $ref_of_mys = PadWalker::peek_my(1);
	my %var_sizes;
	my @sorted_vars;

	if ( $dump_file_prefix ) {
		open(DUMP, ">>$dump_file_prefix.my") or warn "Unable to open file to dump sizes\n";
	} else {
		open(DUMP, ">&STDOUT") or warn "ould not dup STDOUT\n";
	}
	
	print DUMP "Variable name -> Size in bytes\n";
	print DUMP '-' x 80, "\n";

	# Foreach my variable in the caller stack, get "name -> size" as told by Devel::Size::total_size
	foreach my $var_name ( keys(%$ref_of_mys) ) {
		ref($ref_of_mys->{$var_name}) ? $var_sizes{$var_name} = Devel::Size::total_size($ref_of_mys->{$var_name})
			: $var_sizes{$var_name} = Devel::Size::total_size(\$ref_of_mys->{$var_name});
	}
	@sorted_vars = map { "$_ -> $var_sizes{$_}" } sort { $var_sizes{$b} <=> $var_sizes{$a} } (keys(%var_sizes));

	if ( caller(1) ) {
		print DUMP '-' x 30, 'my : ', time(), ' : ', @{[caller(1)]}[3], '/', @{[caller(1)]}[2], '-' x 30, "\n";
	    } else {
		print DUMP '-' x 30, 'my : ', time(), '-' x 40, "\n";
	    }
	print DUMP join("\n", @sorted_vars), "\n";
	print DUMP '-' x 80, "\n";
	close(DUMP);
	
	my $sym_obj = Devel::Symdump->new( (caller(1))[0] );
	my @vars_array;
	if ( $dump_file_prefix ) {
		open(DUMP, ">>$dump_file_prefix.ol") or warn "Unable to open file to dump sizes\n";
	} else {
		open(DUMP, ">&STDOUT") or warn "ould not dup STDOUT\n";
	}

	# Anonymous subroutine for getting "name -> size" variables in symtab of package of caller.
	my $sub_ref = sub {
		my $var_prefix = shift;
		%var_sizes = ();
		@sorted_vars = ();
	    
		# Foreach our/local variable in the symbol table of caller's package, get "name -> size"
		if ( $var_prefix eq '$' ) {
			foreach my $var_name (@vars_array) {
				no strict 'refs';
				if ( $$var_name ) {
					ref($$var_name) ? $var_sizes{$var_name} = Devel::Size::total_size($$var_name)
					: $var_sizes{$var_name} = Devel::Size::size($$var_name);
				} else {
					$var_sizes{$var_name} = 0;
				}
			}
		} elsif ( $var_prefix eq '@' ) {
			foreach my $var_name (@vars_array) {
				no strict 'refs';
				if ( @$var_name ) {
					$var_sizes{$var_name} = Devel::Size::total_size(\@$var_name);
				} else {
					$var_sizes{$var_name} = 0;
				}
			}
		} elsif ( $var_prefix eq '%' ) {
			foreach my $var_name (@vars_array) {
				no strict 'refs';
				if ( %$var_name ) {
					$var_sizes{$var_name} = Devel::Size::total_size(\%$var_name);
				} else {
					$var_sizes{$var_name} = 0;
				}
			}
		}

		@sorted_vars = map { "$var_prefix$_ -> $var_sizes{$_}" } sort { $var_sizes{$b} <=> $var_sizes{$a} } (keys(%var_sizes));
		if ( caller(2) ) {
			print DUMP '-' x 30, 'our/local : ', time(), ' : ', @{[caller(2)]}[3], '/', @{[caller(2)]}[2], '-' x 30, "\n";
		} else {
			print DUMP '-' x 30, 'our/local : ', time(), '-' x 40, "\n";
		}
		print DUMP join("\n", @sorted_vars), "\n";
		print DUMP '-' x 80, "\n";

		@vars_array = ();
	};

	@vars_array = $sym_obj->scalars;
	$sub_ref->('$');
	@vars_array = $sym_obj->arrays;
	$sub_ref->('@');
	@vars_array = $sym_obj->hashes;
	$sub_ref->('%');
	close(DUMP);
}

1;
__END__

=pod

=head1 NAME

Devel::DumpSizes - Dump the name and size in bytes (in increasing order) of variables that are available at a give point in a script.

=head1 SYNOPSIS

use Devel::DumpSizes qw/dump_sizes/;

&Devel::DumpSizes::dump_sizes();

Or,

&Devel::DumpSizes::dump_sizes("/path/of/filename-to-dump-output");

This will print the name of each variable and its size. The name and size are seperated by a '->'

Variable name -> Size in bytes

=head1 EXPORTS

Exports one subroutine by default:

dump_sizes

=head1 DESCRIPTION

This module allows us to print the names and sizes of variables that are available at a give point in a script.

This module was written while debugging a huge long running script. The main use being to understand how variable sizes were fluctuating
during script execution. It uses PadWalker and Devel::Symdump to get the variables. It uses Devel::Size to report the size of each variable.

=head1 METHODS

=head2 dump_sizes

Usage: &Devel::DumpSizes::dump_sizes();

Or

Usage: &Devel::DumpSizes::dump_sizes("/path/of/filename-to-dump-output");

This method accepts one optional parameter that will be used to create the file where the output is dumped.

If parameter is given then two files will be create. One will have extension .my and will contain my variables.
The second file will have extension .ol and will contain our/local variables. If no filename is given output is printed on STDOUT.

As of now, the output is sectioned by printing the following at the start:

	1. either of 'my' or 'our/local' to specify the kind of variables being reported.

	2. output of time().

	3. If possible, subroutine name/line number as returned by caller (perldoc -f caller).

All sizes are in Bytes as returned by Devel::Size. I plan to have more information reported in newer versions. 

=head1 CAVEATS

=over 2

=item *

The limitations of Devel::Size apply to this module.

=back

=head1 BUGS 

=head1 AUTHOR

Gautam Chekuri gautam.chekuri@gmail.com

=head1 COPYRIGHT

Copyright (C) 2006 Chekuri Gatuam

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
