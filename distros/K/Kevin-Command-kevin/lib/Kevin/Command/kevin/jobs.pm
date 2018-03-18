
package Kevin::Command::kevin::jobs;
$Kevin::Command::kevin::jobs::VERSION = '0.6.0';
# ABSTRACT: Command to list Minion jobs
use Mojo::Base 'Mojolicious::Command';

use Kevin::Commands::Util ();
use Mojo::Util qw(getopt);
use Text::Yeti::Table qw(render_table);
use Time::HiRes qw(time);

has description => 'List Minion jobs';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $app    = $self->app;
  my $minion = $app->minion;

  my ($args, $options) = ([], {});
  getopt \@args,
    'l|limit=i'  => \(my $limit  = 100),
    'o|offset=i' => \(my $offset = 0),
    'q|queue=s'  => \$options->{queue},
    'S|state=s'  => \$options->{state},
    't|task=s'   => \$options->{task};

  my $results = $minion->backend->list_jobs($offset, $limit, $options);
  my $items = $results->{jobs};

  my $spec = $self->_table_spec;
  render_table($items, $spec);
}

*_created_since = *Kevin::Commands::Util::_created_since;
*_job_status    = *Kevin::Commands::Util::_job_status;

sub _table_spec {

  my $now = time;
  return [
    qw(id),
    ['priority', undef, 'PRI'],
    qw( task state queue ),
    ['created', sub { _created_since($now - shift) }],
    ['state', sub { _job_status($_[1], $now) }, 'STATUS'],
    qw(worker),
  ];
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   Usage: APPLICATION kevin jobs [OPTIONS]
#pod
#pod     ./myapp.pl kevin jobs
#pod     ./myapp.pl kevin jobs -l 10 -o 20
#pod     ./myapp.pl kevin jobs -q important -t foo -S inactive
#pod
#pod   Options:
#pod     -h, --help                  Show this summary of available options
#pod     -l, --limit <number>        Number of jobs to show when listing
#pod                                 them, defaults to 100
#pod     -o, --offset <number>       Number of jobs to skip when listing
#pod                                 them, defaults to 0
#pod     -q, --queue <name>          List only jobs in this queue
#pod     -S, --state <name>          List only jobs in this state
#pod     -t, --task <name>           List only jobs for this task
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Kevin::Command::kevin::jobs> lists jobs at a L<Minion> queue.
#pod It produces output as below.
#pod
#pod     ID       PRI    TASK         STATE      QUEUE           CREATED          STATUS                    WORKER
#pod     925851   0      resize       finished   image-resizer   7 minutes ago    Finished 7 minutes ago    27297 
#pod     925838   1000   search       failed     item-searcher   13 minutes ago   Failed 13 minutes ago     27191 
#pod     925835   1000   upload       finished   uploader        13 minutes ago   Finished 13 minutes ago   27185 
#pod     925832   1000   search       finished   item-searcher   13 minutes ago   Finished 13 minutes ago   27188 
#pod     925831   100    poke         failed     poker           13 minutes ago   Failed 13 minutes ago     26819 
#pod     925830   100    poke         failed     poker           31 hours ago     Failed 31 hours ago       26847 
#pod
#pod =head1 ATTRIBUTES
#pod
#pod L<Kevin::Command::kevin::jobs> inherits all attributes from
#pod L<Mojolicious::Command> and implements the following new ones.
#pod
#pod =head2 description
#pod
#pod   my $description = $command->description;
#pod   $command        = $command->description('Foo');
#pod
#pod Short description of this command, used for the command list.
#pod
#pod =head2 usage
#pod
#pod   my $usage = $command->usage;
#pod   $command  = $command->usage('Foo');
#pod
#pod Usage information for this command, used for the help screen.
#pod
#pod =head1 METHODS
#pod
#pod L<Kevin::Command::kevin::jobs> inherits all methods from
#pod L<Mojolicious::Command> and implements the following new ones.
#pod
#pod =head2 run
#pod
#pod   $command->run(@ARGV);
#pod
#pod Run this command.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Minion>, L<Minion::Command::minion::job>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Kevin::Command::kevin::jobs - Command to list Minion jobs

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

  Usage: APPLICATION kevin jobs [OPTIONS]

    ./myapp.pl kevin jobs
    ./myapp.pl kevin jobs -l 10 -o 20
    ./myapp.pl kevin jobs -q important -t foo -S inactive

  Options:
    -h, --help                  Show this summary of available options
    -l, --limit <number>        Number of jobs to show when listing
                                them, defaults to 100
    -o, --offset <number>       Number of jobs to skip when listing
                                them, defaults to 0
    -q, --queue <name>          List only jobs in this queue
    -S, --state <name>          List only jobs in this state
    -t, --task <name>           List only jobs for this task

=head1 DESCRIPTION

L<Kevin::Command::kevin::jobs> lists jobs at a L<Minion> queue.
It produces output as below.

    ID       PRI    TASK         STATE      QUEUE           CREATED          STATUS                    WORKER
    925851   0      resize       finished   image-resizer   7 minutes ago    Finished 7 minutes ago    27297 
    925838   1000   search       failed     item-searcher   13 minutes ago   Failed 13 minutes ago     27191 
    925835   1000   upload       finished   uploader        13 minutes ago   Finished 13 minutes ago   27185 
    925832   1000   search       finished   item-searcher   13 minutes ago   Finished 13 minutes ago   27188 
    925831   100    poke         failed     poker           13 minutes ago   Failed 13 minutes ago     26819 
    925830   100    poke         failed     poker           31 hours ago     Failed 31 hours ago       26847 

=head1 ATTRIBUTES

L<Kevin::Command::kevin::jobs> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Kevin::Command::kevin::jobs> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $command->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Minion>, L<Minion::Command::minion::job>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
