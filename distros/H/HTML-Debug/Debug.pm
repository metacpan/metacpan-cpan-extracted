package HTML::Debug;

use strict;
use Data::Dumper;
use HTML::Entities;
use vars qw($VERSION);
use overload '+'  => \&_add, '+=' => \&_add,
             '""' => \&make;

BEGIN {
    eval "require DBI";
}

$VERSION=0.12;

our $AUTOLOAD;

=head1 NAME

HTML::Debug - Enables the output of variable and query debugging information
for display in HTML.

=head1 SYNOPSIS

	use HTML::Debug;
	my $obj = HTML::Debug->new();
	# do some stuff with $obj here...

=head1 DESCRIPTION

HTML::Debug allows the developer to add variables and queries to HTML debugging
output.  The variables and their values will be color-coded based on type.  The
queries are displayed with their name, SQL statement, database driver,
database name, number of records affected, bind values, and the script name the
query is from. The variables are displayed in alphabetical order and the queries
are displayed in the order they were added to the debugging.

This module makes use of Data::Dumper to do the hard work of displaying the
actual variable values.  Some string manipulation is done on the output of
Data::Dumper, but just for aesthetic reasons.

The + and += operators have been overloaded to emulate the add() method.

The "" operator has also been overloaded so you can:
print $obj;
and not have to worry about the make() method.

=head1 METHODS

The following section documents the methods for HTML::Debug.

=over 4

=cut

########## BEGIN METHODS CODE ##########

=pod

=item B<$obj-E<gt>new()>

Creates a new HTML::Debug object. This object will hold the debugging information
sent to it.  The new method takes one optional parameter if this parameter evaluates
to true, then the output will automatically be printed when the object goes out
of scope (or whenever the DESTROY method is called).

Example:

my $obj = HTML::Debug->new(); or

my $obj = HTML::Debug->new(1);

=cut

sub new {
	my $self = shift;
	my $class = ref($self)||$self;
	my $auto_output = shift;

	$auto_output = 0 if (not defined $auto_output);
    
	return bless {auto_output=>$auto_output};
}

=pod

=item B<$obj-E<gt>add()>

This method adds a variable to the debugging.  The first parameter is a string
indicating the name of the variable.  The second parameter is a scalar or reference
to the value of the variable.  For instance if you have an array, pass in \@array.
You may pass in any variable value including scalars, references, blessed references,
hashrefs, arrayrefs, typeglobs, and subroutines.  Although, since Data::Dumper is used
for the output, passing in typeglobs and subroutines is not very useful.

Example:

$obj->add('myvar', $myvar);

=cut

sub add {
	my $self = shift;
	my $name;
	my $value;

	# If only one parameter, this is an anonymous variable.
	if ((@_) == 1) {
	$self->{anon}++;
		$name  = 'VAR'.$self->{anon};
		$value = shift;

	# Otherwise it is named.
	} else {
		$name  = shift;
		$value = shift;
		# If the variable is a statement handle, do the cool query stuff instead.
		if (ref $value eq 'DBI::st') {
			return $self->_query($name, $value, @_);
		}
	}

	# If the variable already exists, append the new value onto an array and use the array as the value.
	if (exists $self->{hVars}->{$name}) {
		if (ref $self->{hVars}->{$name} eq 'ARRAY') {
			push(@{$self->{hVars}->{$name}}, $value);
		} else {
			$self->{hVars}->{$name} = [$self->{hVars}->{$name}, $value];
		}

	# If the variable doesn't exist, make a new entry for it.
	} else {
		return $self->{hVars}->{$name} = $value;
	}
}

sub _query {
	my $self   = shift;
	my $name   = shift;
	my $handle = shift;

        my $hQuery = {name=>$name, st_handle=>$handle, aBindVals=>\@_, script=>$0};

        # Generate the debug text for the query on the fly as the database handle may not exist when make() is called.
        # Output the query name, script name, rows affected, driver, database, and statement.
        my $query = $hQuery->{st_handle};
        my $HTMLoutput .= "<div style='font: 12px Arial;'><b>$hQuery->{name}</b><br />";
        $HTMLoutput .= "<div style='padding-left: 5em;'>Query on ".$hQuery->{script}." affected ".$query->rows." row(s) from ";
        $HTMLoutput .= $query->{Database}->{Driver}->{Name}."::".$query->{Database}->{Name}.".<br />";
        $HTMLoutput .= '<pre>'.encode_entities($query->{Statement}).'</pre>';
        # If bind values were provided, output those values HTML-escaped.
        if (scalar @{$hQuery->{aBindVals}}) {
            local $Data::Dumper::Indent = 0;
            my $bindvals = Dumper($hQuery->{aBindVals});
            $bindvals =~ s/^\$VAR1 = //;
            $bindvals =~ s/;$//;
            $HTMLoutput .= 'Bind Values: <pre>'.encode_entities($bindvals).'</pre><br /><br />';
        }
        $HTMLoutput .= '</div></div>';        
        $hQuery->{debug} = $HTMLoutput;

	# Store the query info in an instance variable.
	push(@{$self->{aQueries}}, $hQuery);
}

=pod

=item B<$obj-E<gt>make()>

This method generates the HTML that represents the debugging information.  It would
most commonly be used to print the debugging info.  The variables are displayed
first in alphabetical order and are color-coded based on type.  All hash values
are displayed alphabetically.  In addition, the variable names are prefaced with
the correct sigil corresponding to their ref type.

The queries are displayed last and are in the order that they were added to the
HTML::Debug object.  Information displayed with each query include: the query's
name, the script on which it ran, the number of rows affected, the database driver
name, the database name, the SQL statement, and the bind values, if any.

The variable names, variable values, SQL statements, and bind values are
HTML-escaped before output.

Example:

print $obj->make();

=cut

sub make {
	my $self = shift;

	# Initalize the debugging output with a header and the server time.
	my $HTMLoutput = "<script type=\"text/javascript\">
function toggle_disp(source) {
    target = source.parentElement.cells[1].style;
    if (target.display == 'none') {
        target.display = '';
    } else {
        target.display = 'none';
    }
}
function toggle_vars(source) {
    target = source.style;
    if (target.display == 'none') {
        target.display = '';
    } else {
        target.display = 'none';
    }
}
</script>";

	$HTMLoutput .= '<div style="font: 10px Arial; "><h2>Debugging Output</h2>';
	$HTMLoutput .= "<b>Server time: ".localtime()."</b><br />";

	# Generate the HTML for the variables.
	$HTMLoutput .= "<h3 onClick=\"toggle_vars(vartable)\">Variables</h3><table border='0' id='vartable'>";
	foreach my $name (sort keys %{$self->{hVars}}) {
		my $value = $self->{hVars}->{$name};

		# Determine the color and sigil of the variable based on the ref type.
		my $type = ref $value;
		my $color;
		my $sigil;
		if ($type eq 'HASH') {
			$color = 'lightblue';
			$sigil = '%';
		} elsif ($type eq '') {
			$color = 'white';
			$sigil = '$';
		} elsif ($type eq 'ARRAY') {
			$color = 'lightgreen';
			$sigil = '@';
		} elsif ($type eq 'CODE') {
			$color = 'orange';
			$sigil = '&';
		} elsif ($type eq 'REF') {
			$color = 'pink';
			$sigil = '$';
		} elsif ($type eq 'SCALAR') {
			$color = 'peru';
			$sigil = '$';
		} elsif ($type eq 'GLOB') {
			$color = 'plum';
			$sigil = '*';
		} else {
			$color = 'gray';
			$sigil = '$';
		}

		# Clean up the output (including HTML-escaping).
		local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Ident = 1;
		local $Data::Dumper::Pair = '~|~|~|~|~';
		my $output = Dumper($value);
		$output =~ s/^\$VAR1 = //;
		$output =~ s/;$//;
		$output =~ s/\n        /\n/g;
		$output =~ s/\n$//;
                $output = encode_entities($output);
                $output =~ s/\n/<br \/>/g;
		$output =~ s/~\|~\|~\|~\|~/ => /g;

		# Set the style attribute of the td (variable value) tag.
		my $style = "font: 12px Arial; color: black; background: $color; border: 1px solid black;";

		$HTMLoutput .= "<tr><th nowrap='nowrap' align='right' valign='top' onClick=\"toggle_disp(this)\"><span style='font: 12px Arial; '>$sigil$name = </span></th>";
		$HTMLoutput .= "<td align='left' valign='top' style='$style'><span><pre>$output</pre></span></td></tr>";
	}
	$HTMLoutput .= "</table>";

	# Generate the HTML for the queries.
	$HTMLoutput .= "<h3 onClick=\"toggle_vars(querytable)\">Queries</h3><div id='querytable' style='text-align:left; padding-left: 10em;'>";
	foreach my $queryinfo (@{$self->{aQueries}}) {
            $HTMLoutput .= $queryinfo->{debug};                
	}
	$HTMLoutput .= '</div></div>';

	return $HTMLoutput;
}

=pod

=item B<$obj += []>

The + and += operators have been overloaded to support adding variables and queries to the debugging info.
The second argument must either be a scalar, in which case you are adding an anonymous value.  Otherwise
it must be an arrayref.  If the arrayref has two or more elements, it is treated as an ordinary variable,
with the first element being the name and the second being the value.  If the value is a statement handle,
it is treated as a query with the remaining elements being the bind values.

Examples:

$obj += ['myvar', $value];

$obj = $obj + ['myvar', $value];

$obj + ['myvar', $value];

$obj += 3; #anonymous variable

=cut

sub _add {
	my $self = shift;
	my $var  = shift;

	# If they passed in an array of two elements or where the second element is a statement handle, then it is a named variable.
	if ((ref $var eq 'ARRAY') and ((@$var == 2) or (ref $var->[1] eq 'DBI::st'))) {
		my @vars  = @$var;
		my $name  = shift @vars;
		my $value = shift @vars;
		$self->add($name, $value, @vars);

	# Otherwise, it is an unnamed variable.
	} else {
		$self->add($var);
	}

	return $self;
}

=pod

=item B<$obj-E<gt>your_varname()>

To make it easy to add the same variable multiple times and see all the values appended into an array, the AUTOLOAD method
has been implemented so you can use your variable name as a method name.  For example:

$obj->i($i);

If inside a loop, you will see a value of $i for each cycle through the loop.

=cut

sub AUTOLOAD {
	my $self  = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*:://g;
	my $value = shift;

	return $self->add($name, $value);
}

=pod

=item B<$obj-E<gt>DESTROY()>

To avoid extra typing, the HTML output is printed when the object goes out of scope assuming you initalized the 
object to do that by specifying HTML::Debug->new(1).

=cut

#sub DESTROY {
#	my $self = shift;
#	print $self->make() if ($self->{auto_output});
#}

########## END METHODS CODE ##########

1;

=pod

=back

=head1 Mason config

Here is how you would configure HTML::Debug to work with HTML::Mason:

In httpd.conf:
PerlSetVar MasonAllowGlobals $d

In autohandler:
<%once>
use HTML::Debug;
</%once>

<%init>
local $d = HTML::Debug->new();
</%init>

<%cleanup>
$m->print( $d->make() );
</%cleanup>

=head1 BUGS

Hopefully none.

=head1 AUTHOR

Mike Randall E<lt>randall@ku.eduE<gt>

=head1 MAINTAINER

Mike Randall E<lt>randall@ku.eduE<gt>
