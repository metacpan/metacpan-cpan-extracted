package HTML::Paging::SQL;

#
# PARAMETER README
#
# $hash->{"HP_A"} : all page(s) amount
# $hash->{"HP_C"} : curret page number
# $hash->{"HP_P"} : other user parameter
# $hash->{"HP_U"} : user script uri
#

#
# Set GET to POST method
#
sub BEGIN {
	# set version to ENV
	$HTML::Paging::SQL::revision = '$Id: SQL.pm,v 1.17 2002/01/18 12:37:57 wangaocheng Exp $';
	($HTML::Paging::SQL::VERSION) = '$Revision: 1.17 $' =~ /(\d+\.\d+)/;
	$ENV{"HTML_PAGING_SQL"} = $HTML::Paging::SQL::VERSION;
	if ($ENV{"REQUEST_METHOD"} eq "POST") {
		sysread(STDIN, $HTML::Paging::SQL::buffer, $ENV{"CONTENT_LENGTH"});
		$ENV{"REQUEST_METHOD"} = "GET";
		$ENV{"QUERY_STRING"} = "$HTML::Paging::SQL::buffer";
	}
}

#
# Create a new object
#
sub new {
	my $class = shift;
	my $self = {};
	# process user parameter
	if (ref($_[0]) eq "HASH") {
		$self = shift;
	} else {
		my %self = @_;
		$self = \%self;
	}	
	if ($self->{"all"} !~ m/^\d+$/) {
		$self->{"all"} = 0; # process error here
	}
	if ($self->{"num"} !~ m/^\d+$/) {
		$self->{"num"} = 10; # set per page default
	}
	return bless $self,$class;
}

#
# Format output with Number Mode
#
sub number {
	my $self = shift;
	my $hash = $self->_status();
	my @result;
	$result[1] = $self->{"num"} * ($hash->{"HP_C"}-1);
	$result[2] = $self->{"num"};
	if ($self->{"all"} < $self->{"num"}) {
		return @result; # output null to caller
	}
	my $param = {};
	# process user parameter
	if (ref($_[0]) eq "HASH") {
		$param = shift;
	} else {
		my %param = @_;
		$param = \%param;
	}
	# set default back & forward icon
	if (!$param->{"bicon"}) {
		$param->{"bicon"} = "&lt;&lt;";
	}
	if (!$param->{"ficon"}) {
		$param->{"ficon"} = "&gt;&gt;";
	}
	if ($param->{"sub"} !~ /^\d+$/ or $param->{"sub"} >= $hash->{"HP_A"}) {
		$param->{"sub"} = 0;
	}
	my ($current,$total);
	if ($param->{"sub"}) {
		$current = $hash->{"HP_C"}/$param->{"sub"}; # start page number
		# not current page end number
		if ($current =~ /\d+\.\d+/) {
			$current = int($current) * $param->{"sub"} + 1;
		} else {
			# I think this is page end number :)
			$current = $hash->{"HP_C"} - $param->{"sub"} + 1;
		}
		$total = $current + $param->{"sub"} - 1;
	} else {
		$current = 1;
		$total = $hash->{"HP_A"};
	}
	# return HTML code
	undef $result[0];
	$result[0] .= "<!-- HTML::Paging::SQL $HTML::Paging::SQL::VERSION Begin -->\n";
	if ($param->{"sub"} && $hash->{"HP_C"} > $param->{"sub"}) {
		$result[0] .= qq|<a href="$hash->{'HP_U'}?|;
		$result[0] .= qq|$hash->{'HP_P'}&| if ($hash->{'HP_P'});
		$result[0] .= qq|HP_C=| . ($current-1) . qq|"|;
		$result[0] .= qq| target="$param->{'target'}"| if ($param->{"target"});
		$result[0] .= qq|>|;
		$result[0] .= qq|$param->{"bicon"}|;
		$result[0] .= qq|</a>\n|;			
	}
	# set number now
	for (my $i=$current; $i<=$total ; $i++) {
		if ($i > $hash->{"HP_A"}) {
			last;
		}
		if ($i == $hash->{"HP_C"}) {
			$result[0] .= qq|$i \n|;
		} else {
			$result[0] .= qq|<a href="$hash->{'HP_U'}?|;
			$result[0] .= qq|$hash->{'HP_P'}&| if ($hash->{'HP_P'});
			$result[0] .= qq|HP_C=$i"|;
			$result[0] .= qq| target="$param->{'target'}"| if ($param->{"target"});
			$result[0] .= qq|>|;
			$result[0] .= qq|$i|;
			$result[0] .= qq|</a>\n|;
		}
		if ($i == $hash->{"HP_A"}) {
			last;
		}
	}
	if ($param->{"sub"} && ($current+$param->{"sub"}-1) < $hash->{"HP_A"}) {
		$result[0] .= qq|<a href="$hash->{'HP_U'}?|;
		$result[0] .= qq|$hash->{'HP_P'}&| if ($hash->{'HP_P'});
		$result[0] .= qq|HP_C=| . ($total+1) . qq|"|;
		$result[0] .= qq| target="$param->{'target'}"| if ($param->{"target"});
		$result[0] .= qq|>|;
		$result[0] .= qq|$param->{"ficon"}|;
		$result[0] .= qq|</a>\n|;
	}
	$result[0] .= "<!-- HTML::Paging::SQL $HTML::Paging::SQL::VERSION End -->\n";
	return @result;
}

#
# Get current status { private method }
#
sub _status {
	my $self = shift;
	my $hash = {};
	my $form = {};
	$hash->{"HP_A"} = $self->{"all"}/$self->{"num"};
	if ($hash->{"HP_A"} =~ /\d+\.\d+/) {
		$hash->{"HP_A"} = int($hash->{"HP_A"}) + 1;
	}
	my $uri = $ENV{"REQUEST_URI"};
	my ($script,$string) = split(/\?/,$uri);
	my @param;
	# process GET method
	if (!$HTML::Paging::SQL::buffer) {
		@param = split('&',$string);
	} else {
		chomp($HTML::Paging::SQL::buffer);
		@param = split('&',$HTML::Paging::SQL::buffer);
	}
	foreach (@param) {
		$_ =~ s/\+/ /g;
		my ($key, $val) = split(/=/,$_);
		$key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
		$val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
		$form->{"$key"} = "$val";
	}
	$hash->{"HP_U"} = $script; #CALLER URI
	$hash->{"HP_C"} = $form->{"HP_C"} || 1; #CURRENT PAGE
	# process overflow
	if ($hash->{"HP_C"} > $hash->{"HP_A"}) {
		$hash->{"HP_C"} = $hash->{"HP_A"};
	}
	if ($hash->{"HP_C"} < 1) {
		$hash->{"HP_C"} = 1;
	}	
	undef @param;
	foreach (keys %$form) {
		next if ($_ eq "HP_C" or $_ eq "");
		push(@param,$_."=".$form->{"$_"});
	}
	$hash->{"HP_P"} = join("&",@param); #OTHER PARAMETER
	return $hash;
}

1;

__END__

# Document

=head1 NAME

HTML::Paging::SQL - HTML pagination with SQL database

=head1 SUPPORTED PLATFORMS

I think you can use this class in all platforms :)

=head1 SYNOPSIS

	use HTML::Paging::SQL;

	my $hp = new HTML::Paging::SQL(
		all => your total amount of the record data£¬
		num => each page layout shows how many data it contains,
	);

	my ($html,$start,$length) = $hp->number(
		sub => the pagination number is shown in each subsection,
		bicon => setting down the icon that moves forward£¬
		ficon => setting down the icon that moves backward,
		target => setting target for display window,
	);

=head1 DESCRIPTION

If you use the SQL database, this class can help you divide the page, support th
e subsection show of pagination numbers, it is similar to the way shown in the Go
ogle's(R) pagination. Under the minimal circumstance you only need to deliver a 
parameter, and you'll get the pagination result and can have the user-defined of 
icons jumping forwards or backwards. 

=head1 HOW TO USE METHOD

=over 2

=item HTML::Paging::SQL->new(all => ?, num => ?)

For example,according to this way to initialize the class, you should at least d
eliver a parameter named "all",which is the total amount of the data you want to 
show. They each express a subsection of the pagination number on each page.If you
do not deliver, num is the default for 10, which means each page will show 10 data. 

=item $hp->number(sub => ?, ficon => ?, bicon => ?, target => ?)

This method can transmit the HTML code with the digital format, among which num and
sub can be separately chosen to deliver parameters, if sub isn't established,the 
result of the subsection show in page code will be closed; for example, sub is 4, 
you'll see the result similar to << 5 6 7 8 >> in the return html code. On the 
condition of a lot of data, it is of great use; in this way you can choose two 
parameters to establish the page number icons for jumping forwards or backwards. 
These two parameters are both "bicon" and "ficon". if you want to specify a target
window for display, you can set "target" parameter. If they are not set up, the 
system will adopt "<<"AND">>" for tacit jump icons. After executing this method 
successfully, it will rebound 3 parameters;the 1st stands for the HTML code of page
number,the 2nd for the limit first parameter in SQL,the 3rd for the limit second 
parameter in SQL.If the 2 nd and 3rd names stand for $start and $length, you can 
use it: "select* from table limit $start,$length".  


=back

=head1 AUTHOR

Wang Aocheng <wangaocheng@hotmail.com>

English: Wang Zhonghua <wzh2k@163.net>

=cut