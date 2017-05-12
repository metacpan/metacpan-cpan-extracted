package Log::Dispatch::DBI;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

use Log::Dispatch 2.00;
use base qw(Log::Dispatch::Output);

use DBI;

sub new {
    my($proto, %params) = @_;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;
    $self->_basic_init(%params);
    $self->_init(%params);

    return $self;
}

sub _init {
    my $self = shift;
    my %params = @_;

    # set parameters
    if ($params{dbh}) {
	$self->{dbh} = $params{dbh};
    } else {
	$self->{dbh} = DBI->connect(@params{qw(datasource username password)})
	    or die $DBI::errstr;
	$self->{_mine} = 1;
    }

    $self->{table} = $params{table} || 'log';
    $self->{sth} = $self->create_statement;
}

sub create_statement {
    my $self = shift;
    return $self->{dbh}->prepare(<<"SQL");
INSERT INTO $self->{table} (level, message) VALUES (?, ?)
SQL
    ;
}

sub log_message {
    my $self = shift;
    my %params = @_;
    $self->{sth}->execute(@params{qw(level message)});
}

sub DESTROY {
    my $self = shift;
    if ($self->{_mine} && $self->{dbh}) {
	$self->{dbh}->disconnect;
    }
}

1;
__END__

=head1 NAME

Log::Dispatch::DBI - Class for logging to database via DBI interface

=head1 SYNOPSIS

  use Log::Dispatch::DBI;

  my $log = Log::Dispatch::DBI->new(
      name       => 'dbi',
      min_level  => 'info',
      datasource => 'dbi:mysql:log',
      username   => 'user',
      password   => 'password',
      table      => 'logging',
  );

  # Or, if your handle is alreaady connected
  $log = Log::Dispatch::DBI->new(
      name => 'dbi',
      min_level => 'info',
      dbh  => $dbh,
  );

  $log->log(level => 'emergency', messsage => 'something BAD happened');

=head1 DESCRIPTION

Log::Dispatch::DBI is a subclass of Log::Dispatch::Output, which
inserts logging output into relational database using DBI interface.

=head1 METHODS

=over 4

=item new

  $log = Log::Dispatch::DBI->new(%params);

This method takes a hash of parameters. The following options are valid:

=item -- name, min_level, max_level, callbacks

Same as various Log::Dispatch::* classes.

=item -- dbh

Database handle where Log::Dispatch::DBI throws log message.

=item -- datasource, username, password

If database connection is not yet established, put the DSN, username
and password for DBI connect method. Destructor method of
Log::Dispatch::DBI disconnects database handle, if the handle is made
inside by these parameters. (The method does not disconnect the handle
if it's supplied with C<dbh> parameter.)

=item -- table

Table name for logging. default is B<log>.

=item log_message

inherited from Log::Dispatch::Output.

=back

=head1 TABLE SCHEMA

Maybe something like this for MySQL.

  CREATE TABLE log (
      id        int unsigned NOT NULL PRIMARY KEY AUTO_INCREMENT,
      level     varchar(9) NOT NULL,
      message   text NOT NULL,
      timestamp timestamp
  );

For example,

  $log->log(level => 'info', message => 'too bad');

will execute the following SQL:

  INSERT INTO log (level, message) VALUES ('info', 'too bad');

If you change this behaviour, what you should do is to subclass
Log::Dispatch::DBI and override C<create_statement> and C<log_message>
method.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch>, L<DBI>, L<Log::Dispatch::Config>

=cut
