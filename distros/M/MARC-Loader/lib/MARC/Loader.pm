# vim: sw=4
package MARC::Loader;
use 5.10.0;
use warnings;
use strict;
use Carp;
use MARC::Record;
use YAML;
use Scalar::Util qw< reftype >;
our $VERSION = '0.004001';
our $DEBUG = 0;
sub debug { $DEBUG and say STDERR @_ }

sub new {
	my ($self,$data) = @_;
	my $r = MARC::Record->new();
	my $orderfields = 0;
	my $ordersubfields = 0;
	my $cleannsb = 0;
	my $lc={};#the controlfield's list
	my $lf={};#the field's list
	my $cf={};#counter where multiple fields with same name
	my $bf={};#bool ok if field have one subfield at least
	if (defined($$data{"ldr"}) and $$data{"ldr"} ne "") {
		$r->leader($$data{"ldr"});
	}
	if ($$data{"orderfields"}) {
		$orderfields=1;
	}
	if ($$data{"ordersubfields"}) {
		$ordersubfields=1;
	}
	if ($$data{"cleannsb"}) {
		$cleannsb=1;
	}
	foreach my $k ( sort {$a cmp $b} keys(%$data) ) {
		if (($k eq "ldr") or ($k eq "orderfields") or ($k eq "ordersubfields") or ($k eq "cleannsb")) {
			next;
		}
		if ( ref( $$data{$k} ) eq "ARRAY" ) {
			foreach my $v ( sort {$a cmp $b} @{$$data{$k}} ) {
				createfield($k,$lc,$lf,$bf,$cf,$v,$cleannsb);
			}
		} else {
			createfield($k,$lc,$lf,$bf,$cf,$$data{$k},$cleannsb);
		}
	}
	foreach my $contk ( sort {$a cmp $b} keys(%$lc) ) {
		if($orderfields) {
			$r->insert_fields_ordered( $$lc{$contk} );
		} else {
			$r->append_fields( $$lc{$contk} );
		}
	}
	foreach my $k ( sort {$a cmp $b} keys(%$lf) ) {
		if ($$bf{$k}==1) {
			$$lf{$k}->delete_subfield(pos => 0);
			if($orderfields) {
				$r->insert_fields_ordered( $$lf{$k} );
			} else {
				$r->append_fields( $$lf{$k} );
			}
		}
	}
	$r;
}

sub createfield {
	my ($k,$lc,$lf,$bf,$cf,$v,$cleannsb) = @_;
	#$k = the hash key that defines the field or subfield name
	#$v = the field or subfield value
	#$lc= the controlfield's list
	#$lf= the field's list
	#$cf= counter where multiple fields with same name
	#$bf= bool ok if field have one subfield at least
	my $prefield="";
	if ($k=~/^((.*)##)?(\D)(\d{3})(\w)$/) {
		$prefield=$1 if $1;
		if (!exists($$lf{$prefield.$4})) {
			if($4<10 and defined($v) and $v ne "") {
				$v=nsbclean($v) if $cleannsb;
				$$lc{$prefield.$4} = MARC::Field->new( "$4", $v );
			} else {
				$$lf{$prefield.$4} = MARC::Field->new( "$4", "", "", 0 => "temp" );
				#$fnoauth = MARC::Field->new( '009', $noauth );
				$$bf{$prefield.$4}=0;
				if (defined($v) and $v ne "") {
					$v=nsbclean($v) if $cleannsb;
					createsubfield($$lf{$prefield.$4},$5,$v,$k);
					$$bf{$prefield.$4}=1;
				}
			}
		} else {
			if (defined($v) and $v ne "") {
				$v=nsbclean($v) if $cleannsb;
				createsubfield($$lf{$prefield.$4},$5,$v,$k);
				$$bf{$prefield.$4}=1;
			}
		}
	} elsif (($k=~/^((.*)##)?(\D)(\d{3})$/) and ( ref( $v ) eq "HASH" )) {
		$prefield=$1 if $1;
		if (!exists($$cf{$prefield.$4})) {
			$$cf{$prefield.$4}=0;
		}
		$$cf{$prefield.$4}++;
		if($4<10){
			foreach my $k ( sort {$a cmp $b} keys(%$v) ) {
				if (defined($$v{$k}) and $$v{$k} ne "") {
					if ($k=~/^((.*)##)?(\D)(\d{3})(\w)$/) {
						$$v{$k}=nsbclean($$v{$k}) if $cleannsb;
						$$lc{$prefield.$4.$$cf{$prefield.$4}} = MARC::Field->new( "$4", $$v{$k} );
						$$bf{$prefield.$4.$$cf{$prefield.$4}}=1;
					} else {
						warn "wrong field name : $k";return;
					}
				}
			}
		}
		else
		{
			$$lf{$prefield.$4.$$cf{$prefield.$4}} = MARC::Field->new( "$4", "", "", 0 => "temp" );
			$$bf{$prefield.$4.$$cf{$prefield.$4}}=0;
			foreach my $k ( sort {$a cmp $b} keys(%$v) ) {
				if (defined($$v{$k}) and $$v{$k} ne "" and ref($$v{$k}) eq "ARRAY" ) {
					foreach my $v ( sort {$a cmp $b} @{$$v{$k}} ) {
						if ($k=~/^((.*)##)?(\D)(\d{3})(\w)$/) {
							$v=nsbclean($v) if $cleannsb;
							createsubfield($$lf{$prefield.$4.$$cf{$prefield.$4}},$5,$v,$k);
							$$bf{$prefield.$4.$$cf{$prefield.$4}}=1;
						} else {
							warn "wrong field name : $k";return;
						}
					}
				} elsif (defined($$v{$k}) and $$v{$k} ne "") {
					if ($k=~/^((.*)##)?(\D)(\d{3})(\w)$/) {
						$$v{$k}=nsbclean($$v{$k}) if $cleannsb;
						createsubfield($$lf{$prefield.$4.$$cf{$prefield.$4}},$5,$$v{$k},$k);
						$$bf{$prefield.$4.$$cf{$prefield.$4}}=1;
					} else {
						warn "wrong field name : $k";return;
					}
				}
			}
		}
	} else {
		warn "wrong field name : $k";return;
	}
}

sub createsubfield {
	my ($f,$s,$v,$k)=@_;
	#$f = the field
	#$s = the subfield name
	#$k = the hash key that defines the subfield name
	#$v = the subfield value
	if ($k=~/^((.*)##)?(i)(\d{3})(\w)$/) {
		my $ind=$5;
		if ( ($5=~/1|2/) and ($v=~/\d|\|/) ) {
			$f->update( "ind$ind" => $v);
		} else {
			warn "wrong ind values : $k=$v";return;
		}
	} else {
		$f->add_subfields( "$s" => $v );
	}
}

sub nsbclean {
    my ($string) = @_ ;
    $_ = $string ;
    s/\x88//g ;# NSB : begin Non Sorting Block
    s/\x89//g ;# NSE : Non Sorting Block end
    s/\x98//g ;# NSB : begin Non Sorting Block
    s/\x9C//g ;# NSE : Non Sorting Block end
    s/\xC2//g ;# What is this char ? It is sometimes left by the regexp after removing NSB / NSE 
    $string = $_ ;
    return($string) ;
}
1;
__END__

=head1 NAME

MARC::Loader - Perl module for creating MARC record from a hash

=head1 VERSION

Version 0.004001

=head1 SYNOPSIS

    use MARC::Loader;
    my $foo={
            'ldr' => 'optionnal_leader',
            'cleannsb' => 1,
            'f005'  => [
                        {
                            'f005_' => 'controlfield_contenta'
                        },
                        {
                            'f005_' => 'controlfield_contentb'
                        }
                       ],
            'f006_' => 'controlfield_content',
            'f010d' => '45',
            'f099c' => '2011-02-03',
            'f099t' => 'LIVRE',
            'i0991' => '3',
            'i0992' => '4',
            'f200a' => "\x88le \x89titre",
            '001##f101a' => ['lat','fre','spa'],
            'f215a' => [ 'test' ],
            'f700'  => [
                        {
                            'f700f' => '1900-1950',
                            'f700a' => 'ICHER',
                            'f700b' => ['jean','francis']
                        },
                        {
                            'f700f' => '1353? - 1435',
                            'f700a' => 'PAULUS',
                            'f700b' => 'MARIA'}
                        ],
            'f995'  => [
                        {
                            'f995e' => 'S1',
                            'f995b' => 'MP',
                            'f995f' => '8002-ex'
                        },
                        {
                            '001##f995e' => 'S2',
                            '002##f995b' => 'MP',
                            '005##f995f' => '8001-ex'
                        }
                       ]
            };
    my $record = MARC::Loader->new($foo);

    # Here, the command "print $record->as_formatted;" will return :
    # LDR optionnal_leader
    # 005     controlfield_contenta
    # 005     controlfield_contentb
    # 006     controlfield_content
    # 101    _afre
    #        _alat
    #        _aspa
    # 010    _d45
    # 099 34 _c2011-02-03
    #        _tLIVRE
    # 200    _ale titre
    # 215    _atest
    # 700    _aICHER
    #        _bfrancis
    #        _bjean
    #        _f1900-1950
    # 700    _aPAULUS
    #        _bMARIA
    #        _f1353? - 1435
    # 995    _bMP
    #        _eS1
    #        _f8002-ex
    # 995    _eS2
    #        _bMP
    #        _f8001-ex

=head1 DESCRIPTION

This is a Perl module for creating MARC records from a hash variable. 
MARC::Loader use MARC::Record.

=head3 Hash keys naming convention.

The names of hash keys are very important. They must begin with letter B<f> followed by the B<3-digit> field name ( e.g. f099), followed, for the subfields, by their B<letter or digit> ( e.g. B<f501b>).

Repeatable fields are arrays of hash ( e.g., 'f700'  => [{'f700f' => '1900','f700a' => 'ICHER'},{'f700f' => '1353','f700a' => 'PAULUS'}] ).

Repeatable subfields are arrays ( e.g., 'f101a' => [ 'lat','fre','spa'] ).

Controlfields are automatically detected when the hash key begin with letter B<f> followed by B<3-digit lower than 10> followed by B<underscore> ( e.g. B<f005_>). 

Indicators must begin with the letter i followed by the 3-digit field name followed by the indicator's position (1 or 2) :  e.g. C<i0991>.

Record's leader can be defined with the hash key 'ldr' ( e.g., 'ldr' => 1 ).

=head3 reorder fields and subfields

Fields and subfields are in lexically order. If you want reorder fields and subfields differently, you can add a reordering string (necessarily followed by ##) at the beginning of hash keys (e.g., to reorder the subfields of f995 to have $e followed by $b : 'f995' => [{'001##f995e' => 'S2','002##f995b' => 'MP')]};).
If you want to reorder fields, please note that the controlfields will always be located before the other (e.g., if you define '001##f101a' => [ 'lat','fre','spa'] , the f101 will be placed after the last controlfield ).

Be careful, the reorder is made lexically, not numerically : 10 will be placed before 2, while 002 will be placed before 010.

If the script you use to build your hash requires you to precede fields AND subfields with a reordering string when you want to reorder only those sub-fields, you can force the module to reorder the fields in alphabetical order with an hash key named 'orderfields' ( e.g., 'orderfields' => 1 ).

You can also remove non-sorting characters with an hash key named 'cleannsb' ( e.g., 'cleannsb' => 1 ).

=head1 METHOD

=head2 new()

=over 4

=item * $record = MARC::Loader->new($foo);

This is the only method provided by the module.

=back

=head1 AUTHOR

Stephane Delaune, (delaune.stephane at gmail.com)

=head1 COPYRIGHT

Copyright 2011 Stephane Delaune for Biblibre.com, all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * MARC::Record (L<http://search.cpan.org/~gmcharlt/MARC-Record/lib/MARC/Record.pm>)

=item * MARC::Field (L<http://search.cpan.org/~gmcharlt/MARC-Record/lib/MARC/Field.pm>)

=item * Library Of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definitive source for all things MARC.

=cut
