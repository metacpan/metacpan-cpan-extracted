package Log::Dynamic;

$VERSION = 0.04;

use strict;
use warnings;

use Carp;
use Data::Dumper;

my $PKG   = __PACKAGE__;
my $MODE  = '>>';  # By default we append
my $UCASE = 1;     # By default we force types to upper case
my $TYPES = undef;

# Constructor
sub open {
	my $class = shift;

	# Catch an object call
	$class = ref $class || $class;

	return bless _init({@_}), $class;
}

# Initialize our params
sub _init {
	my $args = shift;
	my $fh;

	unless ($args->{'file'}) {
		croak "$PKG: Must supply file: Log::Dynamic->open(file => 'foo')";
	}

	# Override append mode to clobber mode if requested
	if (defined $args->{'mode'} && $args->{'mode'} =~ m/^clobber$/) {
		$MODE = '>';
	}

	# Override ucase mode if requested
	if (exists $args->{'ucase'} && !$args->{'ucase'}) {
		$UCASE = 0;
	}

	_init_types($args->{'types'},$args->{'invalid_type'});

	if ($args->{'file'} =~ /STD(?:OUT|ERR)/i) {
		$fh = uc $args->{'file'};
	} else {
		CORE::open($fh, $MODE, $args->{'file'})
			or croak "$PKG: Failed to open file '$args->{file}': $!";
	}

	return \$fh;
}

# Type initialization was a large enough chunk of code that
# I felt it should be pulled into its own subroutine.
sub _init_types {
	my $types   = shift || return;
	my $handler = shift || \&_invalid_type;

	# If provided the invalid type handler must be a coderef
	croak "$PKG: Value for the 'invalid_type' param must be a code ref"
		unless ref $handler eq 'CODE';

	# A Smudge of error checking. Non-empty array ref please
	croak "$PKG: Value for the 'types' param must be an array ref"
		unless ref $types eq 'ARRAY';

	croak "$PKG: Value for the 'types' param must not be an empty list"
		unless @{ $types };

	# We have types! Make a hash of types for easy lookup. 
	# Note that we explicitly register dump here as a valid 
	# type. If we didn't the sub that validates types would 
	# crap out when calling dump(). Seems a bit hacky, I know... 
	# but for the time being I think this solution is OK.
	$TYPES = { map { $_ => 1 } @{ $types }, 'dump' };

	# Store our invalid type handler.
	$TYPES->{'_handle_invalid'} = $handler;
}

# For those of you that decide you want to use the standard 
# constructor notation of new(), here you go.
sub new { shift->open(@_) }

# O'hai. Sry, we closing...
sub close { close ${(shift)} }

# Base logging function
sub log {
	my $fh   = shift;             # File handle reference
	my $type = shift || return;   # Message type, REQUIRED
	my $msg  = shift || return;   # Message body, REQUIRED
	my $time = scalar localtime;  # Formatted timestamp

	_validate_type($type);

	# Formatted caller info. Because custom types are essentially
	# wrapper functions for log() we need to check up one more
	# level to get the correct caller information.
	my $call = join(' ',
		map {
			(caller(1))[$_]  # Called using $log->[custom type]()
			    ||           #      - OR -
			(caller(0))[$_]  # Called using $log->log()
		} 0..2
	);

	# Output formatted log entry. We turn off strict refs so that 
	# we can print to STDERR and STDOUT witout perl spitting an 
	# error and dying.
	no strict 'refs';
	print {$$fh} "$time [".($UCASE?uc($type):$type)."] $msg ($call)\n";
}

sub dump {
	my $log  = shift;
	my $args = shift;

	unless (ref $args) {
		carp "$PKG: dump() requires a hash ref of arg=>value pairs";
		return;
	}

	unless ($args->{'data'}) {
		carp "$PKG: dump() requires the 'data' argument be supplied";
		return;
	}

	# Set defaults
	$args->{'dump_type'} ||= 'dump';
	$args->{'dump_name'} ||= 'anonymous data';
	$args->{'begin_msg'} ||= 'BEGIN dump for:'; 
	$args->{'end_msg'  } ||= 'END dump for:';

	$log->log($args->{'dump_type'},
		$args->{'begin_msg'}    . " '$args->{dump_name}'\n" .
		Dumper($args->{'data'}) .
		$args->{'end_msg'}      . " '$args->{dump_name}'"
	);
}

sub AUTOLOAD {
	my $log  = shift;
	my $type = (our $AUTOLOAD = $AUTOLOAD);

	return if $type =~ /::DESTROY$/;
	$type =~ s/.*::(.+)$/$1/;

	_validate_type($type);

	# Define a subroutine for our new type. Since this new
	# sub just turns around and calls log() with a set value
	# for the $type variable you can probably lable this a 
	# form of function currying. Weeeeee =)
	{
		no strict;
		no warnings;
		*$type = sub { shift->log($type,@_) };
	}

	# Log with our new type
	$log->log($type,@_);
}

# Chage the ucase value
sub ucase { shift;$UCASE = shift || 0}

# Valid log type
sub _validate_type {
	my $type = shift;

	if (defined $TYPES and not $TYPES->{$type}) {
		$TYPES->{'_handle_invalid'}->($type);
	} 
}

sub _invalid_type  {
	my $type = shift;
	croak "$PKG: Type '$type' was not specified as a valid type";
}

# Cleanup... Just close the file handle
sub DESTROY { shift->close }

1;

__END__

=head1 NAME

B<Log::Dynamic> - OOish dynamic and customizable logging

=head1 SYNOPSIS

=head2 Object instatiation

   use Log::Dynamic;

   # Set up logging so that _ALL_ log types are valid
   my $log = Log::Dynamic->open (
       file => 'logs/my.log',
       mode => 'append',
   );

      ## OR ##

   # Set up logging so that there is a set list of valid types
   my $log = Log::Dynamic->open (
       file  => 'logs/my.log',
       mode  => 'append',
       types => [qw/ foo bar baz /],
   );

      ## OR ##

   # Set up logging so that there is a set list of valid types
   # and override the default invalid type handler
   my $log = Log::Dynamic->open (
       file         => 'logs/my.log',
       mode         => 'append',
       types        => [qw/ foo bar baz /],
       invalid_type => sub { "INVALID TYPE: ".(shift)."\n" },
   );

=head2 Basic logging

   # Just like many other logging packages: log(TYPE, MESSAGE)
   $log->log('INFO', 'I can has info?');
   $log->log('ERROR', 'Oh crapz! Someone killed a kittah!');

=head2 Custom logging

   # Call any log type you like as an object method. For 
   # example, if you are logging cache hits and misses you 
   # might want to do something like:
   if ($CACHE->{$key}) {
       $log->cache_hit("Got hit on key $key");
       return $CACHE->{$key};
   } else {
       $log->cache_miss("Awww... Key $key was a miss");
       $CACHE->{$key} = do_expensive_operation(@args);
   }

=head2 Other usage

   # Use the object as a file handle for print() statements
   # from within your script or application:
   print {$$log} "This is a special message. Pay attention!\n";

=head1 DESCRIPTION

Yet another darn logger? Why d00d?

Well, I wanted to write a lite weight logging module that...

=over 2

=item * 

developers could use in a way that felt natural to them and 
it would just work, 

=item * 

was adaptable enough that it could be used in dynamic, ever 
changing environments,

=item * 

was flexible enough to satisfy most logging needs without 
too much overhead,

=item *

and gave developers full control over handling the myriad 
of log events that occur in large applications.

=back

Log::Dynamic still has a ways to go, but the direction seems 
promising. Comments and suggestions are always welcome. 

=head1 LOG FORMAT

Currently Log::Dynamic has only one format for the log entries. This
looks like:

    TIME/DATE STAMP [LOG TYPE] LOG MESSAGE (CALLER INFO)

Eventually this module will have support user defined log formats,
as it should having a name like Log::Dynamic.

=head1 LOG TYPES

Log "type" refers to the string displayed in the square brackets 
of your log output. In the following example the type is 'BEER ERROR':

    Thu Nov  8 21:14:12 2007 [BEER ERROR] Need more (main bottles.pl 99)

For those unfamiliar with logging this is especially useful when
grep-ing through your logs for specific types of errors, ala: 

    % grep -i 'beer error' /path/to/my.log

As stated above, by default there is no set list of types that 
this module supports. If you want to have a new type start showing 
up in your logs just call an object method of that name and 
Log::Dynamic will automatically do what you want: 

    $log->new_type('Hai!');

=head2 Limiting types

By default Log::Dynamic supports any log type you throw at it. However,
if you would like to define a finite set of valid (supported) log types 
you may do so using the 'types' parameter durning object instantiation. 
For example, if you would like only the types 'info', 'warn', and 'error'
to be valid log types within your application you would instantiate you
object like:

    my $log = Log::Dynamic->open (
        file  => 'my.log',
        types => [qw/ info warn error /],
    );

If you decide to define a set of valid types and your application attempts
to log with an invalid type then, by default, B<Log::Dynamic will croak with 
an appropriate error>. _HOWEVER_, if you don't want to go around your 
application wrapping each log call in an eval then you may override this 
behavior using the 'invalid_type' parameter:

    my $log = Log::Dynamic->open (
        file         => 'my.log',
        types        => [qw/ info warn error /],
        invalid_type => sub { warn (shift)." is bad! Moving on...\n" }
    );

If you choose to override the default invalid type handler Log::Dynamic 
will execute the provided subroutine and will pass it one parameter: 
the string of the invalid type that your application attempted to use. 

=head1 METHODS

=head2 open()

This is the object constructor. (Sure, you can still use new() if 
you wish) The open() method has a number of available parameters, 
each with several allowed values. They are:

=over 2

=item *

B<file> (required)

Values: file name, STDOUT or STDERR

=item *

B<mode> (optional)

Values: 'append' or 'clobber'

The default value is 'append'.

=item *

B<types> (optional)

Values: [qw/ array ref of your valid types /]

By default Log::Dynamic lets you call _ANY_ type as 
a method. However, if you would like to limit the set of valid 
types you can do that using this parameter. Once the list is set, 
if an invalid type is called Log::Dynamic croaks with a message.
(Or excutes a method that can be specified using the following
parameter)

=item *

B<invalid_type> (optional)

Value: code ref to handle invalid types

See B<LIMITING LOG TYPES> above.

=item *

B<ucase> (optional)

Values: 0 or 1

By default all types are forced to uppercase when printed to the
logs. For example, a call to C<$log-E<gt>SomeError('Foo')> would
show up in the log as '... [SOMEERROR] Foo ...'. If you would like 
to maintain case then set the 'ucase' flag to a non-true value.

=back

Here is an example instantiation for logging to a file that 
you want to clobber:

    my $log = Log::Dynamic->open (
        file => '/path/to/logs/my.log',
        mode => 'clobber',
    );

Here is an example instantiation for logging to STDERR:

    my $log = Log::Dynamic->open (file => STDERR);

As you can see there is no need to quote STDERR and STDOUT, but
it will still work if you choose to quote them.

=head2 close()

Close the file handle.

=head2 log()

Your basic log subroutine. just give it the log type and
the log message:

    $log->log('TYPE','MESSAGE');

Message Types are discussed above.

=head2 dump()

Use this subroutine if you would like to dump the contents of a data
structure or object to your log file. This sub is different from the
other logging subs in that it requires you pass it a hash reference
of arg/value pairs. Only the 'data' arg is required, however there 
are several others you can use to customize your dump output. They
are:

=over 2

=item *

B<data> (required)

Reference to the data structure or object you want to dump.

=item *

B<dump_name> (optional)

The name you want to give to your dumped data structure. Default:
'anonymous data'.

=item *

B<dump_type> (optional)

The type string that you want to associate with this dump. Default:
'DUMP'.

=item *

B<begin_msg> (optional)

Message printed before the dump. Default: 'BEGIN dump for:'.

=item *

B<end_msg> (optional)

Message printed after the dump, Default: 'END dump for:'.

=back

Here is example output if you specify _only_ the required 'data' argument:

Code:

    my $data = { foo => 'abc', bar => [qw/baz bing] };
    $log->dump({ data => $data });

Output:

    Sat Nov 24 14:05:29 2007 [DUMP] BEGIN dump for: 'anonymous data'
    $VAR1 = {
              'bar' => [
                         'baz',
                         'bing'
                       ],
              'foo' => 'abc'
            };
    END dump for: 'anonymous data' (main my-script.pl 21)

Here is example output where all arguments are specified:

Code:

    my $whoop = { foo => 'abc', bar => [qw/baz bing] };
    $log->dump({
        data      => $whoop,
        dump_name => 'Whoop',
        dump_type => 'its a whoop!',
        begin_msg => 'Lets start rocking with:',
        end_msg   => 'Chill out, its over for:',
    });

Output:

    Sat Nov 24 14:13:26 2007 [ITS A WHOOP!] Lets start rocking with: 'Whoop'
    $VAR1 = {
              'bar' => [
                         'baz',
                         'bing'
                       ],
              'foo' => 'abc'
            };
    Chill out, its over for: 'Whoop' (main whoop.pl 123)

=head2 ucase()

Change the boolean value for the 'ucase' flag. Recommended usage:

    $log->ucase(0);  # The case for types will be preserved
                     #   - OR -
    $log->ucase(1);  # Types will be forced to uppercase (default)

The 'ucase' flag is explained above in the description for the 
open() method.

=head2 Custom Methods

Log any type of message you want simply by calling the type as an
object method. For example, if you want to log a message with a 
type of ALARM you would do:

    $log->alarm('OONTZ!');

This would print a log entry that looks like:

    Thu Nov  8 21:14:12 2007 [ALARM] OONTZ! (main techno.pl 42)

This functionality was the impetus for writing this module.
What ever type you want to see in the log B<JUST USE IT!> =)

=head1 OTHER USAGE

While most OO modules bless a reference to a data structure, this 
module blesses a reference to an open file handle. Why did I do 
that? Because I can and I felt like doing something different. The 
only "special" thing this really lets you do is use the object as 
a file handle from within your script or application. All you have 
to do is dereference it when you use it. For example:

    # Normal log entry
    $log->info('This is information');

    # Special log entry
    print {$$log} "*** Hai. I am special. Pls give me attention! ***\n";

Obviously if you use the object in this special way you will not
get any of the nice additional information (timestamp, log type, 
and caller information) that you would get when using the normal 
way. This simply gives you the flexibility to print anything you 
want to your log. A useful example would be a dump of an object
or data structure: 

    use Data::Dumper;
    print {$$log} "Object dump:\n" . Dumper($object);

=head1 BUGS

None that I know of yet.

=head1 AUTHOR

James Conerly I<E<lt>jconerly@cpan.orgE<gt>> 2007

=head1 LICENSE

This software is free to use. If you use pieces of my code in your
scripts or applications all I ask is that you site me. Other than
that, log away my friends.

=head1 SEE ALSO

 Carp, Data::Dumper 

=cut
