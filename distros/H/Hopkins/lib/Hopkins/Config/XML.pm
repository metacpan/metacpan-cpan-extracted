package Hopkins::Config::XML;

use strict;
use warnings;

=head1 NAME

Hopkins::Config::XML - hopkins configuration via XML

=head1 DESCRIPTION

Hopkins::Config encapsulates all of the busywork associated
in the reading and post-processing of the XML configuration
in addition to providing a simple interface to accessing
values when required.

Hopkins::Config::XML will validate your configuration using
XML Schema via XML::LibXML.  for complete information on the
schema, see the XML Schema document in Hopkins::Config::XML.

=head1 EXAMPLE

 <?xml version="1.0" encoding="utf-8"?>
 <hopkins>
     <state>
         <root>/var/lib/hopkins</root>
     </state>

     <plugin name="HMI">
         <port>8088</port>
     </plugin>

     <plugin name="RPC">
         <port>8080</port>
     </plugin>

     <database>
         <dsn>dbi:mysql:database=hopkins;host=localhost</dsn>
         <user>root</user>
         <pass></pass>
         <options>
             <option name="AutoCommit" value="1" />
             <option name="RaiseError" value="1" />
             <option name="mysql_auto_reconnect" value="1" />
             <option name="quote_char" value="" />
             <option name="name_sep" value="." />
         </options>
     </database>

     <queue name="general">
         <concurrency>16</concurrency>
     </queue>

     <queue name="serial" onerror="halt">
         <concurrency>1</concurrency>
     </queue>

     <task name="Sum" onerror="disable">
         <class>MyApp::Job::Sum</class>
         <queue>general</queue>
     </task>

     <task name="Report" onerror="disable" stack="no">
         <class>MyApp::Job::Report</class>
         <queue>serial</queue>
         <schedule>
             <cron>0 22 * 1-11 *</cron>
             <cron>0 */4 * 12 * *</cron>
         </schedule>
         <options>
             <option name="source" value="production" />
             <option name="destination" value="reports@domain.com" />
         </options>
         <chain task="Sum">
             <options>
                 <option name="categories" value="Books" />
                 <option name="categories" value="CDs" />
             </options>
         </chain>
     </task>
 </hopkins>

=cut

use DateTime::Set;
use DateTime::Event::MultiCron;
use File::Monitor;
use Path::Class::Dir;
use XML::Simple;
use XML::LibXML;
use YAML;

use Hopkins::Config::Status;
use Hopkins::Task;

use Class::Accessor::Fast;

use base qw(Class::Accessor::Fast Hopkins::Config);

__PACKAGE__->mk_accessors(qw(config file monitor xml xsd));

sub new
{
	my $self = shift->SUPER::new(@_);

	$self->monitor(new File::Monitor);
	$self->monitor->watch($self->file);

	$self->xml(new XML::LibXML);
	$self->xsd(new XML::LibXML::Schema string => join '', <DATA>);

	return $self;
}

sub load
{
	my $self = shift;

	Hopkins->log_debug('loading XML configuration file');

	my $status = new Hopkins::Config::Status;
	my $config = $self->parse($self->file, $status);

	# if we have an existing configuration, then we will be
	# fine.  we won't overwrite the existing configuration
	# with a broken one, so no error condition will exist.

	$status->ok($self->config ? 1 : 0);

	if (not defined $config) {
		$status->failed(1);
		$status->parsed(0);

		return $status;
	}

	$status->parsed(1);

	if (my $root = $config->{state}->{root}) {
		$config->{state}->{root} = new Path::Class::Dir $root;
		eval { $config->{state}->{root}->mkpath(0, 0700) };
		if (my $err = $@) {
			Hopkins->log_error("unable to create $root: $@");
			$status->failed(1);
		}
	} else {
		Hopkins->log_error('no root directory defined for state information');
		$status->failed(1)
	}

	# process task configuration data structures.  each task
	# definition is inflated into a Hopkins::Task instance.
	# schedules are inflated into DateTime::Set objects via
	# DateTime::Event::MultiCron.  other forms of schedule
	# definitions may be supported in the future, so long as
	# they grok DateTime::Set.

	foreach my $name (keys %{ $config->{task} }) {
		my $href = $config->{task}->{$name};

		# collapse the damn task queue from the ForceArray
		# and interpret the value of the enabled attribute

		$href->{queue}		= $href->{queue}->[0] if ref $href->{queue};
		$href->{enabled}	= lc($href->{enabled}) eq 'no' ? 0 : 1;

		my $task = new Hopkins::Task { name => $name, %$href };

		if (not $task->queue) {
			Hopkins->log_error("task $name not assigned to a queue");
			$status->failed(1);
		}

		if (not $task->class || $task->cmd) {
			Hopkins->log_error("task $name lacks a class or command line");
			$status->failed(1);
		}

		if ($task->class and $task->cmd) {
			Hopkins->log_error("task $name using mutually exclusive class/cmd");
			$status->failed(1);
		}

		$task->stack(1) if $task->stack and $task->stack eq 'no';
		$task->options([ $self->_setup_options($status, $task->options) ]);
		$task->schedule($self->_setup_schedule($status, $task));

		$config->{task}->{$name} = $task;
	}

	$self->_setup_chains($config, $status, values %{ $config->{task} });

	# check to see if the new configuration includes a
	# modified database configuration.

	if (my $href = $self->config && $self->config->{database}) {
		my @a = map { $href->{$_} || '' } qw(dsn user pass options);
		my @b = map { $config->{database}->{$_} } qw(dsn user pass options);

		# replace the options hashref (very last element in
		# the array) with a flattened representation

		splice @a, -1, 1, keys %{ $a[-1] }, values %{ $a[-1] };
		splice @b, -1, 1, keys %{ $b[-1] }, values %{ $b[-1] };

		# temporarily change the list separator character
		# (default 0x20, a space) to the subscript separator
		# character (default 0x1C) for a precise comparison
		# of the two configurations

		local $" = $;;

		$status->store_modified("@a" ne "@b");
	}

	if (not $status->failed) {
		$self->config($config);
		$status->updated(1);
		$status->ok(1);
	}

	return $status;
}

sub _setup_chains
{
	my $self	= shift;
	my $config	= shift;
	my $status	= shift;

	while (my $task = shift) {
		my @chain;

		next if not defined $task->chain;

		foreach my $href (@{ $task->chain }) {
			my $name = $href->{task};
			my $next = $config->{task}->{$name};

			if (not defined $next) {
				Hopkins->log_error("chained task $name for " . $task->name . " not found");
				$status->failed(1);
			}

			my $task = new Hopkins::Task $next;

			$task->options($href->{options});
			$task->chain($href->{chain});
			$task->schedule(undef);

			push @chain, $task;
		}

		$self->_setup_chains($config, $status, @chain);

		$task->chain(\@chain);
	}
}

sub _setup_options
{
	my $self	= shift;
	my $status	= shift;
	my $options	= shift || {};

	return map { $self->_setup_option($_ => $options->{$_}) } keys %$options;
}

sub _setup_option
{
	my $self	= shift;
	my $name	= shift;
	my $attrs	= shift;

	$attrs = { value => $attrs } if not ref $attrs;

	my $choices	= delete $attrs->{choices};
	my $option	= new Hopkins::TaskOption { name => $name, %$attrs };

	$option->choices(new Hopkins::TaskOptionChoices $choices) if $choices;

	return $option;
}

sub _setup_schedule
{
	my $self	= shift;
	my $status	= shift;
	my $task	= shift;
	my $ref		= $task->{schedule};

	return undef if not ref $ref eq 'HASH';

	my $superset = DateTime::Set->empty_set;

	if (my $aref = $ref->{cron}) {
		my $set = eval { DateTime::Event::MultiCron->from_multicron(@$aref) };

		if (my $err = $@) {
			Hopkins->log_error('unable to setup schedule for ' . $task->name . ': ' . $err);
			$status->failed(1);
			$status->errmsg($err);
		} else {
			$superset = $superset->union($set);
		}
	}

	return $superset;
}

sub parse
{
	my $self	= shift;
	my $file	= shift;
	my $status	= shift;

	eval { $self->xsd->validate($self->xml->parse_file($file)) };

	if (my $err = $@) {
		$status->errmsg($err);

		return undef;
	}

	my %xmlsopts =
	(
		ValueAttr		=> [ 'value' ],
		GroupTags		=> { options => 'option' },
		SuppressEmpty	=> '',
		ForceArray		=> [ 'plugin', 'task', 'chain', 'option', 'cron' ],
		ContentKey		=> '-value',
		ValueAttr		=> { option => 'value' },
		KeyAttr			=>
		{
			plugin	=> 'name',
			option	=> 'name',
			queue	=> 'name',
			task	=> 'name'
		}
	);

	my $xs	= new XML::Simple %xmlsopts;
	my $ref	= eval { $xs->XMLin($file) };

	if (my $err = $@) {
		$status->errmsg($err);

		return undef;
	}

	Hopkins->log_debug(Dump $ref);

	return $ref;
}

sub scan
{
	my $self = shift;

	return scalar $self->monitor->scan;
}

sub get_queue_names
{
	my $self	= shift;
	my $config	= $self->config || {};

	return $config->{queue} ? keys %{ $config->{queue} } : ();
}

sub get_task_names
{
	my $self	= shift;
	my $config	= $self->config || {};

	return $config->{task} ? keys %{ $config->{task} } : ();
}

sub get_task_info
{
	my $self = shift;
	my $task = shift;

	return $self->config->{task}->{$task};
}

sub get_queue_info
{
	my $self = shift;
	my $name = shift;

	return { name => $name, %{ $self->config->{queue}->{$name} } };
}

sub get_plugin_names
{
	my $self = shift;

	return keys %{ $self->config->{plugin} };
}

sub get_plugin_info
{
	my $self = shift;
	my $name = shift;

	return $self->config->{plugin}->{$name};
}

sub has_plugin
{
	my $self = shift;
	my $name = shift;

	return exists $self->config->{plugin}->{$name} ? 1 : 0;
}

sub fetch
{
	my $self = shift;
	my $path = shift;

	$path =~ s/^\/+//;

	my $ref = $self->config;

	foreach my $spec (split '/', $path) {
		for (ref($ref)) {
			/ARRAY/	and do { $ref = $ref->[$spec] }, next;
			/HASH/	and do { $ref = $ref->{$spec} }, next;

			$ref = undef;
		}
	}

	return $ref;
}

sub loaded
{
	my $self = shift;

	return $self->config ? 1 : 0;
}

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<xs:schema elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xs:element name="hopkins" type="hopkins" />

	<xs:complexType name="hopkins">
		<xs:choice minOccurs="0" maxOccurs="unbounded">
			<xs:element name="plugin" type="plugin" />
			<xs:element name="database" type="database" />
			<xs:element name="queue" type="queue" />
			<xs:element name="task" type="task" />
			<xs:element name="state" type="state" />
		</xs:choice>
	</xs:complexType>

	<xs:complexType name="state">
		<xs:sequence>
			<xs:element name="root" type="xs:string" />
		</xs:sequence>
	</xs:complexType>

	<xs:complexType name="plugin">
		<xs:sequence>
			<xs:any minOccurs="0" maxOccurs="unbounded" processContents="skip" />
		</xs:sequence>
		<xs:attribute name="name" type="xs:string" />
	</xs:complexType>

	<xs:complexType name="database">
		<xs:all>
			<xs:element name="dsn" />
			<xs:element name="user" />
			<xs:element name="pass" />
			<xs:element name="options" type="dboptions" minOccurs="0" />
		</xs:all>
	</xs:complexType>

	<xs:complexType name="dboptions">
		<xs:sequence>
			<xs:element name="option" maxOccurs="unbounded" />
		</xs:sequence>
	</xs:complexType>

	<xs:complexType name="options">
		<xs:sequence>
			<xs:element name="option" type="option" maxOccurs="unbounded" />
		</xs:sequence>
	</xs:complexType>

	<xs:complexType name="option">
		<xs:all>
			<xs:element name="choices" type="choices" minOccurs="0" />
		</xs:all>

		<xs:attribute name="name" type="xs:string" />
		<xs:attribute name="value" type="xs:string" />
		<xs:attribute name="type">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="bool" />
					<xs:enumeration value="text" />
					<xs:enumeration value="combo" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
	</xs:complexType>

	<xs:complexType name="choices">
		<xs:sequence>
			<xs:element name="choice" minOccurs="0" maxOccurs="unbounded" />
		</xs:sequence>

		<xs:attribute name="type">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="json" />
					<xs:enumeration value="xml" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="src" type="xs:string" />
		<xs:attribute name="root" type="xs:string" />
		<xs:attribute name="name" type="xs:string" />
		<xs:attribute name="value" type="xs:string" />
	</xs:complexType>

	<xs:complexType name="queue">
		<xs:sequence>
			<xs:element name="concurrency" type="xs:integer" />
		</xs:sequence>

		<xs:attribute name="name" type="xs:string" />
		<xs:attribute name="onerror">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="halt" />
					<xs:enumeration value="freeze" />
					<xs:enumeration value="shutdown" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
	</xs:complexType>

	<xs:complexType name="task">
		<xs:all>
			<xs:element name="cmd" type="xs:string" minOccurs="0" />
			<xs:element name="class" type="xs:string" minOccurs="0" />
			<xs:element name="queue" type="xs:string" />
			<xs:element name="schedule" type="schedule" minOccurs="0" />
			<xs:element name="options" type="options" minOccurs="0" />
			<xs:element name="chain" type="chain" minOccurs="0" />
		</xs:all>

		<xs:attribute name="name" type="xs:string" />
		<xs:attribute name="run">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="serial" />
					<xs:enumeration value="parallel" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="enabled">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="yes" />
					<xs:enumeration value="no" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="stack">
			<xs:simpleType>
				<xs:union>
					<xs:simpleType>
						<xs:restriction base="xs:string">
							<xs:enumeration value="yes" />
							<xs:enumeration value="no" />
						</xs:restriction>
					</xs:simpleType>
					<xs:simpleType>
						<xs:restriction base="xs:integer">
							<xs:minInclusive value="-1" />
						</xs:restriction>
					</xs:simpleType>
				</xs:union>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="onerror">
			<xs:simpleType>
				<xs:restriction base="xs:string">
					<xs:enumeration value="disable" />
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
	</xs:complexType>

	<xs:complexType name="schedule">
		<xs:sequence>
			<xs:element name="cron" type="xs:string" maxOccurs="unbounded" />
		</xs:sequence>
	</xs:complexType>

	<xs:complexType name="chain">
		<xs:all>
			<xs:element name="options" type="options" minOccurs="0" />
			<xs:element name="chain" type="chain" minOccurs="0" />
		</xs:all>

		<xs:attribute name="task" type="xs:string" />
	</xs:complexType>
</xs:schema>
