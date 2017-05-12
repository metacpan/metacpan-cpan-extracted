package Log::Handler::Plugin::DBI;

use strict;
use warnings;

use Log::Handler::Output::DBI;

use vars qw(@EXPORT @ISA);

@EXPORT = (qw/configure_logger log log_object/);
@ISA    = ('Exporter');

my($object);

our $VERSION = '1.02';

# -----------------------------------------------

sub configure_logger
{
	my($self, $config) = @_;
	$object = Log::Handler::Output::DBI -> new
		(
		 columns     => [qw/level message/],
		 data_source => $$config{dsn},
		 password    => $$config{password},
		 persistent  => 1,
		 table       => $$config{table_name} || 'log',
		 user        => $$config{username},
		 values      => [qw/%level %message/],
		);

}	# End of configure_logger.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$object -> log(level => $level, message => $s || '');

} # End of log.

# -----------------------------------------------

sub log_object
{
	my($self) = @_;

	return $object;

} # End of log_object.

# --------------------------------------------------

1;

=head1 NAME

Log::Handler::Plugin::DBI - A plugin for Log::Handler using Log::Hander::Output::DBI

=head1 Synopsis

Firstly, use your config file to connect to the db and create the 'log' table.

Then:

	package My::App;

	use strict;
	use warnings;

	use Config::Plugin::Tiny; # For config_tiny().

	use File::Spec;

	use Log::Handler::Plugin::DBI; # For configure_logger() and log().

	# ------------------------------------------------

	sub marine
	{
		my($self)   = @_;
		my($config) = $self -> config_tiny(File::Spec -> catfile('some', 'dir', 'config.tiny.ini') );

		$self -> configure_logger($$config{logger});

		$self -> log(debug => 'Hi from sub marine()');

	} # End of marine.

	# --------------------------------------------------

	1;

t/config.logger.ini is used in the test file t/test.t, and also ships with the L<CGI::Snapp::Demo::Four> distro.

=head1 Description

When you 'use' this module (as in the Synopsis), it automatically imports into your class several methods. See L</Methods> for details.

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

This module does not have, and does not need, a constructor.

=head1 Methods

=head2 configure_logger($hashref)

Configures the internal log object with these parameters from $hashref:

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

=head2 log($level => $message)

Logs $message at $level.

See L<Log::Handler#LOG-LEVELS> and L<Log::Handler::Levels>.

=head2 log_object()

Returns the internal log object, for those cases when you want to pass it to some other class.

See the L<CGI::Snapp::Demo::Four> distro, which contains httpd/cgi-bin/cgi.snapp.demo.four.cgi, which uses L<CGI::Snapp::Demo::Four::Wrapper>.

The latter passes this log object to L<CGI::Snapp>'s logger() method, to demonstrate logging a L<CGI> script's method call sequence to a database table.

=head1 FAQ

=head2 When would I use this module?

In your sub-class of L<CGI::Snapp> for example, or anywhere else you want to log to a database.

See L<Log::Handler::Plugin::DBI::CreateTable> for help creating a 'log' table.

For sample code, study L<CGI::Snapp::Demo::Four>.

=head2 What is the expected structure of the 'log' table?

See the L<Log::Handler::Plugin::DBI::CreateTable/FAQ>. In pseudo-code:

	id primary key + (db_vendor-dependent stuff)
	level varchar(255) not null,
	message not null + (db_vendor eq 'ORACLE' ? 'long' : 'text')
	timestamp timestamp not null default current_timestamp +
	(db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : '')

Also, if you're using MySQL, you might want to set the engine=innodb option.

See scripts/create.table.pl and scripts/drop.table.pl for an easy way to do all this.

=head2 Can this module be used in any module?

Yes. See t/test.t, which passes undef as the first parameter to each method, because there is no $self available.

Alternately, if you 'use' this module within any other module, calling $self -> log() will work.

It's used in L<CGI::Snapp::Demo::Four::Wrapper>, which inherits from L<CGI::Snapp::Demo::Four>, which inherits from L<CGI::Snapp>. So, even though L<CGI::Snapp> has its own
log() method, the one imported from the current module overrides that one.

=head2 Why can't I call $log_object -> info($message) etc as with Log::Handler?

Because it's I<not> true that an object of type L<Log::Handler::Output::DBI> (the underlying object here) 'isa' L<Log::Handler>.

=head2 Why don't you 'use Exporter;'?

It is not needed; it would be for documentation only.

For the record, Exporter V 5.567 ships with Perl 5.8.0. That's what I had in Build.PL and Makefile.PL until I tested the fact I can omit it.

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

L<Log::Handler::Plugin::DBI> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
