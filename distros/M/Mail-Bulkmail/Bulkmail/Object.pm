package Mail::Bulkmail::Object;

#Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
#Mail::Bulkmail::Object is distributed under the terms of the Perl Artistic License.

# SCROLL DOWN TO @conf_files ARRAY TO CONFIGURE IT

=pod

=head1 NAME

Mail::Bulkmail::Object - used to create subclasses for Mail::Bulkmail.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

Older versions of this code used to be contained within the Mail::Bulkmail package itself, but since 3.00 now has
all of the code compartmentalized, I couldn't leave this in there. Well, technically I *could*, but I didn't like that.
It's wasteful to make Mail::Bulkmail::Server a subclass of Mail::Bulkmail, for instance, since they don't share
any methods, attributes, whatever. Well, none beyond the standard object methods that I like to use. Hence this module
was born.

Of course, you don't have to use this to create subclasses, but you'll run the risk of making something with an inconsistent
interface vs. the rest of the system. That'll confuse people and make them unhappy. So I recommend subclassing off of here
to be consistent. Of course, you may not like these objects, but they do work well and are consistent. Consistency is
very important in interface design, IMHO.

=cut

$VERSION = '3.12';

use Socket;
no warnings 'portable';
use 5.6.0;
#use Data::Dumper ();

#sub dump {
#	my $self = shift;
#	return Data::Dumper::Dumper($self);
#};

use strict;
use warnings;

=pod

=head1 SET-UP

You'll need to specify your conf files. There is the @conf_files array, toss in as many conf files as you'd like

 my @conf_files = qw(
 	/etc/mail.bulkmail.cfg
 	/etc/mail.bulkmail.cf2
 );

It'll just silently ignore any conf files that aren't present, so don't expect any errors. That's to allow you
to place multiple conf files in for use on multiple servers and then not worry about them.

Multiple conf files are in significance order. So if mail.bulkmail.cfg and mail.bulkmail.cf2 both define a value
for 'foo', then the one in mail.bulkmail.cfg is used. And so on, conf files listed earlier are more important.
There is no way for a program to later look at a less significant conf value.

=cut

#you'll need to specify your conf files
{
	my @conf_files = qw(

	);

=pod

=head1 METHODS

=over 11

=item conf_files

conf_files returns your conf_files array.

 my @conf_files = $class->conf_files();

You can also programmatically add a new conf_file this way.

 $class->conf_files('/path/to/new/conf.file', '/path/to/other/conf.file');	#, etc

However, it'd be better to specify your conf file at use time.

 use Mail::Bulkmail::Object 3.00 "/path/to/conf.file";

This also (naturally) works in all subclasses.

 use Mail::Bulkmail 3.00 "/path/to/conf.file";
 use Mail::Bulkmail::Dynamic 3.00 "/path/to/conf/file";

and so on.

Note that adding on via ->conf_files or importing puts onto the FRONT of the @conf_files array,
i.e., those conf files are more significant.

So,

 @conf_files = qw(/path/to/file /path/to/file2);

 use Mail::Bulkmail::Object 3.00 "/path/to/file3" "/path/to/file4";

 Mail::Bulkmail::Object->conf_files("/path/to/file5", "/path/to/file6");

 print Mail::Bulkmail::Object->conf_files;
 	#prints out /path/to/file5 /path/to/file6 /path/to/file3 /path/to/file4 /path/to/file path/to/file2

Note that you don't *need* conf files, you can still specify all information at construction time, or
via mutators, or whatever. But a conf file can make your life a lot easier.

=cut

	sub conf_files {
		my $self = shift;
		unshift @conf_files, $_ foreach reverse @_;
		return @conf_files;
	};

	# the importer looks to any arguments specified at import and puts them
	# on the FRONT of the conf_files array.
	sub import {
		my $class = shift;
		unshift @conf_files, $_ foreach reverse @_;
		return 1;
	};

};

# You really probably don't want to change this
# If the conf file doesn't have a package defined, then it will assume that it's in the package defined here
# in this case, Mail::Bulkmail::Object
my $default_package = __PACKAGE__;

=item add_attr

add_attr adds object attributes to the class.

Okay, now we're going to get into some philosophy. First of all, let me state that I *love* Perl's OO implementation.
I usually get smacked upside the head when I say that, but I find it really easy to use, work with, manipulate, and so
on. And there are things that you can do in Perl's OO that you can't in Java or C++ or the like. Perl, for example, can
have *totally* private values that are completely inaccessible (lexicals, natch). private vars in the other languages
can be redefined or tweaked or subclassed or otherwise gotten around in some form. Not Perl.

And I obviously just adore Perl anyway. I get funny looks when I tell people that I like perl so much because it works
the way I think. That bothers people for some reason.

Anyway, as much as I like how it works, I don't like the fact that there's no consistent object type. An object is,
of course, a blessed ((thingie)) (scalar, array, code, hash, etc) reference. And there are merits to using any of those
things, depending upon the situation. Hashes are easy to work with and most similar to traditional objects.

 $object->{$attribute} = $value;

And whatnot. Arrays are much faster (typically 33% in tests I've done), but they suck to work with.

 $object->[15] = $value;	#the hell is '15'?

 (
  by the way, you can make this easier with variables defined to return the value, i.e.
  $object->[$attribute] = $value;	#assuming $attribute == 15
 )

Scalars are speciality and coderefs are left to the magicians. Don't get me wrong, coderefs as objects are nifty, but
they can be tricky to work with.

So, I wanted a consistent interface. I'm not going to claim credit for this idea, since I think I originally read it
in Object Oriented Programming in Perl (Damien's book). In fact, I think the error reporting method I use was also
originally detailed in there. Anyway, I liked it a lot and decided I'd implement my own version of it.

Basically, attributes are accessed and mutated via methods.

 $object->attribute($value);

For all attributes. This way, the internal object can be whatever you'd like. I used to use mainly arrays for the speed
boost, but lately I use hashes a lot because of the ease of dumping and reading the structure for debugging purposes.
But, with this consistent interface of using methods to wrapper the attributes, I can change the implementation of
the object (scalar, array, hash, code, whatever) up in this module and *nothing* else needs to change.

Say you implemented a giant system in OO perl. And you chose hashrefs as your "object". But then you needed a big
speed boost later, which you could easily get by going to arrays. You'd have to go through your code and change all
instances of $object->{$attribute} to $object->[15] or whatever. That's an awful lot of work.

With everything wrappered up this way, changes can be made in the super object class and then automagically populate
out everywhere with no code changes. Spiffy stuff.

There are some disadvantages, there is a little more overhead for doing the additional method call, but it's usually
negligible. And you can't do nice things like:

 $object->{$attribute}++;
 you'd have to do
 $object->attribute($object->attribute + 1);

Which is annoying. But I think it's offset by the consistent interface regardless of what your underlying object is.

Enough with the philosophy, though. You need to know how this works.

It's easy enough:

 package Some::Class;

 Some::Class->add_attr('foo');

Now your Some::Class objects have a foo attribute, which can be accessed as above. If called with a value, it's the mutator
which sets the attribute to the new value and returns the new value. If called without one, it's the accessor which
returns the value.

 my $obj = Some::Class->new();
 $obj->foo('bar');
 print $obj->foo();			#prints bar
 print $obj->foo('boo');	#prints boo
 print $obj->foo();			#prints boo

add_attr calls should only be in your module. B<Never in your program>. And they really should be defined up at the top.

Internally, an add_attr call creates a function inside your package of the name of the attribute which reflects through
to the internal _accessor method which handles the mutating and accessing.

There is another syntax for add_attr, to define a different internal accessor:

 Some::Class->add_attr(['foo', 'other_accessor']);

This creates method called 'foo' which talks to a separate accessor, in this case "other_accessor" instead of going
to _accessor. This is useful if you want to create a validating method on your attribute.

Additionally, it creates a normal method going to _accessor called '_foo', which is assumed to be the internal attribute
slot your other accessor with use. In generall, for a given "attribute", "_attribute" will be created for internal use.

"other_accessor" will get the object as the first arg (as always) and the name of the internal method as the second.

Example:

 Some::Class->add_attr(['foo', 'other_accessor']);

 $obj->foo('bee');

 sub other_accessor {
 	my $self	= shift;
 	my $method	= shift;	# "_foo", in this example

	if (@_){
		my $val = shift;	# "bee", in this example
		if ($val == 7){
 			return $self->$method($val);
 		}
 		else {
 			return $self->error("Cannot store value...foo must be 7!");
 		};
 	}
 	else {
 		return $self->$method();
 	};
 };

And, finally, you can also pass in additional arguments as static args if desired.

 Some::Class->add_attr(['foo', 'other_accessor'], 'bar');

 $obj->foo('bee');

 sub other_accessor {
 	my $self	= shift;
 	my $method	= shift;
 	my $static 	= shift;	#'bar' in our example

 	my $value	= shift;	#'bee' in our example
 	.
 	.
 	.
 };

 All easy enough. Refer to any subclasses of this class for further examples.

=cut

sub add_attr {
	my $pkg			= shift;
	my $method		= shift;

	my $accessor	= "_accessor";

	my @static_args	= @_;

	if (ref $method){
		($method, $accessor) = @$method;
		no strict 'refs';
		my $internal_method = '_' . $method;
		$pkg->add_attr($internal_method);
		no strict 'refs';
		*{$pkg . "::$method"}  = sub {shift->$accessor($internal_method, @static_args, @_)};
	}
	else {
		no strict 'refs';
		*{$pkg . "::$method"}  = sub {shift->$accessor($method, @static_args, @_)};
	};

	return $method;
};

=pod

=item add_class_attr

This is similar to add_attr, but instead of adding object attributes, it adds class attributes. You B<cannot> have
object and class attributes with the same name. This is by design. (error is a special case)

 Some::Class->add_attr('foo');			#object attribute foo
 Some::Class->add_class_attr('bar'):	#class attribute bar

 print $obj->foo();
 print Some::Class->bar();

Behaves the same as an object method added with add_attr, mutating with a value, accessing without one. Note
that add_class_attr does not have the capability for additional internal methods or static values. If you want
those on a class method, you'll have to wrapper the class attribute yourself on a per case basis.

Note that you can access class attributes via an object (as expected), but it's frowned upon since it may be
confusing.

class attributes are automatically initialized to any values in the conf file upon adding, if present.

=cut

sub add_class_attr {
	my $pkg		= shift;
	my $method	= shift;

	my $f = q{
			{
				my $attr = undef;
				sub {
					my $pkg = shift;
					$attr = shift if @_;
					return $attr;
				}
			}
		};

	no strict 'refs';
	*{$pkg . "::$method"} = eval $f;

	#see if there's anything in the conf file

	my $conf = $pkg->read_conf_file
		|| die "Conf file error : " . $pkg->error . " " . $pkg->errcode;
	if ($conf->{$pkg}->{$method}){
		$pkg->$method($conf->{$pkg}->{$method});
	};

	if (@_){
		$pkg->$method(@_);
	};

	return $method;
};

=pod

=item add_tricke_class_attr

It's things like this why I really love Perl.

add_trickle_class_attr behaves the same as add_class_attr with the addition that it will trickle the attribute down
into any class as it is called. This is useful for subclasses.

Watch:

 package SuperClass;

 SuperClass->add_class_attr('foo');
 SuperClass->foo('bar');

 package SubClass;
 @ISA = qw(SuperClass);

 print SubClass->foo();			#prints bar
 print SuperClass->foo();		#prints bar

 print SuperClass->foo('baz');	#prints baz
 print SubClass->foo();			#prints baz

 print SubClass->foo('dee');	#prints dee
 print SuperClass->foo();		#prints dee

See? The attribute is still stored in the super class, so changing it in a subclass changes it in the super class as well.
Usually, this behavior is fine, but sometimes you don't want that to happen. That's where add_trickle_class_attr comes
in. Its first call will snag the value from the SuperClass, but then it will have its own attribute that's separate.

Again, watch:


 package SuperClass;

 SuperClass->add_trickle_class_attr('foo');
 SuperClass->foo('bar');

 package SubClass;
 @ISA = qw(SuperClass);

 print SubClass->foo();			#prints bar
 print SuperClass->foo();		#prints bar

 print SuperClass->foo('baz');	#prints baz
 print SubClass->foo();			#prints bar

 print SubClass->foo('dee');	#prints dee
 print SuperClass->foo();		#prints baz

This is useful if you have an attribute that should be unique to a class and all subclasses. These are equivalent:

 package SuperClass;
 SuperClass->add_class_attr('foo');

 package SubClass
 SubClass->add_class_attr('foo');

 and

 package SuperClass;
 SuperClass->add_trickle_class_attr('foo');

You'll usually just use add_class_attr. Only use trickle_class_attr if you know you need to, since you rarely would.
There is a *slight* bit of additional processing required for trickled accessors.

trickled class attributes are automatically initialized to any values in the conf file upon adding, if present.

=cut

sub add_trickle_class_attr {
	my $pkg		= shift;
	my $method	= shift;

	my $f = qq{
		{
			my \$attr = undef;
			my \$internalpkg = "$pkg";
			my \$method = "$method";
			sub {
				my \$pkg = shift;
				\$pkg = ref \$pkg ? ref \$pkg : \$pkg;	#use as a class or regular method
				if (\@_ && \$pkg ne \$internalpkg){
					my \$func = \$method;
					\$pkg->add_trickle_class_attr(\$func);
					\$pkg->\$func(\$internalpkg->\$func);	#inherit the superclass class value
					return \$pkg->\$func(\@_);
				}
				else {
					\$attr = shift if \@_;
					return \$attr;
				}
			}

		}
	};

	no strict 'refs';
	*{$pkg . "::$method"} = eval $f;

	#if it's an internal attribute, then don't look in the conf file
	unless ($method =~ /^_/){
		#see if there's anything in the conf file
		my $conf = $pkg->read_conf_file
			|| die "Conf file error : " . $pkg->error . " " . $pkg->errcode;
		if ($conf->{$pkg}->{$method}){
			$pkg->$method($conf->{$pkg}->{$method});
		};

		if (@_){
			$pkg->$method(@_);
		};
	};

	return $method;
};

# _accessor is the main accessor method used in the system. It defines the most simple behavior as to how objects are supposed
# to work. If it's called with no arguments, it returns the value of that attribute. If it's called with arguments,
# it sets the object attribute value to the FIRST argument passed and ignores the rest
#
# example:
# my $object;
# print $object->attribute7();		#prints out the value of attribute7
# print $object->attribute7('foo');	#sets the value of attribute7 to 'foo', and prints 'foo'
# print $object->attribute7();		#prints out the value of attribute7, which is now known to be foo
#
# All internal accessor methods should behave similarly, read the documentation for add_attr for more information
#
# accessor is known to return errorcode MBO001 - not a class attribute, if it is accessed by a class

sub _accessor {
	my $self = shift;
	my $prop = shift;

	return $self->error("Not a class attribute", "MBO001") unless ref $self;

	$self->{$prop} = shift if @_;

	return $self->{$prop};
};

=pod

=item error and errcode

error rocks. All error reporting is set and relayed through error. It's a standard accessor, and an *almost*
standard mutator. The difference is that when used as a mutator, it returns undef (or an empty list) instead
of the value mutated to.

If a method fails, it is expected to return undef (or an empty list) and set error.

example:

 sub someMethod {
 	my $self = shift;
 	my $value = shift;

 	if ($value > 10){
 		return 1;		#success
 	}
 	else {
 		return $self->error("Values must be greater than 10");
 	};
 };

 $object->someMethod(15) || die $object->error;	#succeeds
 $object->someMethod(5)	 || die $object->error;	#dies with an error..."Values must be greater than 10"

Be warned if your method can return '0', this is a valid successful return and shouldn't give an error.
But most of the time, you're fine with "true is success, false is failure"

As you can see in the example, we mutate the error attribute to the value passed, but it returns undef.

However, error messages can change and can be difficult to parse. So we also have an error code, accessed
by errcode. This is expected to be consistent and machine parseable. It is mutated by the second argument
to ->error

example:

 sub someMethod {
 	my $self = shift;
 	my $value = shift;

 	if ($value > 10){
 		return 1;		#success
 	}
 	else {
 		return $self->error("Values must be greater than 10", "ERR77");
 	};
 };

 $object->someMethod(15) || die $object->error;		#succeeds
 $object->someMethod(5)	 || die $object->errcode;	#dies with an error code ... "ERR77"

If your code is looking for an error, read the errcode. if a human is looking at it, display the error.
Easy as pie.

Both classes and objects have error methods.

 my $obj = Some::Class->new() || die Some::Class->error();
 $obj->foo() || die $obj->error();

Note that error is a special method, and not just a normal accessor or class attribute. As such:

 my $obj = Some::Class->new();
 Some::Class->error('foo');
 print $obj->error();			#prints undef
 print Some::Class->error();	#prints foo

i.e., you will B<not> get a class error message by calling ->error on an object.

There is also an optional third paramenter..."not logged", which sounds horribly ugly, I know. But it is a bit of an
after-market hack, so it's to be expected. The third argument does what you'd think, it prevents the error message from
being logged.

 $self->error("This is an error message", "code", "not logged");

Any true value may be passed for the 3rd argument, but something that makes it obvious what it's doing is recommended, hence
my use of 'not logged'. This is useful for bubbling up errors.

 $class->error($self->error, $self->errcode, 'not logged');

The reason is that the error was already logged when it was stored in $self. So you'd end up logging it twice in your error
file, which is very confusing. So it's recommended to use the three argument form for errors that are bubbling up, but not
elsewhere.

As of 3.06, if an error is returned in a list context, an empty list will be returned instead of undef. undef is still
returned in a scalar context.

=cut

sub error {
	my $self		= shift;

	my $errormethod	= ref $self	? "_obj_error"		: "_pkg_error";
	my $codemethod	= ref $self	? "_obj_errcode"	: "_pkg_errcode";

	if (@_){
		my $error	= shift;
		my $code	= shift;
		my $nolog	= shift || 0;
		$self->$errormethod($error);
		$self->$codemethod(defined $code ? $code : undef);
		$self->logToFile($self->ERRFILE, "error: $error" . (defined $code ? "\tcode : $code" : '')) if !$nolog && $self->ERRFILE && $error;

		return;
	}
	else {
		return $self->$errormethod();
	};
};

=pod

=item errcode

errcode is an accessor ONLY. You can only mutate the errcode via error, see above.

 print $obj->errcode;

Both objects and classes have errcode methods.

 my $obj = Some::Class->new() || die Some::Class->errcode();
 $obj->foo() || die $obj->errcode();

Where possible, the pod will note errors that a method is known to be able to return. Please
note that this will B<never> be an all inclusive list of all error codes that may possibly
ever be returned by this method. Only error codes generated by a particular method will be listed.

=cut

sub errcode {
	my $self	= shift;
	my $method	= ref $self ? "_obj_errcode"		: "_pkg_errcode";
	return $self->$method(@_);
};

=pod

=item errstring

errstring is just a quick alias for:

 $bulk->error . ": " . $bulk->errcode;

Nothing more.

=cut

sub errstring {
	my $self = shift;

	return
		(defined $self->error ? $self->error : '')
		 . "...with code (" .
		 (defined $self->errcode ? $self->errcode : '')
		 . ")";

};

=pod

=item errvals

similar to errstring, but returns the error and errcode in an array. This is great for bubbling
up error messages.

 $attribute = $obj->foo() || return $self->error($obj->errvals);

=cut

sub errvals {
	my $self = shift;

	my @return = ();

	if (defined $self->error) {
		push @return, $self->error;
	}
	elsif (defined $self->errcode) {
		push @return, undef;
	};

	if (defined $self->errcode) {
		push @return, $self->errcode;
	};

	return @return;
};


=pod

=item read_conf_file

read_conf_file will read in the conf files specified in the @conf_files array up at the top.

You can also pass in a list of conf files to read, in most to least significant order, same as the @conf_files array.

 my $conf = Mail::Bulkmail::Object->read_conf_file();
 or
 my $conf = Mail::Bulkmail::Object->read_conf_file('/other/conf.file');

If you pass in a list of conf files, then the internal @conf_files array is bypassed.

$conf is a hashref of hashrefs. the main keys are the package names, the values are the hashes of the values
for that object.

Example:

 #conf file
 define package Mail::Bulkmail

 use_envelope = 1
 Trusting @= duplicates

 define package Mail::Bulkmail::Server

 Smtp = your.smtp.com
 Port = 25

 $conf = {
 	'Mail::Bulkmail' => {
 		'use_envelope' => 1,
 		'Trusting' => ['duplicates']
 	},
 	'Mail::Bulkmail::Server' => {
 		'Smtp' => 'your.smtp.com',
 		'Port' => 25
 	}
 };

read_conf_file is called at object initialization. Any defaults for your object are read in at this time.
You'll rarely need to read the conf file yourself, since at object creation it is read and parsed and the values passed
on.

B<Be sure to read up on the conf file structure, below>

The conf file is only re-read if it has been modified since the last time it was read.

this method is known to be able to return MBO002 - Invalid conf file

=cut

{
	my $global_conf	= {};
	my $loaded		= {};
	sub read_conf_file {
		my $class = shift;

		my @confs	= reverse(@_ ? @_ : $class->conf_files());
		my $conf	= @_ ? {} : $global_conf;

		foreach my $conf_file (@confs){
			next unless -e $conf_file ;
			if (! $loaded->{$conf_file} || -M $conf_file <= 0){
				my $pkg	 = $default_package;

				open (CONF, $conf_file) || next;
				while (my $line = <CONF>) {
					next if ! defined $line || $line =~ /^\s*#/ || $line =~ /^\s*$/;
					if ($line =~ /define package\s+(\S+)/){
						$pkg = $1;
						next;
					};

					$line =~ s/(?:^\s+|\s+$)//g;
					$line =~ /^(?:\s*(\d+)\s*:)?\s*(\w+)\s*(@?)=\s*(.+)/
						|| return $class->error("Invalid conf file : $line", "MBO002");

					my ($user, $key, $array, $val) = ($1, $2, $3, $4);

					unless (defined $val){
						($user, $key, $array, $val) = ($user, $key, undef, $array);
					};

					unless (defined $array){
						($user, $key, $array, $val) = (undef, $user, $array, $key);
					};

					($user, $key, $val) = (undef, $user, $key) unless defined $val;

					next if defined $user && $user != $>;

					$val = undef if $val eq 'undef';

					$val = eval qq{return "$val"} if defined $val && $val =~ /^\\/;

					if ($array) {
						$conf->{$pkg}->{$key} ||= [];
						push @{$conf->{$pkg}->{$key}}, $val;
					}
					else {
						$conf->{$pkg}->{$key} = $val;
					};
				};	#end while
				$loaded->{$conf_file} = 1 unless @_;
			};	#end if
		};	#end foreach
		return $conf;

	};	#end sub
};

=pod

=item gen_handle

returns a filehandle in a different package. Useful for when you need to open filehandles and pass 'em around.

 my $handle = Mail::Bulkmail->gen_handle();
 open ($handle, "/path/to/my/list");

 my $bulk = Mail::Bulkmail->new(
 	'LIST' => $handle
 );

You never need to use gen_handle if you don't want to. It's used extensively internally, though.

=cut

{
	my $handle = 0;

	sub gen_handle {
		no strict 'refs';
		my $self = shift;
		return \*{"Mail::BulkMail::Handle::HANDLE" . $handle++};	#You'll note that I don't want my
																	#namespace polluted either
	};

};

=pod

=item new

Finally! The B<constructor>. It's very easy, for a minimalist object, do this:

 my $obj = Class->new() || die Class->error();

Ta da! You have an object. Any attributes specified in the conf file will be loaded into your object. So if your
conf file defines 'foo' as 'bar', then $obj->foo will now equal 'bar'.

If you'd like, you can also pass in method/value pairs to the constructor.

 my $obj = Class->new(
 	'attribute' => '17',
 	'foo'		=> 'baz',
 	'method'	=> '88'
 ) || die Class->error();

This is (roughly) the same as:

 my $obj = Class->new() || die Class->error();

 $obj->attribute(17) || die $obj->error();
 $obj->foo('baz') || die $obj->error();
 $obj->method(88) || die $obj->error();

Any accessors or methods you'd like may be passed to the constructor. Any unknown pairs will be silently ignored.
If you pass a method/value pair to the constructor, it will override any equivalent method/value pair in the
conf file.

Additionally, if you need to set up values in your object, this is the place to do it. Note that setting default
values should probably be done in the conf file, but if you need to populate a data structure into a method, do it here.

 package SubClass;
 @ISA = qw(SuperClass);

 sub new {
 	return shift->new(
 		'servers'		=> [],
 		'connections'	=> {},
 		@_
 	);
 };

This will cause your SubClass to use the normal constructor, but get default values of the empty data structures
specified.

=cut

sub new {
	my $class	= shift;
	my $self	= bless {}, $class;

	return $self->init(
		@_
	) || $class->error($self->error, $self->errcode, 'not logged');
};

=pod

=item init

The object initializer. Arguably more important than the constructor, but not something you need to worry about.
The constructor calls it internally, and you really shouldn't touch it or override it. But I wanted it here so
you know what it does.

Simply, it iterates through the conf file and mutates any of your object attributes to the value specified in the conf
file. It then iterates through the hash you passed to ->new() and does the same thing, overriding any conf values, if
necessary.

init is smart enough to use all super class values defined in the conf file, in hierarchy order. So if your conf file
contains:

 define package SuperClass

 foo = 'bar'

And you're creating a new SubClass object, then it will get the default of foo = 'bar' as in the conf file, despite
the fact that it was not defined for your own package. Naturally, the more significant definition is used.

 define package SuperClass

 foo = 'bar'

 define package SubClass

 foo = 'baz'

SuperClass objects will default foo to 'bar', SubClass objects will default foo to 'baz'

this method is known to be able to return

 MBO003 - could not initialize value to conf value
 MBO004 - could not initialize value to constructor value
 MBO006 - odd number of elements in hash assignment

=cut

sub init {
	my $self	= shift;
	my $class	= ref $self;

#	my %init	= @_;

	my $conf = $self->read_conf_file
		|| die "Conf file error : " . $self->error . " " . $self->errcode;

	#initialize our defaults from the conf file
	foreach my $pkg (@{$class->isa_path() || []}){
		foreach my $method (keys %{$conf->{$pkg}}){
			if ($self->can($method)){
				$self->error(undef);
				$self->errcode(undef);
				my $return = $self->$method($conf->{$pkg}->{$method}) if $self->can($method);
				my $value = defined $conf->{$pkg}->{$method} ? $conf->{$pkg}->{$method} : 'value is undef';
				return $self->error("Could not initilize method ($method) to  value ($value)"
					. (defined $self->error ? " : " . $self->error : '')
					, ($self->errcode || "MBO003")
				) unless defined $return;
			};
		};
	};

	#initialize our defaults as passed in to the constructor
#	foreach my $method (keys %init){

	while (@_) {
		my $method	= shift;
		my $value	= undef;

		if (@_){
			$value	= shift;
		}
		else {
			return $self->error("Odd number of elements in hash assignment", "MBO006");
		};

		if ($self->can($method)){
			$self->error(undef);
			$self->errcode(undef);
			#my $return = $self->$method($init{$method});
			my $return = $self->$method($value);
			#my $value = defined $init{$method} ? $init{$method} : 'value is undef';
			my $errval = defined $value ? $value : 'value is undef';
			return $self->error("Could not initilize method ($method) to  value ($errval)"
				. (defined $self->error ? " : " . $self->error : '')
				, ($self->errcode || "MBO004")
			) unless defined $return;
		};
	};

	return $self;
};

=pod

=item isa_path

This is mainly used by the conf reader, but I wanted to make it publicly accessible. Given a class, it
will return an arrayref containing all of the superclasses of that class, in inheritence order.

Note that once a path is looked up for a class, it is cached. So if you dynamically change @ISA, it won't be reflected in the return of isa_path.
Obviously, dynamically changing @ISA is frowned upon as a result.

=cut

{
	my $paths = {};

	sub isa_path {
		my $class	= shift;
		my $seen	= shift || {};

		return undef if $seen->{$class}++;

		return $paths->{$class} if $paths->{$class};

		no strict 'refs';
		my @i = @{$class . "::ISA"};

		my @s = ($class);
		foreach my $super (@i){
			next if $seen->{$super};
			#my $super_isa = $super->can('isa_path') ? $super->isa_path($seen) : [];
			my $super_isa = isa_path($super, $seen);
			push @s, @$super_isa;
		};

		@s = reverse @s;	#we want to look at least significant first

		$paths->{$class} = \@s;

		return \@s;

	};

};

# _file_accessor is an internal accessor for accessing external information. Said external information can be in
# the form of a file (either a globref or a string containing the path/to/the/file), an arrayref, or a coderef
# It will open up path/to/file strings and create an internal filehandle. it also makes sure that all filehandles
# are piping hot. Look at getNextLine and logToFile to see examples of how to deal with a value that is
# set via _file_accessor
#
# _file_accessor expects a token to tell it which way the IO goes, either "<", ">", or ">>"
#
# i.e., __PACKAGE__->add_attr(["LIST", '_file_accessor'], "<");
# i.e., __PACKAGE__->add_attr(["GOOD", '_file_accessor'], ">>");

sub _file_accessor {
	my $self	= shift;
	my $prop	= shift;
	my $IO		= shift;
	my $file	= shift;

	if (defined $file){
		if (! ref $file) {
			my $handle = $self->gen_handle();
			if ($IO =~ /^(?:>>?|<)$/){
				open ($handle, $IO . $file)
					|| return $self->error("Could not open file $file : $!", "MB702");
				select((select($handle), $| = 1)[0]); 		#Make sure the file is piping hot!
				return $self->$prop($handle);
			}
			else {
				return $self->error("Invalid IO : $IO, must be '>', '>>', '<'", "MB703");
			};
		}
		elsif (ref ($file) =~ /^(?:GLOB|ARRAY|CODE)$/){
			select((select($file), $| = 1)[0]) if ref $file eq "GLOB"; 		#Make sure the file is piping hot!
			return $self->$prop($file);
		}
		else {
			return $self->error("File error. I don't know what a $file is", "MB701");
		};
	}
	else {
		return $self->$prop();
	};

};

=pod

=item getNextLine

getNextLine is called on either a filehandleref, an arrayref, or a coderef

 $obj->getNextLine(\*FOO);

will return the next line off of FOO;

 $obj->getNextLine(\@foo);

will shift the next line off of @foo and return it.

 $obj->getNextLine(\&foo);

will call foo($obj) and return whatever the function returns.

Note that your bulkmail object is the first argument passed to your function. It's not called as a method, but
the object is still the first argument passed.

This is mainly used with attribues going through _file_accessor.

 package SomeClass;

 SomeClass->add_attr(['FOO', '_file_accessor'], "<");
 my $obj = SomeClass->new(
 	FOO => \&foo
 ) || die SomeClass->error();

 my $val = $obj->getNextLine($obj->FOO);

=cut

sub getNextLine {
	my $self = shift;

	my $list = shift || $self->LIST() || return $self->error("Cannot get next line w/o list", "MB045");

	if (ref $list eq "GLOB"){
		my $email = scalar <$list>;
		return undef unless defined $email;
		chomp $email;
		return $email;
	}
	elsif (ref $list eq "ARRAY"){
		return shift @$list;
	}
	elsif (ref $list eq "CODE"){
		return $list->($self);
	}
	else {
		return $self->error("Cannot get next line...don't know what a $list is", "MB046");
	};

};

=pod

=item logToFile

logToFile is the opposite of getNextLine, it writes out a value instead of reading it.

logToFile is called on either a filehandleref, an arrayref, or a coderef

 $obj->logToFile(\*FOO, "bar");

will append a new line to FOO, "bar"

 $obj->logToFile(\@foo, "bar");

will push the value "bar" onto the end of @foo

 $obj->logToFile(\&foo, "bar");

will call foo($obj, "bar")

Note that your bulkmail object is the first argument passed to your function. It's not called as a method, but
the object is still the first argument passed.

This is mainly used with attribues going through _file_accessor.

 package SomeClass;

 SomeClass->add_attr(['FOO', '_file_accessor'], ">>");
 my $obj = SomeClass->new(
 	FOO => \&foo
 ) || die SomeClass->error();

 my $val = $obj->logToFile($obj->FOO, "valid address);

Internally, logToFile calls convert_to_scalar on the value it is called with.

This method is known to be able to return:

 MBO005 - cannot log to file

=cut

sub logToFile {
	my $self	= shift;
	my $file	= shift || return $self->error("Cannot log to file w/o file", "MB047");

	my $value	= shift;

	$value 		= $self->convert_to_scalar($value);

	if (ref $file eq "GLOB"){
		print $file $value, "\015\012" if $value;
		return 1;
	}
	elsif (ref $file eq 'ARRAY'){
		push @$file, $value;
		return 1;
	}
	elsif (ref $file eq "CODE"){
		$file->($self, $value);
		return 1;
	}
	else {
		return $self->error("Cannot log to file...don't know what a $file is", "MBO005");
	};

};

=pod

=item convert_to_scalar

called by logToFile. used to convert the value passed to a scalar.

Mail::Bulkmail::Object's convert_to_scalar method will only handle scalars, it will dereference
scalarrefs, or return scalar values. This method will also strip out any carriage returns or newlines
within the scalar before returning it. If passed by reference, your original variable will not be modified.

This is useful to subclass if you ever want to log values other than simple scalars

=cut

sub convert_to_scalar {
	my $self 	= shift;
	my $value	= shift;

	my $v2 = ref $value ? $$value : $value;

	$v2 =~ s/[\015\012]//g if defined $v2;

	return $v2;
};

#internal attributes, for storing error information

# _obj_error is the object attribute slot for storing the most recent error that occurred. It is
# set via the first argument to the ->error method when called with an object.
# i.e., $obj->error('foo', 'bar');	#_obj_error is 'foo'
__PACKAGE__->add_attr('_obj_error');

# _obj_errcode is the object attribute slot for storing the most recent error code that occurred. It is
# set via the second argument to the ->error method when called with an object.
# i.e., $obj->error('foo', 'bar');	#_obj_errcode is 'bar'
__PACKAGE__->add_attr('_obj_errcode');

# _pkg_error is the class attribute slot for storing the most recent error that occurred. It is
# set via the first argument to the ->error method when called with a class.
# i.e., $class->error('foo', 'bar');	#_pkg_error is 'foo'
__PACKAGE__->add_trickle_class_attr('_pkg_error');

# _pkg_errcode is the class attribute slot for storing the most recent error code that occurred. It is
# set via the second argument to the ->error method when called with a class.
# i.e., $class->error('foo', 'bar');	#_pkg_errcode is 'bar'
__PACKAGE__->add_trickle_class_attr('_pkg_errcode');

#and for logging errors, if desired

# _ERRFILE internally stores the ERRFILE parameter, if it is set. See the documentation for ERRFILE, below.
# _ERRFILE needs to exist because add_class_attr and add_trickle_class_attr do not have add_attr's additional
# powers to create attributes with non-standard accessors.
__PACKAGE__->add_class_attr('_ERRFILE');

=pod

=item ERRFILE

This is an optional log file to keep track of any errors that occur.

ERRFILE may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail::Object will attempt to open that file (in append mode) as your log:

 $bulk->ERRFILE("/path/to/my/error.file");

If a globref, it is assumed to be an open filehandle in append mode:

 open (E, ">>/path/to/my/error.file");
 $bulk->ERRFILE(\*E);

if a coderef, it is assumed to be a function to call with the address as an argument:

 sub E { print "ERROR : ", shift, "\n"};	#or whatever your code is
 $bulk->ERRFILE(\&E);

if an arrayref, then bad addresses will be pushed on to the end of it

 $bulk->ERRFILE(\@errors);

Use whichever item is most convenient, and Mail::Bulkmail::Object will take it from there.

It is recommended you turn on ERRFILE in a debugging envrionment, and leave it off in production. You probably shouldn't
be getting errors in a production environment, but there may be internal errors that you're not even aware of, so
you'll end up filling up that file. And there's the slight additional overhead.

Keep it on in production if you know what you're doing, off otherwise.

=cut

sub ERRFILE {
	my $self = shift;
	if (@_){
		my $file = shift;
		$self->_file_accessor("_ERRFILE", ">>", $file);
	}
	else {
		return $self->_ERRFILE();
	};
};

1;

__END__

=pod

=back

=head1 CONF FILE specification

Your conf files are very important. You did specify them up in the @conf_files list above, right? Of course you did.

But now you need to know how they look. They're pretty easy.

Each line of the conf file is a name = value pair.

 ERRFILE = /path/to/err.file

Do not put the value in quotes, or they will be assigned.

 ERRFILE = /path/to/err.file		#ERRFILE is /path/to/err.file
 ERRFILE = "/path/to/err.file"		#ERRFILE is "/path/to/err.file"

the conf file is analyzed by the object initializer, and then each value is passed to the appropriate object upon
object creation. So, in this case your ERRFILE class_attribute would be set to ERRFILE leading and trailing whitespace
is stripped.

 so these are all the same:
 ERRFILE = /path/to/err.file
    ERRFILE        =     /path/to/err.file
            ERRFILE =        /path/to/err.file
            										^^^^^extra spaces

Your conf file is read by read_conf_file. As you saw in the docs for read_conf_file, it creates a hashref. The top
hashref has keys of package names, and the conf->{package} hashref is the name value pairs. To do that, you'll need
to define which package you're looking at.

 define package SomeClass

 define package OtherClass

 ERRFILE = /path/to/err.file

So ERRFILE is now defined for OtherClass, but not for SomeClass (unless of course, OtherClass is a sub-class of
SomeClass)

If you do not define a package, then the default package is assumed.

Multiple entries in a conf file take the last one.

 define package SomeClass

 ERRFILE = /path/to/err.file
 ERRFILE = /path/to/err.other.file

so SomeClass->ERRFILE is /path/to/err.other.file There is no way to programmatically access /path/to/err.file, the
value was destroyed, even though it is still in the conf file.

There is one magic value token...undef

 ERRFILE = undef

This will set ERRFILE to the perl value 'undef', as opposed to the literal string "undef"

Sometimes, you will want to give a conf entry multiple values. Then, use the @= syntax.

 define package SomeClass

 foo = 7
 bar @= 8
 bar @= 9

SomeClass->foo will be 7, SomeClass->bar will be [8, 9]

There is no way to assign a value more complex than a scalar or an arrayref.

Comments are lines that begin with a #

 #enter the SomeClass package
 define package SomeClass

 #connections stores the maximum number of connections we want
 connections = 7


If you want to get *really* fancy, you can restrict values to the user that is running the script. Use
the :ID syntax for that.

 define package SomeClass

 #everyone else gets this value
 foo = 11

 #user 87 gets this value
 87:foo	= 9

 #user 93 gets this value
 93:foo = 10

Note that a default value must be listed FIRST, or it will override any user specific values.

=head1 SAMPLE CONF FILE

 #this is in the default package
 ERRFILE = /path/to/err.file

 define package Mail::Bulkmail::Server
 #set our Smtp Server
 Smtp	= your.smtp.cpm

 #set our Port
 Port	= 25

 define package JIM::SubClass

 #store the IDs of the server objects we want to use by default

 servers @= 7
 servers @= 19
 servers @= 34

=head1 GRAMMAR

In fact, we'll even get fancy, and specify an ABNF grammar for the conf file.

	CONFFILE = *(LINE "\n")					; a conf file consists of 0 or more lines

	LINE = (
			DEFINE 			; definition line
			/ COMMENT 		; comment line
			/ EQUATION 		; equation line
			/ *(WSP)		; blank line
		) "\n"				; followed by a newline character

	DEFINE = %b100 %b101 %b102 %b105 %b110 %b101 %b32 %b112 %b97 %b99 %b107 %b97 %b103 %b101 TEXT
		; the literal string "define package" in lower case, followed by TEXT

	COMMENT = *(WSP) "#" TEXT

	EQUATION = *(WSP) (VARIABLE / USER_VARIABLE) *(WSP) EQUATION_SYMBOL *(WSP) VALUE *(WSP)

	USER_VARIABLE = USER *(WSP) ":" *(WSP) VARIABLE

	USER = 1*(DIGIT)

	EQUATION_SYMBOL = "=" / "@="

	VALUE = *(TEXT)

	USER_VARIABLE = *(TEXT)

	TEXT = VISIBLE *(VISIBLE / WSP) [VISIBLE]

	VISIBLE = %d33-%d126	; visible ascii characters


=head1 SEE ALSO

Mail::Bulkmail, Mail::Bulkmail::Server

=head1 COPYRIGHT (again)

Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Mail::Bulkmail::Object is distributed under the terms of the Perl Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut


=cut
