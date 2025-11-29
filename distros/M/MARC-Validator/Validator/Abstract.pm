package MARC::Validator::Abstract;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime;
use Error::Pure qw(err);
use Mo::utils 0.06 qw(check_bool check_required);
use Mo::utils::Hash qw(check_hash);

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Debug mode.
	$self->{'debug'} = 0;

	# Error id definition.
	$self->{'error_id_def'} = '001';

	# Structure.
	$self->{'struct'} = {};

	# Verbose mode.
	$self->{'verbose'} = 0;

	# Process parameters.
	set_params($self, @params);

	# Check 'debug'.
	check_bool($self, 'debug');

	# Check 'error_id_def'.
	check_required($self, 'error_id_def');

	# Check 'struct'.
	check_hash($self, 'struct');

	# Check 'verbose'.
	check_bool($self, 'verbose');

	return $self;
}

# Initialization.
sub init {
	my $self = shift;

	# Common initialization.
	$self->{'struct'}->{'name'} = $self->name;
	$self->{'struct'}->{'datetime'} = DateTime->now->iso8601;

	$self->{'cb_error_id'} = sub {
		my $marc_record = shift;

		my $error_id;
		my ($field, $subfield) = $self->{'error_id_def'} =~ m/^(\d+)(.*)$/ms;
		my $field_obj = $marc_record->field($field);
		if (defined $field_obj) {
			if ($subfield) {
				$error_id = $field_obj->subfield($subfield);
			} else {
				$error_id = $field_obj->as_string;
			}
		} else {
			err 'Record id is not defined.',
				'Error ID definition', $self->{'error_id_def'},
			;
		}

		return $error_id;
	};

	# Plugin initialization.
	$self->_init;

	return;
}

# Name of plugin.
sub name {
	my $self = shift;

	err __PACKAGE__.' is abstract class,';
}

sub postprocess {
	my $self = shift;

	return;
}

# Process statistics.
sub process {
	my ($self, $marc_record) = @_;

	err __PACKAGE__.' is abstract class.';
}

sub struct {
	my $self = shift;

	return $self->{'struct'};
}

sub _init {
	my $self = shift;

	err __PACKAGE__.' is abstract class.';
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Validator::Abstract - Abstract class for MARC::Validator plugins.

=head1 SYNOPSIS

 my $obj = MARC::Validator::Abstract->new;
 $obj->init;
 my $name = $obj->name;
 my $process = $obj->process($marc_record);
 $obj->postprocess;
 my $struct_hr = $obj->struct;

=head1 DESCRIPTION

This is abstract class for L<MARC::Validator> plugins, which are used in
L<App::MARC::Validator> tool.

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Validator::Abstract->new(%params);

Constructor.

=over 8

=item * C<debug>

Debug mode.

Default value is 0.

=item * C<error_id_def>

Error ID definition in MARC field/subfield hierarchy.
For control fields is simple number, for field/subfield is something like '015a'.

Default value is '001' = control field 001.

=item * C<struct>

Structure for statistics. It could be returned by L<struct> method.

Default value is {}.

=item * C<verbose>

Verbose mode.

Default value is 0.

=back

Returns instance of object.

=head2 C<init>

 $obj->init;

Initialize plugin.

Returns undef.

=head2 C<name>

 my $name = $obj->name;

Get name of plugin.

Returns string.

=head2 C<postprocess>

 $obj->postprocess;

Postprocess after all processing items.

Returns undef.

=head2 C<process>

 $obj->proces($marc_record);

Process L<MARC::Record> instance.

Returns undef.

=head2 C<struct>

 my $struct_hr = $obj->struct;

Get output structure.

Returns reference to hash.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::check_bool():
                 Parameter 'debug' must be a bool (0/1).
                         Value: %s
                 Parameter 'verbose' must be a bool (0/1).
                         Value: %s
         Record id is not defined.
                 Error ID definition: %s

         (only in this abstract class)
         MARC::Validator::Abstract is abstract class.

=head1 EXAMPLE

=for comment filename=example_plugin.pl

 use strict;
 use warnings;

 package MARC::Validator::Plugin::Foo;
 use base qw(MARC::Validator::Abstract);

 our $VERSION = 1.01;

 sub name {
         my $self = shift;
 
         return 'foo';
 }

 sub postprocess {
         my $self = shift;

         $self->{'struct'}->{'stats'}->{'bar_stat'}
                 = $self->{'struct'}->{'stats'}->{'foo_stat'} + 1;

         return;
 }
 
 sub process {
         my ($self, $marc_record) = @_;
 
         $self->{'struct'}->{'stats'}->{'foo_stat'}++;
 
         return;
 }
 
 sub _init {
         my $self = shift;
 
         $self->{'struct'}->{'module_name'} = __PACKAGE__;
         $self->{'struct'}->{'module_version'} = $VERSION;
 
         $self->{'struct'}->{'stats'}->{'foo_stat'} = 0;
 
         return;
 }

 package main;

 use Data::Printer;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
 use MIME::Base64;

 # Content.
 my $marc_xml_example = <<'END';
 PD94bWwgdmVyc2lvbiA9ICIxLjAiIGVuY29kaW5nID0gIlVURi04Ij8+CiAgPGNvbGxlY3Rpb24g
 eG1sbnM9Imh0dHA6Ly93d3cubG9jLmdvdi9NQVJDMjEvc2xpbSIKeG1sbnM6eHNpPSJodHRwOi8v
 d3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIKeHNpOnNjaGVtYUxvY2F0aW9uPSJo
 dHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0KaHR0cDovL3d3dy5sb2MuZ292L3N0YW5kYXJk
 cy9tYXJjeG1sL3NjaGVtYS9NQVJDMjFzbGltLnhzZCI+CiAgICA8cmVjb3JkIHhtbG5zPSJodHRw
 Oi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iCnhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcv
 MjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCnhzaTpzY2hlbWFMb2NhdGlvbj0iaHR0cDovL3d3dy5s
 b2MuZ292L01BUkMyMS9zbGltCmh0dHA6Ly93d3cubG9jLmdvdi9zdGFuZGFyZHMvbWFyY3htbC9z
 Y2hlbWEvTUFSQzIxc2xpbS54c2QiPgogICAgICA8bGVhZGVyPiAgICAgbmFtIGEyMiAgICAgICAg
 NDUwMDwvbGVhZGVyPgogICAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDAxIj5jazgzMDAwNzg8L2Nv
 bnRyb2xmaWVsZD4KICAgICAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMyI+Q1ogUHJOSzwvY29udHJv
 bGZpZWxkPgogICAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDA1Ij4yMDIxMDMwOTEyMTk1MS4wPC9j
 b250cm9sZmllbGQ+CiAgICAgIDxjb250cm9sZmllbGQgdGFnPSIwMDciPnR1PC9jb250cm9sZmll
 bGQ+CiAgICAgIDxjb250cm9sZmllbGQgdGFnPSIwMDgiPjgzMDMwNHMxOTgyICAgIHhyIGEgICAg
 ICAgICB1MHwwIHwgY3plPC9jb250cm9sZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIwMTUi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5jbmIwMDAwMDAw
 OTY8L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjAy
 MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9InEiPihCcm/Fvi4p
 IDo8L3N1YmZpZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJjIj45IEvEjXM8L3N1YmZpZWxk
 PgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjAzNSIgaW5kMT0iICIg
 aW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPihPQ29MQykzOTU2MDY2NDwvc3Vi
 ZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iMDQwIiBpbmQx
 PSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+QUJBMDAxPC9zdWJmaWVs
 ZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVsZD4KICAgICAgICA8c3Vi
 ZmllbGQgY29kZT0iZCI+QUJBMDAxPC9zdWJmaWVsZD4KICAgICAgPC9kYXRhZmllbGQ+CiAgICAg
 IDxkYXRhZmllbGQgdGFnPSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICAgIDxzdWJmaWVs
 ZCBjb2RlPSJhIj4zNTIvMzUzPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iMiI+
 dW5kZWY8L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9
 IjA4MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPjMzOC40
 Njwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4K
 ICAgICAgPC9kYXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIxMDAiIGluZDE9IjEiIGlu
 ZDI9IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5HYWJyaWVsLCBWbGFkaXNsYXY8L3N1
 YmZpZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSI3Ij5temsyMDE0ODUyNzIzPC9zdWJmaWVs
 ZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iNCI+YXV0PC9zdWJmaWVsZD4KICAgICAgPC9kYXRh
 ZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIyNDUiIGluZDE9IjEiIGluZDI9IjAiPgogICAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5TbHXFvmJ5IHYgc3lzdMOpbXUgbsOhcm9kbsOtY2ggdsO9
 Ym9yxa8gOjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPnZ5YnJhbsOpIGth
 cGl0b2x5IDogdXLEjWVubyBwcm8gcG9zbC4gZmFrLiBvYmNob2Ruw60sIG9ib3IgRWtvbm9taWth
 IHNsdcW+ZWIgYSBjZXN0b3Zuw61obyBydWNodSAvPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmll
 bGQgY29kZT0iYyI+VmxhZGlzbGF2IEdhYnJpZWwsIExhZGlzbGF2IFphcGFkbG88L3N1YmZpZWxk
 PgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjI1MCIgaW5kMT0iICIg
 aW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPjEuIHZ5ZC48L3N1YmZpZWxkPgog
 ICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjI2MCIgaW5kMT0iICIgaW5k
 Mj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPlByYWhhIDo8L3N1YmZpZWxkPgogICAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5TUE4sPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQg
 Y29kZT0iYyI+MTk4Mjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImUiPihQxZnD
 rWJyYW0gOjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImYiPlRaIDY2KTwvc3Vi
 ZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iMzAwIiBpbmQx
 PSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+MTkyIHMuIDo8L3N1YmZp
 ZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5zY2jDqW1hdGEgOzwvc3ViZmllbGQ+CiAg
 ICAgICAgPHN1YmZpZWxkIGNvZGU9ImMiPjMwIGNtPC9zdWJmaWVsZD4KICAgICAgPC9kYXRhZmll
 bGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICAg
 IDxzdWJmaWVsZCBjb2RlPSJhIj5Sb3ptbi48L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4K
 ICAgICAgPGRhdGFmaWVsZCB0YWc9IjUwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1
 YmZpZWxkIGNvZGU9ImEiPjMwMCB2w710Ljwvc3ViZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgog
 ICAgICA8ZGF0YWZpZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3Vi
 ZmllbGQgY29kZT0iYSI+S2FwLiA0LiBuYXBzLiBSxa/FvmVuYSBEdWRvdsOhLCBrYXAuIDguIGpl
 IHNlc3QuIHogcMWZw61zcMSbdmvFryByxa96LiBhdXRvcsWvPC9zdWJmaWVsZD4KICAgICAgPC9k
 YXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI1NTAiIGluZDE9IiAiIGluZDI9IiAiPgog
 ICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5WeWRhdmF0ZWw6IFbFoEUgdiBQcmF6ZTwvc3ViZmll
 bGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iNjU1IiBpbmQxPSIg
 IiBpbmQyPSI3Ij4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+dcSNZWJuaWNlIHZ5c29rw71j
 aCDFoWtvbDwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjciPmZkMTMzNzcyPC9z
 dWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iMiI+Y3plbmFzPC9zdWJmaWVsZD4KICAg
 ICAgPC9kYXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI3MDAiIGluZDE9IjEiIGluZDI9
 IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5aYXBhZGxvLCBMYWRpc2xhdjwvc3ViZmll
 bGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjQiPmF1dDwvc3ViZmllbGQ+CiAgICAgIDwvZGF0
 YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iNzEwIiBpbmQxPSIyIiBpbmQyPSIgIj4KICAg
 ICAgICA8c3ViZmllbGQgY29kZT0iYSI+Vnlzb2vDoSDFoWtvbGEgZWtvbm9taWNrw6EgdiBQcmF6
 ZTwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjciPmtuMjAwMTA3MDk0MDM8L3N1
 YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9Ijk5OCIgaW5k
 MT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPmh0dHA6Ly9hbGVwaC5u
 a3AuY3ovRi8/ZnVuYz1kaXJlY3QmYW1wO2RvY19udW1iZXI9MDAwMDAwMDk2JmFtcDtsb2NhbF9i
 YXNlPUNOQjwvc3ViZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgPC9yZWNvcmQ+Cgo8cmVj
 b3JkIHhtbG5zPSJodHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iCnhtbG5zOnhzaT0iaHR0
 cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCnhzaTpzY2hlbWFMb2NhdGlv
 bj0iaHR0cDovL3d3dy5sb2MuZ292L01BUkMyMS9zbGltCmh0dHA6Ly93d3cubG9jLmdvdi9zdGFu
 ZGFyZHMvbWFyY3htbC9zY2hlbWEvTUFSQzIxc2xpbS54c2QiPgogIDxsZWFkZXI+ICAgICBuYW0g
 YTIyICAgICAgICA0NTAwPC9sZWFkZXI+CiAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMSI+Y2s4MzAw
 MDgwPC9jb250cm9sZmllbGQ+CiAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMyI+Q1ogUHJOSzwvY29u
 dHJvbGZpZWxkPgogIDxjb250cm9sZmllbGQgdGFnPSIwMDUiPjIwMDUwNTE3MDk0MjEyLjA8L2Nv
 bnRyb2xmaWVsZD4KICA8Y29udHJvbGZpZWxkIHRhZz0iMDA3Ij50dTwvY29udHJvbGZpZWxkPgog
 IDxjb250cm9sZmllbGQgdGFnPSIwMDgiPjgzMDMxNnMxOTgzICAgIHhyICAgICAgICAgICB1MHww
 ICAgY3plPC9jb250cm9sZmllbGQ+CiAgPGRhdGFmaWVsZCB0YWc9IjAxNSIgaW5kMT0iICIgaW5k
 Mj0iICI+CiAgICA8c3ViZmllbGQgY29kZT0iYSI+Y25iMDAwMDAwMDk4PC9zdWJmaWVsZD4KICA8
 L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMDIwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAg
 IDxzdWJmaWVsZCBjb2RlPSJxIj4oQnJvxb4uKSA6PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBj
 b2RlPSJjIj4zMCBLxI1zPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRh
 Zz0iMDM1IiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj4oT0NvTEMp
 Mzk1NjA2ODg8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSIwNDAi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPkFCQTAwMTwvc3ViZmll
 bGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBj
 b2RlPSJkIj5BQkEwMDE8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFn
 PSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPjMzOS45MjM8
 L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4KICA8L2Rh
 dGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMDgwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxz
 dWJmaWVsZCBjb2RlPSJhIj4zMzguNDU8L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9IjIi
 PnVuZGVmPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMTAwIiBp
 bmQxPSIxIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5WbGFkeWthLCBKb3NlZjwv
 c3ViZmllbGQ+CiAgICA8c3ViZmllbGQgY29kZT0iNyI+angyMDA1MDYyODAzNjwvc3ViZmllbGQ+
 CiAgICA8c3ViZmllbGQgY29kZT0iNCI+YXV0PC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8
 ZGF0YWZpZWxkIHRhZz0iMjQ1IiBpbmQxPSIxIiBpbmQyPSIwIj4KICAgIDxzdWJmaWVsZCBjb2Rl
 PSJhIj5Ww712b2ogYSBwbMOhbnkgcm96dm9qZSBwcsWvbXlzbHUgZXZyb3Bza8O9Y2ggemVtw60g
 UlZIUCAxOTc2LTE5ODUgLzwvc3ViZmllbGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYyI+dnlwcmFj
 LiBKb3NlZiBWbGFkeWthPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRh
 Zz0iMjYwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5QcmFoYSA6
 PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBjb2RlPSJiIj7DmlZURUksPC9zdWJmaWVsZD4KICAg
 IDxzdWJmaWVsZCBjb2RlPSJjIj4xOTgzPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0
 YWZpZWxkIHRhZz0iMzAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJh
 Ij41NSBzLiA6PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBjb2RlPSJiIj50Yi4gOzwvc3ViZmll
 bGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYyI+MzAgY208L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxk
 PgogIDxkYXRhZmllbGQgdGFnPSI0OTAiIGluZDE9IjEiIGluZDI9IiAiPgogICAgPHN1YmZpZWxk
 IGNvZGU9ImEiPlB1Ymxpa2FjZSBTSVZPIDs8L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9
 InYiPjE4OTQ8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSI1MDAi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPlDFmWVobC4gbGl0PC9z
 dWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBp
 bmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Sb3ptbi48L3N1YmZpZWxkPgogIDwvZGF0
 YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1
 YmZpZWxkIGNvZGU9ImEiPlBvem4uPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZp
 ZWxkIHRhZz0iODMwIiBpbmQxPSIgIiBpbmQyPSIwIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Q
 dWJsaWthY2UgU0lWTzwvc3ViZmllbGQ+CiAgPC9kYXRhZmllbGQ+CiAgPGRhdGFmaWVsZCB0YWc9
 Ijk5OCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICA8c3ViZmllbGQgY29kZT0iYSI+aHR0cDovL2Fs
 ZXBoLm5rcC5jei9GLz9mdW5jPWRpcmVjdCZhbXA7ZG9jX251bWJlcj0wMDAwMDAwOTgmYW1wO2xv
 Y2FsX2Jhc2U9Q05CPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KPC9yZWNvcmQ+Cgo8L2NvbGxl
 Y3Rpb24+Cg==
 END

 my ($temp_file, $temp_file_fh) = tempfile();

 barf($temp_file_fh, decode_base64($marc_xml_example));

 my $marc_file = MARC::File::XML->in($temp_file);
 my $marc_record = $marc_file->next;

 my $obj = MARC::Validator::Plugin::Foo->new;
 $obj->init;
 my $process = $obj->process($marc_record);
 $obj->postprocess;

 my $name = $obj->name;
 print "Name: $name\n";

 my $struct_hr = $obj->struct;
 print "Output structure:\n";
 p $struct_hr;

 unlink $temp_file;

 # Output:
 # Name: foo
 # Output structure:
 # {
 #     datetime         "2025-06-20T17:13:25" (dualvar: 2025),
 #     module_name      "MARC::Validator::Plugin::Foo",
 #     module_version   1.01,
 #     name             "foo",
 #     stats            {
 #         bar_stat   2,
 #         foo_stat   1
 #     }
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<DateTime>,
L<Error::Pure>,
L<Mo::utils>,
L<Mo::utils::Hash>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Validator>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.08

=cut
