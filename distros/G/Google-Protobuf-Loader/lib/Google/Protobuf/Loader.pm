package Google::Protobuf::Loader;

use strict;
use warnings;
use utf8;

use Carp;
use English;
use File::Spec::Functions 'catfile';
use Google::ProtocolBuffers::Dynamic;

our $VERSION = '0.01';

# use Proto::Foo::Bar will search for lib/Foo/Bar.proto
# package "foo.bar_baz" in proto will give Proto::Foo::BarBaz in Perl
# import "Foo/Bar.proto" will search for lib/Foo/Bar.proto
#
# There is currently no options but here are possible options for the future:
#
# - Regex to match use statements that are intercepted by this module.
# - Whether the module is pushed or unshifted on @INC.
# - The name of the package prefix being used (if any).
# - Capitalization rules for the proto to Perl package translation
# - Support for non UTF-8 encoding in the input file.
# - Custom search path ignoring @INC (or in addition to @INC).

my %package_options;

my $IS_USED_HINT_KEY = 'Google::Protobuf::Loader/is_used';

sub import {  ## no critic (RequireArgUnpacking)
  my (undef) = shift @_;  # This is the package being imported, so our self.

  my $calling_pkg_name = caller(0);
  $^H{$IS_USED_HINT_KEY} = 1;

  while (defined (my $arg = shift)) {
    if ($arg eq 'map_options') {
      $package_options{$calling_pkg_name} = shift;
    } else {
      croak "Unknown parameter: $arg";
    }
  }
  push @INC, \&use_proto_file_hook;
  return;
}

# Search for the given proto file if the @INC directories and load it if found.
sub use_proto_file_hook {
  # The first argument is ourselves, this is the calling convention for
  # references added to @INC.
  my (undef, $module_name) = @_;
  return unless $^H{$IS_USED_HINT_KEY};
  return unless $module_name =~ s{^Proto/(.+)\.pm$}{$1.proto};
  my $calling_pkg_name = caller(0);
  return search_and_include($module_name, $calling_pkg_name);
}

my %SEARCH_PROTO;
my %INC_PROTO;

sub search_and_include {
  my ($file_name, $calling_pkg_name) = @_;
  return \'1;' if $INC_PROTO{$file_name};
  croak "Infinite loop while loading ${file_name}" if exists $SEARCH_PROTO{$file_name};
  $SEARCH_PROTO{$file_name} = 1;
  for my $inc (@INC) {
    next if (!defined $inc || ref $inc);
    my $test_file_path = catfile($inc, $file_name);
    next unless -f $test_file_path;
    load_proto_file($test_file_path, $file_name, $calling_pkg_name);
    $INC_PROTO{$file_name} = 1;
    delete $SEARCH_PROTO{$file_name};
    return \'1;';
  }
  return;
}

# Load one proto file, following the convention of the @INC processing. See the
# reference in: https://perldoc.perl.org/functions/require
#
# Succeeds (and returns nothing) or dies.
my $dyn_pb = Google::ProtocolBuffers::Dynamic->new();

sub load_proto_file {
  my ($full_file_name, $rel_file_name, $calling_pkg_name) = @_;
  my $content = read_file($full_file_name);
  # Unfortunately, the Google::ProtocolBuffers::Dynamic module does not support
  # using the root package.
  if ($content !~ m/^\s* package \s* ([a-zA-Z0-9._]+) \s* ;/mx) {
    croak "No package definition in '${rel_file_name}'";
  }
  my $package = $1;
  while ($content =~ m{^\s* import \s* " ([a-zA-Z0-9._/]+) " \s* ;}mgx) {
    search_and_include($1, $calling_pkg_name);
  }
  $dyn_pb->load_string($rel_file_name, $content);
  my $prefix = $package =~ s/(^|\.|_)(.)/($1 eq '.' ? '::' : '').uc($2)/egr;
  my %options;
  if (exists $package_options{$calling_pkg_name}) {
    %options = (options => $package_options{$calling_pkg_name});
  }
  $dyn_pb->map({package => $package, prefix => "Proto::${prefix}", %options});
  return;
}

sub read_file {
  my ($file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file
      or croak "Cannot open file '${file}' for reading: ${ERRNO}\n";
  my $data;
  {
    local $RS = undef;
    $data = <$fh>;
  }
  close $fh or croak "Cannot close file '${file}' after read: ${ERRNO}\n";
  return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Google::Protobuf::Loader - Automatically load .proto file using the standard
"use" syntax.

=head1 SYNOPSIS

  use Google::Protobuf::Loader;
  use Proto::Foo::Bar;

  my $proto = Proto::Foo::Bar::Baz->new();
  print $proto->message_descriptor()->full_name();  # prints foo.Bar

=head1 DESCRIPTION

This module uses L<Google::ProtocolBuffers::Dynamic> to load F<.proto> files
using a standard C<use> syntax.

I<Note>: To install the L<Google::ProtocolBuffers::Dynamic> module and its
dependencies you need to have some Protocol Buffer headers on your system that
are provided, at least on Debian based systems, by the C<libprotoc-dev> package.

Once loaded with C<use Google::Protobuf::Loader;> this module will intercept
C<use> statement with a bare-word or filename starting with C<Proto::> (or
C<Proto/>). When they are seen, the module will then search for a F<.proto> file
matching the name used, including its capitalization, but without its C<Proto>
prefix. For example C<use Proto::Foo::Bar;> will search for a file named
F<Foo/Bar.proto>. The search is performed in the standard C<@INC> directories
(but does not execute any of the hooks that this may contain).

When such a file is found, it is parsed by L<Google::ProtocolBuffers::Dynamic>
and loaded in a Perl package named based on the C<package> declaration in the
F<.proto> file (that declaration is required when using this module). The Perl
package name is generated by turning the I<snake-case> proto package into a
I<camel-case> name and prefixing it with C<Proto>. For example,
C<package foo.bar_baz;> in the F<.proto> file will give a Perl
C<Proto::Foo::BarBaz> package containing the class definition for all the
messages defined in the proto file.

The proto files that are loaded by this module can use C<import> statements. In
that case, the proto file that they name are searched for in the C<@INC>
directories as-is (without any change to their name). The packages that they
name are loaded in Perl following the same rule as described above.

For the API of the generated classes, please refer to the documentation of
L<Google::ProtocolBuffers::Dynamic>, especially its
L<Language Mapping section|Google::ProtocolBuffers::Dynamic/"LANGUAGE MAPPING">,
and L<Google::ProtocolBuffers::Dynamic::Message>.

=head1 OPTIONS

You can pass options to the module when it is loaded initially:

  use Google::Protobuf::Loader option => value, ...;

Currently, a single option is supported: C<map_options> whose value must be a
hash reference containing options passed to the
L<map call|Google::ProtocolBuffers::Dynamic/"map"> used with
L<Google::ProtocolBuffers::Dynamic> to load the proto. The list of
L<supported options is here|Google::ProtocolBuffers::Dynamic/"OPTIONS">.

Note that this option will apply only for F<.proto> files loaded from the same
package as where the option is set. However, any F<.proto> file is only loaded
once in a program, the first time that is is required. So you should either pass
the same options all the time or ensure that you only loads proto files that are
not used anywhere else.

=head1 AUTHOR

Mathias Kende L<mailto:mathias@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over

=item *

L<Google::ProtocolBuffers::Dynamic>: The underlying library used by this module.

=item *

L<Google::ProtocolBuffers::Dynamic::Message>: The interface implemented by the
class generated for loaded protocol buffers.

=item *

L<Google::ProtocolBuffers>: Another protocol buffer implementation in Perl.

=back

=cut
