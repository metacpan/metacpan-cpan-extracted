package Grid::Request::Param;

=head1 NAME

Param.pm - Models a parameter for Grid::Request jobs.

=head1 VERSION

This document refers to Param.pm

=head1 SYNOPSIS

 use Grid::Request::Param;
 my $param = Grid::Request:Param->new();
 $param->type("DIR");
 $param->key('--file=$(Name)');
 $param->value("/path/to/some/directory");

=head1 DESCRIPTION

A module that models Grid::Request parameters.

=over 4

=cut

use strict;
use Log::Log4perl qw(get_logger);
use Grid::Request::Exceptions;

my $MW_PARAM_DELIMITER = ":";

my %VALID_TYPE = ( ARRAY => 1,
                   DIR   => 1,
                   PARAM => 1,
                   FILE  => 1,
                 );

my $logger = get_logger(__PACKAGE__);

our $VERSION = '0.11';
if ($^W) {
    $VERSION = $VERSION;
}

# This is the constructor
sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class || ref($class);
    $self->_init(@args);
    return $self;
}

# This _init() method is used to initialize new instances of this class/module.
sub _init {
    my ($self, @args) = @_;
    if (scalar @args == 1 && ref(\$args[0]) eq "SCALAR") {
        my $param_string = $args[0];
        my @parts = split(/$MW_PARAM_DELIMITER/, $param_string);
        if (scalar @parts == 3) {
            $self->{_type} = $parts[0];
            $self->{_value} = $parts[1];
            $self->{_key} = $parts[2];
        } elsif (scalar @parts == 2 && $parts[0] eq "PARAM") {
            $self->{_type} = $parts[0];
            $self->{_value} = $parts[1];
        }
    } else {
        $self->{_type} = "PARAM";
        $self->{_value} = undef;
        $self->{_key} = undef;
    }
}


=item $obj->type([$type]);
                                                                                                                                       
B<Description:> Sets or retrieves the type of the parameter. Allowable "types"
are: ARRAY, DIR, FILE, and the default, PARAM.

B<Parameters:> An optional scalar, $type.

B<Returns:> If called as a getter (no-arguments), returns the current type.
If called as a setter, nothing is returned (undef).

=cut 

sub type {
    $logger->debug("In type.");
    my ($self, @args) = @_;
    if (@args) {
        my $type = $args[0];
        if ($VALID_TYPE{$type}) {
            $self->{_type} = $args[0];
        } else {
            Grid::Request::Exception->throw("Invalid param type: $type.");
        }
    } else {
        return $self->{_type};
    }
}


=item $obj->value([$value]);

B<Description:> A getter/setter that is used to set and retrieve the "value" of
a Grid::Request parameter. Grid::Request jobs may specified an executable to run
on the grid, and the executable may have or require one or more arguments (such as
those typically specified on the command line). These arguments are modeled with
the Grid::Request::Param module. Simple parameters do not trigger any iteration,
however, parameters of type "ARRAY", "DIR", and "FILE", trigger iterations, and
subsequently grid jobs that perform "parameter sweep" (sometimes referred to as
"array jobs").

B<Parameters:> None.

B<Returns:> If called as a getter (no-arguments), returns the current value
of the parameter. If called as a setter, nothing is returned (undef).

=cut 

sub value {
    $logger->debug("In value.");
    my ($self, @args) = @_;
    if (@args) {
        $self->{_value} = $args[0];
    } else {
        return $self->{_value};
    }
}


=item $obj->key([$key]);

B<Description:> For each parameter, the key is what tells how the parameter
should be passed as a command line argument and how the values from the iterable
directory, array or file are to be dropped into the argument. Parameter keys can
make use of two tokens: $(Index) and $(Name). The $(Index) token is replaced at
with the actual sequence number of the job on the grid, and the $(Name) token
is replaced with the string taken from the iterable value. In the case of parameters
of type

    FILE  -> $(Name) is replaced with the string from the line in the file
    ARRAY -> $(Name) is replaced with the value of the element of the array
    DIR   -> $(Name) is replaced with the name of the file in the directory 

Examples: 

   FILE
    # From the constructor
    Grid::Request::Param->new( type => "FILE",
                               key  => '--string=$(Name)',
                               value => "/path/to/some/file.txt" )

   DIR
      $param = Grid::Request::Param->new();
      $param->type("DIR");
      $param->key('--filepath=$(Name)');
      $param->value("/path/to/some/directory");

   ARRAY
      $param = Grid::Request::Param->new();
      $param->type("ARRAY");
      $param->key('--element=$(Name)');
      $param->value(\@array);

B<Parameters:> None.

B<Returns:> A non-negative integer scalar.

=cut

sub key {
    my ($self, @args) = @_;
    $logger->debug("In key.");
    if (@args) {
        $self->{_key} = $args[0];
    } else {
        return $self->{_key};
    }
}

=item $obj->count();

B<Description:> Retrieves the number of iterations that this parameter will
trigger. For parameters of type "ARRAY", it will be the nubmer of array
elements, for parameters of type "DIR", it will be the number of non-hidden
files in the specified directory; for parameters of type "FILE", it will the
number of lines in the file (with the exception of lines with nothing but
whitespace). 

B<Parameters:> None.

B<Returns:> A non-negative integer scalar.

=cut

sub count {
    my ($self, @args) = @_;
    $logger->debug("In count.");
    my $count;
    my $type = $self->type();
    if ($type eq "PARAM") {
        $count = 1;
    } elsif ($type eq "DIR") {
        my $dir = $self->value();
        $count = _dir_count($dir);
    } elsif ($type eq "FILE") {
        my $file = $self->value();
        $count = _file_count($file);
    } elsif ($type eq "ARRAY") {
        my $array_ref = $self->value();
        $count = scalar(@$array_ref);
    } else {
        Grid::Request::InvalidArgumentException->throw("Unknown parameter type: $type.");
    }
    $logger->debug("Returning: $count.");
    return $count;
}

# A private method used to count how many files are in a directory. 
# Hidden files are NOT included.
sub _dir_count {
    $logger->debug("In _dir_count.");
    my $dir = shift;
    if (! -d $dir) {
        Grid::Request::InvalidArgumentException->throw("$dir is not a directory.");
    }

    # Go through all the files
    opendir(DIR, $dir) or
        Grid::Request::Exception->throw("Could not open directory $dir.");

    # Make sure we ignore hidden files/paths here. That's what the grep is for.
    my @files = grep { !/^\./ } readdir DIR;
    closedir DIR;

    my $count = scalar(@files);
    $logger->debug("Returning $count.");
    return $count;
}


# A private method used to count how many lines are in a file. Newlines
# are considered to be the separator. In addition, if the line only contains
# whitespace, then it is NOT counted...
sub _file_count {
    $logger->debug("In _file_count.");
    my $file = shift;
    if (! -f $file) {
        Grid::Request::InvalidArgumentException->throw("$file is not a file.");
    }
    # Open the file for reading.
    open (FILE, "<", $file) or
        Grid::Request::Exception->throw("Could not open file $file.");
    my $count = 0;
    # Iterate over the file and examine each line.
    while (<FILE>) {
        my $line = $_;
        if ($line =~ m/\W/) {
            $count++;
        } else {
            $logger->debug("Didn't count line containing just white space.");
        }
    }
    # Attempt to close the filhandle.
    close FILE or
        Grid::Request::Exception->throw("Could not close filehandle for: $file.");
    $logger->debug("Returning $count.");
    return $count;
}

sub to_string {
    my $self = shift;
    my $string;
    if ($self->type() eq "PARAM") {
        $string = sprintf( '%s' . $MW_PARAM_DELIMITER . '%s',
                            $self->type(), $self->value());
    } else {
        $string = sprintf( '%s' . $MW_PARAM_DELIMITER . '%s' . $MW_PARAM_DELIMITER . '%s',
                            $self->type(), $self->value(), $self->key() );
    }
    return $string;
}

1;

__END__

=back

=head1 ENVIRONMENT

This module does not read or set any environment variables.

=head1 BUGS

None known.

=head1 SEE ALSO

 Grid::Request
 Grid::Request::Exceptions
 Log::Log4perl
