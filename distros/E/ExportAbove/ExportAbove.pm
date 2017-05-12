package ExportAbove;

use strict;
use vars qw($VERSION);

$VERSION = '0.02';

my %Already;

sub import {
	my($class, @args) = @_;
	my $from = caller;
	no strict 'refs';
	for my $sym(keys %{$from."::"}) {
		next if $sym =~ /^[A-Z]+$/;  # neglect BEGIN, AUTOLOAD, ...
		my @expnames;
		if( defined *{$from."::".$sym}{CODE} ) {
			push @expnames, newname($from, $sym);
		}
		if( defined *{$from."::".$sym}{SCALAR} ) {
			push @expnames, newname($from, '$'.$sym);
		}
		if( defined *{$from."::".$sym}{HASH} ) {
			push @expnames, newname($from, '%'.$sym);
		}
		if( defined *{$from."::".$sym}{ARRAY} ) {
			push @expnames, newname($from, '@'.$sym);
		}
		#print "@expnames\n";
		if( @args ) {
			my($taged, $oked) = (0, 0);
			for my $arg(@args) {
				if( $arg eq 'OK' ) {
					push @{$from."::EXPORT_OK"}, @expnames;
					$oked = 1;
				} else {
					$arg =~ s/^://;
					push @{${$from."::EXPORT_TAGS"}{$arg}}, @expnames;
					$taged = 1;
				}
			}
			if( $taged && !$oked) {
				push @{$from."::EXPORT"}, @expnames;
			}
		} else {
			push @{$from."::EXPORT"}, @expnames;
		}
	}
}

sub unimport {
	my $from = caller;
	no strict 'refs';
	for my $sym(keys %{$from."::"}) {
		next if $sym =~ /^[A-Z]+$/;
		if( defined *{$from."::".$sym}{CODE} ) {
			newname($from, $sym);
		}
		if( defined *{$from."::".$sym}{SCALAR} ) {
			newname($from, '$'.$sym);
		}
		if( defined *{$from."::".$sym}{HASH} ) {
			newname($from, '%'.$sym);
		}
		if( defined *{$from."::".$sym}{ARRAY} ) {
			newname($from, '@'.$sym);
		}
	}
}

sub newname {
	my($pkg, $name) = @_;
	if( $Already{$pkg}{$name} ) {
		return ();
	} else {
		$Already{$pkg}{$name}++;
		return ($name);
	}
}

1;
__END__

=head1 NAME

ExportAbove - set sub or var names into @EXPORT* automatically

=head1 SYNOPSIS

  package SomeModule;
  use Exporter;
  @ISA = qw(Exporter);
  
  $qux = ...;            # NOT export
  sub foo {...}          # NOT export
  no ExportAbove;
  
  @quux = (...);         # into @EXPORT
  sub bar {...}          # into @EXPORT
  use ExportAbove;
  
  %quuux = (...);        # into %EXPORT_TAGS and @EXPORT_OK
  sub baz {...}          # into %EXPORT_TAGS and @EXPORT_OK
  use ExportAbove qw(:Tag OK);
  
  $goo = ...;            # NOT export
  sub gle {...}          # NOT export
  # End of SomeModule

=head1 DESCRIPTION

ExportAbove is a helper module for Exporter.

ExportAbove sets your module's subroutine or variable (scalar, array or hash) 
names into @EXPORT, @EXPORT_OK or %EXPORT_TAGS automatically. You do not have 
to write '@EXPORT = qw(...);' and so on. Instead write 'use ExportAbove;' 
below the subroutine or variable definitions you want to export. 

You do not have to write same subroutine or variable names twice at 
'@EXPORT = qw(...);' and its definition. It makes module maintenance easy. 
If you want to change an exported names, you simply change only its 
definitions. If you want to move an exported subroutine or variable to 
another related module, simply do it.

=head2 Set into @EXPORT

If you want to export some subroutines or variables in 
default, write as following below its definitions.

  use ExportAbove;

=head2 Set into @EXPORT_OK

If you want to export some subroutines or variables on demand, write as 
following below its definitions.

  use ExportAbove 'OK';

=head2 Set into %EXPORT_TAGS and @EXPORT

If you want to export some subroutines or variables in default or on demand 
by the tag name 'Tag', write as following below its definitions.

  use ExportAbove ':Tag';

Two or more tag names are available as following.

  use ExportAbove qw(:Foo :Bar);

=head2 Set into %EXPORT_TAGS and @EXPORT_OK

If you want to export some subroutines or variables not in default and on demand 
by the tag name 'Tag', write as following below its definitions.

  use ExportAbove qw(:Tag OK);

Two or more tag names are available.

=head2 Not export

If you do not want to export some subroutines or variables, write as following 
below its definitions.

  no ExportAbove;

=head2 Mixed uses

Mixed uses are available. See SYNOPSIS above.

=head2 Exceptional names

ExportAbove never set all capital names such as BEGIN, AUTOLOAD, @ISA,... into 
@EXPORT*.

=head2 Exporter required

ExportAbove does NOT export the names you specified. Exporter module does it.
Please do NOT forget to use Exporter and set 'Exporter' into @ISA.

=head1 AUTHOR

nakajima@netstock.co.jp

=head1 SEE ALSO

Exporter

=cut
