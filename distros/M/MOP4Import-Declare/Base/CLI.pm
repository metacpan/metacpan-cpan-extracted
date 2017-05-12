package MOP4Import::Base::CLI;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro qw/c3/;

use File::Basename ();
use Data::Dumper ();

use MOP4Import::Base::Configure -as_base, qw/FieldSpec/
  , [fields =>
     [quiet => doc => 'to be (somewhat) quiet']
   ];
use MOP4Import::Util qw/parse_opts terse_dump fields_hash fields_array
			take_hash_opts_maybe/;
use MOP4Import::Util::FindMethods;

#========================================

sub run {
  my ($class, $arglist, $opt_alias) = @_;

  my MY $self = $class->new($class->parse_opts($arglist, undef, $opt_alias));

  unless (@$arglist) {
    # Invoke help command if no arguments are given.
    $self->cmd_help
  }

  my $cmd = shift @$arglist;
  if (my $sub = $self->can("cmd_$cmd")) {
    # Invoke official command.

    $sub->($self, @$arglist);

  } elsif ($sub = $self->can($cmd)) {
    # Invoke internal methods.

    my @res = $sub->($self, @$arglist);
    print join("\n", map {terse_dump($_)} @res), "\n"
      if not $self->{quiet} and @res;

    if ($cmd =~ /^has_/) {
      # If method name starts with 'has_' and result is empty,
      # exit with 1.
      exit(@res ? 0 : 1);

    } elsif ($cmd =~ /^is_/) {
      # If method name starts with 'is_' and first result is false,
      # exit with 1.
      exit($res[0] ? 0 : 1);
    }

  } else {
    $self->cmd_help("Error: No such command '$cmd'\n");
  }
}

sub run_with_context {
  my ($class, $arglist, $opt_alias) = @_;
  my MY $self = $class->new($class->parse_opts($arglist, undef, $opt_alias));
  unless (@$arglist) {
    $self->cmd_help
  }
  my $cmd = shift @$arglist;
  if (my $sub = $self->can("cmd_$cmd")) {
    $sub->($self, $self->parse_opts($arglist, +{}), @$arglist);
  } elsif ($sub = $self->can($cmd)) {
    if ($cmd =~ /^is/) {
      exit($sub->($self, $self->parse_opts($arglist, +{}), @$arglist) ? 0 : 1);
    } else {
      my @res = $sub->($self, $self->parse_opts($arglist, +{}), @$arglist);
      print join("\n", map {terse_dump($_)} @res), "\n" if @res;
    }
  } else {
    die "$0: No such command $cmd\n";
  }
}

sub cmd_help {
  my $self = shift;
  my $pack = ref $self || $self;
  my $fields = fields_hash($self);
  my $names = fields_array($self);
  my @methods = FindMethods($pack, sub {s/^cmd_//});
  die join("\n", @_, <<END);
Usage: @{[File::Basename::basename($0)]} [--opt=value].. <command> [--opt=value].. ARGS...

Commands:
  @{[join("\n  ", @methods)]}

Options: 
  --@{[join "\n  --", map {
  if (ref (my FieldSpec $fs = $fields->{$_})) {
    join("\t  ", $_, ($fs->{doc} ? $fs->{doc} : ()));
  } else {
    $_
  }
} grep {/^[a-z]/} @$names]}
END
}

1;

__END__

=head1 NAME

MOP4Import::Base::CLI - Base class for Command Line Interface app.

=head1 SYNOPSIS

F<MyCLI.pm>  (chmod a+x this!).

  #!/usr/bin/env perl
  package MyCLI;
  use MOP4Import::Base::CLI -as_base, qw/terse_dump/,
      [fields =>
         qw/verbose debug _dbh/,
         [dbname =>
             doc => "filename of sqlite3 database",
             default => "myapp.db"]
      ];
  
  use MOP4Import::Types
    TableInfo => [[fields => qw/
  			       TABLE_SCHEM
  			       TABLE_NAME
  			       TABLE_CAT
  			       TABLE_TYPE
  			       REMARKS
  			     /]];
  
  sub cmd_tables {
    (my MY $self, my ($pattern, $type)) = @_;
    my $sth = $self->DBH->table_info(undef, undef
  				   , $pattern // '%'
  				   , $type // 'TABLE');
    while (my TableInfo $row = $sth->fetchrow_hashref) {
      print $self->{verbose} ? terse_dump($row) : $row->{TABLE_NAME}, "\n";
    }
  }
  
  use DBI;
  sub DBH {
    (my MY $self) = @_;
    $self->{_dbh} //= do {
      DBI->connect("dbi:SQLite:dbname=$self->{dbname}", undef, undef
  		 , {PrintError => 0, RaiseError => 1, AutoCommit => 1});
    };
  }
  
  MY->run(\@ARGV) unless caller;
  1;

Then from command line:

=for code sh

  % ./MyCLI.pm
  Usage: MyCLI.pm [--opt-value].. <command> [--opt-value].. ARGS...
  
  Commands:
    help
    tables
  
  Options:
    --verbose
    --debug
    --dbname        filename of sqlite3 database
  % sqlite3 myapp.db "create table foo(x,y)"
  % ./MyCLI.pm tables
  foo
  % ./MyCLI.pm --verbose tables
  {'REMARKS' => undef,'TABLE_NAME' => 'foo','TABLE_SCHEM' => 'main','sqlite_sql' => 'CREATE TABLE foo(x,y)','TABLE_TYPE' => 'TABLE','TABLE_CAT' => undef}
  % 

=head1 DESCRIPTION

MOP4Import::Base::CLI is a
L<MOP4Import|MOP4Import::Intro> family
and an easy-to-start base class for Command Line Interface applications.

=head1 METHODS

=head2 run (\@ARGV)

  MY->run(\@ARGV) unless caller;
  1;

This parses minimum posix style options (C<--name> or C<--name=value>)
and create your object with them.
Then C<cmd_...> entry method of
your object will be invoked with first word argument.

