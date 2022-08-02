# Copyright (C) 2022  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Game::HexDescribe::Command::rule

=head1 SYNOPSIS

hex-describe rule [--table=B<table>] [--rule=B<rule>] [--limit=B<number>]

hex-describe rule --help

=head1 DESCRIPTION

Prints the random results of rules.

=head1 OPTIONS

C<--help> prints the man page.

C<--table> specifies the table to load.

Without C<--table>, print all the tables there are.

C<--rule> specifies the rule to use.

C<--text> specifies the text to use (with rules in square brackets).

Without C<--rule> or C<--text>, print all the rules there are.

C<--limit> limits the output to a certain number of entries. The default is 10.

C<--separator> changes the separator between entries. The default is two
newlines, three dashes, and two newlines ("\n\n---\n\n").

=head1 EXAMPLES

Find all orc related rules:

C<hex-describe rule --table=schroeder | grep orc>

Print an orc tribe:

C<hex-describe rule --table=schroeder --rule="orcs" --limit=1>

Print ten orc names:

C<hex-describe rule --table=schroeder --rule="orc name" --separator=\n

=cut

package Game::HexDescribe::Command::rule;

use Modern::Perl '2018';
use Mojo::Base 'Mojolicious::Command';
use Pod::Simple::Text;
use Getopt::Long qw(GetOptionsFromArray);
use Game::HexDescribe::Utils qw(markdown describe_text parse_table load_table list_tables);
use Role::Tiny;
binmode(STDOUT, ':utf8');

has description => 'Print the output of a rule to STDOUT';

has usage => sub { my $self = shift; $self->extract_usage };

sub run {
  my ($self, @args) = @_;
  my ($help, $table, $rule, $text, $limit, $separator);
  GetOptionsFromArray (
    \@args,
    "help" => \$help,
    "table=s" => \$table,
    "rule=s" => \$rule,
    "text=s" => \$text,
    "limit=i" => \$limit,
    "separator=s" => \$separator);
  if ($help) {
    seek(DATA, 0, 0); # read from this file
    my $parser = Pod::Simple::Text->new();
    $parser->output_fh(*STDOUT);
    $parser->parse_lines(<DATA>);
    return 1;
  }
  my $dir = $self->app->config('contrib');
  if (not $table) {
    say for list_tables($dir);
    return 1;
  }
  if (not $rule and not $text) {
    say for keys %{parse_table(load_table($table, $dir))};
    return 1;
  }
  my $data = parse_table(load_table($table, $dir));
  $text //= "[$rule]\n" x ($limit || 10);
  say join("\n", markdown(describe_text($text, $data), $separator));
  1;
}

1;

__DATA__
