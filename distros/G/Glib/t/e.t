#!/usr/bin/perl
#
# ParamSpec stuff.
#
use strict;
use utf8;
use Glib ':constants';
use Test::More tests => 312;

# first register some types with which to play below.

Glib::Type->register_enum ('Fish', qw(one two red blue));
Glib::Type->register_flags ('Rain', qw(warm cold light heavy));
Glib::Type->register_object ('Glib::Object', 'Skeezle');


my @params;
my $pspec;

# compares only three decimal places of a floating point number.
sub is_float {
	my ($a, $b, $blurb) = @_;
	is (sprintf ('%.3f', $a),
	    sprintf ('%.3f', $b),
	    $blurb);
}

#
# assumes:
#   name = lc $nick
#   type = Glib::Param::$nick
#   value_type = Glib::$nick (unless you supply a specific one)
#   blurb is set and not ''
#   pspec has not been added to an object class (owner_type is undef)
#
sub pspec_common_ok {
	my ($pspec, $nick, $flags, $value_type) = @_;

	$value_type = "Glib::$nick"
		unless $value_type;

	isa_ok ($pspec, 'Glib::ParamSpec');
	isa_ok ($pspec, "Glib::Param::$nick");
	is ($pspec->get_name, lc $nick, "$nick name");
	is ($pspec->get_nick, $nick, "$nick nick");
	ok ($pspec->get_blurb, "$nick blurb");
	ok ($pspec->get_flags == $flags, "$nick flags"); # overloaded eq
	is ($pspec->get_value_type, $value_type, "$nick value type");
	ok (! $pspec->get_owner_type, "$nick owner type (hasn't been added to a class yet)");

	# for hysterical raisons and backward compatibility, the paramspec
	# objects have four keys in them:
	is ($pspec->{name}, $pspec->get_name, "$nick -> {name}"); # not valid if there's a - in the name!
	is ($pspec->{type}, $pspec->get_value_type, "$nick -> {type}");
	ok ($pspec->{flags} == $pspec->get_flags, "$nick -> {flags}");
	is ($pspec->{descr}, $pspec->get_blurb, "$nick -> {descr}");
}

$pspec = Glib::ParamSpec->boolean ('boolean', 'Boolean',
	                           'Is you is, or is you ain\'t my baby',
	                           TRUE, 'readable');
pspec_common_ok ($pspec, 'Boolean', 'readable');
ok ($pspec->get_default_value, "Boolean default (expect TRUE)");
push @params, $pspec;
{
  $pspec = Glib::ParamSpec->boolean ('boolean-default-false',
				     'Boolean-default-false',
				     'Blurb',
				     FALSE, 'readable');
  is ($pspec->get_default_value, '');  # boolSV style empty '' return
}


$pspec = Glib::ParamSpec->string ('string', 'String',
				  'Stringing you along with NULL default.',
				  undef,
				  'readable');
pspec_common_ok ($pspec, 'String', 'readable', 'Glib::String');
is ($pspec->get_default_value, undef, "String default NULL");
push @params, $pspec;


#
# all of the integer types have the same interface.
#
foreach my $inttype (
  [ 'Char', 'It builds character', -10, 120, 64, 'writable'],
  [ 'UChar', 'Give me sign!  I have no sign!', 10, 250, 128, ['readable', 'writable']],
  [ 'Int', 'most bugs show up in integration', -65535, 65535, 1138, ['readable', 'writable', 'construct']],
  [ 'UInt', 'UInt good enough for her', 256, 2**30, 7879, ['readable', 'writable', 'construct-only']],
  [ 'Long', 'Why the long face?', -10000, 10000, 0, G_PARAM_READWRITE],
  [ 'ULong', 'What do ulong for?', 0, 1000000, 100, G_PARAM_READWRITE],
) {
	my ($nick, $blurb, $min, $max, $default, $flags) = @$inttype;
	my $name = lc $nick;
	$pspec = Glib::ParamSpec->$name ($name, @$inttype);
	pspec_common_ok ($pspec, $nick, $flags);
	is ($pspec->get_minimum, $min, "$nick min");
	is ($pspec->get_maximum, $max, "$nick max");
	is ($pspec->get_default_value, $default, "$nick default");
	push @params, $pspec;
}

#
# floating-point types add get_epsilon to the integer interface.
# we also need to use a more sophisticated comparison of the float
# values, since == is rarely sufficient.
#
foreach my $floattype (
  ['Float', 'In the event of a water landing, your seat coushin may be used as a floation device.', -2.718, 3.141529, 0.707, G_PARAM_READWRITE], 
  ['Double', 'Double your pleasure, double your fun', 1.23456789, 9876543.21, 2.0, G_PARAM_READWRITE],
) {
	my ($nick, $blurb, $min, $max, $default, $flags) = @$floattype;
	my $name = lc $nick;
	$pspec = Glib::ParamSpec->$name ($name, @$floattype);
	pspec_common_ok ($pspec, $nick, $flags);
	is_float ($pspec->get_minimum, $min, "$nick minimum");
	is_float ($pspec->get_maximum, $max, "$nick maximum");
	is_float ($pspec->get_default_value, $default, "$nick default");
	ok ($pspec->get_epsilon > 0.0, "$nick epsilon");
	push @params, $pspec;
}


#
# and now the rest.
#

$pspec = Glib::ParamSpec->enum ('enum', 'Enum',
	                        'U Pluribus Enum.',
	                        'Fish', 'blue', G_PARAM_READWRITE);
pspec_common_ok ($pspec, 'Enum', G_PARAM_READWRITE, 'Fish');
is ($pspec->get_enum_class, 'Fish', 'enum class');
is ($pspec->get_default_value, 'blue', "Enum default");
push @params, $pspec;


$pspec = Glib::ParamSpec->flags ('flags', 'Flags',
	                         'Are people loyal to ideas or to flags?',
	                         'Rain', ['light', 'warm'], G_PARAM_READWRITE);
pspec_common_ok ($pspec, 'Flags', G_PARAM_READWRITE, 'Rain');
is ($pspec->get_flags_class, 'Rain', 'flags class');
ok ($pspec->get_default_value == ['light', 'warm'], 'Flags default');
push @params, $pspec;


$pspec = Glib::ParamSpec->boxed ('boxed', 'Boxed',
	                         'Big things come in little boxes',
	                         # we only know one boxed type at this point.
	                         'Glib::Scalar', G_PARAM_READWRITE);
pspec_common_ok ($pspec, 'Boxed', G_PARAM_READWRITE, 'Glib::Scalar');
is ($pspec->get_default_value, undef, 'Boxed default');
push @params, $pspec;


$pspec = Glib::ParamSpec->object ('object', 'Object',
	                          'I object, Your Honor, that\'s pure conjecture!',
	                          'Skeezle', G_PARAM_READWRITE);
pspec_common_ok ($pspec, 'Object', G_PARAM_READWRITE, 'Skeezle');
is ($pspec->get_default_value, undef, 'Object default');
push @params, $pspec;


$pspec = Glib::ParamSpec->param_spec ('param-spec', 'ParamSpec',
	                              '',
	                              'Glib::Param::Enum', G_PARAM_READWRITE);
isa_ok ($pspec, 'Glib::ParamSpec');
isa_ok ($pspec, 'Glib::Param::Param');
is ($pspec->get_name, 'param_spec', 'Param name (modified)');
is ($pspec->{name}, 'param-spec', 'Param name (unmodified)');
is ($pspec->get_nick, 'ParamSpec', 'Param nick');
is ($pspec->get_blurb, '', 'Param blurb');
ok ($pspec->get_flags == G_PARAM_READWRITE, 'Param flags');
is ($pspec->get_value_type, 'Glib::Param::Enum', 'Param value type');
ok (! $pspec->get_owner_type, 'Param owner type');
is ($pspec->get_default_value, undef, 'Param default');
push @params, $pspec;


$pspec = Glib::ParamSpec->unichar ('unichar', 'Unichar',
	                           'is that like unixsex?',
	                           'ö', qw/readable/);
pspec_common_ok ($pspec, 'Unichar', qw/readable/, 'Glib::UInt');
is ($pspec->get_default_value, 'ö', 'Unichar default');
push @params, $pspec;
{
  $pspec = Glib::ParamSpec->unichar ('unichar-nul', 'Unichar-Nul',
				     'Blurb',
				     "\0", # default
				     qw/readable/);
  is ($pspec->get_default_value, "\0",
      'ParamSpec unichar - default zero byte');

  $pspec = Glib::ParamSpec->unichar ('unichar-nul', 'Unichar-Nul',
				     'Blurb',
				     "0", # default
				     qw/readable/);
  is ($pspec->get_default_value, "0",
      'ParamSpec unichar - default zero digit');
}


#
# specific to the perl bindings
#
$pspec = Glib::ParamSpec->IV ('iv', 'IV',
	                      'This is the same as Int',
	                      -20, 10, -5, G_PARAM_READWRITE);
isa_ok ($pspec, 'Glib::Param::Long', 'IV is actually Long');
is ($pspec->get_default_value, -5, 'IV default');
push @params, $pspec;


$pspec = Glib::ParamSpec->UV ('uv', 'UV',
	                      'This is the same as UInt',
	                      10, 20, 15, G_PARAM_READWRITE);
isa_ok ($pspec, 'Glib::Param::ULong', 'UV is actually ULong');
is ($pspec->get_default_value, 15, 'UV default');
push @params, $pspec;


$pspec = Glib::ParamSpec->scalar ('scalar', 'Scalar',
	                          'This is the same as Boxed',
	                          G_PARAM_READWRITE);
isa_ok ($pspec, 'Glib::Param::Boxed', 'Scalar is actually Boxed');
is ($pspec->get_value_type, 'Glib::Scalar', 'boxed holding scalar');
is ($pspec->get_default_value, undef, 'Scalar default');
push @params, $pspec;



#
# now add all of these properties to an object class and verify that
# the owner types are correct.
#

Glib::Type->register (
	'Glib::Object' => 'Bar',
	properties => \@params
);

foreach (@params) {
	is ($_->get_owner_type, 'Bar', ref($_)." owner type after adding");
}

{
  my $object = Bar->new;

  # exercise default GET_PROPERTY fetching pspec default value
  foreach my $pspec (@params) {
    if ($pspec->get_flags & 'readable') {
      my $pname = $pspec->get_name;
      $object->get($pname);
    }
  }

  is ($object->get_property('unichar'), ord('ö'),
      'get_property() unichar default value (unicode code point number)');
}


SKIP: {
	skip "GParamSpecOverride is new in glib 2.4.0", 27
		unless Glib->CHECK_VERSION (2, 4, 0);

	my $pbase = Glib::ParamSpec->boolean ('obool','obool', 'Blurb',
					      0, G_PARAM_READWRITE);
	is ($pspec->get_redirect_target, undef);

	$pspec = Glib::ParamSpec->override ('over', $pbase);
	isa_ok ($pspec, 'Glib::Param::Override');
	is_deeply ($pspec->get_redirect_target, $pbase);
	{
	  my $pbase = Glib::ParamSpec->boolean ('obool',
						'Obool',
						'pbase blurb',
						0, G_PARAM_READWRITE);
	  is ($pbase->get_default_value, '');
	  is ($pbase->get_redirect_target, undef);

	  # p1 targetting pbase
	  my $p1 = Glib::ParamSpec->override ('over', $pbase);
	  isa_ok ($p1, 'Glib::Param::Override');
	  # is_deeply() because paramspec is GBoxed, so no identical objects
	  is_deeply ($p1->get_redirect_target, $pbase);

	  is ($p1->get_blurb, 'pbase blurb');
	  is ($p1->get_nick,  'Obool');
	  is ($p1->get_default_value, '');

	  # p2 targetting p1
	  my $p2 = Glib::ParamSpec->override ('over-over', $p1);
	  isa_ok ($p2, 'Glib::Param::Override');
	  # is_deeply() because paramspec is GBoxed, so no identical objects
	  is_deeply ($p2->get_redirect_target, $pbase);

	  is ($p2->get_blurb, 'pbase blurb');
	  is ($p2->get_nick,  'Obool');
	  is ($p2->get_default_value, '');
	}

	{
	  my $pbase = Glib::ParamSpec->unichar ('ounichar',
						'Ounichar',
						'pbase blurb',
						'z',
						G_PARAM_READWRITE);
	  is ($pbase->get_default_value, 'z');
	  is ($pbase->get_redirect_target, undef);

	  # p1 targetting pbase
	  my $p1 = Glib::ParamSpec->override ('over', $pbase);
	  isa_ok ($p1, 'Glib::Param::Override');
	  # is_deeply() because paramspec is GBoxed, so no identical objects
	  is_deeply ($p1->get_redirect_target, $pbase);

	  is ($p1->get_blurb, 'pbase blurb');
	  is ($p1->get_nick,  'Ounichar');
	  is ($p1->get_default_value, 'z');

	  # p2 targetting p1
	  my $p2 = Glib::ParamSpec->override ('over-over', $p1);
	  isa_ok ($p2, 'Glib::Param::Override');
	  # is_deeply() because paramspec is GBoxed, so no identical objects
	  is_deeply ($p2->get_redirect_target, $pbase);

	  is ($p2->get_blurb, 'pbase blurb');
	  is ($p2->get_nick,  'Ounichar');
	  is ($p2->get_default_value, 'z');
	}
}

#
# Since this is conditional on version, we don't want to overcomplicate
# the testing logic above.
#
SKIP: {
	skip "GParamSpecGType is new in glib 2.10.0", 18
		unless Glib->CHECK_VERSION (2, 10, 0);
	@params = ();

	$pspec = Glib::ParamSpec->gtype ('object', 'Object Type',
					 "Any object type",
					 Glib::Object::,
					 G_PARAM_READWRITE);
	isa_ok ($pspec, 'Glib::Param::GType');
	isa_ok ($pspec, 'Glib::ParamSpec');
	is ($pspec->get_is_a_type, 'Glib::Object');
	is ($pspec->get_value_type, 'Glib::GType');
	push @params, $pspec;

	$pspec = Glib::ParamSpec->gtype ('type', 'Any type', "Any type",
					 undef, G_PARAM_READWRITE);
	isa_ok ($pspec, 'Glib::Param::GType');
	isa_ok ($pspec, 'Glib::ParamSpec');
	is ($pspec->get_is_a_type, undef);
	is ($pspec->get_value_type, 'Glib::GType');
	push @params, $pspec;

	Glib::Type->register ('Glib::Object' => 'Baz', properties => \@params);

	my $baz = Glib::Object::new ('Baz');
	isa_ok ($baz, 'Glib::Object');
	is ($baz->get ('object'), 'Glib::Object');
	is ($baz->get ('type'), undef);

	$baz = Glib::Object::new ('Baz', object => 'Bar', type => 'Glib::ParamSpec');
	isa_ok ($baz, 'Glib::Object');
	is ($baz->get ('object'), 'Bar');
	is ($baz->get ('type'), 'Glib::ParamSpec');

	$baz->set (type => 'Bar');
	is ($baz->get ('type'), 'Bar');
	$baz->set (type => 'Glib::ParamSpec');
	is ($baz->get ('type'), 'Glib::ParamSpec');

        $baz->set (object => 'Glib::Object');
	is ($baz->get ('object'), 'Glib::Object');
        $baz->set (object => 'Glib::InitiallyUnowned');
	is ($baz->get ('object'), 'Glib::InitiallyUnowned');
}



#
# verify that NULL param specs are handled gracefully
#

my $object = Bar->new;
my $x = $object->get ('param_spec');
is ($x, undef);



#
# value_validate() and value_cmp()
#
{ my $p = Glib::ParamSpec->int ('name','nick','blurb',
                                20, 50, 25, G_PARAM_READWRITE);
  ok (! scalar ($p->value_validate('30')), "value 30 valid");
  my @a = $p->value_validate('30');
  is (@a, 2);
  ok (! $a[0], "value 30 bool no modify (array context)");
  is ($a[1], 30, "value 30 value unchanged");

  my ($modif, $newval) = $p->value_validate(70);
  ok ($modif, 'modify 70 to be in range');
  is ($newval, 50, 'clamp 70 down to be in range');
  ($modif, $newval) = $p->value_validate(-70);
  ok ($modif, 'modify -70 to be in range');
  is ($newval, 20, 'clamp -70 down to be in range');

  is ($p->values_cmp(22, 33), -1);
  is ($p->values_cmp(33, 22), 1);
  is ($p->values_cmp(22, 22), 0);
}
