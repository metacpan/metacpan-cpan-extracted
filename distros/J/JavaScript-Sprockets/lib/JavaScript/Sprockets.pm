package JavaScript::Sprockets;

use warnings;
use strict;

use Any::Moose;
use List::MoreUtils qw/any/;
use File::Which qw/which/;
use IPC::Open3;

our $VERSION = '0.03';

has 'bin' => (
  is    => 'ro',
  isa   => 'Str',
  default => sub {
    my $path = which('sprocketize');
    die "sprocketize not available\n" if ! $path;
    return $path;
  }
);

has 'root' => (
  is    => 'rw',
  isa   => 'Str',
);

has 'load_paths' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub {[]},
);

sub add_load_path {push @{shift->load_paths}, @_}
sub _filter_load_path {grep {$_[1]->($_)} @{$_[0]->load_paths}}

sub remove_load_path {
  my ($self, @remove) = @_;
  $self->load_paths([
    $self->_filter_load_paths(sub {any {$_[0] ne $_} @remove})
  ]);
}

sub _build_options {
  my $self = shift;
  my @options = map {("-I", $_)} @{$self->load_paths};
  push @options, "-C", $self->root if $self->root;
  return @options;
}

sub concatenation {
  my ($self, @files) = @_;
  my $err = 1; # $err needs to be true for open3 to use it
  my $pid = open3(my $in, my $out, $err, $self->bin, $self->_build_options, @files);
  waitpid $pid, 0;
  my $stdout = join "", <$out>;
  my $stderr = join "", <$err>;
  warn $stderr if $stderr;
  return $stdout;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

JavaScript::Sprockets - create javascript concatenations

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Create javascript concatenations using the sprockets command-line tool. Read more about why using sprockets is useful at L<http://getsprockets.org>.

    use JavaScript::Sprockets;

    my $sp = JavaScript::Sprockets->new(
      load_paths => ["src/javascripts", "vendor/jquery"],
    );

    # a concatenation of app.js and its requirements
    my $concat = $sp->concatenation("app.js");

=head1 CONSTRUCTOR

=head2 new

Optional parameters include

=over 4

=item root

Change to this directory before doing anything.

=item load_paths

Search these directories for files. Takes an array reference.

=item bin

A path to the sprocketize program.

=back

=head1 METHODS

=over 4

=item concatenation

Build a concatention for the provided file.

=item add_load_path

Adds the provided directory to the load_path.

=item remove_load_path

Remove the provided directory from the load_path.

=back

=head1 AUTHOR

Lee Aylward, C<< <leedo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-javascript-sprockets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-Sprockets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::Sprockets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-Sprockets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JavaScript-Sprockets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JavaScript-Sprockets>

=item * Search CPAN

L<http://search.cpan.org/dist/JavaScript-Sprockets/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lee Aylward.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
