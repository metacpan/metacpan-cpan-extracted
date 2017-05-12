package Log::Handler::Plugin::DBI::CreateTable;

use strict;
use warnings;

use Carp;

use DBIx::Admin::CreateTable;
use DBIx::Connector;

use Hash::FieldHash ':all';

fieldhash my %config      => 'config';
fieldhash my %connector   => 'connector';
fieldhash my %creator     => 'creator';
fieldhash my %engine      => 'engine';
fieldhash my %time_option => 'time_option';

our $VERSION = '1.02';

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = ${$self -> config}{table_name} || 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($type)        = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(255) not null,
message $type not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_log_table.

# --------------------------------------------------

sub drop_log_table
{
	my($self)       = @_;
	my($table_name) = ${$self -> config}{table_name} || 'log';

	$self -> creator -> drop_table($table_name);

	if ($table_name ne 'log')
	{
		$self -> report($table_name, 'dropped');
	}

} # End of drop_log_table.

# --------------------------------------------------

sub _init
{
	my($self, $arg)    = @_;
	$$arg{config}      ||= '';
	$$arg{connector}   = '';
	$$arg{creator}     = '';
	$$arg{engine}      = '';
	$$arg{time_option} = '';
	$self              = from_hash($self, $arg);

	croak "Error: config hashref must be passed to new()\n" if (! $self -> config || (ref $self -> config ne 'HASH') );

	my($config) = $self -> config;
	my($attr)   = {AutoCommit => $$config{AutoCommit}, RaiseError => $$config{RaiseError} };

	if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode})
	{
		$$attr{sqlite_unicode} = 1;
	}

	$self -> connector
		(
		 DBIx::Connector -> new($$config{dsn}, $$config{username}, $$config{password}, $attr)
		);

	if ($$config{dsn} =~ /SQLite/i)
	{
		$self -> connector -> dbh -> do('PRAGMA foreign_keys = ON');
	}

	$self -> creator
		(
		 DBIx::Admin::CreateTable -> new
		 (
		  dbh     => $self -> connector -> dbh,
		  verbose => 0,
		 )
		);

	$self -> engine
		(
		 $self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
		);

	$self -> time_option
		(
		 $self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
		);

	return $self;

} # End of _init.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

} # End of new.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		croak "Error: Table '$table_name' $result. \n";
	}
	else
	{
		print "Created table '$table_name'. \n";
	}

} # End of report.

# --------------------------------------------------

1;
=head1 NAME

Log::Handler::Plugin::DBI::CreateTable - A helper for Log::Hander::Output::DBI to create your 'log' table

=head1 Synopsis

See scripts/create.table.pl and scripts/drop.table.pl.

The programs use these methods: L</create_log_table()> and L</drop_log_table()>.

=head1 Description

This module is a customised wrapper for L<DBIx::Admin::CreateTable>, which means it handles a range of database server SQL formats for creating tables and the corresponding sequences.

Likewise for dropping tables and sequences.

The table name defaults to 'log', and it has the correct structure to be compatible with L<Log::Handler::Output::DBI>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Log::Handler::Plugin::DBI> as you would for any C<Perl> module:

Run:

	cpanm Log::Handler::Plugin::DBI

or run:

	sudo cpan Log::Handler::Plugin::DBI

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($app) = Log::Handler::Plugin::DBI::CreateTable -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Log::Handler::Plugin::DBI::CreateTable>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</config([$hashref])>]):

=over 4

=item o config => $hashref

The keys and values of this hashref are documented below under L</config([$hashref])>.

=back

=head1 Methods

=head2 config([$hashref])

Gets or sets the hashref of options used by the other methods.

Here, the [] indicate an optional parameter.

The hashref takes these (key => value) pairs:

=over 4

=item o dsn => $string

A typical $string might be 'dbi:SQLite:dbname=/tmp/logger.test.sqlite'.

=item o username => $string

Supply your database server username, or leave empty for databases such as SQLite.

=item o password => $string

Supply your database server password, or leave empty for databases such as SQLite.

=item o table_name => $string

Supply your log table name, or let it default to 'log'.

=back

'config' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 create_log_table()

Creates the table named in the config hashref passed in to new.

=head2 drop_log_table()

Drops the table named in the config hashref passed in to new.

=head1 FAQ

=head2 When would I use this module?

You use scripts/*.pl in preparation for using any class or program which you want to log to a database.

Having create the 'log' table, then you write code using L<Log::Handler::Plugin::DBI>.

For sample code, study L<CGI::Snapp::Demo::Four>.

=head2 What is the expected structure of the 'log' table?

In pseudo-code:

	id primary key + (db_vendor-dependent stuff)
	level varchar(255) not null,
	message not null + (db_vendor eq 'ORACLE' ? 'long' : 'text')
	timestamp timestamp not null default current_timestamp +
	(db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : '')

Also, if you're using MySQL, you might want to set the engine=innodb option.

See scripts/create.table.pl and scripts/drop.table.pl for an easy way to do all this.

=head2 Can this module be used in any module?

Sure, but it's I<not> a plugin like L<Log::Handler::Plugin::DBI> is.

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

L<CGI::Snapp::Demo::One> - A template-free demo of CGI::Snapp using just 1 run mode

L<CGI::Snapp::Demo::Two> - A template-free demo of CGI::Snapp using N run modes

L<CGI::Snapp::Demo::Three> - A template-free demo of CGI::Snapp using the forward() method

L<CGI::Snapp::Demo::Four> - A template-free demo of CGI::Snapp using Log::Handler::Plugin::DBI

L<CGI::Snapp::Demo::Four::Wrapper> - A wrapper around CGI::Snapp::Demo::Four, to simplify using Log::Handler::Plugin::DBI

L<Config::Plugin::Tiny> - A plugin which uses Config::Tiny

L<Config::Plugin::TinyManifold> - A plugin which uses Config::Tiny with 1 of N sections

L<Data::Session> - Persistent session data management

L<Log::Handler::Plugin::DBI> - A plugin for Log::Handler using Log::Hander::Output::DBI

L<Log::Handler::Plugin::DBI::CreateTable> - A helper for Log::Hander::Output::DBI to create your 'log' table

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Credits

Please read L<https://metacpan.org/module/CGI::Application::Plugin::Config::Simple#AUTHOR>, since a lot of the ideas for this module were copied from
L<CGI::Application::Plugin::Config::Simple>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log::Handler::Plugin::DBI>.

=head1 Author

L<Log::Handler::Plugin::DBI::CreateTable> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
