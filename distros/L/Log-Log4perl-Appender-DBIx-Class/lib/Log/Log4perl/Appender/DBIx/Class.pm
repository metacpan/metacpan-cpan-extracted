package Log::Log4perl::Appender::DBIx::Class;

use strict;
use warnings;

use Carp;

our @ISA = qw(Log::Log4perl::Appender);

our $VERSION = '0.02';

sub new {
    my $class = shift;

    my $self = { @_ };

    die 'Must supply a schema' unless(exists($self->{schema}));
    unless (ref($self->{schema})) {
      eval "require $self->{schema}";
      die "failed to load $self->{schema}: $@" if $@;
      $self->{schema} = $self->{schema}->connect( $self->{connect_info} );
    }

    $self->{class}           ||= 'Log';
    $self->{category_column} ||= 'category';
    $self->{level_column}    ||= 'level';
    $self->{message_column}  ||= 'message';

    return bless($self, $class);
}

sub log {
    my $self = shift;
    my %p = @_;

    #%p is
    #    { name    => $appender_name,
    #      level   => loglevel
    #      message => $message,
    #      log4p_category => $category,
    #      log4p_level  => $level,);
    #    },

    my $rs = $self->{schema}->resultset($self->{class});
    unless(defined($rs)) {
        carp('Could not find resultset for "'.$self->{class}.'"');
        return;
    }

    my $message = $p{message};
    chomp($message);

    my $row = $rs->new_result({
        $self->{message_column} => $message,
        $self->{category_column} => $p{log4p_category},
        $self->{level_column} => $p{log4p_level}
    });

    if(defined($self->{other_columns}) && ref($self->{other_columns}) eq 'ARRAY') {
        foreach my $col (@{ $self->{other_columns}}) {
            $row->$col($self->{$col});
        }
    }

    # people should probably use DBIx::Class::TimeStamp instead of this
    if($self->{datetime_column}) {
        my $accessor = $self->{datetime_column};
        $row->$accessor($self->{datetime_subref}->());
    }

    $row->insert;
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::DBIx::Class - appender for DBIx::Class

=head1 SYNOPSIS

  my $dbic_appender = Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::DBIx::Class',
    schema => $schema,
    class => 'Message',
  );

  $log->add_appender($dbic_appender);

  $log->error('Hello!');

=head1 DESCRIPTION

This is a specialized Log4perl appender that allows you to log to with
DBIx::Class.  Each appender can use a different (or the same) class and
each column is configurable.

=head1 PARAMETERS

These can be supplied to Appender's C<new> method.

=over 4

=item B<schema>

The schema object or class to use.  If a class is passed instead of an object,
connect will be called with the B<connect_info> passes as connection args.

=item B<class>

The resultset class to use for logging.  Defaults to 'Log'.

=item B<category_column>

The column in which to store the Log4perl category.  Defaults to 'category'.

=item B<connect_info>

Argument passed to connect if an unconnected schema was passed.

=item B<level_column>

The column in which to store the Log4perl level.  Defaults to 'level'.

=item B<message_column>

The column in which to store the Log4perl message.  Defaults to 'message'. In
case you are wondering (I was), this column WILL received the formatted message
as defined by the appender's layout.

=item B<other_columns>

This parameter allows you to pass in an arrayref of arbitrary column names.
At the time the row is created, this arrayref will be iterated over and any
column names will be set:

  foreach my $col (@{ $self->{column_names}}) {
      $row->$col($self->{$col});
  }

This allows you to specificy arbitrary options when you create the appender
and have the logged in any rows created.  An example is in order:

  my $appender = Log::Log4perl::Appender->new(
      'Log::Log4perl::Appender::DBIx::Class',
      schema => $schema,
      class => 'Message',
      user => 'someuser',
      other_columns => [qw(user)]
  );

This will cause any Message objects that are logged to have their C<user>
column set to 'someuser'.

=back

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 CONTRIBUTORS

Arthur Axel "fREW" Schmidt

=head1 SEE ALSO

L<Log::Log4perl>, L<DBIx::Class>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
