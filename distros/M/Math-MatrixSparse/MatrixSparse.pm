package Math::MatrixSparse;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::MatrixSparse ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
				   splitkey
				   makekey
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

use overload
    "+" => "add",
    "*" => "quickmultiply",
    "x" => "kronecker",
    "-" => "subtract",
    "neg" => "negate",
    "~"  => "transpose",
    "**" => "exponentiate",
    "==" => "equals",
    '""' => "print",
    "&" => "matrixand",
    "|" => "matrixor",
    "fallback" => undef;


# Preloaded methods go here.

### CREATION METHODS
sub new {
    my ($proto,$name) = @_;
    my $this;
    $this->{data} = undef;
    $this->{name} = $name;
    $this->{rows} = 0;
    $this->{columns} =0;
    $this->{special}->{bandwidth} = 0;
    $this->{special}->{structure} = "";
    $this->{special}->{shape} = "";
    $this->{special}->{sign} = "";
    $this->{special}->{pattern} = 0;
    $this->{special}->{field} = "real";

    bless ($this);
    return $this;
}


sub newfromstring {
    my ($proto, $string,$name) = @_;
    my $this=new Math::MatrixSparse;
    my @entries = split(/\n/,$string);
    $this->{special}->{structure} = ".";
    foreach my $entry (@entries) {
	my ($i,$j,$value) = $entry=~m/^\s*(\d+)\s+(\d+)\s+(.+)\s*$/;
	$this->assign($i,$j,$value);
    }
    $this->{name} =$name;
    $this->{special}->{field} = "real";
    return $this;
}

sub newdiag {
    my ($proto, $diag, $name) = @_;
    my @data = @{$diag};
    my $this = new Math::MatrixSparse;
    $this->name($name);
    my $i=1;
    foreach my $entry (@data){
	$this->assign($i,$i,$entry);
	$i++;
    }
    $this->{special}->{structure} = "symmetric";
    $this->{special}->{shape} = "diagonal";
    $this->{special}->{field} = "real";
    $this->{special}->{square} = 1;
    return $this;
}



sub newdiagfromstring {
    my ($proto, $string, $name) = @_;
    my $this=new Math::MatrixSparse;
    my @entries = split(/\n/,$string);
    foreach my $entry (@entries) {
	my ($i,$value) = $entry=~m/^(\d+)\s+(.+)$/;
	$this->assign($i,$i,$value);
    }
    $this->{name} =$name;
    $this->{special}->{structure} = "symmetric";
    $this->{special}->{field} = "real";
    $this->{special}->{shape} = "diagonal";
    $this->{special}->{square} = 1;
    return $this;
}


sub newidentity {
    my ($proto, $n,$m) = @_;
    my $this = new Math::MatrixSparse;
    $m=$n unless ($m);
    $this->{name} = "I$n";
    my  $min = $m<$n ? $m :$n;
    for my $i (1..$min) {
	$this->assign($i,$i,1);
    }
    $this->{rows} = $n;
    $this->{columns} = $m;
    $this->{special}->{structure} = "symmetric";
    $this->{special}->{field} = "real";
    $this->{special}->{shape} = "diagonal";
    $this->{special}->{sign} = "nonnegative";
    $this->{special}->{square} = 1 if $m==$n;
    $this->{special}->{pattern} = 0;
    return $this;
}

sub newrandom {
    my ($proto,$maxrow,$maxcol,$max,$density,$name) = @_;
    $maxcol = $maxrow unless defined $maxcol;
    $density = 1 unless (defined $density)&&($density>=0) && ($density<=1);
    my $stoch = new Math::MatrixSparse($name);
    unless (defined $max) {
	for my $i (1..$maxrow) {
	    for my $j (1..$maxcol) {
		my $uniform = rand;
		next unless $uniform<=$density;
		$stoch->assign($i,$j,rand);
	    }
	}
	return $stoch;
    }
    $name = "" unless defined $name;
    $stoch->assign($maxrow,$maxcol,0);
    my $k = 1;
    while ($k<=$max) {
	my ($i,$j) = (int($maxrow* rand)+1,int($maxcol* rand)+1);
	next if $stoch->element($i,$j);
	my $uniform = rand;
	if ($uniform>$density) {
	    carp "Math::MatrixReal::newrandom ignoring element";
	}
	next unless $uniform <= $density;
	$stoch->assign($i,$j,rand);
	$k++;
    }
    $stoch->{special}->{sign}="nonnegative";
    return $stoch;
}

### INPUT-OUTPUT METHODS
sub newharwellboeing {
    my ($proto, $filename) = @_;
    open(HB,"<$filename" ) || croak "Math::MatrixSparse::newharwellboeing Can't open $filename\n";
    my $this = new Math::MatrixSparse;
    $_ = <HB>;
    chomp();
    my ($ident, $key) = $_ =~ m/^(.*)(........)\s*$/;
    $key =~ s/\s*$//;
    $this->{name} = $key;
    $_ = <HB>;
    chomp();
    my ($lines, $pline, $rline, $nvline, $rhsline) = $_ =~ 
     m/^\s*(\d{1,14})\s*(\d{1,14})\s*(\d{1,14})\s*(\d{1,14})\s*(\d{1,14})\s*$/;
    $_ = <HB>;
    chomp();
    my ($mattype, $rows, $columns, $rvi, $eme) = $_ =~ 
         m/^\s*(...)\s*(\d{1,14})\s*(\d{1,14})\s*(\d{1,14})\s*(\d{1,14})\s*$/;
    if ($mattype =~ /^C/) {
	croak "Math::MatrixSparse::newharwellboeing Complex types not implemented, exiting\n";
    } else {
	$this->{special}->{field} = "real";
    }
    $this->{rows} = $rows;
    $this->{columns} = $columns; 
    my $formatline = <HB>;
    chomp($formatline);
    my ($colft, $rowft, $valft,$rhsft) = $formatline =~ m/(\([a-zA-Z0-9.+-+]+\))/g;
    unless (($colft =~ /I/i)&&($rowft =~ /I/i)) {
	carp "Math::MatrixSparse::newharwellboeing non-integer format for rows and columns";
    }
    $valft =~ s/\d+P//g;
    my ($valrep, $valsize) = $valft =~ m/(\d+)[a-zA-Z](\d+)/;
    my $valregex = '.' x $valsize;
    my $rhsspec;
    if ($rhsline) {
	$rhsspec = <HB>;
	chomp($rhsspec);
    }
    #now read the column pointer data...
    my @colpointers;
    for my $i  (1..$pline) {
	$_ = <HB>;
	s/^\s*//;
	s/\s*$//;
	push @colpointers, split(/\s+/);
    }
    #...and the row data...
    my @rowindex;
    for my $i (1..$rline) {
	$_ = <HB>;
	s/^\s*//;
	s/\s*$//;
	push @rowindex, split(/\s+/);
    }
    #...and any value data.  If the matrix is a pattern type, fill
    # @values with ones.  
    my @values;
    if ($mattype =~ m/^P..$/i) {
	@values = (1) x $rvi;
    } else {
	for my $i (1..$nvline) {
	    $_ = <HB>;
	    s/D/e/g;
	    push @values, map {s/\s//g; $_+0} m/$valregex/g;
	}
    }

    my $curcol = 1;
    foreach my $i (0..($#colpointers-1)) {
	my $thiscol = $colpointers[$i];
	my $nextcol = $colpointers[$i+1];
	my @rowslice = @rowindex[$thiscol-1..$nextcol-2];
	my @valslice = @values[$thiscol-1..$nextcol-2];
	foreach my $j (0..$#rowslice) {
	    $this->assign($rowslice[$j],$curcol,$valslice[$j]);
	}
	$curcol++;
    }
    if ($mattype =~ /^.S.$/) {
	 $this->_symmetrify();
    } elsif ($mattype =~ /^.Z.$/) {
	$this->_skewsymmetrify();
    }

    return $this;
}

sub newmatrixmarket {
    my ($proto, $filename) = @_;
    my $this = new Math::MatrixSparse;
    confess "Math::MatrixSparse::newmatrixmarket undefined filename" unless defined $filename;
    open(MM,"<$filename" ) || croak "Math::MatrixSparse::newmatrixmarket Can't open $filename for reading";
    $_=<MM>;
    unless (/^\%\%MatrixMarket/) {
	confess "Math::MatrixSparse::newmatrixmarket Invalid start of file";
    }
    unless (/coordinate/i) {
	confess "Math::MatrixSparse::newmatrixmarket dense format not implemented";
    }
    if (/complex/i) {
	carp "Math::MatrixSparse::newmatrixmarket Complex matrices not implemented, ignoring imaginary part\n";
	$this->{special}->{field} = "real";
    } else {
	$this->{special}->{field} = "real";
    }
    my $specifications = $_;
    my $ispattern;
    my $issymmetric;
    my $isskewsymmetric;
    if ($specifications =~ /pattern/i) {
	$ispattern = 1;
	$this->{special}->{pattern} = 1;
    } 
    $this->{name} = $filename;
    my $startdata=0;
    my $entries =0;
    my ($rows,$columns);

    while (<MM>) {
	next if /^\%/;
	unless ($startdata) {
	    s/^\s*//;
	    s/\s*$//;
	    ($rows,$columns,$entries) = split(/\s+/);
	    $this->{rows} = $rows;
	    $this->{columns} = $columns;
	    $startdata = 1;
	} else {
	    s/^\s*//;
	    s/\s*$//;
	    ($rows,$columns,$entries) = split(/\s+/);
	    $entries = 1 if $ispattern;
	    $this->assign($rows,$columns,$entries);
	}
    }
    if ($specifications =~ /\Wsymmetric/i) {
	$this->{special}->{structure} = "symmetric";
	return $this->symmetrify();
    } 
    if ($specifications =~ /skewsymmetric/i) {
	$this->{special}->{structure} = "skewsymmetric";
	return $this->skewsymmetrify();
    } 
#    if ($specifications =~ /hermetian/i) {
#	$this->{special}->{structure} = "hermetian";
#	return $this->symmetrify();
#    } 
    return $this;
}

sub writematrixmarket {
    my ($matrix, $filename) = @_;
    open(MM,">$filename" ) || croak "Math::MatrixSparse::newmatrixmarket Can't open $filename for writing";
    print MM '%%MatrixMarket matrix coordinate ';
    print MM $matrix->{special}->{pattern} ? "pattern " : "real ";
    if ($matrix->{special}->{structure} =~ m/^symmetric/i) {
	$matrix=$matrix->symmetrify();
	print MM "symmetric";
    } elsif ($matrix->{special}->{structure} =~ m/skewsymmetric/i) {
	$matrix=$matrix->skewsymmetrify();
	print MM "skewsymmetric";
    } else {
	print MM "general\n";
    }
    print MM "$matrix->{rows} $matrix->{columns} ";
    print MM $matrix->count() , "\n";
    if ($matrix->{special}->{pattern}) {
	foreach my $key ($matrix->sortbycolumn()) {
	    my ($i,$j) = &splitkey($key);
	    next unless $matrix->element($i,$j);
	    print MM "$i $j\n";
	}
    } else {
	foreach my $key ($matrix->sortbycolumn()) {
	    my ($i,$j) = &splitkey($key);
	    print MM "$i $j ", $matrix->{data}{$key}, "\n";
	}
    }
    return;
}


sub copy {
    my ($proto,$name) = @_;
    my $this = new Math::MatrixSparse;
    return $this unless defined $proto;
    if (defined $proto->{data}) {
	%{$this->{data}} = %{$proto->{data}};
    }
    %{$this->{special}} = %{$proto->{special}};
    $this->{name} = defined $name ? $name : $proto->{name};
    $this->{rows} = $proto->{rows};
    $this->{columns} = $proto->{columns};
    return $this;
}

sub name {
    my ($object,$name) = @_;
    $object->{name} = $name;
    return $name;
}

### INSERTION AND LOOKUP METHODS
sub assign {
    my ($object, $i,$j,$x)=@_;
    return undef unless ((defined $i) && (defined $j)&&(defined $object));
    $x = 1 if $object->{special}->{pattern};
    return undef unless defined $x;
    #update matrix's shape if necessary.
    if ((defined $object->{special}) &&
	 ($object->{special}->{shape} =~ m/diagonal/i) && 
	 ($i!= $j) ) {
 	if ($i<$j) {
 	    $object->{special}->{shape} = "upper"
 	} else  {
 	    $object->{special}->{shape} = "lower"
 	}
     } elsif (($object->{special}->{shape} =~ m/strictlower/i) 
	      && ($i<= $j) ) {
 	if ($i==$j) {
  	    $object->{special}->{shape} = "lower";
 	} else {
 	    $object->{special}->{shape}="";
 	}
     } elsif (($object->{special}->{shape} =~ m/strictupper/i) 
	      && ($i>= $j) ) { 
 	if ($i==$j) {
 	    $object->{special}->{shape} = "upper";
 	} else {
 	    $object->{special}->{shape}="";
 	}
     } elsif (($object->{special}->{shape} =~ m/^lower/i) && ($i< $j) ) {
 	$object->{special}->{shape}="";
     } elsif (($object->{special}->{shape} =~ m/^upper/i) && ($i= $j) ) { 
        $object->{special}->{shape}="";
     }  
    $object->{special}->{pattern} = 0 unless ($x==1);
    #update bandwidth
    if (abs($i-$j) > $object->{special}->{bandwidth}) {
	$object->{special}->{bandwidth} = abs($i-$j);
    }
    #update symmetric and skew-symmetric structure if necessary
     if (
 	($i!=$j) && ( defined $object->{special}->{structure}) &&
  	(
 	 ($object->{special}->{structure} =~ /symmetric/i)
# 	 ||($object->{special}->{structure} =~ /hermetian/i)
 	 )
 	) {
 	$object->{special}->{structure} = "";
     } elsif (($i==$j)&&
 	     ($object->{special}->{structure} =~ /skewsymmetric/i)&&
	      ($x)) {
 	#skew-symmetric matrices must have zero diagonal
 	$object->{special}->{structure} = "";
     }
    #update sign if necessary
     if ( ($object->{special}->{sign} =~ /^positive/) && ($x<=0) ) {
 	if ($x<0) {
 	    $object->{special}->{sign}="";
 	} else {
 	    $object->{special}->{sign} = "nonnegative";
 	}
     } elsif ( ($object->{special}->{sign} =~ /^negative/) && ($x>=0) ) {
 	if ($x>0) {
 	     $object->{special}->{sign}="";
 	} else {
 	    $object->{special}->{sign} = "nonpositive";
 	}
     } elsif ( ($object->{special}->{sign} =~ /nonnegative/i) && ($x<0) ) {
 	 $object->{special}->{sign}="";
     } elsif ( ($object->{special}->{sign} =~ /nonpositive/i) && ($x>0) ) {
 	 $object->{special}->{sign}="";
     } 
    my $key = &makekey($i,$j);
    delete $object->{sortedrows};
    delete $object->{sortedcolumns};
    delete $object->{data}->{$key};
    $object->{data}->{$key} = $x;
    #update size of matrix, and squareness, if necessary
    $object->{rows} = $i if ($i>$object->{rows});
    $object->{columns} = $j if ($j>$object->{columns});
    $object->{special}->{square} = ( $object->{columns}==$object->{rows});
    return $x;
}

sub assignspecial {
    #as assign, except that it respects special properties of 
    #the matrix.  For example, symmetrical matrices are kept symmetric.  
    my ($object, $i,$j,$x)=@_;
    return undef unless ((defined $i) && (defined $j)&&(defined $object));
    $x = 1 if $object->{special}->{pattern};
    return undef unless defined $x;
    my $key = &makekey($i,$j);
    my $revkey = &makekey($j,$i);
    if ($object->{special}->{structure} =~ m/^symmetric/i) {
	if ($i==$j)  {
	    $object->{data}{$key} = $x;
	} else {
	    $object->{data}{$key} = $x;
	    $object->{data}{$revkey} = $x;
	}
    } elsif ($object->{special}->{structure} =~ m/^symmetric/i) {
	if (($i==$j)&&($x)) {
	    croak "Math::MatrixSparse::assignspecial skewsymmetric matrices must have zero diagonal";
	} else {
	    $object->{data}{$key} = $x;
	    $object->{data}{$revkey} = -$x;
	}
    } else {
	$object->assign($i,$j,$x);
    }
    return $x;
}

sub assignkey {
    my ($object, $key,$x)=@_;
    my ($i,$j) = &splitkey($key);
    return unless ((defined $i) && (defined $j));
    $object->assign($i,$j,$x);
    return $x;
}

sub element {
    my ($object, $i,$j) = @_;
    my $key = &makekey($i,$j);
    if (defined $object->{data}{$key}) {
	return $object->{data}{$key};
    } else {
	return 0;
    }
}

sub elementkey {
    my ($object, $key) = @_;
    if (defined $object->{data}{$key}) {
	return $object->{data}{$key};
    } else {
	return 0;
    }
}

sub elements {
    my ($matrix) = @_;
    return keys %{$matrix->{data}};
}


#returns row number $row of matrix as a row matrix
sub row {
    my ($matrix, $row,$persist) = @_;
    my $matrow = new Math::MatrixSparse;
    $matrow->{columns} = $matrix->{columns};
    $matrow->{rows} = 1;
    $matrow->name($matrix->{name});
    reuturn $matrow unless $row;
    if ($persist) {
	@{$matrix->{sortedrows}} = $matrix->sortbyrow() 
	    unless defined $matrix->{sortedrows};
    }
    if (defined $matrix->{sortedrows}) {
	#binary search for proper values
	my @rows = @{$matrix->{sortedrows}};
	my ($left,$right) = (0,$#rows);
	my $mid = int(($right+$left)/2.0);
	while (
	       ((&splitkey($rows[$mid]))[0] != $row ) 
	       && ($right-$left>0)
	       ) {
	    if ((&splitkey($rows[$mid]))[0] < $row) {
		$left = $mid;
	    } else {
		$right = $mid;
	    }
	    $mid = int(($right+$left)/2.0);
	}
	return $matrow unless (&splitkey($rows[$mid]))[0]==$row;
	$right = $mid;
	while (  ($right<=$#rows)&&
		 ((&splitkey($rows[$right]))[0]==$row)
		 )
	{
	    $matrow->assign(1,
			    (&splitkey($rows[$right]))[1],
			    $matrix->elementkey($rows[$right]));
	    $right++;
	}
	$left = $mid-1;
	while (  ($left) &&
		 ((&splitkey($rows[$left]))[0]==$row)
		 ){
	    $matrow->assign(1,
			    (&splitkey($rows[$left]))[1],
			    $matrix->elementkey($rows[$left]));
	    $left--;
	}
	return $matrow;
    }
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrow->assignkey($key, $matrix->{data}{$key}) if ($i==$row);
    }
    return $matrow;
}

#returns column number $col of matrix as a column matrix
sub column {
    my ($matrix, $col,$persist) = @_;
    my $matcol = new Math::MatrixSparse;
    $matcol->{columns} = $matrix->{columns};
    $matcol->{cols} = 1;
    $matcol->name($matrix->{name});
    if ($persist) {
	@{$matrix->{sortedcols}} = $matrix->sortbycolumn() unless defined $matrix->{sortedcols};
    }
    if (defined $matrix->{sortedcols}) {
	#binary search for proper values
	my @cols = @{$matrix->{sortedcols}};
	my ($left,$right) = (0,$#cols);
	my $mid = int(($right+$left)/2.0);
	while (
	       ((&splitkey($cols[$mid]))[1] != $col ) 
	       && ($right-$left>0)
	       ) {
	    if ((&splitkey($cols[$mid]))[1] < $col) {
		$left = $mid;
	    } else {
		$right = $mid;
	    }
	    $mid = int(($right+$left)/2.0);
	}
	return $matcol unless (&splitkey($cols[$mid]))[1]==$col;
	$right = $mid;
	while (  ($right<=$#cols)&&
		 ((&splitkey($cols[$right]))[1]==$col)
		 )
	{
	    $matcol->assign((&splitkey($cols[$right]))[0],1,
			    $matrix->elementkey($cols[$right]));
	    $right++;
	}
	$left = $mid-1;
	while (  ($left) &&
		 ((&splitkey($cols[$left]))[1]==$col)
		 ){
	    $matcol->assign((&splitkey($cols[$left]))[0],1,
			    $matrix->elementkey($cols[$left]));
	    $left--;
	}
	return $matcol;
    }
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matcol->assignkey($key, $matrix->{data}{$key}) if ($j==$col);
    }
    return $matcol;
}


### PRINT

sub print {
    my ($object,$name,$rc) = @_;
    return unless defined $object;
    my $label = $name ? $name : $object->{name};
    my @order ;
    $rc = "n" unless defined($rc);
    if ($rc =~ /^r/i) {
	@order = $object->sortbyrow();
    } elsif ($rc =~ /^c/i) {
	@order = $object->sortbycolumn();
	
    } else {
	@order = keys %{$object->{data}};
    }
    foreach my $key (@order){
	my ($i,$j) = &splitkey($key);
	print "$label($i, $j) = ", $object->{data}{$key},"\n";
    }
    return "";
}


###ARITHMETIC METHODS

#left+$right, dimensions must be identical
sub add {
    my ($left,$right,$switch) = @_;
    if (($left->{rows} == $right->{rows})&&($left->{columns} == $right->{columns})) {
	
	my $sum= $left->addfree($right);

	$sum->{rows} = $left->{rows};
	$sum->{columns} = $left->{columns};
	return $sum;
    } else {
	return undef;
    }
}

#as add, but no restrictions on dimensions.   
sub addfree {
    my ($left, $right,$switch) = @_;
    my $sum = new Math::MatrixSparse;
    $sum = $left->copy();
    if ((defined $left->{name})&&(defined $right->{name})) {
	$sum->{name} = $left->{name} . "+" . $right->{name};
    }
    foreach my $rightkey (keys %{$right->{data}}) {
	if (defined $sum->{data}{$rightkey}) {
	    $sum->{data}{$rightkey}+= $right->{data}{$rightkey};
	} else {
	    $sum->{data}{$rightkey} = $right->{data}{$rightkey};
	}
    }
    $sum->{rows} = $left->{rows} >$right->{rows} ? 
	$left->{rows} : $right->{rows};
    $sum->{columns} = $left->{columns} >$right->{columns} ? 
	$left->{columns} : $right->{columns};
    if ($left->{special}->{structure} eq $right->{special}->{structure}) {
	$sum->{special}->{structure} = $left->{special}->{structure};
    }
    if ($left->{special}->{shape} eq $right->{special}->{shape}) {
	$sum->{special}->{shape} = $left->{special}->{shape};
    }
    return $sum;
}


sub subtract {
    my ($left, $right, $switch) = @_;
    if ($switch) {
	($left,$right) = ($right, $left);
    }
    if (
	($left->{rows} == $right->{rows})&&
	($left->{columns} == $right->{columns})
	) {
	my $diff= $left->subtractfree($right);
	$diff->{rows} = $left->{rows};
	$diff->{columns} = $left->{columns};
	return $diff;
    } else {
	return undef;
    }
    
}

#as subtract, but no restrictions on dimensions.   
sub subtractfree {
    my ($left, $right,$switch) = @_;
    my $diff = new Math::MatrixSparse;
    $diff = $left->copy();
    foreach my $rightkey (keys %{$right->{data}}) {
	if (defined $diff->{data}{$rightkey}) {
	    $diff->{data}{$rightkey}-= $right->{data}{$rightkey};
	} else {
	    $diff->{data}{$rightkey} = -1* $right->{data}{$rightkey};
	}
    }
    if ((defined $left->{name})&&(defined $right->{name})) {
	$diff->{name} = $left->{name} . "-" . $right->{name};
    }
    $diff->{rows} = $left->{rows} >$right->{rows} ? 
	$left->{rows} : $right->{rows};
    $diff->{columns} = $left->{columns} >$right->{columns} ? 
	$left->{columns} : $right->{columns};
    if ($left->{special}->{structure} eq $right->{special}->{structure}) {
	$diff->{special}->{structure} = $left->{special}->{structure};
    }
    if ($left->{special}->{shape} eq $right->{special}->{shape}) {
	$diff->{special}->{shape} = $left->{special}->{shape};
    }
    return $diff;
}

sub negate {
    my ($matrix) = @_;
    return $matrix->multiplyscalar(-1);
}

sub _negate {
    my ($matrix) = @_;
    return $matrix->_multiplyscalar(-1);
}

sub multiplyscalar {
    my ($matrix, $scalar) = @_;
    my $product = $matrix->copy();
    $scalar = 0 unless $scalar;
    foreach my $key (keys %{$product->{data}}) {
	$product->assignkey($key,$matrix->elementkey($key)*$scalar);
    }
    $product->{name} = "$scalar*".$product->{name} if defined $product->{name};
    if ($scalar <0 ) {
	if ($matrix->{special}->{sign} =~ m/positive/i) {
	    $product->{special}->{sign} = "negative";
	} elsif ($matrix->{special}->{sign} =~ m/negative/i) {
	    $product->{special}->{sign} = "positive";
	} elsif ($matrix->{special}->{sign} =~ m/nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($matrix->{special}->{sign} =~ m/nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    }  else {
	$product->{special}->{sign} =$matrix->{special}->{sign};
    }
    $product->{special}->{sign} = "zero" unless $scalar;
    return $product;
}

sub _multiplyscalar {
    my ($matrix, $scalar) = @_;
    $scalar = 0 unless $scalar;
    foreach my $key (keys %{$matrix->{data}}) {
	$matrix->{data}{$key} = $matrix->{data}{$key}*$scalar;
    }
    if ($scalar <0 ) {
	if ($matrix->{special}->{sign} =~ m/positive/i) {
	    $matrix->{special}->{sign} = "negative";
	} elsif ($matrix->{special}->{sign} =~ m/negative/i) {
	    $matrix->{special}->{sign} = "positive";
	} elsif ($matrix->{special}->{sign} =~ m/nonpositive/i) {
	    $matrix->{special}->{sign} = "nonnegative";
	} elsif ($matrix->{special}->{sign} =~ m/nonnegative/i) {
	    $matrix->{special}->{sign} = "nonpositive";
	}
    }
    $matrix->{special}->{sign} = "zero" unless $scalar;
    return $matrix;
}


#finds $left*$right, if compatible
sub multiply {
    my ($left,$right,$switch) = @_;
    unless (ref($right)) {
	return $left->multiplyscalar($right);
    }
    return undef if ($left->{columns} != $right->{rows});
    my $product = new Math::MatrixSparse;
    $product->{rows} = $left->{rows};
    $product->{columns} = $right->{columns};
    if ((defined $left->{name})&&(defined $right->{name})) {
	$product->{name} = $left->{name} . "*" . $right->{name};
    }
    foreach my $leftkey (keys %{$left->{data}}) {
	my ($li,$lj) = &splitkey($leftkey);
	foreach my $rightkey (keys %{$right->{data}}) {
	    my ($ri,$rj) = &splitkey($rightkey);
	    next unless ($lj==$ri);
	    my $thiskey = &makekey($li, $rj);
	    my $prod = $left->{data}{$leftkey}*$right->{data}{$rightkey};
	    if (defined $product->{data}{$thiskey}) {
		$product->{data}{$thiskey} += $prod;
	    } else {
		$product->{data}{$thiskey} = $prod;
	    }

	}
	
    }
    if (
	($left->{special}->{sign} =~ /zero/i)||
	($right->{special}->{sign} =~ /zero/i)) {
	$product->{special}->{sign} = "zero";
	return $product;
    }
    if ($left->{special}->{sign} =~ /^positive/i) {
	$product->{special}->{sign} = $right->{special}->{sign};
    } elsif ($left->{special}->{sign} =~ /nonpositive/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /^negative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "negative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "positive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /nonnegative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonnegative";
	}
    }
    return $product;
    
}


sub quickmultiply {
    my ($left,$right,$switch) = @_;
    unless (ref($right)) {
	return $left->multiplyscalar($right);
    }
    return undef if ($left->{columns} != $right->{rows});
    my $product = new Math::MatrixSparse;
    $product->{special}->{structure} = "";
    $product->{special}->{pattern}=0;
    $product->{special}->{shape} = "";
    $product->{rows} = $left->{rows};
    $product->{columns} = $right->{columns};
    my @leftcols = $left->sortbycolumn();
    my @rightrows = $right->sortbyrow();
    if ((defined $left->{name})&&(defined $right->{name})) {
	$product->{name} = $left->{name} . "*" . $right->{name};
    }
    my $lastrow = 0;
    foreach my $leftkey (@leftcols) {
	my ($li,$lj) = &splitkey($leftkey);
	my $i = 0;
	my $thiskey;
	if ($lj >$lastrow ) {
	    $lastrow = $lj;
	    #remove elements that won't be used again in multiplication
	    while (defined ($thiskey = $rightrows[0])){
		my ($ri,$rj) = &splitkey($thiskey);
		last if $ri>=$lj;
		shift @rightrows;
	    }
	}
	foreach my $rightkey (@rightrows) {
	    my ($ri,$rj) = &splitkey($rightkey);
	    last if ($ri>$lj);
	    next if ($ri<$lj);
	    my $thiskey = &makekey($li, $rj);
	    my $prod = $left->{data}{$leftkey}*$right->{data}{$rightkey};
	    if (defined $product->{data}{$thiskey}) {
		$product->{data}{$thiskey} += $prod;
	    } else {
		$product->{data}{$thiskey} = $prod;
	    }

	}
	
    }
    if (
	($left->{special}->{sign} =~ /zero/i)||
	($right->{special}->{sign} =~ /zero/i)) {
	$product->{special}->{sign} = "zero";
	return $product;
    }
    if ($left->{special}->{sign} =~ /^positive/i) {
	$product->{special}->{sign} = $right->{special}->{sign};
    } elsif ($left->{special}->{sign} =~ /nonpositive/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /^negative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "negative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "positive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /nonnegative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonnegative";
	}
    }
    return $product;
    
}

sub quickmultiplyfree {
    my ($left,$right,$switch) = @_;
    unless (ref($right)) {
	return $left->multiplyscalar($right);
    }
    my $product = new Math::MatrixSparse;
    $product->{rows} = $left->{rows};
    $product->{columns} = $right->{columns};
    my @leftcols = $left->sortbycolumn();
    my @rightrows = $right->sortbyrow();
    if ((defined $left->{name})&&(defined $right->{name})) {
	$product->{name} = $left->{name} . "*" . $right->{name};
    }
    my $lastrow = 0;
    foreach my $leftkey (@leftcols) {
	my ($li,$lj) = &splitkey($leftkey);
	my $i = 0;
	my $thiskey;
	if ($lj >$lastrow ) {
	    $lastrow = $lj;
	    #remove elements that won't be used again in multiplication
	    while (defined ($thiskey = $rightrows[0])){
		my ($ri,$rj) = &splitkey($thiskey);
		last if $ri>=$lj;
		shift @rightrows;
	    }
	}
	foreach my $rightkey (@rightrows) {
	    my ($ri,$rj) = &splitkey($rightkey);
	    last if ($ri>$lj);
	    next if ($ri<$lj);
	    my $thiskey = &makekey($li , $rj);
	    my $prod = $left->{data}{$leftkey}*$right->{data}{$rightkey};
	    if (defined $product->{data}{$thiskey}) {
		$product->{data}{$thiskey} += $prod;
	    } else {
		$product->{data}{$thiskey} = $prod;
	    }

	}
	
    }
    if (
	($left->{special}->{sign} =~ /zero/i)||
	($right->{special}->{sign} =~ /zero/i)) {
	$product->{special}->{sign} = "zero";
	return $product;
    }
    if ($left->{special}->{sign} =~ /^positive/i) {
	$product->{special}->{sign} = $right->{special}->{sign};
    } elsif ($left->{special}->{sign} =~ /nonpositive/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /^negative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "negative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "positive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /nonnegative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonnegative";
	}
    }
    return $product;
    
}


#as multiply, but no restrictions on dimensions.
sub multiplyfree {
    my ($left,$right,$switch) = @_;
    my $product = new Math::MatrixSparse;
    $product->{rows} = $left->{rows};
    $product->{columns} = $right->{columns};
    if ((defined $left->{name})&&(defined $right->{name})) {
	$product->{name} = $left->{name} . "*" . $right->{name};
    }
    foreach my $leftkey (keys %{$left->{data}}) {
	my ($li,$lj) = &splitkey($leftkey);
	foreach my $rightkey (keys %{$right->{data}}) {
	    my ($ri,$rj) = &splitkey($rightkey);
	    next unless ($lj==$ri);
	    my $thiskey = &makekey($li, $rj);
	    my $prod = $left->{data}{$leftkey}*$right->{data}{$rightkey};
	    if (defined $product->{data}{$thiskey}) {
		$product->{data}{$thiskey} += $prod;
	    } else {
		$product->{data}{$thiskey} = $prod;
	    }

	}
    }
    if (
	($left->{special}->{sign} =~ /zero/i)||
	($right->{special}->{sign} =~ /zero/i)) {
	$product->{special}->{sign} = "zero";
	return $product;
    }
    if ($left->{special}->{sign} =~ /^positive/i) {
	$product->{special}->{sign} = $right->{special}->{sign};
    } elsif ($left->{special}->{sign} =~ /nonpositive/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /^negative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "negative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "positive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonpositive";
	}
    } elsif ($left->{special}->{sign} =~ /nonnegative/i) {
	if ($right->{special}->{sign} =~ /^positive/i) {
	    $product->{special}->{sign} = "nonnegative";
	} elsif ($right->{special}->{sign} =~ /nonpositive/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /^negative/i) {
	    $product->{special}->{sign} = "nonpositive";
	} elsif ($right->{special}->{sign} =~ /nonnegative/i) {
	    $product->{special}->{sign} = "nonnegative";
	}
    }
    return $product;
    
}

sub kronecker {
    my ($left,$right);
    my ($rr,$rc) = $right->size();
    return undef unless ($rr&&$rc);
    my $kroprod = new Math::MatrixSparse;
    foreach my $key (keys %{$left->{data}}) {
	my ($i,$j) = &splitkey($key);
	$kroprod->_insert($i*$rr,$j*$rc,$right*$left->elementkey($key));
    }
    if ((defined $left->{name})&&(defined $right->{name})) {
	$kroprod->{name} = $left->{name} . "x" . $right->{name};
    }
    return $kroprod;
}

sub termmult {
    my ($left,$right) = @_;
    my $termprod = $left->copy();
    foreach my $key (keys %{$termprod->{data}}) {
	$termprod->assignkey($key,$termprod->elementkey($key)* $right->elementkey($key));
    }
    return $termprod;
    
}

sub exponentiate {
    my ($matrix,$power)  = @_;
    unless ($matrix->is_square()) {
	carp "Math::MatrixSparse::exponentiate matrix must be square";
	return undef ;
    }
    return Math::MatrixSparse->newidentity($matrix->{rows}) unless $power;
    unless ($power>0) {
	carp "Math::MatrixSparse::exponentiate exponent must be positive";
	return undef ;
    }
    unless ($power =~ /^[+]?\d+/) {
	carp "Math::MatrixSparse::exponentiate exponent must be an integer";
	return undef ;
    }
    my $product = $matrix->copy();
#    $product->clearspecials();
    for my $i (2..$power) {
	$product = $product->quickmultiply($matrix);
    }
    $product->{name} = $matrix->{name} ."^$power" if  $matrix->{name};
    return $product;
}

sub largeexponentiate {
    #find matrix^power using the square-and-multiply method
    my ($matrix,$power)  = @_;
    unless ($matrix->is_square()) {
	carp "Math::MatrixSparse::exponentiate matrix must be square";
	return undef ;
    }
    return Math::MatrixSparse->newidentity($matrix->{rows}) unless $power;
    unless ($power>0) {
	carp "Math::MatrixSparse::exponentiate exponent must be positive";
	return undef ;
    }
    unless ($power =~ /^[+]?\d+/) {
	carp "Math::MatrixSparse::exponentiate exponent must be an integer";
	return undef ;
    }
    #get a representation of $exponent in binary
    my $bitstr = unpack('B32',pack('N',$power));
    $bitstr =~s/^0*//;
    my @bitstr=split(//,$bitstr);
    my $z = Math::MatrixSparse->newidentity($matrix->{rows});
    foreach my $bit (@bitstr){
        $z = ($z*$z);
        if ($bit){
            $z = ($z*$matrix);
        }
    }
    $z->{name} = "";
    $z->{name} = $matrix->{name} . "^$power" if  $matrix->{name};
    return $z;
}


sub transpose {
    my ($matrix) = @_;
    my $this= new Math::MatrixSparse;
    $this->{rows} = $matrix->{columns};
    $this->{columns} = $matrix->{rows};
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$this->assign($j,$i,$matrix->{data}{$key});
    }
    $this->{name} = $matrix->{name} . "'" if $matrix->{name};
    $this->{special}->{structure} = $matrix->{special}->{structure};
    $this->{special}->{sign} = $matrix->{special}->{sign};
    $this->{special}->{pattern} = $matrix->{special}->{pattern};
    $this->{special}->{square} = $matrix->{special}->{square};
    if ($matrix->{special}->{shape} =~ /diagonal/i) {
	$this->{special}->{shape}  = "diagonal";
    } elsif ($matrix->{special}->{shape} =~ /^lower/i) {
	$this->{special}->{shape}  = "upper";
    } elsif  ($matrix->{special}->{shape} =~ /^upper/i) {
	$this->{special}->{shape}  = "lower";
    } elsif  ($matrix->{special}->{shape} =~ /strictupper/i) {
	$this->{special}->{shape}  = "strictlower";
    } elsif  ($matrix->{special}->{shape} =~ /strictlower/i) {
	$this->{special}->{shape}  = "strictlower";
    } else {
	$this->{special}->{shape} = "";
    }
    return $this;
}


sub terminvert {
    my ($matrix) = @_;
    my $this = $matrix->copy();
    foreach my $key (keys %{$this->{data}}) {
	next unless $this->{data}{$key};
	$this->{data}{$key} = 1.0/($this->{data}{$key});
    }
    return $this;
}

sub _terminvert {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}) {
	next unless $matrix->{data}{$key};
	$matrix->{data}{$key} = 1.0/($matrix->{data}{$key});
    }
    return $matrix;
}



### DISSECTION METHODS
sub diagpart {
    my ($matrix,$offset) = @_;
    my $diag = new Math::MatrixSparse;
    $offset = 0 unless defined $offset;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next unless ($i == ($j+$offset));
	$diag->assign($i,$j,$matrix->{data}{$key});
    }
    $diag->{rows} = $matrix->{rows};
    $diag->{columns} = $matrix->{columns};
    $diag->{special}->{shape} = "diagonal";
    return $diag;
}

sub nondiagpart {
    my ($matrix,$offset) = @_;
    my $diag = new Math::MatrixSparse;
    $offset = 0 unless defined $offset;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next if ($i == ($j+$offset));
	$diag->assign($i,$j,$matrix->{data}{$key});
    }
    $diag->{rows} = $matrix->{rows};
    $diag->{columns} = $matrix->{columns};
    return $diag;
}

sub lowerpart {
    my ($matrix) = @_;
    my $lower = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next unless ($i > $j);
	$lower->assign($i,$j,$matrix->{data}{$key});
    }
    $lower->{rows} = $matrix->{rows};
    $lower->{columns} = $matrix->{columns};
    $lower->{special}->{shape} = "strictlower";

    return $lower;
}

sub nonlowerpart {
    my ($matrix) = @_;
    my $lower = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next if ($i > $j);
	$lower->assign($i,$j,$matrix->{data}{$key});
    }
    $lower->{rows} = $matrix->{rows};
    $lower->{columns} = $matrix->{columns};
    $lower->{special}->{shape} = "upper";
    return $lower;
}

sub upperpart {
    my ($matrix) = @_;
    my $upper = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next unless ($i < $j);
	$upper->assign($i,$j,$matrix->{data}{$key});
    }
    $upper->{rows} = $matrix->{rows};
    $upper->{columns} = $matrix->{columns};
    $upper->{special}->{shape} = "strictupper";
    return $upper;
}

sub nonupperpart {
    my ($matrix) = @_;
    my $upper = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	next if ($i < $j);
	$upper->assign($i,$j,$matrix->{data}{$key});
    }
    $upper->{rows} = $matrix->{rows};
    $upper->{columns} = $matrix->{columns};
    $upper->{special}->{shape} = "lower";

    return $upper;
}


sub _diagpart {
    my ($matrix,$offset) = @_;
    $offset = 0 unless defined $offset;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) unless ($i == ($j+$offset));
    }
    $matrix->{special}->{shape} = "diagonal";
    return $matrix;
}

sub _nondiagpart {
    my ($matrix,$offset) = @_;
    $offset = 0 unless defined $offset;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) if ($i == ($j+$offset));
    }
    $matrix->{special}->{shape}="" if 
	$matrix->{special}->{shape} =~ m/diagonal/i;
    return $matrix;
}


sub _lowerpart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) unless ($i > $j);
    }
    $matrix->{special}->{shape} = "strictlower";
    return $matrix;
}

sub _nonlowerpart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) if ($i > $j);
    }
    $matrix->{special}->{shape} = "upper";
    return $matrix;
}

sub _upperpart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) unless ($i < $j);
    }
    $matrix->{special}->{shape} = "strictupper";
    return $matrix;
}

sub _nonupperpart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	my ($i,$j) = &splitkey($key);
	$matrix->delete($i,$j) if ($i < $j);
    }
    $matrix->{special}->{shape} = "lower";
    return $matrix;
}


sub symmetricpart {
    #.5*( A+A' )
    my ($matrix) = @_;
    my $sp =($matrix+$matrix->transpose());
    $sp = 0.5*$sp;
    $sp->{special}->{structure} = "symmetric";
    return $sp;
    
}
sub _symmetricpart {
    #.5*( A+A' )
    my ($matrix) = @_;
    my $sp =($matrix+$matrix->transpose());
    $sp = 0.5*$sp;
    $sp->{special}->{structure} = "symmetric";
    return $matrix=$sp->copy();
}

sub skewsymmetricpart {
    #.5*( A-A' )
    my ($matrix) = @_;
    my $ssp= 0.5*($matrix-$matrix->transpose());
    $ssp->{special}->{structure} = "skewsymmetric";
    return $ssp;
}

sub _skewsymmetricpart {
    #.5*( A-A' )
    my ($matrix) = @_;
    my $ssp= 0.5*($matrix-$matrix->transpose());
    $ssp->{special}->{structure} = "skewsymmetric";
    return $matrix=$ssp->copy();
}


sub positivepart {
    my ($matrix) = @_;
    my $pos = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	next unless $matrix->elementkey($key) >0;
	$pos->assignkey($key,$matrix->{data}{$key});
    }
    $pos->{rows} = $matrix->{rows};
    $pos->{columns} = $matrix->{columns};
    return $pos;
}


sub negativepart {
    my ($matrix) = @_;
    my $neg = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}){
	next unless $matrix->elementkey($key) <0;
	$neg->assignkey($key,$matrix->{data}{$key});
    }
    $neg->{rows} = $matrix->{rows};
    $neg->{columns} = $matrix->{columns};
    return $neg;
}

sub _positivepart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	next if $matrix->elementkey($key) >0;
	$matrix->deletekey($key,$matrix->{data}{$key});
    }
    return $matrix;
}

sub _negativepart {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}){
	next if $matrix->elementkey($key) <0;
	$matrix->deletekey($key,$matrix->{data}{$key});
    }
    return $matrix;
}


sub mask{
    my ($matrix, $i1,$i2,$j1,$j2) = @_;
    return undef  unless (($i1<=$i2)&&($j1<=$j2));
    my $mask = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	next unless (($i>=$i1)&&($i<=$i2));
	next unless (($j>=$j1)&&($j<=$j2));
	$mask->assignkey($key,$matrix->{data}{$key});
    }
    return $mask;
}

sub _mask{
    my ($matrix, $i1,$i2,$j1,$j2) = @_;
    return undef  unless (($i1<=$i2)&&($j1<=$j2));
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	next if (($i>=$i1)&&($i<=$i2));
	next if (($j>=$j1)&&($j<=$j2));
	$matrix->assignkey($key,0);
    }
    return $matrix;
}

sub submatrix{
    my ($matrix, $i1,$i2,$j1,$j2) = @_;
    return undef  unless (($i1<=$i2)&&($j1<=$j2));
    my $subm = new Math::MatrixSparse;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	next unless (($i>=$i1)&&($i<=$i2));
	next unless (($j>=$j1)&&($j<=$j2));
	$subm->assign($i-$i1,$j-$j1,$matrix->{data}{$key});
    }
    return $subm;
}

sub insert {
    my ($big, $i0,$j0,$small) = @_;
    my $insert = $big->copy();
    foreach my $key (keys %{$small->{data}}){
	my ($i,$j) = &splitkey($key);
	$insert->assignkey($i+$i0,$j+$j0,$small->elementkey($key));
    }
    return $insert;
}

sub _insert {
    my ($big, $i0,$j0,$small) = @_;
    
    foreach my $key (keys %{$small->{data}}){
	my ($i,$j) = &splitkey($key);
	$big->assignkey($i+$i0,$j+$j0,$small->elementkey($key));
    }
    return $big;
}


sub shift {
    my ($matrix, $i1,$j1) = @_;
    my $this = new Math::MatrixSparse;
    $this->{name}=$matrix->{name};
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$this->assign($i+$i1,$j+$j1,$matrix->{data}{$key});
    }
    return $this;
}

sub each {
    my ($matrix,$coderef) = @_;
    my $this = $matrix->copy();
    foreach my $key (keys %{$this->{data}}) {
	my ($i,$j) = &splitkey($key);
	$this->assign($i,$j,&$coderef($this->{data}{$key},$i,$j));
    }
    return $this;
}

sub _each {
    my ($matrix,$coderef) = @_;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$matrix->assign($i,$j,&$coderef($matrix->{data}{$key},$i,$j));
    }
    return $matrix;
}

### INFORMATIONAL AND STATISTICAL METHODS


sub printstats {
    my ($matrix,$name) = @_;
    return unless defined $matrix;

    $name = $name || $matrix->{name} || "unnamed matrix";
    print "Statistics for $name :\n";
    print "rows: $matrix->{rows}\t";
    print "columns: $matrix->{columns}\tdefined elements: ";
    print $matrix->count(), "\n";
    my ($width) = $matrix->width();
    print "Bandwidth: $width\t";
    print "Symmetric " if $matrix->is_symmetric();
    print "Skew-Symmetric " if $matrix->is_skewsymmetric();
#    print "Hermetian " if $matrix->{special}->{structure} =~m/^hermetian/i;
    print "Real " if $matrix->{special}->{field} =~ m/real/i;
#    print "Complex " if $matrix->{special}->{field} =~ m/complex/i;
    print "Strictly " if $matrix->{special}->{shape} =~ m/strict/;
    print "Upper Triangular " if $matrix->{special}->{shape} =~ m/upper/;
    print "Lower Triangular " if $matrix->{special}->{shape} =~ m/lower/;
    print "Diagonal" if $matrix->is_diagonal();
    print "Pattern " if $matrix->is_pattern();
    print "Square " if $matrix->is_square();
    print "\n";
}


sub dim {
    my ($matrix) = @_;
    return ($matrix->{rows},$matrix->{columns});
}

sub exactdim {
    my ($matrix) = @_;
    my $rows=0;
    my $columns = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$rows = $i if $i>$rows;
	$columns = $j if $j > $rows;
    }
    return ($rows,$columns);
}


sub count {
    my ($matrix) = @_;
    return scalar keys %{$matrix->{data}};
}

sub width {
    my ($matrix) = @_;
    return $matrix->{special}->{bandwidth} if $matrix->{special}->{bandwidth};
    my $width = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$width = abs($i- $j) if abs($i-$j) > $width;
    }
    return ($width);
}

sub sum {
    my ($matrix) = @_;
    my $sum = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	$sum += $matrix->elementkey($key);
    }
    return $sum;
}

sub sumeach {
    my ($matrix,$coderef) = @_;
    my $sum = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey( $key);
	$sum += &$coderef($matrix->elementkey($key),$i,$j);
    }
    return $sum;
}

sub abssum {
    my ($matrix) = @_;
    my $sum = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	$sum += abs($matrix->elementkey($key));
    }
    return $sum;
}

sub rownorm {
    my ($matrix) = @_;
    my %rowsums;
    return  0 unless defined $matrix;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$rowsums{$i}+= abs($matrix->elementkey($key));
    }
    return (sort {$a <=> $b} values %rowsums)[0];
}


sub columnnorm {
    my ($matrix) = @_;
    my %columnsums;
    return 0 unless defined $matrix;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$columnsums{$i}+= $matrix->elementkey($key);
    }
    return (sort {$a <=> $b} values %columnsums)[0];
}

sub norm_max {
    return $_[0]->rownorm();
}

sub norm_one {
    return $_[0]->columnnorm();
}

sub norm_frobenius {
    return sqrt($_[0]->sumeach(sub {$_[0]*$_[0]}));
}


sub trace {
    my ($matrix) = @_;
    return $matrix->diagpart()->sum();
}

### BOOLEAN METHODS

sub equals {
    my ($left,$right) = @_;
    return 1 unless ( defined $left|| defined $right);
    return 0 unless  defined $left;
    return 0 unless  defined $right;
    my $truth = 1;
    foreach my $key (keys %{$left->{data}}, keys %{$right->{data}}) {
	$truth *= ($left->elementkey($key) == $right->elementkey($key));
    }
    return $truth;
}

sub is_square { 
    my ($matrix)  = @_;
    return 0 unless  defined $matrix;
    return $matrix->{rows} == $matrix->{columns};
}
sub is_quadratic { 
    my ($matrix)  = @_;
    return 0 unless  defined $matrix;
    return $matrix->{rows} == $matrix->{columns};
}

sub is_symmetric {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    return 1 if $matrix->{special}->{structure} =~ m/^symmetric/;
    return 0 if $matrix->{special}->{structure} =~ m/skewsymmetric/;
#    return 0 if $matrix->{special}->{structure} =~ m/hermetian/;
    
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	my $reversekey = &makekey($j, $i);
	$truth *= ($matrix->elementkey($key)
		   == $matrix->elementkey($reversekey));
	return 0 unless $truth;
    }
    return $truth;
}

sub is_skewsymmetric {
    my ($matrix) = @_;
    return 0 unless  defined $matrix;
    return 0 if $matrix->{special}->{structure} =~ m/^symmetric/;
    return 1 if $matrix->{special}->{structure} =~ m/^skewsymmetric/;
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	my $reversekey = &makekey($j , $i);
	$truth *= ($matrix->elementkey($key) 
		   == -1*$matrix->elementkey($reversekey));
	return 0 unless $truth;
    }
    return $truth;
}

sub is_diagonal {
    my ($matrix) = @_;
    return 0 unless  defined $matrix;
    return 1 if $matrix->{special}->{shape}=~m/diagonal/i;
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$truth *= ($i==$j);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_strictlowertriangular {
    my ($matrix) = @_;
    return 0 unless  defined $matrix;
    return 1 if $matrix->{special}->{shape}=~m/strictlower/i;
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$truth *= ($i > $j);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_strictuppertriangular {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    return 1 if $matrix->{special}->{shape}=~m/strictupper/i;
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$truth *= ($i < $j);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_lowertriangular {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    my $truth = 1;
    return 1 if $matrix->{special}->{shape}=~m/lower/i;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$truth *= ($i >= $j);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_uppertriangular {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    my $truth = 1;
    return 1 if $matrix->{special}->{shape}=~m/upper/i;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$truth *= ($i <= $j);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_positive {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    return 1 if $matrix->{special}->{sign} =~ m/^positive/i;
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= ($matrix->elementkey($key)>0);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_zero {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    my $truth = 1;
    return 1 if $matrix->{special}->{sign} =~ /zero/i;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= ($matrix->elementkey($key)==0);
	return 0 unless $truth;
    }
    return $truth;
}


sub is_nonpositive {
    my ($matrix) = @_;
    my $truth = 1;
    return 0 unless defined $matrix;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= ($matrix->elementkey($key)<=0);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_negative {
    my ($matrix) = @_;
    my $truth = 1;
    return 0 unless defined $matrix;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= ($matrix->elementkey($key)<0);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_nonnegative {
    my ($matrix) = @_;
    my $truth = 1;
    return 0 unless defined $matrix;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= ($matrix->elementkey($key)>=0);
	return 0 unless $truth;
    }
    return $truth;
}

sub is_boolean {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    return 1 if $matrix->{special}->{pattern};
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= (($matrix->elementkey($key) == 0)||($matrix->elementkey($key) == 1));
	return 0 unless $truth;
    }
    return $truth;
}

sub is_pattern {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    return 1 if $matrix->{special}->{pattern};
    my $truth = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	$truth *= (($matrix->elementkey($key) == 0)||($matrix->elementkey($key) == 1));
	return 0 unless $truth;
    }
    return $truth;
}


sub diagnose {
    my ($matrix) = @_;
    return 0 unless defined $matrix;
    my $boolean = 1;
    $matrix->_sizetofit();
    $matrix->{special}->{square}  = ($matrix->{rows} == $matrix->{columns});
    my $upper = 1;
    my $diagonal = 1;
    my $lower = 1;
    my $strictupper = 1;
    my $strictlower = 1;
    my $positive = 1;
    my $nonpositive = 1;
    my $negative = 1;
    my $nonnegative = 1;
    my $zero = 1;
    my $symmetric = 1;
    my $skewsymmetric = 1;
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	my $reversekey = &makekey($j,$i);
        $symmetric *= ($matrix->elementkey($key)
		       == $matrix->elementkey($reversekey));
        $skewsymmetric *= ($matrix->elementkey($key) 
			   == -1*$matrix->elementkey($reversekey));
	$diagonal *= ($i==$j);
	$strictlower *= ($i > $j);
	$lower *= ($i >= $j);
	$strictupper *= ($i > $j);
	$upper *= ($i >= $j);
	$positive *= ($matrix->elementkey($key)>0);
	$nonpositive *= ($matrix->elementkey($key)<=0);
	$negative *= ($matrix->elementkey($key)<0);
	$nonnegative *= ($matrix->elementkey($key)>=0);
	$boolean *= (($matrix->elementkey($key) == 0)
		     ||($matrix->elementkey($key) == 1)); 
	$zero *= !($matrix->elementkey($key));
    }
    $matrix->{special}->{pattern} = $boolean;
    if ($diagonal) {
	$matrix->{special}->{shape} = "diagonal";
    } elsif ($lower) {
	if ($strictlower) {
	    $matrix->{special}->{shape} = "strictlower";
	} else {
	    $matrix->{special}->{shape} = "lower";
	}
    } elsif ($upper) {
	if ($strictlower) {
	    $matrix->{special}->{shape} = "strictupper";
	} else {
	    $matrix->{special}->{shape} = "upper";
	}
    } else {
	$matrix->{special}->{shape}="";
    }
    if ($symmetric) {
	$matrix->{special}->{structure}="symmetric";
    } elsif ($skewsymmetric) {
	$matrix->{special}->{structure}="skewsymmetric";
    } else {
	 $matrix->{special}->{structure}="";
    }
    if ($zero) {
	$matrix->{special}->{sign} = "zero";
    } elsif ($nonpositive) {
	if ($negative) {
	    $matrix->{special}->{sign}="negative";
	} else {
	    $matrix->{special}->{sign}="nonpositive";
	}
    } elsif ($nonnegative) {
	if ($positive) {
	    $matrix->{special}->{sign}="positive";
	} else {
	    $matrix->{special}->{sign}="nonnegative";
	}
    } else {
	$matrix->{special}->{sign}="";
    } 
    return $matrix;
}


### BOOLEAN ARITHMETIC METHODS

sub matrixand {
    my ($matrix1, $matrix2) = @_;
    my $truth = new Math::MatrixSparse;
    $truth->{rows} = ($matrix1->{rows}<$matrix2->{rows}) ? $matrix1->{rows} : $matrix2->{rows};
    $truth->{columns} = ($matrix1->{columns}<$matrix2->{columns}) ? $matrix1->{columns} : $matrix2->{columns};
    foreach my $key (keys %{$matrix1->{data}}) {
	$truth->assignkey($key,$matrix1->elementkey($key)&&
			  $matrix2->elementkey($key));
    }
    if ((defined $matrix1->{name})&&(defined $matrix2->{name})) {
	$truth->{name} = $matrix1->{name} . "&" . $matrix2->{name};
    }
    #should be updated already.
    $truth->{special}->{pattern} = 1;
    return $truth;
}

sub matrixor {
    my ($matrix1, $matrix2) = @_;
    my $truth = new Math::MatrixSparse;
    $truth->{rows} = ($matrix1->{rows}<$matrix2->{rows}) ? $matrix1->{rows} : $matrix2->{rows};
    $truth->{columns} = ($matrix1->{columns}<$matrix2->{columns}) ? $matrix1->{columns} : $matrix2->{columns};
    foreach my $key (keys %{$matrix1->{data}}) {
	$truth->assignkey($key,$matrix1->elementkey($key)||
			  $matrix2->elementkey($key));
    }
    if ((defined $matrix1->{name})&&(defined $matrix2->{name})) {
	$truth->{name} = $matrix1->{name} . "|" . $matrix2->{name};
    }
    #should be updated already.
    $truth->{special}->{pattern} = 1;
    return $truth;
}


### DELETION FUNCTIONS
sub delete {
    my ($matrix,$i,$j) = @_;
    my $key = &makekey($i,$j);
    $matrix->deletekey($key);
    return;
} 

sub deletekey {
    my ($matrix, $key) = @_;
    my $old = $matrix->elementkey($key);
    my ($i,$j) = &splitkey($key);
    delete $matrix->{data}{$key};
    #sign
    if ($matrix->{special}->{sign} =~ /^positive/i) {
	$matrix->{special}->{sign} = "nonnegative";
    } elsif ($matrix->{special}->{sign} =~ /^positive/i) {
	$matrix->{special}->{sign} = "nonpositive";
    } 
    #structure
    if (
	($matrix->{special}->{structure} =~ m/symmetric/i)
	&&($i!=$j)
	) {
	$matrix->{special}->{structure} = "";
    }
    #band
    if (abs($i-$j) >= $matrix->{special}->{bandwidth}) {
	$matrix->{special}->{bandwidth} = 0;
    }
    #pattern--no change necessary
    #shape--no change necessary
    #persistent row and column data
    delete $matrix->{sortedrows};
    delete $matrix->{sortedcolumns};
    return undef;
} 

sub cull {
    my ($matrix) = @_;
    my $this = $matrix->copy();
    foreach my $key (keys %{$this->{data}}) {
	next if $this->{data}{$key};
	$this->deletekey($key);
    }
    return $this;
}

sub _cull {
    my ($matrix) = @_;
    foreach my $key (keys %{$matrix->{data}}) {
	next if $matrix->{data}{$key};
	$matrix->deletekey($key);
    }
    return $matrix;
}

sub threshold {
    my ($matrix,$thresh) = @_;
    return undef if $thresh <0;
    my $this = $matrix->copy();
    foreach my $key (keys %{$this->{data}}) {
	next if abs($this->{data}{$key})>$thresh;
	$this->deletekey($key);
    }
    return $this;
}

sub _threshold {
    my ($matrix,$thresh) = @_;
    return undef if $thresh <0;
    foreach my $key (keys %{$matrix->{data}}) {
	next if abs($matrix->{data}{$key})>$thresh;
	$matrix->deletekey($key);
    }
    return $matrix;
}

sub sizetofit {
    my ($matrix) = @_;
    my $this = $matrix->copy();
    my ($maxrow,$maxcol) = $this->exactdim();
    $this->{rows} = $maxrow;
    $this->{columns} = $maxcol;
    return $this;
}


sub _sizetofit {
    my ($matrix) = @_;
    my ($maxrow,$maxcol) = $matrix->exactdim();
    $matrix->{rows} = $maxrow;
    $matrix->{columns} = $maxcol;
    return $matrix;
}


sub clearspecials {
    my ($matrix) = @_;
    $matrix->{special}->{pattern} = 0;
    $matrix->{special}->{sign} = "";
    $matrix->{special}->{structure} = "";
    $matrix->{special}->{shape} = "";
}

### SOLVER METHODS

sub gaussseidel {
    #solves Ax=b by Gauss-Seidel, or SOR with relaxation parameter 1.
    #b ($constant) and x0 ($guess) should be column vectors.
    my ($matrix, $constant, $guess,$tol, $steps) = @_;
    return $matrix->SOR($constant,$guess,1,$tol,$steps);
}

sub SOR {
    #solves Ax=b by Symmetric Over-Relaxation
    #b ($constant) and x0 ($guess) should be column vectors.
    my ($matrix, $constant, $guess, $omega,$tol, $steps) = @_;
    my $diag = $matrix->diagpart();
    my $lower = $matrix->lowerpart();
    my $upper = $matrix->upperpart();
    my $iterator;
    my $dinv = $diag->terminvert();
    my $soln = $guess->copy();
    foreach my $key (keys %{$constant->{data}}) {
	next  if defined $soln->{data}{$key};
	$soln->{data}{$key} = 0;
    }
    my @lowerkeys = $lower->sortbyrow();
    my @upperkeys = $upper->sortbyrow();
    my @solnkeys = $soln->sortbyrow();
    $steps = 100 unless $steps;
    for my $k (1 .. $steps) {
	my $oldsoln = $soln->copy();
	foreach my $thissolnkey (keys %{$soln->{data}}) {
	    my ($i,$j) = &splitkey($thissolnkey);
	    next unless $j == 1;
	    my $prev = $oldsoln->{data}{$thissolnkey}*(1.0-$omega);
	    my $scal = $omega * $dinv->element($i,$i);
	    my $lowersum=0;
	    my $uppersum = 0;
	    foreach my $lowerkey (@lowerkeys) {
		my ($li,$lj) = &splitkey($lowerkey);
		#unnecessary b/c of source of @lowerkeys
		next if $lj > ($i-1);
#		print "L $li $lj\n";
		$lowersum += $soln->element($lj,1)*$lower->{data}{$lowerkey};
	    }
	    foreach my $upperkey (@upperkeys) {
		my ($ui,$uj) = &splitkey($upperkey);
		#unnecessary b/c of source of @upperkeys
		next if $uj < ($i+1);
		$uppersum += $soln->element($uj,1)*$upper->{data}{$upperkey};
	    }
	    my $update = $prev+$scal*($constant->element($i,1)-$lowersum-$uppersum);
	    $soln->assign($i,1,$update);
	}
	my $err = &abssum($oldsoln-$soln);
	return $soln if $err<$tol;
    }
    return undef;
}


sub jacobi {
    #solves Ax=b by Jacobi iteration.
    #Note that b doesn't have to be a column vector
    #$guess (x0) should be the same size as $constant (b)
    my ($matrix, $constant, $guess,$tol, $steps) = @_;
    my $diag = $matrix->diagpart();
    my $lower = $matrix->lowerpart();
    my $upper = $matrix->upperpart();
    my $iterator;
    my $dinv = $diag->terminvert();
    my $nondiag = ($lower+$upper);
    my $soln = $guess->copy();
    my $oldsoln;
    $steps = 100 unless $steps;
    for my $i (1 .. $steps) {
	$oldsoln=$soln->copy();;
	$soln = $dinv*$constant - $dinv*$nondiag*$soln;
	my $err = &abssum($oldsoln-$soln);
	return $soln if $err<$tol;
    }
    return undef;
}


### SORTING METHODS

#note: column is a secondary sort criterion
# 1 2 3
# 4 5 6
# 7 8 9
sub sortbyrow {
    my ($matrix) = @_;
    my @sorted = map  { $_->[0] }
    sort { ($a->[1] <=> $b->[1])||($a->[2]<=>$b->[2]) }
    map  { [ $_, &splitkey($_) ] } keys %{$matrix->{data}};
    return @sorted;
}

#note: row is a secondary sort criterion
# 1 4 7
# 2 5 8
# 3 6 9
sub sortbycolumn {
    my ($matrix) = @_;
    my @sorted = map  { $_->[0] }
    sort { ($a->[2] <=> $b->[2])||($a->[1]<=>$b->[1]) }
    map  { [ $_, &splitkey($_) ] } keys %{$matrix->{data}};
    
    return @sorted;
}

#note: row is a secondary sort criterion
#lower diagonals are sorted in front of higher ones
#4 7 9
#2 5 8
#1 3 6
sub sortbydiagonal {
    my ($matrix) = @_;
    my @sorted = map  { $_->[0] }
    sort { (($a->[1]-$a->[2]) <=> ($b->[1]-$b->[2]))||($a->[1]<=>$b->[1]) }
    map  { [ $_, &splitkey($_) ] } keys %{$matrix->{data}};
    
    return @sorted;
}

#sorts the elements of $matrix by value, smallest first.
#row is a secondary criterion, and column is tertiaty.
sub sortbyvalue {
    my ($matrix) = @_;
    my @sorted = map  { $_->[0] }
    sort { 
	($matrix->elementkey($a->[0]) <=> $matrix->elementkey($a->[0])) 
	    || ($a->[1]<=>$b->[1])  
		||($a->[2]<=>$b->[2]) 
	}
    map  { [ $_, &splitkey($_) ] } keys %{$matrix->{data}};
    
    return @sorted;
}


### SYMMETRIC METHODS
sub symmetrify {
    #takes a matrix, returns the matrix obtained by reflecting 
    #non-lower part around main diagonal
    my ($matrix) = @_;
    return $matrix if $matrix->{special}->{shape} =~ /diagonal/i;
    my $this = $matrix->copy();
    $this->_symmetrify();
    return $this;
}


sub _symmetrify {
    #takes a matrix, reflects it about main diagonal
    my ($matrix) = @_;
    return $matrix if $matrix->{special}->{shape} =~ /diagonal/i;
    $matrix->_nonlowerpart();
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	unless ($i==$j) {
	    my $transkey = &makekey($j , $i);
	    $matrix->assign($j,$i,$matrix->element($i,$j));
	}
    }
    $matrix->_sizetofit();
    $matrix->{special}->{shape} = "";
    $matrix->{special}->{structure} = "symmetric";
    return $matrix;
}

sub skewsymmetrify {
    #takes a matrix, returns the matrix obtained by reflecting 
    #upper part around main diagonal
    my ($matrix) = @_;
    my $this = $matrix->copy();
    return $this->_skewsymmetrify();
}

sub _skewsymmetrify {
    #takes a matrix, reflects upper part about main diagonal
    my ($matrix) = @_;
    $matrix->_upperpart();
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	my $transkey = &makekey($j , $i);
	$matrix->assign($j,$i,-1*$matrix->element($i,$j));
    }
    $matrix->{special}->{shape} = "";
    $matrix->{special}->{structure} = "skewsymmetric";
    return $matrix;
}


### PROBABILISTIC METHODS
sub normalize {
    my ($matrix) = @_;
    return undef unless defined $matrix;
    my $name = $matrix->{name};
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalize matrix has negative elements";
	return undef;
    }
    my  $matsum = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	$matsum += $matrix->elementkey($key);
    }
    $matrix= $matrix->multiplyscalar(1.0/$matsum) if $matsum;
    $matrix->name($name . "/||" . $name . "||") if ($name);
    return $matrix;
}

sub _normalize {
    
    my ($matrix) = @_;
    return undef unless defined $matrix;
    my $name = $matrix->{name};
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalize matrix has negative elements";
	return undef;
    }
    my  $matsum = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	$matsum += $matrix->elementkey($key);
    }
    $matrix= $matrix->_multiplyscalar(1.0/$matsum) if $matsum;
    $matrix->name($name . "/||" . $name . "||") if ($name);
    return $matrix;
}


sub normalizerows {
    my ($matrix) = @_;
    my %rowsums;
    return undef unless defined $matrix;
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalizerows matrix has negative elements";
	return undef;
    }
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$rowsums{$i}+= $matrix->elementkey($key);
    }
    my $rownormed = $matrix->cull();
    foreach my $key (keys %{$rownormed->{data}}) {
	my ($i,$j) = &splitkey($key);
	next unless $rowsums{$i};
	$rownormed->assign($i,$j,($rownormed->elementkey($key))/$rowsums{$i});
    }
    my $name = $matrix->{name};
    $rownormed->name($name . "/||" . $name . "||") if ($name);
    return $rownormed;
}



sub _normalizerows {
    my ($matrix) = @_;
    my %rowsums;
    return undef unless defined $matrix;
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalizerows matrix has negative elements";
	return undef;
    }
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$rowsums{$i}+= $matrix->{data}{$key};
    }
    $matrix->_cull();
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	next unless $rowsums{$i};
	$matrix->assign($i,$j,($matrix->elementkey($key))/$rowsums{$i});
    }
    my $name = $matrix->{name};
    $matrix->name($name . "/||" . $name . "||") if ($name);
    return $matrix;
}

sub normalizecolumns {
    my ($matrix) = @_;
    my %columnsums;
    return undef unless defined $matrix;
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalizecolumns matrix has negative elements";
	return undef;
    }
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$columnsums{$j}+= $matrix->elementkey($key);
    }
    my $columnnormed = $matrix->copy();
    foreach my $key (keys %{$columnnormed->{data}}) {
	my ($i,$j) = &splitkey($key);
	$columnnormed->assign($i,$j,$columnnormed->elementkey($key)/$columnsums{$j});
    }
    my $name = $matrix->{name};
    $columnnormed->name($name . "/||" . $name . "||") if ($name);
    return $columnnormed;
}


sub _normalizecolumns {
    my ($matrix) = @_;
    my %columnsums;
    return undef unless defined $matrix;
    unless ($matrix->is_nonnegative()) {
	carp "Math::MatrixSparse::normalizecolumns matrix has negative elements";
	return undef;
    }
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$columnsums{$j}+= $matrix->elementkey($key);
    }
    $matrix->_cull();
    foreach my $key (keys %{$matrix->{data}}) {
	my ($i,$j) = &splitkey($key);
	$matrix->assign($i,$j,$matrix->elementkey($key)/$columnsums{$j});
    }
    my $name = $matrix->{name};
    $matrix->name($name . "/||" . $name . "||") if ($name);
    return $matrix;
}


sub discretepdf {
    my ($matrix) = @_;
    my $uniform = rand;

    my $current;
    my $curpos = 0;
    foreach my $key (keys %{$matrix->{data}}) {
	last if $curpos >=$uniform;
	$current = $key;
	$curpos += $matrix->{data}{$key};
    }
    return $current;

}

### KEY-INTERFACE METHODS

sub splitkey {
    my ($key) = @_;
    my ($i,$j) = split(/\0/,$key);
    return ($i,$j);
}

sub makekey {
    my ($i,$j) = @_;
    return ($i . "\0" . $j) if ((defined $i)&&(defined $j));

}


1;
__END__

=head1 NAME

Math::MatrixSparse - Perl extension for sparse matrices.

=head1 SYNOPSIS

Math::MatrixSparse is a module implementing naive sparse matrices.  Its
syntax is designed to partially overlap with Math::MatrixReal where
possible and reasonable.

Basic matrix operations are present, including addition, subtraction,
scalar multiplication, matrix multiplication, transposition,
and exponentiation.

Three methods of solving systems iteratively are available, including
Jacobi, Gauss-Seidel, and Symmetric Over-Relaxation. 

Real-valued matrices can be read from files in the Matrix Market and
Harwell Boeing formats, and written in the Matrix Market format. In
addition, they can be read from a given string.

Certain special types of matrices are understood, but not optimized
for, such as upper and lower triangular, diagonal, symmetric,
skew-symmetric, positive, negative, and pattern.  Methods are
available to determine the properties of a given matrix.

Individual rows, columns, and diagonals of matrices can be obtained,
as can the upper and lower triangular, symmetric, skew symmetric,
positive and negative portions.


=head1 DESCRIPTION

=over 4

=item *

C<< use Math::MatrixSparse; >>

Load the module and make its methods and operators available.

=back

=head2 CREATION AND INPUT-OUTPUT METHODS

=over 4

=item * 

C<< Math::MatrixSparse->new($name) >>

C<< new Math::MatrixSparse($name) >>

Creates a new empty matrix named $name, which may be undef.

=item * 

C<< Math::MatrixSparse->newfromstring($string,$name) >>

Creates a new matrix named $name based on $string.  
$string is of the pattern /(\d+)\s+(\d+)\s+(.+)\n/, 
where ($row, $column, $value) = ($1,$2,$3).  

Example:

 $matrixspec = <<MATRIX;
 1 1 1
 1 2 2
 2 1 3
 3 3 4
 MATRIX
 my $MS = Math::MatrixSparse->newfromstring($matrixspec,"MS");

$MS has four elements, (1,1), (1,2), (2,1), and (3,3), with the values
1,2,3, and 4.

=item * 

C<< Math::MatrixSparse->newdiag($arrayref,$name) >>

Creates a new square matrix named $name from the elements in $arrayref.  
$arrayref[0] will become $matrix(1,1), etc.  

=item * 

C<<  Math::MatrixSparse->newdiagfromstring($string, $name) >>

Similar to C<< Math::MatrixSparse->newfromstring  >> except that 
$string  is of the pattern /(\d+)\s+(.+)\n/, and 
($row, $column, $value) = ($1, $1, $2).

Example:

 $diagspec = <<MATRIX;
 1   1
 2   -1
 20  1 
 300 -1
 MATRIX
 my $MD = Math::MatrixSparse->newdiagfromstring($matrixspec,"MS");

$MD has four elements, (1,1), (2,2), (20,20), and (300,300), with the values
1, -1, 1, and -1, and is square.

=item *

C<< Math::MatrixSparse->newrandom($maxrow, $maxcol, $maxentries, $density,$name) >>

Creates a new matrix of the specified size ($maxrow*$maxcol) with at most
$maxentries.  If $density is between 0 and 1 (inclusive), the expected
number of entries is $maxentries*$density.  If $maxentries is undef, 
it is set to $maxrow*$maxcol; if $maxcol is missing, it is set to 
$maxrow.  If $density is missing, or outside the valid range, it 
is set to one.  


=item *

C<< Math::MatrixSparse->newmatrixmarket($filename)  >>

Creates a new matrix based on data stored in the file $filename,
in Matrix Market format.  See http://www.nist.gov/MatrixMarket/
for more information on this format.  

Pattern matrix data has elements set to one.  Matrices flagged
as symmetric or skew symmetric have symmetrify() or skewsymmetrify()
applied.  

Exits with an error if $filename cannot be read from.

=item *

C<< Math::MatrixSparse->newharwellboeing($filename)  >>

Creates a new matrix based on data stored in the file $filename,
in Harwell-Boeing format.  See 
http://math.nist.gov/MatrixMarket/collections/hb.html
for more information on this format.  

Pattern matrix data has elements set to one.  Matrices flagged
as symmetric or skew symmetric have symmetrify() or skewsymmetrify()
applied.  

Exits with an error if $filename cannot be read from.

=item *

C<< $matrix->writematrixmarket($filename)  >>

The contents of $matrix are written, in Matrix Market format, to 
$filename.  It is assumed that $matrix->{rows} and $matrix->{columns}
are accurate--$matrix->sizetofit() should be called if this is not 
the case.  No optimizations are performed for symmetric, skew symmetric,
or pattern data, and real values are assumed.  

See http://www.nist.gov/MatrixMarket/ for more information on this format.  

Exits with an error if $filename cannot be written to.

=item * 

C<< Math::MatrixSparse->newidentity($n,$m)  >>

Creates an identity matrix with $n rows and $m columns.    If $m
is omitted it is assumed equal to $n.

=item * 

C<< print $matrix >>

C<< $matrix->print($name) >>

C<< $matrix->print() >>

Prints the element in the matrix in the format 
  $name($row,$colum) = $value

Calling this as a method with an argument overrides the value in 
$matrix->{name}.


=back

=head2 INTERFACE METHODS

=over 4

=item * 

C<< ($i,$j) = &splitkey($key) >>

C<< $key = &makekey($i,$j) >>

These two routines convert a position ($i,$j) of the matrix into a
key $key.  Programs that use Math::MatrixSparse should not have to use keys
at all, but if they do, they should use these routines.  

=back

=head2 GENERAL METHODS

=over 4

=item * 

C<< $matrix2 = $matrix1->copy() >>

C<< $matrix2 = $matrix1->copy($name) >>

Returns an exact copy of $matrix1, including dimensions, name,
and special flags.  If $name is given, it will be the name of 
$matrix2.

=item * 

C<< $matrix->name($name) >>

Gives a name to $matrix. Useful mostly in printing.  Certain methods
attempt to create useful names, but you probably want to set your
own. 

=item * 

C<< $matrix->assign($i,$j,$value) >>

Puts $value in row $i, column $j of $matrix.  Updates $matrix->{row}
and $matrix->{column} if necessary.  Removes or modifies special flags when
necessary.  

=item * 

C<< $matrix->assignspecial($i,$j,$value) >>

As $matrix->assign(), except that it preserves symmetry and skew-symmetry.
That is, if $matrix is marked symmetric, assigning a value to ($i,$j) 
also assigns the value to ($j,$i). Also preserves patterns.

=item * 

C<< $matrix->assignkey($key,$value) >>

As $matrix->assign(), except $i and $j have already been combined into $key. 

=item * 

C<< $matrix->element($i,$j) >>

Returns the element at row $i column $j of $matrix.

=item * 

C<< $matrix->elementkey($key) >>

As $matrix->element(), except $i and $j have already been combined into $key. 


=item * 

C<< $matrix->elements() >>

Returns an array consisting of all the elements of $matrix, in 
key form, suitable for a loop.

See also SORTING METHODS below if the order of the elements is important.

Example:
    foreach my $key ($matrix->elements()) {
	my ($i,$j) = &splitkey($key);
	...
    }

=item * 

C<< $matrix->delete($i,$j) >>

Deletes the ($i,$j) element of $matrix.

=item * 

C<< $matrix->deletekey($key) >>

As $matrix->delete(), except $i and $j have already been combined into $key. 

=item * 

C<< $matrix->cull() >>

Returns a copy of $matrix with any zero elements removed.
Equivalent to $matrix->threshold(0).

=item * 

C<< $matrix->threshold($thresh) >>

Returns a copy of $matrix with any elements with absolute value less 
than $thresh removed.

=item * 

C<< $matrix->sizetofit() >>

Returns a copy of $matrix with dimensions sufficient only to cover its data.

=item * 

C<< $matrix->clearspecials() >>

Removes all knowledge of special properties of $matrix.  Use
$matrix->diagnose() to put them back.



=back

=head2 DECOMPOSITIONAL METHODS

=over 4 

=item * 

C<< $matrix->row($i) >>

C<< $matrix->row($i,$persist) >>

Returns a matrix consisting only of the $i th row of $matrix.  If 
$persist is non-zero, the elements of $matrix are sorted by row,
to speed up future calls to row(). 

Note that many methods, most notably assign() and delete(), remove the
data necessary to use the fast algorithm.  If this data is present, a
binary search is used instead of an exhaustive term-by-term search.
There is an intial cost of O(n log n) operations (n==$matrix->count())
to use this data, but each search costs O(log n) operations.  This is
in comparison to O(n) operations without the data.  

So, in summary, if many separate rows are needed, and the matrix
is unchanging, the first (at least) call to row() should have
a non-zero value of $persist.

=item * 

C<< $matrix->column($j) >>

C<< $matrix->column($j,$persist) >>

Returns a matrix consisting only of the $j th column of $matrix.  See
also $matrix->row().


=item * 

C<< $matrix->diagpart($offset) >>

If $offset is zero or undefined, returns a matrix consisting of the
diagonal elements of $matrix, if any. If $offset is non-zero, returns
a parallel diagonal. For example, if $offset=1, the first superdiagonal is
returned.  Posive $offset s return diagonals above the main diagonal, negative
offsets return diagonals below the main diagonal.  

The returned matrix is the same size as $matrix.

=item * 

C<< $matrix->lowerpart() >>

Returns a matrix consisting of the strictly lower triangular parts of $matrix,
if any. The returned matrix is the same size as $matrix.

=item * 

C<< $matrix->upperpart() >>

Returns a matrix consisting of the strictly upper triangular parts of $matrix,
if any. The returned matrix is the same size as $matrix.


=item *

C<< $matrix->nondiagpart($offset) >>
C<< $matrix->nonlowerpart() >>
C<< $matrix->nonupperpart() >>

As before, except that the returned matrix is everything except the 
part specified.  

Example:

 A =  D1  U1  U2
      L1  D2  U3
      L2  L3  D3

 $A->lowerpart() == L1 L2 L3
 $A->diagpart() == D1 D2 D3
 $A->diagpart(1) == U1 U3
 $A->diagpart(-1) == L1 L3
 $A->upperpart() == U1 U2 U3
 $A->nonlowerpart() == D1 U1 U2 D2 U3 D3
 $A->nondiagpart(1) == D1 U2 L1 D2 L2 L3 D3

=item *

C<< $matrix->symmetricpart() >> 

Returns the symmetric part of $matrix, i.e. 0.5*($matrix+$matrix->transpose()).

=item *

C<< $matrix->skewsymmetricpart() >> 

Returns the skewsymmetric part of $matrix,
i.e. 0.5*($matrix-$matrix->transpose()).

=item * 

C<< $matrix->positivepart() >>

Returns the positive part of $matrix, i.e. those elements of $matrix
larger than zero.

=item * 

C<< $matrix->negativepart() >>

Returns the positive part of $matrix, i.e. those elements of $matrix
larger than zero.

=item * 

C<< $matrix->mask($i1,$i2,$j1,$j2) >>

Returns a matrix whose only elements are inside
 ($i1,$j1)    ($i1,$j2)
 ($i2,$j1)    ($i2,$j2)


=item * 

C<< $matrix->submatrix($i1,$i2,$j1,$j2) >>

Returns that portion of $matrix between 
 ($i1,$j1)    ($i1,$j2)
 ($i2,$j1)    ($i2,$j2)

Subscripts are changed, so $matrix($i1,$j1) is $submatrix(1,1).

=item * 

C<< $matrix1->insert($i,$j,$matrix2) >>

The values of $matrix2 are assigned to the values of $matrix1, offset by
($i,$j).  That is, $matrix1($i+$k,$j+$l)=$matrix2($j,$l).

=item *

C<< $A = $matrix->shift($row,$col) >>

Creates a new matrix $A, $matrix($i,$j) == $A($i+$row,$j+$col)

=back

=head2 INFORMATIONAL METHODS

=over 4

=item * 

C<< $matrix->dim() >>

Returns 
 ($matrix->{rows}, $matrix->{columns})


=item * 

C<< $matrix->exactdim() >>

Calculates explicitly the dimension of $matrix.  This differs from
$matrix->dim() in that $matrix->{rows} and $matrix->{columns}
may not have been updated properly.  


=item * 

C<<  $matrix->count() >>

Returns the number of defined elements in $matrix, 0 or otherwise.

=item *

C<< $matrix->width() >>

Calculates the bandwidth of $matrix, i.e. the maximum value of abs($i-$j)
for all elements at ($i,$j) in $matrix.

=item * 

C<< $matrix->sum() >>

Finds the sum of all elements in $matrix.

=item * 

C<< $matrix->abssum() >>

Finds the sum of the absolute values of all elements in $matrix.

=item * 

C<< $matrix->sumeach($coderef) >>

Applies &$coderef to each of the elements of $matrix, and sums the 
result.  See C<< $matrix->each($coderef) >> for more details. 

=item * 

C<< $matrix->columnnorm() >>

C<< $matrix->norm_one() >>

Finds the maximum column sum of $matrix.  That is, for each column of 
$matrix, find the sum of absolute values of its elements, then 
return the largest such sum. C<< norm_one >> is provided for compatibility
with Math::MatrixReal.

=item * 

C<< $matrix->rownorm() >>

C<< $matrix->norm_max() >>

Finds the maximum row sum of $matrix.  That is, for each row of 
$matrix, find the sum of absolute values of its elements, then 
return the largest such sum. C<< norm_max >> is provided for compatibility
with Math::MatrixReal.

=item *

C<< $matrix->norm_frobenius() >>

Finds the Frobenius norm of $matrix.  This is just an alias of 
sqrt($matrix->sumeach(sub {$_[0]*$_[0]}).

=item *

C<< $matrix->trace() >>

Finds the trace of $matrix, which is the sum of its diagonal elements.
This just is an alias for $matrix->diagpart->sum().

=item *

C<< $matrix->diagnose() >>

Sets the special flags of $matrix.   

=back

=head2 BOOLEAN INFORMATIONAL METHODS

The following is_xxx() methods use the special flags if they are present.
If more than one will be called for a given matrix, consider calling
$matrix->diagnose() to set the flags.  

=over 4

=item * 

C<< $matrix->is_square() >>

C<< $matrix->is_quadratic() >>

Returns the value of the comparison 
 $matrix->{rows}==$matrix->{columns}
That is, it returns 1 if the matrix is square, 0 otherwise.

=item * 

C<< $matrix->is_diagonal() >>

Returns 1 if $matrix is a diagonal matrix, 0 otherwise.  $matrix need
not be square.

=item * 

C<< $matrix->is_lowertriangular() >>

Returns 1 if $matrix is a lower triangular matrix, 0 otherwise.  $matrix need
not be square. Diagonal elements are allowed.

=item * 

C<< $matrix->is_strictlowertriangular() >>

Returns 1 if $matrix is a lower triangular matrix, 0 otherwise.  $matrix need
not be square. Diagonal elements are not allowed.

=item * 

C<< $matrix->is_uppertriangular() >>

Returns 1 if $matrix is an upper triangular matrix, 0 otherwise.  $matrix need
not be square. Diagonal elements are allowed.

=item * 

C<< $matrix->is_strictuppertriangular() >>

Returns 1 if $matrix is an upper triangular matrix, 0 otherwise.  $matrix need
not be square. Diagonal elements are not allowed.


=item * 

C<< $matrix->is_positive() >>

Returns 1 if all elements of $matrix are positive, 0 otherwise.

=item * 

C<< $matrix->is_negative() >>

Returns 1 if all elements of $matrix are negative, 0 otherwise.  


=item * 

C<< $matrix->is_nonpositive() >>

Returns 1 if all elements of $matrix are nonpositive (i.e. <=0), 0 otherwise.

=item * 

C<< $matrix->is_nonnegative() >>

Returns 1 if all elements of $matrix are nonnegative (i.e. >=0), 0 otherwise.  


=item * 

C<< $matrix->is_boolean() >>

C<< $matrix->is_pattern() >>

Returns 1 if all elements of $matrix are 0 or 1, 0 otherwise.  

=item *

C<< $matrix->is_symmetric() >>

Returns 1 if $matrix is symmetric, i.e. $matrix==$matrix->transpose(), 
0 otherwise.  $matrix is assumed to be square.

=item *

C<< $matrix->is_skewsymmetric() >>

Returns 1 if $matrix is skew-symmetric, i.e. $matrix==-1*$matrix->transpose(), 
0 otherwise. $matrix is assumed to be square. 



=back

=head2 ARITHMETIC METHODS

=over 4

=item * 

C<< $matrix1->add($matrix2) >>

Finds and returns $matrix1 + $matrix2.  Matrices must be of the same
size.

=item * 

C<< $matrix1->multiply($matrix2) >>

Finds and returns $matrix1 * $matrix2.  $matrix1->{columns} must
equal $matrix2->{rows}.

=item * 

C<< $matrix1->multiplyfree($matrix2) >>

C<< $matrix1->addfree($matrix2) >>

As add() and multiply(), but with no limitations on the dimensions
of the matrices.

=item * 

C<< $matrix1->quickmultiply($matrix2) >>

C<< $matrix1->quickmultiplyfree($matrix2) >>

As multiply() and multiplyfree(), but with a different algorithm that
is faster for larger matrices.

=item * 

C<< $matrix->multiplyscalar($scalar) >>

Returns the product of $matrix and $scalar.

=item *

C<< $matrix1->kronecker($matrix2) >>

Returns the direct product of $matrix1 and $matrix2.  Every element
of $matrix1 is multiplied by the entirely of $matrix2, and those
matrices assembled into a big matrix and returned.  

=item * 

C<< $matrix->exponentiate($n) >>
C<< $matrix->largeexponentiate($n) >>

Finds and returns $matrix raised to the $n th power.  $n must be
nonnegative and integral, and $matrix must be square.

For large values of $n, largeexponentiate() is faster.

=item * 

C<< $matrix->terminvert() >>

Returns the matrix whose elements are the multiplicative inverses of
$matrix.  If $matrix is square diagonal, C<< $matrix->terminvert() >> is
the multiplicative inverse of $matrix.

=item * 

C<< $matrix->transpose() >>

Returns the transpose of $matrix.

=item * 

C<< $matrix->each($coderef) >>

Applies a subroutine referred to by $coderef to each element of $matrix.
&$coderef should take three arguments ($value, $row, $column).  

=item * 

C<< $matrix->symmetrify() >>

Returns a matrix obtained by reflecting $matrix about its main
diagonal. $matrix does not need to be square.

Exits with an error if $matrix(i,j) and $matrix(j,i) both exist
and are not identical.

=item *

C<< $matrix->skewsymmetrify() >>

As symmetrify(), except that the reflected terms are made negative.

Exits with an error if $matrix(i,j) and $matrix(j,i) both exist
and are not negatives of each other.

=item *

C<< $matrix1->matrixand($matrix2) >>

Finds and returns the matrix whose ($i,$j) element is 
 $matrix1($i,$j) && $matrix2($i,$j). 
The returned matrix is a pattern matrix.

=item *

C<< $matrix1->matrixor($matrix2) >>

Finds and returns the matrix whose ($i,$j) element is 
 $matrix1($i,$j) || $matrix2($i,$j).  
The returned matrix is a pattern matrix.


=back

=head2 PROBABILISTIC METHODS

=over 4

=item *

C<< $matrix->normalize()  >>

Returns a matrix $matrix2 scaled so that $matrix2->sum()==1.  

Exits on error if $matrix is not nonnegative.

=item *

C<< $matrix->normalizerows()  >>

As $matrix->normalize(), except that each row is scaled to have a 
sum of 1. 

Exits on error if $matrix is not nonnegative.

=item *

C<< $matrix->normalizecolumns()  >>

As $matrix->normalizerows(), except with columns. Mathematically equivalent to 
$matrix->transpose()->normalizerows()->transpose(). 

Exits on error if $matrix is not nonnegative.

=item *

C<< $matrix->discretepdf() >>

Assuming that $matrix->sum()==1 and $matrix is non-negative, chooses a
random element from $matrix based on the assumption that
the entry at ($i,$j) is the probability of choosing ($i,$j).

=back 

=head2 SOLUTION OF SYSTEMS METHODS

=over 4


=item * 

C<< $matrix->jacobi($constant,$guess, $tol,  $steps) >>

Uses Jacobi iteration to find and return the solution to the
system of equations $matrix * x = $constant, with initial guess
$constant, tolerance $tol,  and maximum iterations $steps.

If $steps is undefined, the default value of 100 is used.

Care should be taken to ensure that $matrix is such that the 
iteration actually converges.

=item * 

C<< $matrix->gaussseidel($constant,$guess,  $tol,  $steps) >>

Uses Gauss-Seidel iteration to find and return the solution to the
system of equations $matrix * x = $constant, with initial guess
$constant, tolerance $tol, and maximum
iterations $steps. This is equivalent to $matrix->SOR with 
relaxation parameter 1.  

Care should be taken to ensure that $matrix is such that the 
iteration actually converges.  

=item * 

C<< $matrix->SOR($constant,$guess, $relax, $tol,  $steps) >>

Uses Successive Over-Relaxation to find and return the solution to the
system of equations $matrix * x = $constant, with initial guess
$constant, relaxation parameter $relax, tolerance $tol, and maximum
iterations $steps.

Care should be taken to ensure that $matrix is such that the 
iteration actually converges.  

=back

=head2 SORTING METHODS

=over 4

=item * 

C<< $matrix->sortbycolumn() >>

C<< $matrix->sortbyrow() >>

Returns an array containing the keys of $matrix, sorted primarily
by either column or row (and secondarily by row or column).  

C<< $matrix->sortbydiagonal() >>

Returns an array containing the keys of $matrix, sorted primarily by
their distance from elements on the main diagonal, lower diagonals
first.  The row of the key is a secondary criterion.

C<< $matrix->sortbyvalue() >>

Returns an array containing the keys of $matrix, sorted primarily by
the value of the element indexed by the key.  Row and column are
secondary and tertiaty criteria. 

These methods are suitable for using inside a loop.  See also 
$matrix->elements() if the order of the elements is not important.

Example:

A 3x3 matrix will be sorted in the following manners:

 sortbycolumn()
 1 4 7 
 2 5 8
 3 6 9

 sortbyrow()
 1 2 3
 4 5 6
 7 8 9

 sortbydiagonal()
 4 7 9
 2 5 8
 1 3 6

=back

=head2 IN-LINE METHODS

The following are as described above, except that they modify their
calling object instead of a copy thereof.  

C<< _each >>

C<< _mask >>

C<< _insert >>

C<< _cull >>

C<< _threshold >>

C<< _sizetofit  >>

C<< _negate  >>

C<< _multiplyscalar  >>

C<< _terminvert  >>

C<< _symmetrify  >>

C<< _skewsymmetrify  >>

C<< _normalize() >>

C<< _normalizerows() >>

C<< _normalizecolumns() >>

C<< _diagpart() >>

C<< _nondiagpart() >>

C<< _upperpart() >>

C<< _nonupperpart() >>

C<< _lowerpart() >>

C<< _nonlowerpart() >>

C<< _positivepart() >>

C<< _negativepart() >>

C<< _symmetricpart() >>

C<< _skewsymmetricpart() >>


In addition to these, the following methods modify the calling object.

C<< name() >>

C<< assign() >>

C<< assignspecial() >>

C<< assignkey() >>

C<< row() >> (if called with the optional second argument)

C<< column() >> (if called with the optional second argument)

C<< diagnose() >>

C<< delete() >>

C<< deletekey() >>

C<< clearspecials() >>


=head2 OVERLOADED OPERATORS

C<< + >> add()

C<< - >> subtract()

C<< * >> quickmultiply()

C<< x >> kronecker()

C<< ** >> exponential()

C<< ~ >> transpose()

C<< & >> matrixand()

C<< | >> matrixor()

C<< "" >> print()

Unary C<< - >> negate()

=head2 SPECIAL MATRIX FLAGS

Certain information is stored about the matrix, and is updated
when necessary.  See also C<< $matrix->diagnose() >>.  All 
flags can also be C<undef>.  These should not be accessed 
directly--use the boolean is_whatever() methods instead.  

=over 4

=item I<structure> 

The symmetry of the matrix. Can be C<symmetric> or C<skewsymmetric>.

=item I<shape>

The shape of the matrix.  Can be C<diagonal>, C<lower> (triangular),
C<upper>, C<strictlower> or C<strictupper>.

=item I<sign>

The sign of all the elemetns of a matrix.  Can be C<positive>, 
C<negative>, C<nonpostive>, C<nonnegative>, or C<zero>.

=item I<pattern>

Indicates whether the matrix should be treated as a pattern.  
Is non-zero if so.  

=item I<bandwidth> 

Calculates the bandwidth of $matrix, i.e. the maximum value of abs($i-$j)
for all elements at ($i,$j) in $matrix.

=item I<field>

The underlying field of the elements of the matrix.  Currently, can
only be C<real>.

=back

=head2 INTERFACING

The user should not attempt to access the pieces of a Math::MatrixReal
object directly, but instead use the routines provided.  Certain
methods, such as the sorters, return keys to the elements of the matrix,
and these should be fed into C<< splitkey() >> to obtain row-column 
indices.  

=head1 EXPORT

None.

=head1 EXPORT_OK

&splitkey() and &makekey().  

=head1 BUGS

Horribly, hideously inefficient.

No checks are made to be sure that values are of a proper type, or
even that indices are integers.  It is entirely possible to
assign() a value that is, say, another Math::MatrixSparse. 
However, because of the lack of these checks, indices can start at
zero, or even negative values, if an algorithm calls for it.  

Harwell Boeing support is not robust, and output is not implemented.

Complex matrices in Harwell Boeing and Matrix Market are not supported.
In Matrix Market format, only the real part is read--the imaginary
part is discarded.  

Many methods do not modify their calling object, but instead return a
new object.  This can be inefficent and a waste of resources,
especially when it will be assigned to the new object anyway.  Use the
analogous methods listed in IN-LINE METHODS instead if this is an
issue.

=head1 AUTHOR

Jacob C. Kesinger, E<lt>kesinger@math.ttu.eduE<gt>

=head1 SEE ALSO

L<perl>, Math::MatrixReal.

=cut
