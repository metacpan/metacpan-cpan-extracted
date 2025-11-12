package Getopt::EX::Hashed;

our $VERSION = '1.0602';

=encoding utf-8

=head1 NAME

Getopt::EX::Hashed - Hash object automation for Getopt::Long

=head1 VERSION

Version 1.0602

=head1 SYNOPSIS

  # script/foo
  use App::foo;
  App::foo->new->run();

  # lib/App/foo.pm
  package App::foo;

  use Getopt::EX::Hashed; {
      Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
      has start    => ' =i  s begin ' , default => 1;
      has end      => ' =i  e       ' ;
      has file     => ' =s@ f       ' , any => qr/^(?!\.)/;
      has score    => ' =i          ' , min => 0, max => 100;
      has answer   => ' =i          ' , must => sub { $_[1] == 42 };
      has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
      has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
  } no Getopt::EX::Hashed;

  sub run {
      my $app = shift;
      use Getopt::Long;
      $app->getopt or pod2usage();
      if ($app->answer == 42) {
          $app->question //= 'life';
          ...

=cut

use v5.14;
use warnings;
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
use Carp;
use Data::Dumper;
use List::Util qw(first);

# store metadata in caller context
my  %__DB__;
sub  __DB__ {
    my $caller = shift;
    state $pkg = __PACKAGE__ =~ s/::/_/gr;
    no strict 'refs';
    $__DB__{$caller} //= \%{"$caller\::$pkg\::__DB__"};
}
sub __Member__ { __DB__($_[0])->{Member} //= [] }
sub __Config__ { __DB__($_[0])->{Config} //= {} }

my %DefaultConfig = (
    DEBUG_PRINT        => 0,
    LOCK_KEYS          => 1,
    REPLACE_UNDERSCORE => 1,
    REMOVE_UNDERSCORE  => 0,
    GETOPT             => 'GetOptions',
    GETOPT_FROM_ARRAY  => 'GetOptionsFromArray',
    ACCESSOR_PREFIX    => '',
    ACCESSOR_LVALUE    => 1,
    DEFAULT            => [],
    INVALID_MSG        => \&_invalid_msg,
    );
lock_keys %DefaultConfig;

our @EXPORT = qw(has);

sub import {
    my $pkg = shift;
    my $caller = caller;
    no strict 'refs';
    push @{"$caller\::ISA"}, __PACKAGE__;
    *{"$caller\::$_"} = \&$_ for @EXPORT;
    my $config = __Config__($caller);
    unless (%$config) {
	unlock_keys %$config;
	%$config = %DefaultConfig or die "Failed to initialize config";
	lock_keys %$config;
    }
}

sub unimport {
    my $caller = caller;
    no strict 'refs';
    delete ${"$caller\::"}{$_} for @EXPORT;
}

sub configure {
    my $class = shift;
    my $config = do {
	if (ref $class) {
	    $class->_conf;
	} else {
	    my $ctx = $class ne __PACKAGE__ ? $class : caller;
	    __Config__($ctx);
	}
    };
    while (my($key, $value) = splice @_, 0, 2) {
	if ($key eq 'DEFAULT') {
	    ref($value) eq 'ARRAY' or die "DEFAULT must be arrayref";
	    @$value % 2 == 0       or die "DEFAULT has wrong members";
	}
	$config->{$key} = $value;
    }
    return $class;
}

sub reset {
    my $caller = caller;
    my $member = __Member__($caller);
    my $config = __Config__($caller);
    @$member = ();
    %$config = %DefaultConfig;
    return $_[0];
}

sub has {
    my($key, @param) = @_;
    if (@param % 2) {
	my $default = ref $param[0] eq 'CODE' ? 'action' : 'spec';
	unshift @param, $default;
    }
    my @name = ref $key eq 'ARRAY' ? @$key : $key;
    my $caller = caller;
    my $member = __Member__($caller);
    for my $name (@name) {
	my $append = $name =~ s/^\+//;
	my $i = first { $member->[$_][0] eq $name } keys @$member;
	if ($append) {
	    defined $i or die "$name: Not found\n";
	    push @{$member->[$i]}, @param;
	} else {
	    defined $i and die "$name: Duplicated\n";
	    my $config = __Config__($caller);
	    push @$member, [ $name, @{$config->{DEFAULT}}, @param ];
	}
    }
}

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $master = __Member__($ctx);
    my $member = $obj->{__Member__} = [];
    my $config = $obj->{__Config__} = { %{__Config__($ctx)} }; # make copy
    for my $m (@$master) {
	my($name, %param) = @$m;
	push @$member, [ $name => \%param ];
	next if $name eq '<>';
	if (my $is = $param{is}) {
	    no strict 'refs';
	    my $sub = "$class\::" . $config->{ACCESSOR_PREFIX} . $name;
	    if (defined &$sub) {
		croak "&$sub already exists.\n";
	    }
	    $is = 'lv' if $is eq 'rw' && $config->{ACCESSOR_LVALUE};
	    *$sub = _accessor($is, $name);
	}
	$obj->{$name} = do {
	    local $_ = $param{default};
	    if    (ref eq 'ARRAY') {  [ @$_ ]  }
	    elsif (ref eq 'HASH' ) { ({ %$_ }) }
	    elsif (ref eq 'CODE' ) {  $_->()   }
	    else                   {  $_       }
	};
    }
    lock_keys %$obj if $config->{LOCK_KEYS};
    $obj;
}

sub DESTROY {
    my $obj = shift;
    my $pkg = ref $obj;
    my $hash = do { no strict 'refs'; \%{"$pkg\::"} };
    my $prefix = $obj->_conf->{ACCESSOR_PREFIX};
    for (@{ $obj->_member }) {
	next unless $_->[1]->{is};
	my $name = $prefix . $_->[0];
	delete $hash->{$name} if exists $hash->{$name};
    }
}

sub optspec {
    my $obj = shift;
    map $obj->_opt_pair($_), @{$obj->_member};
}

sub getopt {
    my $obj = shift;
    if (@_ == 0) {
	my $getopt = caller . "::" . $obj->_conf->{GETOPT};
	no strict 'refs';
	$getopt->($obj->optspec());
    }
    elsif (@_ == 1 and ref $_[0] eq 'ARRAY') {
	my $getopt = caller . "::" . $obj->_conf->{GETOPT_FROM_ARRAY};
	no strict 'refs';
	$getopt->($_[0], $obj->optspec());
    }
    else {
	die "getopt: wrong parameter.";
    }
}

sub use_keys {
    my $obj = shift;
    unlock_keys %$obj;
    lock_keys_plus %$obj, @_;
}

sub _conf   { $_[0]->{__Config__} }

sub _member { $_[0]->{__Member__} }

sub _accessor {
    my($is, $name) = @_;
    {
	ro => sub {
	    @_ > 1 and die "$name is readonly\n";
	    $_[0]->{$name};
	},
	rw => sub {
	    @_ > 1 and do { $_[0]->{$name} = $_[1]; return $_[0] };
	    $_[0]->{$name};
	},
	lv => sub :lvalue {
	    @_ > 1 and do { $_[0]->{$name} = $_[1]; return $_[0] };
	    $_[0]->{$name};
	},
    }->{$is} or die "$name has invalid 'is' parameter.\n";
}

sub _opt_pair {
    my $obj = shift;
    my $member = shift;
    my $spec_str = $obj->_opt_str($member) // return ();
    ( $spec_str => $obj->_opt_dest($member) );
}

sub _opt_str {
    my $obj = shift;
    my($name, $m) = @{+shift};

    $name eq '<>' and return $name;
    my $spec = $m->{spec} // return undef;
    if (my $alias = $m->{alias}) {
	$spec .= " $alias";
    }
    $obj->_compile($name, $spec);
}

sub _compile {
    my $obj = shift;
    my($name, $args) = @_;
    my @args  = split ' ', $args;
    my $spec_re = qr/[!+=:]/;
    my @spec  = grep  /$spec_re/, @args;
    my @alias = grep !/$spec_re/, @args;
    my $spec = do {
	if    (@spec == 0) { '' }
	elsif (@spec == 1) { $spec[0] }
	else               { die "Multiple option specs found: @spec" }
    };
    my @names = ($name, @alias);
    for ($name, @alias) {
	push @names, tr[_][-]r if /_/ && $obj->_conf->{REPLACE_UNDERSCORE};
	push @names, tr[_][]dr if /_/ && $obj->_conf->{REMOVE_UNDERSCORE};
    }
    push @names, '' if @names and $spec !~ /^($spec_re|$)/;
    join('|', @names) . $spec;
}

sub _opt_dest {
    my $obj = shift;
    my($name, $m) = @{+shift};

    my $action = $m->{action};
    if (my $is_valid = _validator($m)) {
	$action ||= \&_generic_setter;
	sub {
	    local $_ = $obj;
	    &$is_valid or die &{$obj->_conf->{INVALID_MSG}};
	    &$action;
	};
    }
    elsif ($action) {
	sub { &$action for $obj };
    }
    else {
	if (ref $obj->{$name} eq 'CODE') {
	    sub { &{$obj->{$name}} for $obj };
	} elsif (ref $obj->{$name} eq 'SCALAR') {
	    $obj->{$name};
	} else {
	    \$obj->{$name};
	}
    }
} 

my %tester = (
    min  => sub { $_[-1] >= $_->{min} },
    max  => sub { $_[-1] <= $_->{max} },
    must => sub {
	my $must = $_->{must};
	for (ref($must) eq 'ARRAY' ? @$must : $must) {
	    return 0 if not &$_;
	}
	return 1;
    },
    any => sub {
	my $any = $_->{any};
	for (ref($any) eq 'ARRAY' ? @$any : $any) {
	    if (ref eq 'Regexp') {
		return 1 if $_[-1] =~ $_;
	    } elsif (ref eq 'CODE') {
		return 1 if &$_;
	    } else {
		return 1 if $_[-1] eq $_;
	    }
	}
	return 0;
    },
    );

sub _tester {
    my $m = shift;
    map $tester{$_}, grep { defined $m->{$_} } keys %tester;
}

sub _validator {
    my $m = shift;
    my @test = _tester($m) or return undef;
    sub {
	local $_ = $m;
	for my $test (@test) {
	    return 0 if not &$test;
	}
	return 1;
    }
}

sub _generic_setter {
    my $dest = $_->{$_[0]};
    (ref $dest eq 'ARRAY') ? do { push @$dest, $_[1] } :
    (ref $dest eq 'HASH' ) ? do { $dest->{$_[1]} = $_[2] }
                           : do { $_->{$_[0]} = $_[1] };
}

sub _invalid_msg {
    my $opt = do {
	$_[0] = $_[0] =~ tr[_][-]r;
	if (@_ <= 2) {
	    '--' . join '=', @_;
	} else {
	    sprintf "--%s %s=%s", @_[0..2];
	}
    };
    "$opt: option validation error\n";
}

1;

__END__

=head1 DESCRIPTION

B<Getopt::EX::Hashed> is a module to automate the creation of a hash
object to store command line option values for B<Getopt::Long> and
compatible modules including B<Getopt::EX::Long>.  The module name
shares the B<Getopt::EX> prefix, but it works independently from other
modules in B<Getopt::EX>, so far.

The major objective of this module is integrating initialization and
specification into a single place.  It also provides a simple
validation interface.

Accessor methods are automatically generated when C<is> parameter is
given.  If the same function is already defined, the program causes
fatal error.  Accessors are removed when the object is destroyed.
Problems may occur when multiple objects are present at the same time.

=head1 FUNCTION

=head2 B<has>

Declare option parameters in the following form.  The parentheses are
for clarity only and may be omitted.

    has option_name => ( param => value, ... );

For example, to define the option C<--number>, which takes an integer
value as a parameter, and also can be used as C<-n>, do the following

    has number => spec => "=i n";

The accessor is created with the first name. In this
example, the accessor will be defined as C<< $app->number >>.

If an array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

If the name starts with plus (C<+>), the given parameter updates the
existing setting.

    has '+left' => ( default => 1 );

As for the C<spec> parameter, the label can be omitted if it is the
first parameter.

    has left => "=i", default => 1;

If the number of parameters is odd, the first parameter is treated as
having an implicit label: C<action> if it is a code reference,
C<spec> otherwise.

Following parameters are available.

=over 7

=item [ B<spec> => ] I<string>

Give option specification.  C<< spec => >> label can be omitted if and
only if it is the first parameter.

In I<string>, option spec and alias names are separated by white
space, and can show up in any order.

To have an option called C<--start> that takes an integer as its value
and can also be used with the names C<-s> and C<--begin>, declare as
follows.

    has start => "=i s begin";

The above declaration will be compiled into the following string.

    start|s|begin=i

which conforms to the C<Getopt::Long> definition.  Of course, you can
write it as:

    has start => "s|begin=i";

If the name and aliases contain underscore (C<_>), another alias name
is defined with dash (C<->) in place of underscores.

    has a_to_z => "=s";

The above declaration will be compiled into the following string.

    a_to_z|a-to-z=s

If no option spec is needed, give an empty (or white space only)
string as a value.  Without a spec string, the member will not be
treated as an option.

=item B<alias> => I<string>

Additional alias names can be specified by the B<alias> parameter too.
There is no difference from the ones in the C<spec> parameter.

    has start => "=i", alias => "s begin";

=item B<is> => C<ro> | C<rw>

To produce an accessor method, the C<is> parameter is necessary.  Set
the value C<ro> for read-only, C<rw> for read-write.

Read-write accessor has lvalue attribute, so it can be assigned to.
You can use like this:

    $app->foo //= 1;

This is much simpler than writing as in the following.

    $app->foo(1) unless defined $app->foo;

If you want to make accessors for all following members, use
C<configure> to set the C<DEFAULT> parameter.

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

If you don't like assignable accessors, configure the C<ACCESSOR_LVALUE>
parameter to 0.  Because accessors are generated at the time of C<new>,
this value is effective for all members.

=item B<default> => I<value> | I<coderef>

Set default value.  If no default is given, the member is initialized
as C<undef>.

If the value is a reference to an ARRAY or HASH, a shallow copy is
created for each C<new> call.  This means the reference itself is
copied, but the contents are shared.  Modifying the array or hash
contents will affect all instances.

If a code reference is given, it is called at the time of B<new> to
get default value.  This is effective when you want to evaluate the
value at the time of execution, rather than declaration.  If you want
to define a default action, use the B<action> parameter.  If you want
to set code reference as the initial value, you must specify a code
reference that returns a code reference.

If a reference to SCALAR is given, the option value is stored in the
data indicated by the reference, not in the hash object member.  In
this case, the expected value cannot be obtained by accessing the hash
member.

=item [ B<action> => ] I<coderef>

Parameter C<action> takes code reference which is called to process
the option.  C<< action => >> label can be omitted if and only if it
is the first parameter.

When called, hash object is passed as C<$_>.

    has [ qw(left right both) ] => '=i';
    has "+both" => sub {
        $_->{left} = $_->{right} = $_[1];
    };

You can use this for C<< "<>" >> to handle non-option arguments.  In
that case, the spec parameter does not matter and is not required.

    has ARGV => default => [];
    has "<>" => sub {
        push @{$_->{ARGV}}, $_[0];
    };

=back

Following parameters are all for data validation.  First, C<must> is a
generic validator and can implement anything.  Others are shortcuts
for common rules.

=over 7

=item B<must> => I<coderef> | [ I<coderef> ... ]

Parameter C<must> takes a code reference to validate option values.
It takes the same arguments as C<action> and returns a boolean.  With
the following example, option B<--answer> takes only 42 as a valid
value.

    has answer => '=i',
        must => sub { $_[1] == 42 };

If multiple code references are given, all code must return true.

    has answer => '=i',
        must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

=item B<min> => I<number>

=item B<max> => I<number>

Set the minimum and maximum limit for the argument.

=item B<any> => I<arrayref> | qr/I<regex>/ | I<coderef>

Set the valid string parameter list.  Each item can be a string, a
regex reference, or a code reference.  The argument is valid when it
is the same as, or matches any item of the given list.  If the value
is not an arrayref, it is taken as a single item list (regexpref or
coderef usually).

Following declarations are almost equivalent, except second one is
case insensitive.

    has question => '=s',
        any => [ 'life', 'universe', 'everything' ];

    has question => '=s',
        any => qr/^(life|universe|everything)$/i;

If you are using optional argument, don't forget to include default
value in the list.  Otherwise it causes validation error.

    has question => ':s',
        any => [ 'life', 'universe', 'everything', '' ];

=back

=head1 METHOD

=head2 B<new>

A class method that creates a new hash object.  Initializes all
members with their default values and creates accessor methods as
configured.  Returns a blessed hash reference.  The hash keys are
locked if LOCK_KEYS is enabled.

=head2 B<optspec>

Returns the option specification list which can be passed to the
C<GetOptions> function.

    GetOptions($obj->optspec)

C<GetOptions> has the capability of storing values in a hash by
giving the hash reference as the first argument, but it is not
necessary.

=head2 B<getopt> [ I<arrayref> ]

Calls the appropriate function defined in the caller's context to
process options.

    $obj->getopt

    $obj->getopt(\@argv);

The above examples are shortcuts for the following code.

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

=head2 B<use_keys> I<keys>

When LOCK_KEYS is enabled, accessing a non-existent member causes an
error.  Use this method to declare new member keys before accessing
them.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

You can change this behavior by C<configure> with C<LOCK_KEYS>
parameter.

=head2 B<configure> B<label> => I<value>, ...

Use class method C<< Getopt::EX::Hashed->configure() >> before
creating an object; this information is stored separately for each
calling package.  After calling C<new()>, the package-level
configuration is copied into the object for its use.  Use
C<< $obj->configure() >> to update object-level configuration.

The following configuration parameters are available.

=over 7

=item B<LOCK_KEYS> (default: 1)

Lock hash keys.  This prevents typos or other mistakes from creating
unintended hash entries.

=item B<REPLACE_UNDERSCORE> (default: 1)

Automatically create option aliases with underscores replaced by
dashes.

=item B<REMOVE_UNDERSCORE> (default: 0)

Automatically create option aliases with underscores removed.

=item B<GETOPT> (default: 'GetOptions')

=item B<GETOPT_FROM_ARRAY> (default: 'GetOptionsFromArray')

Set the function name called from the C<getopt> method.

=item B<ACCESSOR_PREFIX> (default: '')

When specified, it will be prepended to the member name to make the
accessor method.  If C<ACCESSOR_PREFIX> is defined as C<opt_>, the
accessor for member C<file> will be C<opt_file>.

=item B<ACCESSOR_LVALUE> (default: 1)

If true, read-write accessors have the lvalue attribute.  Set to zero
if you don't like that behavior.

=item B<DEFAULT>

Set default parameters.  When C<has> is called, DEFAULT parameters are
inserted before the explicit parameters.  If a parameter appears in
both, the explicit one takes precedence.  Incremental calls with C<+>
are not affected.

A typical use of DEFAULT is C<is> to prepare accessor methods for all
following hash entries.  Declare C<< DEFAULT => [] >> to reset.

    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

=begin comment

=item B<INVALID_MSG> (default: built-in error message generator)

Set a code reference to generate error messages for validation
failures.  The code reference receives the same arguments as the option
handler ($_[0] is option name, $_[1] is the value for simple options,
or $_[1] and $_[2] for hash options).  The default function generates
messages like "--option=value: option validation error".

    Getopt::EX::Hashed->configure(
        INVALID_MSG => sub {
            my $opt = shift;
            "Invalid value for --$opt: @_\n";
        }
    );

=end comment

=back

=head2 B<reset>

Reset the class to the original state.

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::EX>, L<Getopt::EX::Long>

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2025 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  Accessor param ro rw accessor undef coderef qw ARGV
#  LocalWords:  validator qr GETOPT GetOptions getopt obj optspec foo
#  LocalWords:  Kazumasa Utashiro min lvalue arrayref regex regexpref
#  LocalWords:  argv GetOptionsFromArray
