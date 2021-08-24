package Getopt::EX::Hashed;

our $VERSION = '0.9916';

=head1 NAME

Getopt::EX::Hashed - Hash store object automation

=head1 VERSION

Version 0.9916

=head1 SYNOPSIS

  use App::foo;
  App::foo->new->run();

  package App::foo;

  use Getopt::EX::Hashed;
  has start  => ( spec => "=i s begin", default => 1 );
  has end    => ( spec => "=i e" );
  has file   => ( spec => "=s", is => 'rw', re => qr/^(?!\.)/ );
  has score  => ( spec => '=i', min => 0, max => 100 );
  has answer => ( spec => '=i', must => sub { $_[1] == 42 } );
  no  Getopt::EX::Hashed;

  sub run {
      my $app = shift;
      use Getopt::Long;
      $app->getopt or pod2usage();
      if ($app->{start}) {
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
    $__DB__{$_[0]} //= do {
	no strict 'refs';
	state $sub = __PACKAGE__ =~ s/::/_/gr;
	\%{"$_[0]\::$sub\::__DB__"};
    };
}
sub __Member__ { __DB__(@_)->{Member} //= [] }
sub __Config__ { __DB__(@_)->{Config} //= {} }

my %DefaultConfig = (
    DEBUG_PRINT        => 0,
    LOCK_KEYS          => 1,
    REPLACE_UNDERSCORE => 1,
    REMOVE_UNDERSCORE  => 0,
    GETOPT             => 'GetOptions',
    ACCESSOR_PREFIX    => '',
    DEFAULT            => undef,
    INVALID_MSG        => \&_invalid_msg,
    );
lock_keys %DefaultConfig;

our @EXPORT = qw(has);

sub import {
    my $caller = caller;
    no strict 'refs';
    push @{"$caller\::ISA"}, __PACKAGE__;
    *{"$caller\::$_"} = \&$_ for @EXPORT;
    my $config = __Config__($caller);
    unless (%$config) {
	%$config = %DefaultConfig or die "something wrong!";
	lock_keys %$config;
    }
}

sub configure {
    my $class = shift;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $config = __Config__($ctx);
    while (my($key, $value) = splice @_, 0, 2) {
	$config->{$key} = $value;
    }
    return $class;
}

sub unimport {
    no strict 'refs';
    my $caller = caller;
    delete ${"$caller\::"}{$_} for @EXPORT;
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
    my @name = ref $key eq 'ARRAY' ? @$key : $key;
    my $caller = caller;
    my $member = __Member__($caller);
    my $config = __Config__($caller);
    for my $name (@name) {
	my $append = $name =~ s/^\+//;
	my $i = first { $member->[$_]->[0] eq $name } 0 .. $#{$member};
	if ($append) {
	    defined $i or die "$name: Not found\n";
	    push @{$member->[$i]}, @param;
	} else {
	    defined $i and die "$name: Duplicated\n";
	    if (my $default = $config->{DEFAULT}) {
		if (ref $default eq 'ARRAY') {
		    unshift @param, @$default;
		}
	    }
	    push @$member, [ $name, @param ];
	}
    }
}

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $member = __Member__($ctx);
    my $config = $obj->{__Config__} = __Config__($ctx);
    my $order  = $obj->{__Order__} = [];
    my $hash   = $obj->{__Hash__} = {};
    for my $m (@$member) {
	my($name, %param) = @$m;
	if (my $is = $param{is}) {
	    no strict 'refs';
	    my $access = $config->{ACCESSOR_PREFIX} . $name;
	    *{"$class\::$access"} = _accessor($is, $name);
	}
	$obj->{$name} = $param{default};
	push @$order, $name;
	$hash->{$name} = \%param;
    }
    lock_keys %$obj if $config->{LOCK_KEYS};
    $obj;
}

sub _conf {
    my $obj = shift;
    my $config = $obj->{__Config__} or die;
    if (@_) {
	$config->{+shift};
    } else {
	$config;
    }
}

sub _accessor {
    my($is, $name) = @_;
    {
	ro => sub {
	    $#_ and die "$name is readonly\n";
	    $_[0]->{$name};
	},
	rw => sub {
	    $#_ and do { $_[0]->{$name} = $_[1]; return $_[0] };
	    $_[0]->{$name};
	}
    }->{$is} or die "$name has invalid 'is' parameter.\n";
}

sub optspec {
    my $obj = shift;
    my $member = $obj->{__Hash__};
    my @spec = do {
	# spec .= alias
	map  {
	    if (my $alias = $member->{$_->[0]}->{alias}) {
		$_->[1] .= " $alias";
	    }
	    $_;
	}
	# spec = '' if $name eq = '<>'
	grep {
	    $_->[0] eq '<>' and $_->[1] //= '';
	    defined $_->[1];
	}
	# get spec
	map  { [ $_ => $member->{$_}->{spec} ] }
	@{$obj->{__Order__}};
    };
    my @optlist = map {
	my($name, $spec) = @$_;
	my $compiled = $obj->_compile($name, $spec);
	my $m = $member->{$name};
	my $action = $m->{action};
	$action and ref $action ne 'CODE'
	    and die "$name->action: not a coderef.\n";
	my $dest = do {
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
		} else {
		    \$obj->{$name};
		}
	    }
	};
	$compiled => $dest;
    } @spec;
}

sub _invalid_msg {
    my $opt = do {
	if (@_ <= 2) {
	    '--' . join '=', @_;
	} else {
	    sprintf "--%s %s=%s", @_[0..2];
	}
    };
    "$opt: option validation error\n";
}

my %tester = (
    min  => sub { $_[-1] >= $_->{min} },
    max  => sub { $_[-1] <= $_->{max} },
    re   => sub { $_[-1] =~ $_->{re} },
    must => sub { &{$_->{must}} },
    );

sub _tester {
    my $m = shift;
    map { $tester{$_} } grep { defined $m->{$_} } keys %tester;
}

sub _validator {
    my $m = shift;
    my @test = _tester($m) or return undef;
    sub {
	local $_ = $m;
	for my $test (@test) { &$test or return 0 }
	return 1;
    }
}

sub _generic_setter {
    my $dest = $_->{$_[0]};
    (ref $dest eq 'ARRAY') ? do { push @$dest, $_[1] } :
    (ref $dest eq 'HASH' ) ? do { $dest->{$_[1]} = $_[2] }
                           : do { $_->{$_[0]} = $_[1] };
}

my $spec_re = qr/[!+=:]/;

sub _compile {
    my $obj = shift;
    my($name, $args) = @_;

    return $name if $name eq '<>';

    my @args = split ' ', $args;
    my @spec = grep /$spec_re/, @args;
    my $spec = do {
	if    (@spec == 0) { '' }
	elsif (@spec == 1) { $spec[0] }
	else               { die }
    };
    my @alias = grep !/$spec_re/, @args;
    my @names = ($name, @alias);
    for ($name, @alias) {
	push @names, tr[_][-]r if /_/ && $obj->_conf->{REPLACE_UNDERSCORE};
	push @names, tr[_][]dr if /_/ && $obj->_conf->{REMOVE_UNDERSCORE};
    }
    push @names, '' if @names and $spec !~ /^($spec_re|$)/;
    join('|', @names) . $spec;
}

sub getopt {
    my $obj = shift;
    my $getopt = caller . "::" . $obj->_conf('GETOPT');
    no strict 'refs';
    $getopt->($obj->optspec());
}

sub use_keys {
    my $obj = shift;
    unlock_keys %{$obj};
    lock_keys_plus %{$obj}, @_;
}

1;

__END__

=head1 DESCRIPTION

B<Getopt::EX::Hashed> is a module to automate a hash object to store
command line option values.  Major objective of this module is
integrating initialization and specification into single place.
Module name shares B<Getopt::EX>, but it works independently from
other modules included in B<Getopt::EX>, so far.

In the current implementation, using B<Getopt::Long>, or compatible
module such as B<Getopt::EX::Long> is assumed.  It is configurable,
but no other module is supported now.

Accessor methods are automatically generated when appropriate parameter
is given.

=head1 FUNCTION

=head2 B<has>

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

If the name start with plus (C<+>), given parameters are added to
current value.

    has '+left' => ( default => 1 );

Following parameters are available.

=over 7

=item B<is> => C<ro> | C<rw>

To produce accessor method, C<is> parameter is necessary.  Set the
value C<ro> for read-only, C<rw> for read-write.

If you want to make accessor for all following members, use
C<configure> and set C<DEFAULT> parameter.

    Getopt::EX::Hashed->configure( DEFAULT => is => 'rw' );

=item B<spec> => I<string>

Give option specification.  Option spec and alias names are separated
by white space, and can show up in any order.

Declaration

    has start => ( spec => "=i s begin" );

will be compiled into string:

    start|s|begin=i

which conform to C<Getopt::Long> definition.  Of course, you can write
as this:

    has start => ( spec => "s|begin=i" );

If the name and aliases contain underscore (C<_>), another alias name
is defined with dash (C<->) in place of underscores.  So

    has a_to_z => ( spec => "=s" );

will be compiled into:

    a_to_z|a-to-z:s

If nothing special is necessary, give empty (or white space only)
string as a value.  Otherwise, it is not considered as an option.

=item B<alias> => I<string>

Additional alias names can be specified by B<alias> parameter too.
There is no difference with ones in C<spec> parameter.

=item B<default> => I<value>

Set default value.  If no default is given, the member is initialized
as C<undef>.

=item B<action> => I<coderef>

Parameter C<action> takes code reference which is called to process
the option.  When called, hash object is passed as C<$_>.

    has [ qw(left right both) ] => spec => '=i';
    has "+both" => action => sub {
        $_->{left} = $_->{right} = $_[1];
    };

You can use this for C<< "<>" >> to catch everything.  In that case,
spec parameter does not matter and not required.

    has ARGV => default => [];
    has "<>" => action => sub {
        push @{$_->{ARGV}}, $_[0];
    };

In fact, C<default> parameter takes code reference too.  It is stored
in the hash object and the code works almost same.  But the hash value
can not be used for option storage.

=back

Following parameters are all for data validation.  First C<must> is a
generic validator and can implement anything.  Others are shorthand
for common rules.

=over 7

=item B<must> => I<coderef>

Parameter C<must> takes a code reference to validate option values.
It takes same arguments as C<action> and returns boolean.  With next
example, option B<--answer> takes only 42 as a valid value.

    has answer =>
        spec => '=i',
        must => sub { $_[1] == 42 };

=item B<min> => I<number>

=item B<max> => I<number>

Set the minimum and maximum limit for the argument.

=item B<re> => qr/I<pattern>/

Set the required regular expression pattern for the argument.

=back

=head1 METHOD

=over 7

=item B<new>

Class method to get initialized hash object.

=item B<optspec>

Return option specification list which can be given to C<GetOptions>
function.

    GetOptions($obj->optspec)

C<GetOptions> has a capability of storing values in a hash, by giving
the hash reference as a first argument, but it is not necessary.

=item B<getopt>

Call C<GetOptions> function defined in caller's context with
appropriate parameters.

    $obj->getopt

is just a shortcut for:

    GetOptions($obj->optspec)

=item B<use_keys>

Because hash keys are protected by C<Hash::Util::lock_keys>, accessing
non-existent member causes an error.  Use this function to declare new
member key before use.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

You can change this behavior by C<configure> with C<LOCK_KEYS>
parameter.

=item B<configure> B<label> => I<value>, ...

There are following configuration parameters.

=over 7

=item B<LOCK_KEYS> (default: 1)

Lock hash keys.  This avoids accidental access to non-existent hash
entry.

=item B<REPLACE_UNDERSCORE> (default: 1)

Produce alias with underscores replaced by dash.

=item B<REMOVE_UNDERSCORE> (default: 0)

Produce alias with underscores removed.

=item B<GETOPT> (default: 'GetOptions')

Set function name called from C<getopt> method.

=item B<ACCESSOR_PREFIX>

When specified, it is prepended to the member name to make accessor
method.  If C<ACCESSOR_PREFIX> is defined as C<opt_>, accessor for
member C<file> will be C<opt_file>.

=item B<DEFAULT>

Set default parameters.  At the call for C<has>, DEFAULT parameters
are inserted before argument parameters.  So if both include same
parameter, later one in argument list has precedence.  Incremental
call with C<+> is not affected.

Typical use of DEFAULT is C<is> to prepare accessor method for all
following hash entries.  Declare C<< is => '' >> to reset.

    Getopt::EX::Hashed->configure(is => 'ro');

=back

=item B<reset>

Reset the class to the original state.

=back

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::EX>, L<Getopt::EX::Long>

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  Accessor param ro rw accessor undef coderef qw ARGV
#  LocalWords:  validator qr GETOPT GetOptions getopt obj optspec foo
#  LocalWords:  Kazumasa Utashiro min
