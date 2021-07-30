package Getopt::EX::Hashed;

our $VERSION = '0.9904';

=head1 NAME

Getopt::EX::Hashed - Hash store object automation

=head1 SYNOPSIS

  use App::foo;
  App::foo->new->run();

  package App::foo;

  use Getopt::EX::Hashed;
  has start => ( spec => "=i s begin", default => 1 );
  has end   => ( spec => "=i e" );
  no  Getopt::EX::Hashed;

  sub run {
      my $app = shift;
      use Getopt::Long;
      $app->getopt or pod2usage();
      if ($app->{start}) {
          ...

=head1 DESCRIPTION

B<Getopt::EX::Hashed> is a module to automate a hash object to store
command line option values.  Major objective of this module is to
integrate initialization and specification into single place.  Module
name shares B<Getopt::EX>, but it works independently from other
modules included in B<Getopt::EX>, so far.

In the current implementation, using B<Getopt::Long>, or compatible
module such as B<Getopt::EX::Long> is assumed.  It is configurable,
but no other module is supported now.

=head1 FUNCTION

=head2 B<has>

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( param => value, ... );

If the name start with plus (C<+>), given parameters are added to
current value.

    has '+left' => ( default => 1 );

Following parameters are available.

=over 7

=item B<spec> => I<string>

Give option specification.  Option spec and alias names are separated
by white space, and can show up in any order.

Declaration

    has start => ( spec => "=i s begin" );

will be compiled into string:

    start|s|begin:i

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
as C<undef>.  See B<action>.

=item B<action> => I<coderef>

Parameter B<action> takes code reference which called to process the
option.  When called, hash object is passed through C<$_>.

    has [ qw(left right both) ] => spec => '=i';
    has "+both" => action => sub {
        $_->{left} = $_->{right} = $_[1];
    };

You can use this for C<< "<>" >> too.  In this case, spec parameter
does not matter and is not required.

    has ARGV => default => [];
    has "<>" => action => sub {
        push @{$_->{ARGV}}, $_[0];
    };

In fact, B<default> and B<action> parameters are twins and works same.
Parameter B<action> is just a little more understandable, one byte
shorter, and verifies the value.  They are exclusive.

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

    GetOptions($obj, $obj->optspec)

=item B<optspec>

Return option specification list which can be given to C<GetOptions>
function with the hash object.

=item B<use_keys>

Because hash keys are protected by C<Hash::Util::lock_keys>, accessing
non-existing member causes an error.  Use this function to declare new
member key before use.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

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

use v5.14;
use warnings;
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
use Carp;
use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw(has new);

my @Member;
my %Member;

my %Config = (
    LOCK_KEYS          => 1,
    REPLACE_UNDERSCORE => 1,
    GETOPT             => 'GetOptions',
    );
lock_keys %Config;

sub configure {
    my $obj = shift;
    while (my($key, $value) = splice @_, 0, 2) {
	$Config{$key} = $value;
    }
    return $obj;
}

sub unimport {
    no strict 'refs';
    my $caller = caller;
    delete ${"$caller\::"}{has};
}

sub reset {
    @Member = %Member = ();
    return $_[0];
}

sub has {
    my($name, %param) = @_;
    my @name = ref $name eq 'ARRAY' ? @$name : $name;
    for (@name) {
	my $append = s/^\+//;
	if ($append) {
	    $Member{$_} or die "$_: Not defined\n";
	    $Member{$_} = { %{$Member{$_}}, %param };
	} else {
	    $Member{$_} and die "$_: Duplicated\n";
	    push @Member, $_;
	    $Member{$_} = \%param;
	}
    }
}

sub new {
    my $class = shift;
    my $obj = bless {}, __PACKAGE__;
    my $member = $obj->{__Hash__} = { %Member };
    my $order = $obj->{__Order__} = [ @Member ];
    our @ISA = $class if $class ne __PACKAGE__;
    for my $key (@{$order}) {
	my $m = $member->{$key};
	$obj->{$key} = do {
	    my($default, $action) = @{$m}{qw(default action)};
	    if ($action) {
		defined $default and
		    die "$key: Don't define both default and action.\n";
		ref($action) eq 'CODE' or
		    die "$key: action have to be coderef.\n";
		$default = $action;
	    }
	    if (defined($default) and ref($default) eq 'CODE') {
		sub {
		    $default->(@_) for $obj;
		};
	    } else {
		$default;
	    }
	};
    }
    lock_keys %{$obj} if $Config{LOCK_KEYS};
    @Member = %Member = ();
    $obj;
}

sub optspec {
    my $obj = shift;
    my $member = $obj->{__Hash__};
    do {
	map  { _optspec($obj, @$_) }
	map  {
	    if (my $alias = $member->{$_->[0]}->{alias}) {
		$_->[1] .= " $alias";
	    }
	    $_;
	}
	grep {
	    $_->[0] eq '<>' and $_->[1] //= '';
	    defined $_->[1];
	}
	map  { [ $_ => $member->{$_}->{spec} ] }
	@{$obj->{__Order__}};
    };
}

my $spec_re = qr/[!+=:]/;

sub _optspec {
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
    if ($Config{REPLACE_UNDERSCORE}) {
	for ($name, @alias) {
	    push @names, tr[_][-]r if /_/;
	}
    }
    push @names, '' if @names and $spec !~ /^($spec_re|$)/;
    join('|', @names) . $spec;
}

sub getopt {
    my $obj = shift;
    my $getopt = caller . "::" . $Config{GETOPT};
    no strict 'refs';
    &{$getopt}($obj, $obj->optspec);
}

sub use_keys {
    my $obj = shift;
    unlock_keys %{$obj};
    lock_keys_plus %{$obj}, @_;
}

1;
