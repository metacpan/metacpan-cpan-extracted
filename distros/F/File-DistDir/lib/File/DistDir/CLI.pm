package File::DistDir::CLI;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use File::DistDir;
use File::Spec;

use parent qw(CLI::Simple);

our $VERSION = '1.0.0';

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  die "ERROR: --distribution is a required argument\n"
    if !$self->get_distribution;

  $self->set_resource_dir( File::DistDir->new( distribution => $self->get_distribution ) );

  return $self;
}

########################################################################
sub cmd_copy {
########################################################################
  my ($self) = @_;

  my ( $source, $destination ) = $self->get_args;

  die "ERROR: usage: dist-dir -d DISTRIBUTION [-r] cp SOURCE [DESTINATION]\n"
    if !defined $source || ( !defined $destination && $source ne q{.} );

  $self->get_resource_dir->copy( $source, $destination, recursive => $self->get_recursive );

  return $SUCCESS;
}

########################################################################
sub cmd_dir {
########################################################################
  my ($self) = @_;

  print {*STDOUT} $self->get_resource_dir->dir;
  return $SUCCESS;
}

########################################################################
sub cmd_ls {
########################################################################
  my ($self) = @_;

  _print_tree( $self->get_resource_dir->dir );
  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    help|h
    distribution|d=s
    recursive|r
  );

  my %commands = (
    cp      => \&cmd_copy,
    dir     => \&cmd_dir,
    ls      => \&cmd_ls,
    default => 'dir',
  );

  my $cli = __PACKAGE__->new(
    option_specs    => \@option_specs,
    default_options => {},
    extra_options   => [qw(resource_dir)],
    commands        => \%commands,
  );

  return $cli->run();
}

########################################################################
sub _print_tree {
########################################################################
  my ( $root, $prefix ) = @_;

  $prefix //= q{};

  opendir my $dh, $root
    or return;

  my @entries = sort grep { $_ ne q{.} && $_ ne q{..} } readdir $dh;
  closedir $dh;

  for my $i ( 0 .. $#entries ) {
    my $entry   = $entries[$i];
    my $full    = File::Spec->catfile( $root, $entry );
    my $is_last = $i == $#entries;

    print {*STDOUT} $prefix;
    print {*STDOUT} $is_last ? '└── ' : '├── ';
    print {*STDOUT} "$entry\n";

    if ( -d $full && !-l $full ) {
      _print_tree( $full, $prefix . ( $is_last ? '    ' : '│   ' ) );
    }
  }

  return;
}

1;

__END__

=pod

=head1 NAME

File::DistDir::CLI - command-line interface for installed distribution resources

=head1 SYNOPSIS

  dist-dir -d Bedrock dir
  dist-dir -d Bedrock ls
  dist-dir -d Bedrock cp config/tagx.xml ./config/
  dist-dir -d Bedrock -r cp config config
  dist-dir -d Bedrock -r cp .

=head1 DESCRIPTION

This module implements C<dist-dir>, a command-line wrapper around the
L<File::DistDir> object interface. The distribution name is a CPAN
distribution name, not a Perl package name.

=head2 Commands

=over 4

=item dir

Print the installed share-directory path.

=item ls

Print a recursive tree of resources.

=item cp SOURCE [DESTINATION]

Copy a file or, with C<-r>, a directory's B<contents> into the destination.
For C<-r cp .>, the destination defaults to the current directory.
Existing files may be overwritten. For detailed semantics and safety
restrictions see L<File::DistDir/copy(SOURCE, DESTINATION, recursive => 1)>.

=back

=head2 Options

=over 4

=item B<-d, --distribution NAME>

Required distribution name.

=item B<-r, --recursive>

Permit directory copying with the C<cp> command.

=item B<-h, --help>

Show command help.

=back

=head1 SEE ALSO

L<File::DistDir>, L<File::ShareDir>

=cut
