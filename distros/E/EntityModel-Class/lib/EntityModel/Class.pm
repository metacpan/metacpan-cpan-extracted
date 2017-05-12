package EntityModel::Class;
# ABSTRACT: Helper module for generating class definitions
use strict;
use warnings;

use feature ();

use IO::Handle;

our $VERSION = '0.016';

=head1 NAME

EntityModel::Class - define class definition

=head1 VERSION

Version 0.016

=head1 SYNOPSIS

 package Thing;
 use EntityModel::Class {
	name => 'string',
 	items => { type => 'array', subclass => 'string' }
 };

 package main;
 my $thing = Thing->new;
 $thing->name('A thing');
 $thing->items->push('an entry');
 $thing->items->push('another entry');
 print "Have " . $thing->items->count . " items\n";

=head1 DESCRIPTION

Applies a class definition to a package. Automatically includes strict, warnings, error handling and other
standard features without needing to copy and paste boilerplate code.

=head1 USAGE

NOTE: This is mainly intended for use with L<EntityModel> only, please consider L<Moose> or similar for other
projects.

Add EntityModel::Class near the top of the target package:

 package Test;
 use EntityModel::Class { };

The hashref parameter contains the class definition. Each key is the name of an attribute for the class,
with the exception of the following underscore-prefixed keys:

=over 4

=item * C<_vcs> - version control system information, a plain string containing information about the last
changed revision and author for this file.

 use EntityModel::Class { _vcs => '$Id$' };

=item * C<_isa> - set up the parents for this class, similar to C<use parent>.

 use EntityModel::Class { _isa => 'DateTime' };

=back

An attribute definition will typically create an accessor with the same name, and depending on type may
also include some additional helper methods.

Available types include:

=over 4

=item * C<string> - simple string scalar value.

 use EntityModel::Class { name => { type => 'string' } };

=item * C<array> - an array of objects, provide the object type as the subclass parameter

 use EntityModel::Class { childNodes => { type => 'array', subclass => 'Node' } };

=item * C<hash> - hash of objects of subclass type

 use EntityModel::Class { authorMap => { type => 'hash', subclass => 'Author' } };

=back

If the type (or subclass) contains '::', or starts with a Capitalised letter, then it will be treated
as a class. All internal type names are lowercase.

You can also set the scope on a variable, which defines whether it should be include when exporting or
importing:

=over 4

=item * C<private> - private attributes are not exported or visible in attribute lists

 use EntityModel::Class { authorMap => { type => 'hash', subclass => 'Author', scope => 'private' } };

=item * C<public> (default) - public attributes are included in export/import, and will be visible when listing attributes for the class

 use EntityModel::Class { name => { type => 'string', scope => 'public' } };

=back

You can also specify actions to take when a variable is changed, to support internal attribute observers,
by specifying the C<watch> parameter. This takes a hashref with key corresponding to the attribute to watch,
and value indicating the method on that object. For example, C<page => 'path'> would update whenever the
C<path> mutator is called on the C<page> attribute. This is intended for use with hash and array containers,
rather than classes or simple types.

 package Compendium;
 use EntityModel::Class {
 	authors => { type => 'array', subclass => 'Author' },
 	authorByName => { type => 'hash', subclass => 'Author', scope => 'private', watch => { authors => 'name' } }
 };

 package main;
 my $c = Compendium->new;
 $c->authors->push(Author->new("Adams"));
 $c->authors->push(Author->new("Brecht"));
 print $c->authorByName->{'Adams'}->id;

=cut

use Scalar::Util qw(refaddr);
use Check::UnitCheck;
use Module::Load;
use overload;

use EntityModel::Log ':all';
use EntityModel::Array;
use EntityModel::Hash;
use EntityModel::Error;
use EntityModel::Class::Accessor;
use EntityModel::Class::Accessor::Array;
use EntityModel::Class::Accessor::Hash;

my %classInfo;

my %CLASS_DEFAULTS;

=head2 import

Apply supplied attributes, and load in the following modules:

=over 4

=item use strict;

=item use warnings;

=item use feature;

=item use 5.010;

=back

=cut

sub import {
	my $class = __PACKAGE__;
	my $called_on = shift;
	my $pkg = caller(0);

	my $info = (ref($_[0]) && ref($_[0]) eq 'HASH') ? $_[0] : { @_ };  # support list of args or hashref

	# Expand 'string' to { type => 'string' }
	$_ = { type => $_ } foreach grep { !ref($_) && /^[a-z]/i } values %$info;

# Bail out early if we already have inheritance or have recorded this entry in the master list
	return if $classInfo{$pkg} || $pkg->isa('EntityModel::BaseClass');

# Basic setup, including strict and other pragmas
	$class->setup($pkg);
	$class->apply_inheritance($pkg, $info);
	$class->load_dependencies($pkg, $info);
	$class->apply_logging($pkg, $info);
	$class->apply_version($pkg, $info);
	$class->apply_attributes($pkg, $info);
	$class->record_class($pkg, $info);
	1;
}

=head2 record_class

Add an entry for this class in the central class info hash.

=cut

sub record_class {
	my ($class, $pkg, $info) = @_;
	my @attribs = grep { !/^_/ } keys %$info;
	{ no strict 'refs'; *{$pkg . '::ATTRIBS'} = sub () { @attribs }; }
	$classInfo{$pkg} = $info;
}

=head2 apply_inheritance

Set up inheritance as required for this class.

=cut

sub apply_inheritance {
	my ($class, $pkg, $info) = @_;
# Inheritance
	my @inheritFrom = @{ $info->{_isa} // [] };
	push @inheritFrom, 'EntityModel::BaseClass';
	# TODO we want to skip loading if the module has already been loaded or defined
	# earlier, but there is probably a cleaner way to do this?
	Module::Load::load($_) for grep !$pkg->isa($_), @inheritFrom;
	{ no strict 'refs'; push @{$pkg . '::ISA'}, @inheritFrom; }
	delete $info->{_isa};
}

=head2 load_dependencies

Load all modules required for classes

=cut

sub load_dependencies {
	my ($class, $pkg, $info) = @_;
	my @attribs = grep { !/^_/ && !/~~/ } keys %$info;
	my @classList = grep { $_ && /:/ } map { $info->{$_}->{subclass} // $info->{$_}->{type} } grep { !$info->{$_}->{defer} } @attribs;
	CLASS:
	foreach my $c (@classList) {
		my $file = $c;
		$file =~ s{::|'}{/}g;
		$file .= '.pm';
		if($INC{$file}) {
			logDebug("Already in INC: $file");
			next CLASS;
		}
		eval {
			Module::Load::load($c);
			1
		} or do {
			logError($@) unless $@ =~ /^Can't locate /;
		};
	}
}

=head2 apply_logging

=cut

sub apply_logging {
	my ($class, $pkg, $info) = @_;
# Support logging methods by default, unless explicitly disabled
	EntityModel::Log->export_to_level(2, $pkg, ':all')
	 if $info->{_log} || !exists $info->{_log};
# Apply any log-level overrides first at package level
	if(exists $info->{_logMask}->{default}) {
		$EntityModel::Log::LogMask{$pkg}->{level} = EntityModel::Log::levelFromString($info->{_logMask}->{default});
	}

# ... then at method level
	if(exists $info->{_logMask}->{methods}) {
		my %meth = %{$info->{_logMask}->{methods}};
		foreach my $k (keys %meth) {
			$EntityModel::Log::LogMask{$pkg . '::' . $k}->{level} = EntityModel::Log::levelFromString($meth{$k});
		}
	}
}

=head2 apply_version

Record the VCS revision information from C<_vcs> attribute.

=cut

sub apply_version {
	my ($class, $pkg, $info) = @_;
# Typically version is provided as an SVN Rev property wrapped in $ signs.
	if(exists $info->{_vcs}) {
		my $v = delete $info->{_vcs};
		$class->vcs($pkg, $v);
	}
}

=head2 apply_attributes

=cut

sub apply_attributes {
	my ($class, $pkg, $info) = @_;
	my %methodList;
	my @attribs = grep { !/^_/ } keys %$info;

# Smart match support - 1 to use a default refaddr-based system, coderef for anything else
	if(my $match = delete $info->{'~~'}) {
		$class->add_method($pkg, '()', sub () { });
		if(ref $match) {
			$class->add_method($pkg, '(~~', $match);
		} else {
			$class->add_method($pkg, '(~~', sub {
				my ($self, $target) = @_;
				return 0 unless defined($self) && defined($target);
				return 0 unless ref($self) && ref($target);
				return 0 unless $self->isa($pkg);
				return 0 unless $target->isa($pkg);
				return 0 unless refaddr($self) == refaddr($target);
				return 1;
			});
		}

		# Update overload cache if we previously invalidated (for smartmatch or other operators),
		# possibly required if calling L<apply_attributes> at runtime.
		bless {}, $pkg;
	}

# Anything else is an accessor, set it up
	foreach my $attr (@attribs) {
		my $type = $info->{$attr}->{type};
		if($type eq 'array') {
			%methodList = (%methodList, EntityModel::Class::Accessor::Array->add_to_class($pkg, $attr => $info->{$attr}))
		} elsif($type eq 'hash') {
			%methodList = (%methodList, EntityModel::Class::Accessor::Hash->add_to_class($pkg, $attr => $info->{$attr}))
		} else {
			%methodList = (%methodList, EntityModel::Class::Accessor->add_to_class($pkg, $attr => $info->{$attr}))
		}
	}

	$CLASS_DEFAULTS{$pkg} = [ grep { exists $info->{$_}->{default} } @attribs ];

# Apply watchers after we've defined the fields - each watcher is field => method
	foreach my $watcher (grep { exists $info->{$_}->{watch} } @attribs) {
		my $w = $info->{$watcher}->{watch};
		foreach my $watched (keys %$w) {
			$class->add_watcher($pkg, $watcher, $watched, $info->{$watched}, $w->{$watched});
		}
	}

# Thanks to Check::UnitCheck
	Check::UnitCheck::unitcheckify(sub {
		# FIXME Can't call any log functions within UNITCHECK
		local $::DISABLE_LOG = 1;
		my %ml = %methodList;
		$class->add_method($pkg, $_, $ml{$_}) foreach keys %ml;
		$class->add_method($pkg, 'import', sub { }) unless $pkg->can('import');
	}) if %methodList;
}

=head2 add_method

=cut

sub add_method {
	my $class = shift;
	my ($pkg, $name, $method) = @_;
	my $sym = $pkg . '::' . $name;
	logDebug("Add method $sym");
	{ no strict 'refs'; *$sym = $method unless *$sym{CODE}; }
	return $sym;
}

=head2 vcs

Add a version control system tag to the class.

=cut

sub vcs {
	my $class = shift;
	my $pkg = shift;
	my $v = shift;

	# Define with empty prototype, which should mean we compile to a constant
	my $versionSub = sub () { $v };
	my $sym = $pkg . '::VCS_INFO';
	{ no strict 'refs'; *$sym = $versionSub unless *$sym{CODE}; }
}

=head2 setup

Standard module setup - enable strict and warnings, and disable 'import' fallthrough.

=cut

sub setup {
	my ($class, $pkg) = @_;

	strict->import;
	warnings->import();
	feature->import(':5.10');
}


=head2 validator

Basic validation function.

=cut

sub validator {
	my $v = shift;
	my $allowed = $v->{valid};
	return defined $allowed
	 ? ref $allowed eq 'CODE'
	 ? $allowed : sub { $_[0] eq $allowed }
	 : undef;
}

=head2 _attrib_info

Returns attribute information for a given package's attribute.

=cut

sub _attrib_info {
	my $class = shift;
	my $attr = shift;
	# return unless ref $self;
	return $classInfo{ref $class || $class}->{$attr};
}

=head2 has_defaults

Returns any defaults defined for this class.

=cut

sub has_defaults {
	my $class = shift;
	return @{ $CLASS_DEFAULTS{$class} // [] };
}

=head2 add_watcher

Add watchers as required for all package definitions.

Call this after all the class definitions have been loaded.

=cut

sub add_watcher {
	my $class = shift;
	my ($pkg, $obj, $target, $attrDef, $meth) = @_;

# The watcher is called with the new value as add|drop => $v
	my $sub = sub {
		my $self = shift;
		my ($action, $v) = @_;
		return unless $v;
		my $k = $meth ? $v->$meth : $v;
		logDebug("%s for %s with %s", $action, $k, $v);
		if($action eq 'add') {
			$self->$obj->set($k, $v);
		} elsif($action eq 'drop') {
			$self->$obj->erase($k);
		} else {
			logError("Don't know %s", $_);
		}
		return $self;
	};

	if($attrDef->{type} eq 'array') {
		EntityModel::Class::Accessor::Array->add_watcher($pkg, $target, $sub);
	} else {
		die "Unknown type " . ($_ // 'undef');
	}
}

1;

__END__

=head1 SEE ALSO

Or rather, "please use instead of this module":

=over 4

=item * L<Moose>

=item * L<Moo>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2013. Licensed under the same terms as Perl itself.
