package Langertha::Raider::FileTools;
our $VERSION = '0.503';
# ABSTRACT: MCP::Server factory with local filesystem tools (list/read/write/edit)

use strict;
use warnings;
use Cwd qw( realpath );
use Path::Tiny;
use MCP::Server;

use Exporter 'import';
our @EXPORT_OK = qw( build_file_tools_server );


sub build_file_tools_server {
  my %args = @_;
  my $root = defined $args{root} ? path($args{root})->absolute : undef;
  my $root_realpath = $root ? realpath($root) : undef;
  die "Root does not exist: $root\n" if $root && !defined $root_realpath;
  my $real_root = $root ? path($root_realpath)->absolute : undef;

  my $assert_in_root = sub {
    my ($p) = @_;
    return unless $real_root;
    die "Path escapes root: $p\n" unless $real_root->subsumes($p);
    return;
  };

  my $nearest_existing = sub {
    my ($p) = @_;
    my $cur = $p;
    while (!-e $cur) {
      my $parent = $cur->parent;
      die "No existing parent for $p\n" if "$parent" eq "$cur";
      $cur = $parent;
    }
    return $cur;
  };

  my $resolve = sub {
    my ($path) = @_;
    my $p = path($path);
    if ($root) {
      $p = $p->is_absolute ? $p : $root->child($path);
      $p = $p->absolute;
      my $existing = $nearest_existing->($p);
      my $existing_realpath = realpath($existing)
        or die "Cannot resolve path: $existing\n";
      my $real_existing = path($existing_realpath)->absolute;
      $assert_in_root->($real_existing);
      if (-e $p) {
        my $p_realpath = realpath($p)
          or die "Cannot resolve path: $p\n";
        my $real_p = path($p_realpath)->absolute;
        $assert_in_root->($real_p);
        $p = $real_p;
      }
    }
    return $p;
  };

  my $resolve_for_write = sub {
    my ($path) = @_;
    my $p = $resolve->($path);
    return $p if -e $p;
    my $parent = $p->parent;
    my $existing = $nearest_existing->($parent);
    my $existing_realpath = realpath($existing)
      or die "Cannot resolve path: $existing\n";
    my $real_existing = path($existing_realpath)->absolute;
    $assert_in_root->($real_existing);
    return $p;
  };

  my $server = MCP::Server->new(name => 'raider-files', version => '1.0');

  $server->tool(
    name         => 'list_files',
    description  => 'List entries in a directory. Directories are suffixed with "/".',
    input_schema => {
      type       => 'object',
      properties => { path => { type => 'string', description => 'Directory path' } },
      required   => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a directory: $p", 1) unless -d $p;
      my @entries = sort map { -d $_ ? $_->basename . '/' : $_->basename } $p->children;
      return $tool->text_result(join("\n", @entries));
    },
  );

  $server->tool(
    name         => 'read_file',
    description  => 'Read the full contents of a text file.',
    input_schema => {
      type       => 'object',
      properties => { path => { type => 'string', description => 'File path' } },
      required   => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a file: $p", 1) unless -f $p;
      my $content = eval { $p->slurp_utf8 };
      return $tool->text_result("Error reading $p: $@", 1) if $@;
      return $tool->text_result($content);
    },
  );

  $server->tool(
    name         => 'write_file',
    description  => 'Write contents to a file. Creates parent directories, overwrites existing files.',
    input_schema => {
      type       => 'object',
      properties => {
        path    => { type => 'string', description => 'File path' },
        content => { type => 'string', description => 'Full file contents' },
      },
      required => ['path', 'content'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve_for_write->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      eval {
        $p->parent->mkpath unless -d $p->parent;
        $p->spew_utf8($in->{content});
      };
      return $tool->text_result("Error writing $p: $@", 1) if $@;
      return $tool->text_result("Wrote " . length($in->{content}) . " bytes to $p");
    },
  );

  $server->tool(
    name         => 'edit_file',
    description  => 'Replace an exact unique substring in a file (old_string must match exactly once).',
    input_schema => {
      type       => 'object',
      properties => {
        path       => { type => 'string', description => 'File path' },
        old_string => { type => 'string', description => 'Exact text to replace' },
        new_string => { type => 'string', description => 'Replacement text' },
      },
      required => ['path', 'old_string', 'new_string'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $tool->text_result("Error: not a file: $p", 1) unless -f $p;
      my $content = eval { $p->slurp_utf8 };
      return $tool->text_result("Error reading $p: $@", 1) if $@;
      my $old = $in->{old_string};
      my $count = () = $content =~ /\Q$old\E/g;
      return $tool->text_result("Error: old_string not found", 1) if $count == 0;
      return $tool->text_result("Error: old_string matches $count times, must be unique", 1) if $count > 1;
      $content =~ s/\Q$old\E/$in->{new_string}/;
      eval { $p->spew_utf8($content) };
      return $tool->text_result("Error writing $p: $@", 1) if $@;
      return $tool->text_result("Edited $p");
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::FileTools - MCP::Server factory with local filesystem tools (list/read/write/edit)

=head1 VERSION

version 0.503

=head1 DESCRIPTION

The file tools of L<raider>: an L<MCP::Server> with C<list_files(path)>,
C<read_file(path)>, C<write_file(path, content)> and
C<edit_file(path, old_string, new_string)>, confined to one directory.

=head2 build_file_tools_server

    my $server = Langertha::Raider::FileTools::build_file_tools_server(
        root => '/some/dir',  # optional confinement root
    );

Returns an L<MCP::Server> instance with the tools C<list_files>, C<read_file>,
C<write_file>, and C<edit_file> registered. When C<root> is set, all path
arguments are confined to that directory. Existing paths and nearest existing
parents are resolved with C<realpath>, so symlinks cannot be used to escape the
root.

=head1 SEE ALSO

=over

=item * L<MCP::Server>

=item * L<Langertha::Raider::CLI>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
