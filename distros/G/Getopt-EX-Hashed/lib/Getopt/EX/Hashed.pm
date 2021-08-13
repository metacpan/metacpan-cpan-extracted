package Getopt::EX::Hashed;

our $VERSION = '0.9912';

=head1 NAME

Getopt::EX::Hashed - Hash store object automation

=head1 VERSION

Version 0.9912

=head1 SYNOPSIS

  use App::foo;
  App::foo->new->run();

  package App::foo;

  use Getopt::EX::Hashed;
  has start => ( spec => "=i s begin", default => 1 );
  has end   => ( spec => "=i e" );
  has file  => ( spec => "=s", is => 'rw' );
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
    RESET_AFTER_NEW    => 0,
    GETOPT             => 'GetOptions',
    ACCESSOR_PREFIX    => '',
    DEFAULT            => undef,
    );
lock_keys %DefaultConfig;

our @EXPORT = qw(has);

sub import {
    my $caller = caller;
    no strict 'refs';
    push @{"$caller\::ISA"}, __PACKAGE__;
    *{"$caller\::$_"} = \&{$_} for @EXPORT;
    my $C = __Config__($caller);
    unless (%{$C}) {
	%{$C} = %DefaultConfig or die "something wrong!";
	lock_keys %{$C};
    }
}

sub configure {
    my $class = shift;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $C = __Config__($ctx);
    while (my($key, $value) = splice @_, 0, 2) {
	$C->{$key} = $value;
    }
    return $class;
}

sub unimport {
    no strict 'refs';
    my $caller = caller;
    delete ${"$caller\::"}{has};
}

sub reset {
    my $M = __Member__(caller);
    @{$M} = ();
    return $_[0];
}

sub has {
    my($key, @param) = @_;
    my @name = ref $key eq 'ARRAY' ? @$key : $key;
    my $caller = caller;
    my $M = __Member__($caller);
    my $C = __Config__($caller);
    for my $name (@name) {
	my $append = $name =~ s/^\+//;
	my $i = first { ${$M}[$_]->[0] eq $name } 0 .. $#{$M};
	if ($append) {
	    defined $i or die "$name: Not found\n";
	    push @{${$M}[$i]}, @param;
	} else {
	    defined $i and die "$name: Duplicated\n";
	    if (my $default = $C->{DEFAULT}) {
		if (ref $default eq 'ARRAY') {
		    unshift @param, @{$default};
		}
	    }
	    push @{$M}, [ $name, @param ];
	}
    }
}

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $M = __Member__($ctx);
    my $C = __Config__($ctx);
    my $member = $obj->{__Hash__} = {
	map {
	    my($key, %param) = @$_;
	    $key => \%param;
	} @{$M}
    };
    my $order = $obj->{__Order__} = [ map $_->[0], @{$M} ];
    for my $key (@{$order}) {
	my $m = $member->{$key};
	$obj->{$key} = $m->{default};
	if (my $is = $m->{is}) {
	    no strict 'refs';
	    my $access = $C->{ACCESSOR_PREFIX} . $key;
	    *{"$class\::$access"} = _accessor($is, $key);
	}
    }
    lock_keys %{$obj} if $C->{LOCK_KEYS};
    __PACKAGE__->reset if $C->{RESET_AFTER_NEW};
    $obj;
}

sub _accessor {
    my($is, $name) = @_;
    {
	ro => sub {
	    $#_ and die "$name is readonly\n";
	    $_[0]{$name};
	},
	rw => sub {
	    $#_ and do { $_[0]{$name} = $_[1]; return $_[0] };
	    $_[0]{$name};
	}
    }->{$is} or die "$name has invalid 'is' parameter.\n";
}

sub optspec {
    my $obj = shift;
    my $ref = ref $obj;
    my $ctx = $ref ne __PACKAGE__ ? $ref : caller;
    _optspec($obj, $ctx, @_);
}

sub _optspec {
    my $obj = shift;
    my $ctx = shift;
    my $member = $obj->{__Hash__};
    my @optlist = do {
	map  {
	    my($name, $spec) = @$_;
	    my $compiled = _compile($ctx, $name, $spec);
	    my $m = $member->{$name};
	    my $dest = do {
		if (my $action = $m->{action}) {
		    ref $action eq 'CODE' or
			die "$name: action must be coderef.\n";
		    sub { &$action for $obj };
		} else {
		    if (ref $obj->{$name} eq 'CODE') {
			sub { &{$obj->{$name}} for $obj };
		    } else {
			\$obj->{$name};
		    }
		}
	    };
	    $compiled => $dest;
	}
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
    @optlist;
}

my $spec_re = qr/[!+=:]/;

sub _compile {
    my $ctx = shift;
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
    my $C = __Config__($ctx);
    if ($C->{REPLACE_UNDERSCORE}) {
	for ($name, @alias) {
	    push @names, tr[_][-]r if /_/;
	}
    }
    push @names, '' if @names and $spec !~ /^($spec_re|$)/;
    join('|', @names) . $spec;
}

sub getopt {
    my $obj = shift;
    my $ref = ref $obj;
    my $ctx = $ref ne __PACKAGE__ ? $ref : caller;
    my $C = __Config__($ctx);
    my $getopt = caller . "::" . $C->{GETOPT};
    no strict 'refs';
    &{$getopt}(_optspec($obj, $ctx));
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

Accessor methods are automatically generated when appropiate parameter
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

=item B<is> => I<ro> | I<rw>

If an B<is> parameter is given, accessor method for the member,
read-only for I<ro> and read-write for I<rw>, is generated.

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
There is no difference with ones in B<spec> parameter.

=item B<default> => I<value>

Set default value.  If no default is given, the member is initialized
as C<undef>.

=item B<action> => I<coderef>

Parameter B<action> takes code reference which is called to process
the option.  When called, hash object is passed through C<$_>.

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

In fact, B<default> parameter takes code reference too.  It is stored
in the hash object and the code works almost same.  But the hash value
can not be used for option storage.

Because B<action> function intercept the option assignment, it can be
used to verify the parameter.

    has age =>
        spec => '=i',
        action => sub {
            my($name, $i) = @_;
            (0 <= $i and $i <= 150) or
                die "$name: have to be in 0 to 150 range.\n";
            $_->{$name} = $i;
        };

=back

=head1 METHOD

=over 7

=item B<new>

Class method to get initialized hash object.

=item B<configure>

There should be some configurable variables, but not fixed yet.

=item B<getopt>

Call C<GetOptions> function defined in caller's context with
appropriate parameters.

    $obj->getopt

is just a shortcut for:

    GetOptions($obj->optspec)

=item B<optspec>

Return option specification list which can be given to C<GetOptions>
function.  GetOptions has a capability of storing values in a hash, by
giving the hash reference as a first argument, but it is not expected.

=item B<use_keys>

Because hash keys are protected by C<Hash::Util::lock_keys>, accessing
non-existing member causes an error.  Use this function to declare new
member key before use.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

=item B<reset>

Reset the class to original state.  Because the hash object keeps all
information, this does not effect to the existing object.  It returns
the object itself, so you can reset the class after creating a object
like this:

    my $obj = Getopt::EX::Hashed->new->reset;

This is almost equivalent to the next code:

    my $obj = Getopt::EX::Hashed->new;
    Getopt::EX::Hashed->reset;

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
