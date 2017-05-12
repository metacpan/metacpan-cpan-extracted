package Games::Object::Common;

use strict;
use Exporter;

use Carp qw(carp croak confess);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

$VERSION = "0.10";
@ISA = qw(Exporter);
@EXPORT_OK = qw(ANAME_MANAGER FetchParams LoadData SaveData);
%EXPORT_TAGS = (
    attrnames		=> [qw(ANAME_MANAGER)],
    functions		=> [qw(FetchParams LoadData SaveData)],
);

use constant ANAME_MANAGER	=> "_MANAGER";

####
## PUBLIC FUNCTIONS

# Save an item of data to a file.

sub SaveData
{
	my ($file, $data) = @_;

	# Check for undef, as this takes special handling.
	if (!defined($data)) {
	    print $file "U\n";
	    return 1;
	}

	# Now handle everything else.
	my $ref = ref($data);
	if ($ref eq '' && $data =~ /\n/) {
	    # Multiline text scalar
	    my @lines = split(/\n/, $data);
	    print $file "M " . scalar(@lines) . "\n" .
			join("\n", @lines) . "\n";
	} elsif ($ref eq '') {
	    # Simple scalar.
	    print $file "S $data\n";
	} elsif ($ref eq 'ARRAY') {
	    # Array.
	    print $file "A " . scalar(@$data) . "\n";
	    foreach my $item (@$data) {
		SaveData($file, $item);
	    }
	} elsif ($ref eq 'HASH') {
	    # Hash. WARNING: Hash keys cannot have newlines in them!
	    my @keys = keys %$data;
	    print $file "H " . scalar(@keys)  . "\n";
	    foreach my $key (@keys) {
		print $file "$key\n";
		SaveData($file, $data->{$key});
	    }
	} elsif ($ref && UNIVERSAL::can($ref, 'save')) {
	    # Pass along to save method of this object's class.
	    print $file "O $ref\n";
	    $data->save($file);
	} else {
	    # SOL
	    croak("Cannot save reference to $ref object");
	}
	1;
}

# Load data from a file. This can take an optional second parameter. If present,
# this is taken to be a reference to a variable that will hold the data, rather
# than creating our own and returning the result (this applies only to
# non-scalar data). WARNING!! No check is made to insure that the reference
# type is compatible with what is in the file!

sub LoadData
{
	my ($file, $store) = @_;
	my $line = <$file>;

	# The caller is responsible for calling this routine only when there
	# is data to read.
	croak("Unexpected EOF") if (!defined($line));

	# Check for something we recognize.
	chomp $line;
	my $tag = substr($line, 0, 1);
	my $val = substr($line, 2) if ($tag ne 'U'); # Avoid substr warning
	if ($tag eq 'U') {
	    # Undef.
	    undef;
	} elsif ($tag eq 'S') {
	    # Simple scalar value
	    $val;
	} elsif ($tag eq 'M') {
	    # Multiline text, to be returned as scalar.
	    my @text = ();
	    foreach my $i (1 .. $val) {
		my $line2 = <$file>;
		croak("Unexpected EOF") if (!defined($line2));
		push @text, $line2;
	    }
	    join("\n", @text);
	} elsif ($tag eq 'A') {
	    # Build an array.
	    my $ary = $store || [];
	    foreach my $i (1 .. $val) {
		push @$ary, LoadData($file);
	    }
	    $ary;
	} elsif ($tag eq 'H') {
	    # Reconstruct a hash.
	    my $hsh = $store || {};
	    foreach my $i (1 .. $val) {
		my $key = <$file>;
		chomp $key;
		$hsh->{$key} = LoadData($file);
	    }
	    $hsh;
	} elsif ($tag eq 'O') {
	    # Object reference. We first make sure this has the proper method
	    # and then call it.
	    if (UNIVERSAL::can($val, 'load')) {
		my $obj = $val->load($file);
		$obj;
	    } else {
		croak "Cannot load object of class '$val' (no load method)";
	    }
	} else {
	    # Anything else is unrecognized.
	    croak("Unknown tag '$tag' in file, file may be corrupted");
	}

}

# Fetch parameters, checking for required params and validating the values.

sub FetchParams
{
	my ($args, $res, $opts, $del) = @_;
	$del = 0 if (!defined($del));

	# If the first item is the name of this class, shift it off.
	shift @$args if (@$args && $args->[0] =~ /^Games::Object/);

	# Now go down the opts list and see what parameters are needed.
	# Return the results in a hash.
	my %args = @$args;
	while (my $spec = shift @$opts) {

	    # Fetch the values for this spec. Note that not all may be present,
	    # depending on the type.
	    my ($type, $name, $dflt, $rstr) = @$spec;

	    # Philosophy conflict: Many CPAN modules like args to be passed
	    # with '-' prefixing them. I don't. Useless use of an extra
	    # keystroke. However, I want to be consistent. Thus a compromise:
	    # I allow args to be passed with or without the '-', but it always
	    # gets stored internally without the '-'.
	    my $oname = $name;
	    $name = '-' . $name if (defined($args{"-${name}"}));

	    # Is the attribute name a pattern? If so, here's what we do: we
	    # search the list of args for attribute names that match this
	    # and automagically generate specific options that we tack on
	    # to the end of the list.
	    if ($name =~ /[\^\$\.\+\*\[\{]/) {
		my @amatches = grep { /$name/ }
			       map { s/^\-//g; $_; }
			       keys %args;
		foreach my $amatch (@amatches) {
		    push @$opts, [ $type, $amatch, $dflt, $rstr ];
		}
		next;
	    }

	    # Check the type.
	    if ($type eq 'req') {

		# Required parameter, so it must be provided.
	        croak("Missing required argument '$name'")
		  unless (defined($args{$name}));
		$res->{$oname} = $args{$name};

	    } elsif ($type eq 'opt') {

		# Optional parameter. If not there and a default is specified,
		# then set it to that.
		if (defined($args{$name})) { $res->{$oname} = $args{$name}; }
		elsif (defined($dflt))	     { $res->{$oname} = $dflt; }

	    }

	    # Delete item from args if requested.
	    delete $args{$name} if ($del);

	    # Stop here if we wound up with undef anyway or there are no
	    # restrictions on the parameter.
	    next if (!defined($res->{$oname}) || !defined($rstr));

	    # Check for additional restrictions.
	    if (ref($rstr) eq 'CODE') {

		# User defining own validation code.
		croak("Invalid value '$res->{$oname}' for param '$name'")
		    if (! &$rstr($res->{$oname}) );

	    } elsif (ref($rstr) eq 'ARRAY') {

		# Value must be one of these
		my $found = 0;
		foreach my $item (@$rstr) {
		    $found = ( $item eq $res->{$oname} );
		    last if $found;
		}
		croak("Invalid value '$res->{$oname}' for param '$name'")
		    unless ($found);

	    } elsif ($rstr eq 'any') {

		# Automatically succeeds.

	    } elsif ($rstr =~ /^(.+)ref$/) {

		my $reftype = uc($1);
		croak("Parameter '$name' must be $reftype ref")
		    if (ref($res->{$oname}) ne $reftype);

	    } elsif ($rstr eq 'int') {

		# Must be an integer.
		croak("Param '$name' must be an integer")
		    if ($res->{$oname} !~ /^[\+\-\d]\d*$/);

	    } elsif ($rstr eq 'number') {

		# Must be a number. Rather than trying to match against a
		# heinously long regexp, we'll intercept the warning for
		# a non-numeric when we try to int() it. TMTOWTDI.
		my $not_number = 0;
		local $SIG{__WARN__} = sub {
		    my $msg = shift;
		    if ($msg =~ /isn't numeric in int/) {
			$not_number = 1;
		    } else {
			warn $msg;
		    }
		};
		my $x = int($res->{$oname});
		croak("Param '$name' must be a number") if ($not_number);

	    } elsif ($rstr eq 'boolean') {

		# Must be a boolean. We simply convert to a 0 or 1.
		my $bool = ( $res->{$oname} eq '0' ? 0 :
			     $res->{$oname} eq ''  ? 0 :
			     1 );
		$res->{$oname} = $bool;

	    } elsif ($rstr eq 'string') {

		# Must not be a reference
		croak("Param '$name' must be a string, not a reference")
		  if (ref($res->{$oname}));

	    } elsif ($rstr eq 'callback') {

		# Must be a callback definition, which is minimally an
		# array with two items. Note that we can have lists of
		# callbacks as well; so if this is not already such a list,
		# make it one with a single entry for the purposes of checking
		# it here.
		my $list = $res->{$oname};
		croak "Param '$name' must be a callback array or list of " .
		      "callback arrays" if (ref($list) ne 'ARRAY');
		$list = [ $list ]
		    if (@$list == 0 || ref($list->[0]) ne 'ARRAY');
		foreach my $cbk (@$list) {
		    next if (!ref($cbk) && $cbk eq 'FAIL');
		    croak "Param '$name' must be a callback or list of " .
		          "callbacks" if (ref($cbk) ne 'ARRAY');
		    croak "Param '$name' callback must contain at least two " .
			"parameters" if (@$cbk < 2);
		    foreach my $item (@$cbk) {
			croak "Param '$name' callback args must be simple " .
			      "scalars" if (ref($item));
		    }
		}

	    } elsif ($rstr eq 'file') {

		# Must be reference to an IO::File or FileHandle object, or
		# a GLOB.
		croak("Param '$name' must be a file (IO::File/" .
			"FileHandler object or GLOB reference acceptable)")
		  if (ref($res->{$oname}) !~ /^(IO::File|FileHandle|GLOB)$/);

	    } elsif ($rstr eq 'readable_filename' ) {

		# Must be the name of a file that exists and is readable.
		croak("Filename '$res->{$oname}' does not exist")
		    if (! -f $res->{$oname});
		croak("Filename '$res->{$oname}' is not readable")
		    if (! -r $res->{$oname});

	    } elsif ($rstr eq 'object') {

		# Must be an object reference
		my $ref = ref($res->{$oname});
		croak("Param '$name' must be an object reference, not a " .
		      "'$ref' reference")
		  if ($ref =~ /^(SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE)$/);
	    } else {

		croak("'$rstr' is an invalid datatype");

	    }
	}

	# Set args to trimmed amount if delete option requested.
	@$args = %args if ($del);

	$res;
}

1;
